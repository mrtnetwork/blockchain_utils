import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';

/// Shared constants used across the signer implementations.
class CryptoSignerConst {
  static const int ed25519SignatureLength = 64;
  static const int schnorrSignatureLength = 64;
  static const int ecdsaSignatureLength = 64;
  static const int ecdsaRecoveryIdLength = 1;
  static const int digestLength = 32;
  static const int ecdsaSignatureWithRecoveryIdLength =
      ecdsaSignatureLength + ecdsaRecoveryIdLength;

  static final EdwardsLimbPoint generatorED25519 = EdwardsLimbPoint.generator_;
  static final Secp256k1Point generatorSecp256k1 = Secp256k1Point.generator_;

  static const String tronSignMessagePrefix = '\u0019TRON Signed Message:\n';
  static const ethPersonalSignPrefix = '\u0019Ethereum Signed Message:\n';

  /// The secp256r1 generator point.
  static final Secp256r1Point nist256 = Secp256r1Point.generator_;

  /// The length of the digest (or component) in bytes for the secp256r1 curve.
  static const int nist256DigestLength = 32;

  /// Schnorr+SHA256
  static const List<int> bchSchnorrRfc6979ExtraData = [
    83,
    99,
    104,
    110,
    111,
    114,
    114,
    43,
    83,
    72,
    65,
    50,
    53,
    54,
    32,
    32,
  ];
}
