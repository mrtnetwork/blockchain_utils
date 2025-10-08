import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';

class CryptoSignerConst {
  static const int ed25519SignatureLength = 64;
  static const int schnoorSginatureLength = 64;
  static const int ecdsaSignatureLength = 64;
  static const int ecdsaRecoveryIdLength = 1;
  static const int digestLength = 32;
  static const int ecdsaSignatureWithRecoveryIdLength =
      ecdsaSignatureLength + ecdsaRecoveryIdLength;

  static final EDPoint generatorED25519 = Curves.generatorED25519;
  static final curveSecp256k1 = Curves.curveSecp256k1;
  static final ProjectiveECCPoint generatorSecp256k1 =
      Curves.generatorSecp256k1;
  static final BigInt secp256k1Order = generatorSecp256k1.order!;
  static final BigInt secp256k1OrderHalf = secp256k1Order >> 1;

  static const String tronSignMessagePrefix = '\u0019TRON Signed Message:\n';
  static const ethPersonalSignPrefix = '\u0019Ethereum Signed Message:\n';

  /// The projective ECC point representing the secp256r1 elliptic curve.
  static final ProjectiveECCPoint nist256 = Curves.generator256;

  /// The length of the digest (or component) in bytes for the secp256r1 curve.
  static final int nist256DigestLength = nist256.curve.baselen;

  /// The order of the secp256R1 elliptic curve.
  static final nist256256Order = nist256.order!;

  /// Half of the order of the secp256R1 elliptic curve.
  static final BigInt orderHalf = nist256256Order >> 1;

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
    32
  ];
}
