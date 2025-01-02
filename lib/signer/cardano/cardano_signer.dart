import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/cdsa.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';

/// Constants used by the Solana signer for cryptographic operations.
class CardanoSignerConst {
  /// The ED25519 elliptic curve generator point.
  static final EDPoint ed25519Generator = Curves.generatorED25519;

  static final int signatureLen =
      BigintUtils.orderLen(ed25519Generator.curve.p) * 2;
}

/// Class for signing Solana transactions using either EDDSA algorithm.
class CardanoSigner {
  /// The EDDSA private key for signing.
  final EDDSAPrivateKey _signingKey;

  /// Constructs a new SolanaSigner instance with the provided signing keys.
  ///
  /// This constructor is marked as private and takes an EDDSA private key [_signingKey]
  CardanoSigner._(this._signingKey);

  /// Factory method to create an SolanaSigner instance from key bytes.
  factory CardanoSigner.fromKeyBytes(List<int> keyBytes) {
    if (keyBytes.length != Ed25519KholawKeysConst.privKeyByteLen &&
        keyBytes.length != Ed25519KeysConst.privKeyByteLen) {
      throw MessageException("Invalid key bytes length.", details: {
        "length": keyBytes.length,
        "Excepted":
            "${Ed25519KholawKeysConst.privKeyByteLen} or ${Ed25519KeysConst.privKeyByteLen}"
      });
    }
    // Create an EDDSA private key from the key bytes using the ED25519 curve.
    final EDDSAPrivateKey signingKey;
    if (keyBytes.length == Ed25519KholawKeysConst.privKeyByteLen) {
      signingKey = EDDSAPrivateKey.fromKhalow(
          CardanoSignerConst.ed25519Generator, keyBytes);
    } else {
      signingKey = EDDSAPrivateKey(
          CardanoSignerConst.ed25519Generator, keyBytes, () => SHA512());
    }
    return CardanoSigner._(signingKey);
  }

  /// Signs the provided digest using the ED25519 algorithm.
  ///
  /// This method takes a digest as input and uses the private signing key to generate
  /// a signature based on the ED25519 algorithm. It then verifies the signature using
  /// the corresponding verification key and throws an exception if the verification fails.
  ///
  /// [digest] The digest to be signed.
  /// returns A list of bytes representing the generated signature.
  List<int> _signEdward(List<int> digest) {
    final sig = _signingKey.sign(digest, () => SHA512());
    final verifyKey = toVerifyKey();
    final verify = verifyKey._verifyEddsa(digest, sig);
    if (!verify) {
      throw const MessageException(
          'The created signature does not pass verification.');
    }
    return sig;
  }

  /// Signs the provided digest using the appropriate algorithm based on the available signing key.
  ///
  /// This method takes a digest as input and delegates the signing process to either
  /// the ED25519 or ECDSA algorithm based on the type of available signing key.
  ///
  /// [digest] The digest to be signed.
  /// returns A list of bytes representing the generated signature using the appropriate algorithm.
  List<int> sign(List<int> digest) {
    return _signEdward(digest);
  }

  /// Returns an SolanaVerifier instance based on the available signing key type.
  ///
  /// This method constructs and returns an SolanaVerifier instance for signature verification.
  ///
  /// returns An SolanaVerifier instance based on the available signing key type.
  CardanoVerifier toVerifyKey() {
    final keyBytes = _signingKey.publicKey.toBytes();
    return CardanoVerifier.fromKeyBytes(keyBytes);
  }
}

/// Class representing an Solana Verifier for signature verification.
class CardanoVerifier {
  final EDDSAPublicKey? _eddsaPublicKey;

  /// Private constructor to create an SolanaVerifier instance.
  CardanoVerifier._(this._eddsaPublicKey);

  /// Factory method to create an SolanaVerifier instance from key bytes.
  factory CardanoVerifier.fromKeyBytes(List<int> keyBytes) {
    final pub = Ed25519PublicKey.fromBytes(keyBytes);
    final verifyingKey = EDDSAPublicKey(
        CardanoSignerConst.ed25519Generator, pub.compressed.sublist(1));
    return CardanoVerifier._(verifyingKey);
  }

  /// Verifies the EDDSA signature for the provided digest.
  ///
  /// This method verifies the EDDSA signature by using the EDDSA public key to
  /// verify the signature against the given digest using the SHA512 hashing
  /// function.
  ///
  /// [digest] The digest used for verification.
  /// [signature] The EDDSA signature as a list of bytes.
  /// returns True if the signature is verified, false otherwise.
  bool _verifyEddsa(List<int> digest, List<int> signature) {
    return _eddsaPublicKey!.verify(digest, signature, () => SHA512());
  }

  /// Verifies the signature for the provided digest using the available key.
  ///
  /// This method verifies the signature of the provided digest using either EDDSA algorithms,
  /// [digest] The digest to be verified.
  /// [signature] The signature to be verified.
  bool verify(List<int> digest, List<int> signature) {
    return _verifyEddsa(digest, signature);
  }
}
