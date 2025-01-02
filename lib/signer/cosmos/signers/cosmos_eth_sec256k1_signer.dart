import 'package:blockchain_utils/signer/eth/evm_signer.dart';

/// Ethereum Signer class for cryptographic operations, including signing and verification.
///
/// The `CosmosETHSecp256k1Signer` class facilitates the creation of Ethereum signatures and
/// provides methods for signing messages, personal messages, and converting to
/// verification keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class CosmosETHSecp256k1Signer {
  const CosmosETHSecp256k1Signer._(this._signer);

  final ETHSigner _signer;

  /// Factory method to create an CosmosETHSecp256k1Signer from a byte representation of a private key.
  factory CosmosETHSecp256k1Signer.fromKeyBytes(List<int> keyBytes) {
    return CosmosETHSecp256k1Signer._(ETHSigner.fromKeyBytes(keyBytes));
  }

  /// Signs a personal message digest with an optional payload length.
  ///
  /// The Ethereum personal sign prefix is applied to the message, and the resulting
  /// signature is returned as a byte list. Optionally, a payload length can be provided.
  ///
  /// Parameters:
  /// - [digest]: The personal message digest to be signed.
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  ///
  /// Returns:
  /// - A byte list representing the signature of the personal message.
  List<int> sign(List<int> digest, {bool hashMessage = true}) {
    return _signer.sign(digest, hashMessage: hashMessage).toBytes(false);
  }

  /// Converts the CosmosETHSecp256k1Signer to an CosmosETHSecp256k1Verifier for verification purposes.
  ///
  /// Returns:
  /// - An CosmosETHSecp256k1Verifier representing the verification key.
  CosmosETHSecp256k1Verifier toVerifyKey() {
    return CosmosETHSecp256k1Verifier._(_signer.toVerifyKey());
  }
}

/// Ethereum Verifier class for cryptographic operations, including signature verification.
///
/// The `CosmosETHSecp256k1Verifier` class allows the verification of Ethereum signatures and
/// public keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class CosmosETHSecp256k1Verifier {
  final ETHVerifier _verifier;

  CosmosETHSecp256k1Verifier._(this._verifier);

  /// Factory method to create an CosmosETHSecp256k1Verifier from a byte representation of a public key.
  factory CosmosETHSecp256k1Verifier.fromKeyBytes(List<int> keyBytes) {
    return CosmosETHSecp256k1Verifier._(ETHVerifier.fromKeyBytes(keyBytes));
  }

  /// Verifies an Ethereum signature against a message digest.
  ///
  /// Parameters:
  /// - [digest]: The message digest.
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before verification (default is true).
  ///
  /// Returns:
  /// - True if the signature is valid, false otherwise.
  bool verify(List<int> digest, List<int> signature,
      {bool hashMessage = true}) {
    return _verifier.verify(digest, signature, hashMessage: hashMessage);
  }
}
