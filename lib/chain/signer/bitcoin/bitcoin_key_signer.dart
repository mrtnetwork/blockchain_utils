import 'package:blockchain_utils/chain/signer/core/core.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/chain/signer/signer.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Shared Bitcoin signing helpers: curve parameters and message hashing.
class BitcoinSignerUtils {
  static const String signMessagePrefix = '\x18Bitcoin Signed Message:\n';

  /// The generator point for the Secp256k1 curve.
  static Secp256k1Point get generator => Secp256k1Point.generator_;

  /// The base length of the curve associated with the generator.
  static const int baselen = 32;

  /// Calculates a private tweak for a given secret and tweak value.
  ///
  /// The tweak is applied to the negation of the secret key, and the result is adjusted based on
  /// the parity of the corresponding public key.
  ///
  /// Throws [ArgumentException] if [secret] or [tapTweakHash] is not a
  /// 32-byte array, and [CryptoSignException] if the tweaked key cannot
  /// be derived.
  static List<int> calculatePrivateTweak(
    List<int> secret,
    List<int> tapTweakHash,
  ) {
    if (tapTweakHash.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "calculatePrivateTweak",
        name: "tapTweakHash",
        reason: "The tap tweak hash must be 32-byte array.",
      );
    }
    if (secret.length != baselen) {
      throw CoreErrors.invalidOperationArguments(
        "calculatePrivateTweak",
        name: "secret",
        reason: "The secret must be $baselen-byte array.",
      );
    }
    final tweak = Secp256k1Fr.fromBytesUnchecked(tapTweakHash);
    var negatedKey = Secp256k1Fr.fromBytesUnchecked(secret);
    final publicBytes = (generator * negatedKey).toBytes(
      CryptoKeyEncoding.uncompressed,
    );
    if (publicBytes.length != 1 + 2 * baselen) {
      throw CoreErrors.signInvalidArguments(
        "calculatePrivateTweak",
        name: "secret",
        reason: "Cannot derive public key from secret.",
      );
    }
    if ((publicBytes.last & 1) == 1) {
      negatedKey = -negatedKey;
    }
    final tw = negatedKey + tweak;
    return tw.toBytes();
  }

  /// Adds a magic prefix to a message for Bitcoin signing.
  ///
  /// The magic prefix includes the message prefix and the length of the message.
  static List<int> _magicPrefix(List<int> message, List<int> messagePrefix) {
    final encodeLength = IntUtils.encodeVarint(message.length);

    return [...messagePrefix, ...encodeLength, ...message];
  }

  /// Applies the magic prefix and calculates the SHA-256 hash of the message for Bitcoin signing.
  ///
  /// The message prefix is expected to start with the safe Bitcoin message prefix (0x18).
  static List<int> magicMessage(List<int> message, String messagePrefix) {
    final prefixBytes = StringUtils.encode(messagePrefix);
    final magic = _magicPrefix(message, prefixBytes);
    return QuickCrypto.sha256Hash(magic);
  }
}

/// Bitcoin signer: ECDSA (DER), BIP-340 Schnorr, and legacy Schnorr signing,
/// plus Bitcoin's message-signing format.
class BitcoinKeySigner
    extends ISignatureSigner<ISecp256k1VerificationKey, ISecp256k1SigningKey> {
  const BitcoinKeySigner(super.signingKey);

  /// Factory constructor for creating a [BitcoinKeySigner] from private key bytes.
  factory BitcoinKeySigner.fromKeyBytes(List<int> privateKeyBytes) {
    final signingKey = Secp256k1PrivateKey.fromBytes(privateKeyBytes);
    return BitcoinKeySigner(signingKey);
  }

  /// Signs a given digest using the BIP-340 (Schnorr) signature scheme.
  ///
  /// - [digest]: The 32-byte message digest to be signed. It must be exactly
  ///   `BitcoinSignerUtils.baselen` bytes in length.
  /// - [tapTweakHash]: (Optional) A tweak applied to the private key for
  ///   Taproot-related signatures.
  /// - [aux]: (Optional) Auxiliary random data used to add entropy to the
  ///   signature for security against side-channel attacks.
  SignedContent<IECDSASignature> signBip340({
    required List<int> digest,
    List<int>? tapTweakHash,
    List<int>? aux,
  }) {
    final signature = signingKey.signBip340(
      Secp256k1Bip340SigningParams(
        digest: digest,
        aux: aux,
        tapTweakHash: tapTweakHash,
      ),
    );
    return SignedContent(signature: signature, encoded: signature.toBytes());
  }

  /// Signs the given transaction digest using Schnorr signature (old style).
  ///
  /// - [digest]: The transaction digest (message) to sign.
  SignedContent<IECDSASignature> signSchnorr(
    List<int> digest, {
    List<int>? extraEntropy,
  }) {
    final signature = signingKey.signSchnorr(
      Secp256k1SigningParams(digest: digest, extraEntropy: extraEntropy),
    );
    return SignedContent(signature: signature, encoded: signature.toBytes());
  }

  /// Signs a message using Bitcoin's message signing format.
  ///
  /// - [message]: The raw message to be signed.
  /// - [messagePrefix]: The prefix used for Bitcoin's message signing.
  /// - [extraEntropy]: Optional extra entropy to modify the signature.
  SignedContent<IECDSASignature> signMessage({
    required List<int> message,
    bool hashMessage = true,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
    List<int> extraEntropy = const [],
  }) {
    List<int> messageHash = message;
    if (hashMessage) {
      messageHash = QuickCrypto.sha256Hash(
        BitcoinSignerUtils.magicMessage(message, messagePrefix),
      );
    }
    final signature = signingKey.sign(
      Secp256k1SigningParams(digest: messageHash, extraEntropy: extraEntropy),
    );
    return SignedContent<IECDSASignature>(
      signature: signature,
      encoded: signature.toBytes(encoding: ECDSASignatureEncoding.bip137),
      content: messageHash,
    );
  }

  /// Signs the given transaction digest using ECDSA (DER-encoded).
  ///
  /// Retries with incrementing extra entropy if the DER-encoded R value comes
  /// out 33 bytes (i.e. needs a leading zero byte), so the result stays a
  /// consistent, minimal length.
  ///
  /// - [digest]: The transaction digest (message) to sign.
  ///
  /// Throws [CryptoSignException] if a minimal-length signature cannot be
  /// produced within [maxDerRetryAttempts] retries.
  static const int maxDerRetryAttempts = 255;

  SignedContent<IECDSASignature> signECDSADer(
    List<int> digest, {
    List<int>? extraEntropy,
  }) {
    List<int> derBytes(IECDSASignature sig) =>
        sig.toBytes(encoding: ECDSASignatureEncoding.der);
    IECDSASignature signature = signingKey.sign(
      Secp256k1SigningParams(digest: digest, extraEntropy: extraEntropy),
    );
    BigInt attempt = BigInt.one;
    List<int> der = derBytes(signature);
    if (der.length <= 3) {
      throw CoreErrors.signInvalidArguments(
        "signECDSADer",
        name: "digest",
        reason: "Cannot DER-encode signature.",
      );
    }
    int lengthR = der[3];
    int retries = 0;
    while (lengthR == 33) {
      if (retries++ >= maxDerRetryAttempts) {
        throw BuError(DefaultErrorType.invalidLength,
          "Cannot produce minimal-length DER signature.",
          details: {"retries": retries.toString()},
        );
      }
      signature = signingKey.sign(
        Secp256k1SigningParams(
          digest: digest,
          extraEntropy: [
            ...extraEntropy ?? [],
            ...attempt.toBeBytes(length: 32),
          ],
        ),
      );
      attempt += BigInt.one;
      der = derBytes(signature);
      if (der.length <= 3) {
        throw CoreErrors.signInvalidArguments(
          "signECDSADer",
          name: "digest",
          reason: "Cannot DER-encode signature.",
        );
      }
      lengthR = der[3];
    }
    return SignedContent<IECDSASignature>(
      signature: signature,
      content: digest,
      encoded: signature.toBytes(encoding: ECDSASignatureEncoding.der),
    );
  }

  @override
  BitcoinSignatureVerifier toVerifier() {
    return BitcoinSignatureVerifier(signingKey.verificationKey());
  }
}

/// Verifies Bitcoin ECDSA/Schnorr signatures and recovers public keys from them.
class BitcoinSignatureVerifier
    extends ISignatureVerifier<ISecp256k1VerificationKey> {
  /// The ECDSA verification key associated with this Bitcoin verifier.
  // final ISecp256k1VerificationKey verifyKey;
  const BitcoinSignatureVerifier(super.verificationKey);

  factory BitcoinSignatureVerifier.fromKeyBytes(List<int> publicKey) {
    final verifyKey = Secp256k1PublicKey.fromBytes(publicKey);
    return BitcoinSignatureVerifier(verifyKey);
  }

  /// Verifies a BIP-340 Schnorr signature using an x-only public key.
  ///
  /// - [xOnly]: A 32-byte x-only public key (corresponding to the Taproot key).
  /// - [digest]: A 32-byte message digest that was signed.
  /// - [signature]: A 64-byte Schnorr signature (`R.x || s`).
  /// - [tapTweakHash] (optional): A 32-byte tweak hash used to modify the public key.
  static bool verifyBip340SignatureUsingXOnly({
    required List<int> xOnly,
    required List<int> digest,
    required List<int> signature,
    List<int>? tapTweakHash,
  }) {
    return ISecp256k1VerificationKey.verifyBip340SignatureUsingXOnly(
      xOnly: xOnly,
      digest: digest,
      signature: IECDSASignature.fromBytes(signature),
      tapTweakHash: tapTweakHash,
    );
  }

  /// Verifies a BIP-340 Schnorr signature using a public key.
  ///
  /// - [digest]: A 32-byte message digest that was signed.
  /// - [signature]: A 64-byte Schnorr signature (`R.x || s`).
  /// - [tapTweakHash] (optional): A 32-byte tweak hash used to modify the public key.
  bool verifyBip340Signature({
    required List<int> digest,
    required List<int> signature,
    List<int>? tapTweakHash,
  }) {
    return verificationKey.verifyBip340Signature(
      signature: IECDSASignature.fromBytes(signature),
      params: Secp256k1Bip340SigningParams(
        digest: digest,
        tapTweakHash: tapTweakHash,
      ),
    );
  }

  /// Verifies a Schnorr (old style) signature for a given digest.
  ///
  /// - [digest]: The hash or message digest that was signed.
  /// - [signature]: The Schnorr signature to verify.
  bool verifySchnorrSignature({
    required List<int> digest,
    required List<int> signature,
  }) {
    return verificationKey.verifySchnorrSignature(
      signature: IECDSASignature.fromBytes(signature),
      params: Secp256k1SigningParams(digest: digest),
    );
  }

  /// Recovers the ECDSA public key from a Bitcoin signed message.
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: A 65-byte Bitcoin signature (including the recovery ID).
  /// - [messagePrefix] (optional): A custom prefix for the signed message
  ///   (default is Bitcoin's standard prefix).
  static Secp256k1PublicKey recoverPublicKey({
    required List<int> message,
    required List<int> signature,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
  }) {
    if (signature.length != 65) {
      throw CoreErrors.invalidOperationArguments(
        "recoverPublicKey",
        name: "signature",
        reason: "Invalid signature bytes length.",
      );
    }
    final List<int> messageHash = QuickCrypto.sha256Hash(
      BitcoinSignerUtils.magicMessage(message, messagePrefix),
    );
    final point = Secp256k1EcdsaUtils.recoverPublicKey(
      hash: messageHash,
      signature: IECDSASignature.fromBytes(
        signature,
        encoding: ECDSASignatureEncoding.bip137,
      ),
    );
    return Secp256k1PublicKey.fromBytes(point.toBytes());
  }

  /// Verifies a Bitcoin-signed message signature.
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: The ECDSA signature (64 or 65 bytes).
  /// - [messagePrefix] (optional): A custom prefix for the signed message
  ///   (default is Bitcoin's standard prefix).
  bool verifyMessageSignature({
    required List<int> message,
    required List<int> signature,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
  }) {
    bool wRecoveryId =
        signature.length ==
        CryptoSignerConst.ecdsaSignatureLength +
            CryptoSignerConst.ecdsaRecoveryIdLength;
    ECDSASignatureEncoding? encoding;
    if (wRecoveryId) {
      if (signature[0] >= 27) {
        encoding = ECDSASignatureEncoding.bip137;
      }
    }
    return verificationKey.verifyMessageSignature(
      message: message,
      signature: IECDSASignature.fromBytes(signature, encoding: encoding),
    );
  }

  /// Verifies an ECDSA DER-encoded signature against a given digest.
  ///
  /// - [digest]: The hash or message digest that was signed.
  /// - [signature]: The DER-encoded ECDSA signature to verify.
  bool verifyECDSADerSignature({
    required List<int> digest,
    required List<int> signature,
  }) {
    return verificationKey.verify(
      Secp256k1VerifyingParams(
        Secp256k1SigningParams(digest: digest),
        IECDSASignature.fromBytes(signature),
      ),
    );
  }
}
