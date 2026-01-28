import 'package:blockchain_utils/bip/address/p2tr_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/signer/signer.dart';
import 'package:blockchain_utils/signer/types/types.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class BitcoinSignerUtils {
  static const String signMessagePrefix = '\x18Bitcoin Signed Message:\n';

  /// The projective ECC (Elliptic Curve Cryptography) point generator for the Secp256k1 curve.
  static ProjectiveECCPoint get generator => Curves.generatorSecp256k1;

  /// The order of the generator point on the Secp256k1 curve.
  static BigInt get order => generator.order!;

  /// The base length of the curve associated with the generator.
  static int get baselen => generator.curve.baselen;

  /// Calculates a private tweak for a given secret and tweak value.
  ///
  /// The tweak is applied to the negation of the secret key, and the result is adjusted based on
  /// the parity of the corresponding public key.
  static List<int> calculatePrivateTweek(
    List<int> secret,
    List<int> tapTweakHash,
  ) {
    if (tapTweakHash.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "calculatePrivateTweek",
        name: "tapTweakHash",
        reason: "The tap tweak hash must be 32-byte array.",
      );
    }
    final tweakBig = BigintUtils.fromBytes(tapTweakHash);
    BigInt negatedKey = BigintUtils.fromBytes(secret);
    final publicBytes = (generator * negatedKey).toBytes(
      EncodeType.uncompressed,
    );
    final yBig = BigintUtils.fromBytes(
      publicBytes.sublist(EcdsaKeysConst.pubKeyCompressedByteLen),
    );
    if (yBig.isOdd) {
      negatedKey = order - negatedKey;
    }
    final tw = (negatedKey + tweakBig) % order;
    return BigintUtils.toBytes(tw, length: baselen);
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

class BitcoinKeySigner {
  final Secp256k1SigningKey _signingKey;
  Secp256k1SigningKey get signingKey => _signingKey;
  final BitcoinSignatureVerifier verifierKey;
  const BitcoinKeySigner._(this._signingKey, this.verifierKey);

  /// Factory constructor for creating a [BitcoinKeySigner] from private key bytes.
  factory BitcoinKeySigner.fromKeyBytes(List<int> privateKeyBytes) {
    final privateKey = Secp256k1SigningKey.fromBytes(keyBytes: privateKeyBytes);
    final verifyKey = BitcoinSignatureVerifier._(
      ECDSAVerifyKey(privateKey.privateKey.publicKey),
    );
    return BitcoinKeySigner._(
      Secp256k1SigningKey.fromBytes(keyBytes: privateKeyBytes),
      verifyKey,
    );
  }

  /// Signs a given digest using the BIP-340 (Schnorr) signature scheme.
  ///
  ///
  /// - [digest]: The 32-byte message digest to be signed. It must be exactly
  ///   `BitcoinSignerUtils.baselen` bytes in length.
  /// - [tapTweakHash]: (Optional) A tweak applied to the private key for
  ///   Taproot-related signatures.
  /// - [aux]: (Optional) Auxiliary random data used to add entropy to the
  ///   signature for security against side-channel attacks.
  List<int> signBip340({
    required List<int> digest,
    List<int>? tapTweakHash,
    List<int>? aux,
  }) {
    final signature = _signingKey.signBip340(
      digest: digest,
      aux: aux,
      tapTweakHash: tapTweakHash,
    );
    if (verifierKey.verifyBip340Signature(
      digest: digest,
      signature: signature,
      tapTweakHash: tapTweakHash,
    )) {
      return signature;
    }
    throw CryptoSignException.signatureVerificationFailed;
  }

  List<int> signBip340Const({
    required List<int> digest,
    List<int>? tapTweakHash,
    List<int>? aux,
  }) {
    final signature = _signingKey.signBip340Const(
      digest: digest,
      aux: aux,
      tapTweakHash: tapTweakHash,
    );
    if (verifierKey.verifyBip340Signature(
      digest: digest,
      signature: signature,
      tapTweakHash: tapTweakHash,
    )) {
      return signature;
    }
    throw CryptoSignException.signatureVerificationFailed;
  }

  /// Signs the given transaction digest using Schnorr signature (old style).
  ///
  /// - [digest]: The transaction digest (message) to sign.
  List<int> signSchnorr(List<int> digest, {List<int>? extraEntropy}) {
    final signature = _signingKey.signSchnorr(
      digest,
      extraEntropy: extraEntropy,
    );

    final verify = verifierKey.verifySchnorrSignature(
      digest: digest,
      signature: signature,
    );
    if (!verify) {
      throw CryptoSignException.signatureVerificationFailed;
    }
    return signature;
  }

  List<int> signSchnorrConst(
    List<int> digest, {
    List<int>? extraEntropy,
    Secp256k1ECmultGenContext? context,
  }) {
    final signature = _signingKey.signSchnorrConst(
      digest: digest,
      extraEntropy:
          extraEntropy ?? CryptoSignerConst.bchSchnorrRfc6979ExtraData,
    );
    final verify = verifierKey.verifySchnorrSignature(
      digest: digest,
      signature: signature,
    );
    if (!verify) {
      throw CryptoSignException.signatureVerificationFailed;
    }
    return signature;
  }

  /// Signs a message using Bitcoin's message signing format.
  ///
  /// - [message]: The raw message to be signed.
  /// - [messagePrefix]: The prefix used for Bitcoin's message signing.
  /// - [extraEntropy]: Optional extra entropy to modify the signature.
  ///
  List<int> signMessage({
    required List<int> message,
    bool hashMessage = true,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
    List<int> extraEntropy = const [],
  }) {
    List<int> messgaeHash = message;
    if (hashMessage) {
      messgaeHash = QuickCrypto.sha256Hash(
        BitcoinSignerUtils.magicMessage(message, messagePrefix),
      );
    }
    final signature = _signingKey.sign(
      digest: messgaeHash,
      extraEntropy: extraEntropy,
    );
    return [
      signature.$2 + 27,
      ...signature.$1.toBytes(BitcoinSignerUtils.baselen),
    ];
  }

  List<int> signMessageConst({
    required List<int> message,
    bool hashMessage = true,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
    List<int> extraEntropy = const [],
    Secp256k1ECmultGenContext? context,
  }) {
    List<int> messgaeHash = message;
    if (hashMessage) {
      messgaeHash = QuickCrypto.sha256Hash(
        BitcoinSignerUtils.magicMessage(message, messagePrefix),
      );
    }
    final signature = _signingKey.signConst(
      digest: messgaeHash,
      extraEntropy: extraEntropy,
    );
    return [
      signature.$2 + 27,
      ...signature.$1.toBytes(BitcoinSignerUtils.baselen),
    ];
  }

  /// Signs the given transaction digest using ECDSA (DER-encoded).
  ///
  /// - [digest]: The transaction digest (message) to sign.
  ///
  List<int> signECDSADer(List<int> digest, {List<int>? extraEntropy}) {
    List<int> signature = _signingKey.signDer(
      digest: digest,
      extraEntropy: extraEntropy,
    );
    BigInt attempt = BigInt.one;
    int lengthR = signature[3];
    while (lengthR == 33) {
      signature = _signingKey.signDer(
        digest: digest,
        extraEntropy: [
          ...extraEntropy ?? [],
          ...BigintUtils.toBytes(attempt, length: 32),
        ],
      );
      attempt += BigInt.one;
      lengthR = signature[3];
    }
    return signature;
  }

  List<int> signECDSADerConst(List<int> digest, {List<int>? extraEntropy}) {
    List<int> signature = _signingKey.signConstDer(
      digest: digest,
      extraEntropy: extraEntropy,
    );
    BigInt attempt = BigInt.one;
    int lengthR = signature[3];
    while (lengthR == 33) {
      signature = _signingKey.signConstDer(
        digest: digest,
        extraEntropy: [
          ...extraEntropy ?? [],
          ...BigintUtils.toBytes(attempt, length: 32),
        ],
      );
      attempt += BigInt.one;
      lengthR = signature[3];
    }
    return signature;
  }
}

class BitcoinSignatureVerifier {
  /// The ECDSA verification key associated with this Bitcoin verifier.
  final ECDSAVerifyKey _verifyKey;
  const BitcoinSignatureVerifier._(this._verifyKey);

  factory BitcoinSignatureVerifier.fromKeyBytes(List<int> publicKey) {
    final point = ProjectiveECCPoint.fromBytes(
      curve: CryptoSignerConst.curveSecp256k1,
      data: publicKey,
      order: null,
    );
    final pub = ECDSAPublicKey(CryptoSignerConst.generatorSecp256k1, point);
    return BitcoinSignatureVerifier._(ECDSAVerifyKey(pub));
  }

  /// Verifies a BIP-340 Schnorr signature using an x-only public key.
  ///
  ///
  /// - [xOnly]: A 32-byte x-only public key (corresponding to the Taproot key).
  /// - [digest]: A 32-byte message digest that was signed.
  /// - [signature]: A 64-byte Schnorr signature (`R.x || s`).
  /// - [tapTweakHash] (optional): A 32-byte tweak hash used to modify the public key.
  ///
  static bool verifyBip340SignatureUsingXOnly({
    required List<int> xOnly,
    required List<int> digest,
    required List<int> signature,
    List<int>? tapTweakHash,
  }) {
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw ArgumentException.invalidOperationArguments(
        "verifyBip340SignatureUsingXOnly",
        name: "digest",
        reason: "Invalid digest bytes length.",
      );
    }
    if (xOnly.length != EcdsaKeysConst.pointCoordByteLen) {
      throw ArgumentException.invalidOperationArguments(
        "verifyBip340SignatureUsingXOnly",
        name: "xOnly",
        reason: "Invalid xOnlyPublicKey bytes length.",
      );
    }

    final schnorrSignature = BitcoinSchnorrSignature.fromBytes(signature);
    final x = BigintUtils.fromBytes(xOnly);
    final P =
        tapTweakHash != null
            ? tweakKey(xBig: x, tapTweakHash: tapTweakHash)
            : P2TRUtils.liftX(x);
    final ProjectiveECCPoint generator = BitcoinSignerUtils.generator;
    final BigInt prime = BitcoinSignerUtils.generator.curve.p;

    if (schnorrSignature.r >= prime ||
        schnorrSignature.s >= BitcoinSignerUtils.order) {
      return false;
    }
    final eHash = P2TRUtils.taggedHash("BIP0340/challenge", [
      ...schnorrSignature.rBytes(),
      ...P.toXonly(),
      ...digest,
    ]);
    BigInt e = BigintUtils.fromBytes(eHash) % BitcoinSignerUtils.order;
    final sp = generator * schnorrSignature.s;

    if (P.y.isEven) {
      e = BitcoinSignerUtils.order - e;
    }
    final ProjectiveECCPoint eP = P * e;

    final R = sp + eP;

    if (R.y.isOdd || R.x != schnorrSignature.r) {
      return false;
    }

    return true;
  }

  /// Verifies a BIP-340 Schnorr signature using a public key.
  ///
  /// - [digest]: A 32-byte message digest that was signed.
  /// - [signature]: A 64-byte Schnorr signature (`R.x || s`).
  /// - [tapTweakHash] (optional): A 32-byte tweak hash used to modify the public key.
  ///
  bool verifyBip340Signature({
    required List<int> digest,
    required List<int> signature,
    List<int>? tapTweakHash,
  }) {
    return verifyBip340SignatureUsingXOnly(
      xOnly: _verifyKey.publicKey.point.toXonly(),
      digest: digest,
      signature: signature,
      tapTweakHash: tapTweakHash,
    );
  }

  /// Verifies a Schnorr(old style) signature for a given digest.
  ///
  /// - [digest]: The hash or message digest that was signed.
  /// - [signature]: The Schnorr signature to verify.
  ///
  bool verifySchnorrSignature({
    required List<int> digest,
    required List<int> signature,
  }) {
    final schnorrSignature = BitcoinSchnorrSignature.fromBytes(signature);
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw ArgumentException.invalidOperationArguments(
        "verifySchnorrSignature",
        name: "digest",
        reason: "Invalid digest bytes length.",
      );
    }

    final P = _verifyKey.publicKey.point;
    final eHash = QuickCrypto.sha256Hash([
      ...schnorrSignature.rBytes(),
      ..._verifyKey.publicKey.toBytes(),
      ...digest,
    ]);
    final e = BigintUtils.fromBytes(eHash) % CryptoSignerConst.secp256k1Order;
    final sG = CryptoSignerConst.generatorSecp256k1 * schnorrSignature.s;
    final ProjectiveECCPoint eP = -(P * e);
    final R = sG + eP;
    if (R.isZero() ||
        ECDSAUtils.jacobi(R.y, CryptoSignerConst.curveSecp256k1.p) <= 0) {
      return false;
    }
    return R.x == schnorrSignature.r;
  }

  /// Recovers the ECDSA public key from a Bitcoin signed message.
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: A 65-byte Bitcoin signature (including the recovery ID).
  /// - [messagePrefix] (optional): A custom prefix for the signed message
  ///   (default is Bitcoin's standard prefix).
  ///
  static ECDSAPublicKey recoverPublicKey({
    required List<int> message,
    required List<int> signature,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
  }) {
    if (signature.length != 65) {
      throw ArgumentException.invalidOperationArguments(
        "recoverPublicKey",
        name: "signature",
        reason: "Invalid signature bytes length.",
      );
    }
    final List<int> messgaeHash = QuickCrypto.sha256Hash(
      BitcoinSignerUtils.magicMessage(message, messagePrefix),
    );
    int header = signature[0];
    signature = signature.sublist(1);
    final ecdsaSignature = ECDSASignature.fromBytes(
      signature,
      BitcoinSignerUtils.generator,
    );

    if (header < 27 || header > 42) {
      throw ArgumentException.invalidOperationArguments(
        "recoverPublicKey",
        name: "signature",
        reason: "Invalid signature recovery id.",
      );
    }
    if (header >= 39) {
      header -= 12;
    } else if (header >= 35) {
      header -= 8;
    } else if (header >= 31) {
      header -= 4;
    }
    header -= 27;
    if (header > 1) {
      header -= 2;
    }
    return ecdsaSignature.recoverPublicKey(
      messgaeHash,
      BitcoinSignerUtils.generator,
      header,
    );
  }

  /// Verifies a Bitcoin-signed message signature.
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: The ECDSA signature (64 or 65 bytes).
  /// - [messagePrefix] (optional): A custom prefix for the signed message
  ///   (default is Bitcoin's standard prefix).
  ///
  bool verifyMessageSignature({
    required List<int> message,
    required List<int> signature,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
  }) {
    if (signature.length != 64 && signature.length != 65) {
      throw ArgumentException.invalidOperationArguments(
        "verifyMessageSignature",
        name: "signature",
        reason: "Invalid signature bytes length.",
      );
    }
    final List<int> messgaeHash = QuickCrypto.sha256Hash(
      BitcoinSignerUtils.magicMessage(message, messagePrefix),
    );
    int? header;
    if (signature.length == 65) {
      header = signature[0] & 0xFF;
      signature = signature.sublist(1);
    }
    final ecdsaSignature = ECDSASignature.fromBytes(
      signature,
      BitcoinSignerUtils.generator,
    );
    if (header == null) {
      return _verifyKey.verify(ecdsaSignature, messgaeHash);
    }
    if (header < 27 || header > 42) {
      throw ArgumentException.invalidOperationArguments(
        "verifyMessageSignature",
        name: "signature",
        reason: "Invalid signature recovery id.",
      );
    }
    if (header >= 39) {
      header -= 12;
    } else if (header >= 35) {
      header -= 8;
    } else if (header >= 31) {
      header -= 4;
    }
    header -= 27;
    if (header > 1) {
      header -= 2;
    }
    final pubKey = ecdsaSignature.recoverPublicKey(
      messgaeHash,
      _verifyKey.publicKey.generator,
      header,
    );
    return pubKey == _verifyKey.publicKey;
  }

  /// Verifies an ECDSA DER-encoded signature against a given digest.
  ///
  /// - [digest]: The hash or message digest that was signed.
  /// - [signature]: The DER-encoded ECDSA signature to verify.
  ///
  bool verifyECDSADerSignature({
    required List<int> digest,
    required List<int> signature,
  }) {
    final secp256k1Signature = Secp256k1EcdsaSignature.fromDer(signature);
    final ecdsaSignature = ECDSASignature(
      secp256k1Signature.r,
      secp256k1Signature.s,
    );
    return _verifyKey.verify(ecdsaSignature, digest);
  }

  /// Tweaks a public key for Taproot (BIP-341).
  ///
  /// - [xBig]: The x-coordinate of the public key as a `BigInt`.
  /// - [tapTweakHash]: A 32-byte tweak hash used to modify the key.
  ///
  static ProjectiveECCPoint tweakKey({
    required BigInt xBig,
    required List<int> tapTweakHash,
  }) {
    if (tapTweakHash.length != 32) {
      throw ArgumentException.invalidOperationArguments(
        "tweakKey",
        name: "signature",
        reason: "Invalid Tap-tweak hash bytes length.",
      );
    }
    final n =
        BitcoinSignerUtils.generator * BigintUtils.fromBytes(tapTweakHash);
    final outPoint = P2TRUtils.liftX(xBig) + n;
    return outPoint as ProjectiveECCPoint;
  }

  ProjectiveECCPoint publicKeyPoint() {
    return _verifyKey.publicKey.point;
  }
}
