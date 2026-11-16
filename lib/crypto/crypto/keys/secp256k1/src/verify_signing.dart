import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/signer/bitcoin/bitcoin_key_signer.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/src/points.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/src/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// Parameters for a plain ECDSA sign/verify over secp256k1.
class Secp256k1SigningParams implements ISigningParams {
  final BuBytes digest;
  final BuBytes? extraEntropy;
  Secp256k1SigningParams({required List<int> digest, List<int>? extraEntropy})
    : digest =
          digest
              .exc(
                length: 32,
                operation: "Secp256k1SigningParams",
                reason: "Invalid digest length.",
              )
              .asImmutableBytes,
      extraEntropy = extraEntropy?.asImmutableBytes;
}

/// Parameters for verifying a plain ECDSA signature over secp256k1.
class Secp256k1VerifyingParams implements IVerifiyingParams {
  final Secp256k1SigningParams signingParams;
  final IECDSASignature signature;
  Secp256k1VerifyingParams(this.signingParams, this.signature);
}

/// Parameters for a BIP-340 Schnorr sign/verify over secp256k1.
class Secp256k1Bip340SigningParams implements ISigningParams {
  final BuBytes digest;
  final BuBytes? tapTweakHash;
  final BuBytes? aux;
  Secp256k1Bip340SigningParams({
    required List<int> digest,
    List<int>? tapTweakHash,
    List<int>? aux,
  }) : digest =
           digest
               .exc(
                 length: 32,
                 operation: "Secp256k1Bip340SigningParams",
                 reason: "Invalid digest bytes length.",
               )
               .asImmutableBytes,
       tapTweakHash = tapTweakHash?.asImmutableBytes,
       aux =
           aux
               ?.exc(
                 length: 32,
                 operation: "Secp256k1Bip340SigningParams",
                 reason: "Invalid AUX bytes length.",
               )
               .asImmutableBytes;
}

/// Common interface every secp256k1 public key implements.
abstract class ISecp256k1VerificationKey
    implements IVerifiyingKey<Secp256k1VerifyingParams> {
  BuBytes get keyBytes;
  BuBytes toXOnlyBytes();
  Secp256k1Point toPoint();
  const ISecp256k1VerificationKey();

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
    required IECDSASignature signature,
    List<int>? tapTweakHash,
  }) {
    return blockchainUtils.api.signing.secp256k1
        .verifyBip340SignatureUsingXOnly(
          xOnly: xOnly.toImutableBytes,
          digest: digest.asImmutableBytes,
          signature: signature,
          tapTweakHash: tapTweakHash?.asImmutableBytes,
        );
  }

  /// Verifies a BIP-340 Schnorr signature using a public key.
  ///
  /// - [digest]: A 32-byte message digest that was signed.
  /// - [signature]: A 64-byte Schnorr signature (`R.x || s`).
  /// - [tapTweakHash] (optional): A 32-byte tweak hash used to modify the public key.
  ///
  bool verifyBip340Signature({
    required IECDSASignature signature,
    required Secp256k1Bip340SigningParams params,
  }) {
    return verifyBip340SignatureUsingXOnly(
      xOnly: keyBytes.sublist(1),
      digest: params.digest,
      signature: signature,
      tapTweakHash: params.tapTweakHash,
    );
  }

  /// Verifies a Schnorr(old style) signature for a given digest.
  ///
  /// - [digest]: The hash or message digest that was signed.
  /// - [signature]: The Schnorr signature to verify.
  ///
  bool verifySchnorrSignature({
    required IECDSASignature signature,
    required Secp256k1SigningParams params,
  }) {
    return blockchainUtils.api.signing.secp256k1.verifySchnorr(
      digest: params.digest,
      signature: signature,
      publicKey: keyBytes,
    );
  }

  /// Recovers the ECDSA public key from a Bitcoin signed message.
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: A 65-byte Bitcoin signature (including the recovery ID).
  /// - [messagePrefix] (optional): A custom prefix for the signed message
  ///   (default is Bitcoin's standard prefix).
  ///
  static Secp256k1PublicKey recoverPublicKey({
    required List<int> message,
    required IECDSASignature signature,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
  }) {
    if (signature.recoveryId == null) {
      throw CoreErrors.invalidOperationArguments(
        "recoverPublicKey",
        name: "signature",
        reason: "Signature is missing a recovery id.",
      );
    }
    final List<int> messageHash = QuickCrypto.sha256Hash(
      BitcoinSignerUtils.magicMessage(message, messagePrefix),
    );
    final pubKeyPoint = Secp256k1EcdsaUtils.recoverPublicKey(
      hash: messageHash,
      signature: signature,
    );
    return Secp256k1PublicKey.fromBytes(pubKeyPoint.toBytes());
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
    required IECDSASignature signature,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
  }) {
    return blockchainUtils.api.signing.secp256k1.verifyMessageSignature(
      message: message.asImmutableBytes,
      signature: signature,
      publicKey: keyBytes,
      messagePrefix: messagePrefix,
    );
  }

  @override
  bool verify(Secp256k1VerifyingParams verifyParams) {
    return blockchainUtils.api.signing.secp256k1.verify(
      digest: verifyParams.signingParams.digest,
      signature: verifyParams.signature,
      publicKey: keyBytes,
    );
  }
}

/// Common interface every secp256k1 private key implements.
abstract class ISecp256k1SigningKey<P extends ISecp256k1VerificationKey>
    implements ISigningKey<IECDSASignature, Secp256k1SigningParams, P> {
  const ISecp256k1SigningKey();

  IECDSASignature signBip340(Secp256k1Bip340SigningParams params) {
    return takeSecretKey().useValue(
      (k) => blockchainUtils.api.signing.secp256k1.signBip340(
        sk: k,
        publicKey: verificationKey().keyBytes,
        digest: params.digest,
        aux: params.aux,
        tapTweakHash: params.tapTweakHash,
      ),
    );
  }

  IECDSASignature signSchnorr(Secp256k1SigningParams params) {
    return takeSecretKey().useValue(
      (k) => blockchainUtils.api.signing.secp256k1.signSchnorr(
        sk: k,
        publicKey: verificationKey().keyBytes,
        digest: params.digest,
        extraEntropy: params.extraEntropy,
      ),
    );
  }

  @override
  IECDSASignature sign(Secp256k1SigningParams params) {
    return takeSecretKey().useValue(
      (k) => blockchainUtils.api.signing.secp256k1.sign(
        sk: k,
        publicKey: verificationKey().keyBytes,
        digest: params.digest,
        extraEntropy: params.extraEntropy,
      ),
    );
  }
}
