import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/ec/curve/curve.dart';
import 'package:blockchain_utils/crypto/crypto/ec/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/native/native.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

class MuSig2Constants {
  static const int xOnlyBytesLength = 32;
  static const int partialSignatureLength = 32;
  static const int minimumRequiredKey = 2;
  static const int pubnonceLength = 66;
  static const int secnoncelength =
      QuickCrypto.sha256DigestSize * 2 + EcdsaKeysConst.pubKeyCompressedByteLen;
  static final CurveFp curve = Curves.curveSecp256k1;
  static final BigInt order = Curves.generatorSecp256k1.order!;
  static final ProjectiveECCPoint generator = Curves.generatorSecp256k1;
  static int get baselen => Curves.curveSecp256k1.baselen;
  static const String deterministicNonceDomain = "MuSig/deterministic/nonce";
  static const String auxDomain = "MuSig/deterministic/nonce";
  static const String noncecoefDomain = 'MuSig/noncecoef';
  static const String challengeDomain = 'BIP0340/challenge';
  static const String keyAggListDomain = 'KeyAgg list';
  static const String keyAggCoeffDomain = 'KeyAgg coefficient';
  static const String nonceDomain = 'MuSig/nonce';
  static const String musigAuxDomain = "MuSig/aux";
}
