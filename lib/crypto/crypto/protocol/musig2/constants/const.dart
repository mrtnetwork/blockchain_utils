import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';

/// Fixed byte lengths defined by the MuSig2 (BIP-327) spec.
class MuSig2Constants {
  static const int xOnlyBytesLength = 32;
  static const int partialSignatureLength = 32;
  static const int minimumRequiredKey = 2;
  static const int pubnonceLength = 66;
  static const int secnoncelength =
      QuickCrypto.sha256DigestSize * 2 + EcdsaKeysConst.pubKeyCompressedByteLen;
  static const int baselen = 32;
  static final Secp256k1Point generator = Secp256k1Point.generator_;
  static const String deterministicNonceDomain = "MuSig/deterministic/nonce";
  static const String noncecoefDomain = 'MuSig/noncecoef';
  static const String challengeDomain = 'BIP0340/challenge';
  static const String keyAggListDomain = 'KeyAgg list';
  static const String keyAggCoeffDomain = 'KeyAgg coefficient';
  static const String nonceDomain = 'MuSig/nonce';
  static const String musigAuxDomain = "MuSig/aux";
}
