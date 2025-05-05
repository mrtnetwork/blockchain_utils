import 'package:blockchain_utils/crypto/crypto/cdsa/cdsa.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

class Secp256k1Utils {
  /// generate ecmult blind context for ecmult using blind alg.
  static Secp256k1ECmultGenContext initalizeBlindEcMultContext(
      {List<int>? seed}) {
    final context = Secp256k1ECmultGenContext();
    secp256k1ECmultGenBlind(context, null);
    secp256k1ECmultGenBlind(context, seed ?? QuickCrypto.generateRandom());
    return context;
  }

  /// convert bytes 32 to scalar.
  static Secp256k1Scalar scalarFromBytes(List<int> scalarBytes) {
    Secp256k1Scalar scalar = Secp256k1Scalar();
    Secp256k1.secp256k1ScalarSetB32(scalar, scalarBytes);
    return scalar;
  }

  /// check scalar is valid and not zero
  static bool isValidScalar(Secp256k1Scalar scalar) {
    return Secp256k1.secp256k1ScalarCheckOverflow(scalar) == 0 &&
        Secp256k1.secp256k1ScalarIsZero(scalar) == 0;
  }

  /// convert field to 32 bytes.
  static List<int> feToBytes(Secp256k1Fe f) {
    final List<int> bytes = List<int>.filled(32, 0);
    Secp256k1.secp256k1FeGetB32(bytes, f);
    return bytes;
  }

  /// convert scalar to 32 bytes
  static List<int> scalarToBytes(Secp256k1Scalar s) {
    final List<int> bytes = List<int>.filled(32, 0);
    Secp256k1.secp256k1ScalarGetB32(bytes, s);
    return bytes;
  }

  /// create field from bytes
  static List<int> feFromBytes(Secp256k1Fe f) {
    final List<int> bytes = List<int>.filled(32, 0);
    Secp256k1.secp256k1FeGetB32(bytes, f);
    return bytes;
  }

  /// ecmult and then generate public key
  static List<int>? generatePublicKey(List<int> scalarBytes) {
    Secp256k1Scalar a = Secp256k1Scalar();
    Secp256k1.secp256k1ScalarSetB32(a, scalarBytes);
    Secp256k1Gej res1 = Secp256k1Gej();
    Secp256k1.secp256k1ECmultConst(res1, Secp256k1Const.G, a);
    Secp256k1Ge mid1 = Secp256k1Ge();
    Secp256k1.secp256k1GeSetGej(mid1, res1);
    return secp256k1ECkeyPubkeySerialize(mid1, true);
  }

  static List<int>? generatePublicKeyBlind(List<int> scalarBytes,
      {Secp256k1ECmultGenContext? context}) {
    Secp256k1ECmultGenContext c = context ?? initalizeBlindEcMultContext();
    try {
      Secp256k1Scalar a = Secp256k1Scalar();
      Secp256k1.secp256k1ScalarSetB32(a, scalarBytes);
      Secp256k1Gej res1 = Secp256k1Gej();
      Secp256k1.secp256k1ECmultGen(c, res1, a);
      Secp256k1Ge mid1 = Secp256k1Ge();
      Secp256k1.secp256k1GeSetGej(mid1, res1);
      return secp256k1ECkeyPubkeySerialize(mid1, true);
    } finally {
      if (context == null) {
        c.clean();
      }
    }
  }

  /// convert ge to public key
  static List<int>? secp256k1ECkeyPubkeySerialize(
      Secp256k1Ge elem, bool compressed) {
    if (Secp256k1.secp256k1GeIsInfinity(elem) == 1) {
      return null;
    }
    List<int> pub = List<int>.filled(32, 0);
    Secp256k1.secp256k1FeNormalizeVar(elem.x);
    Secp256k1.secp256k1FeNormalizeVar(elem.y);
    Secp256k1.secp256k1FeGetB32(pub, elem.x);
    const int tagPkeyEven = 0x02;
    const int tagPkeyOdd = 0x03;
    const int tagPkeyUncompressed = 0x04;
    int tag;
    if (compressed) {
      final tag =
          Secp256k1.secp256k1FeIsOdd(elem.y) == 1 ? tagPkeyOdd : tagPkeyEven;
      return [tag, ...pub];
    } else {
      tag = tagPkeyUncompressed;
      List<int> unCompressedPart = List<int>.filled(32, 0);
      Secp256k1.secp256k1FeGetB32(unCompressedPart, elem.y);
      return [tag, ...pub, ...unCompressedPart];
    }
  }

  /// generate blind context
  static void secp256k1ECmultGenBlind(
      Secp256k1ECmultGenContext ctx, List<int>? seed32) {
    Secp256k1Scalar b = Secp256k1Scalar();
    Secp256k1Scalar diff = Secp256k1Scalar();
    Secp256k1Gej gb = Secp256k1Gej();
    Secp256k1Fe f = Secp256k1Fe();
    List<int> nonce32 = List<int>.filled(32, 0);
    List<int> keydata = List<int>.filled(64, 0);

    /// Compute the (2^combBits - 1)/2 term once.
    Secp256k1.secp256k1ECmultGenScalarDiff(diff);

    if (seed32 == null) {
      /// When seed is NULL, reset the final point and blinding value.
      Secp256k1.secp256k1GeNeg(ctx.geOffset, Secp256k1Const.G);
      Secp256k1.secp256k1ScalarAdd(
          ctx.scalarOffset, Secp256k1Const.secp256k1ScalarOne, diff);
      ctx.projBlind = Secp256k1Const.secp256k1FeOne.clone();
      return;
    }

    /// The prior blinding value (if not reset) is chained forward by including it in the hash.
    Secp256k1.secp256k1ScalarGetB32(keydata, ctx.scalarOffset);
    keydata.setAll(32, seed32.take(32));
    nonce32 = RFC6979.generateSecp256k1KBytes(
        secexp: keydata.sublist(0, 32),
        hashFunc: () => SHA256(),
        data: keydata.sublist(32));

    /// Compute projective blinding factor (cannot be 0).
    Secp256k1.secp256k1FeSetB32Mod(f, nonce32);
    Secp256k1.secp256k1FeCmov(f, Secp256k1Const.secp256k1FeOne,
        Secp256k1.secp256k1FeNormalizesToZero(f));
    ctx.projBlind = f;
    nonce32 = RFC6979.generateSecp256k1KBytes(
        secexp: keydata.sublist(0, 32),
        hashFunc: () => SHA256(),
        data: keydata.sublist(32),
        retryGn: 1);
    Secp256k1.secp256k1ScalarSetB32(b, nonce32);
    Secp256k1.secp256k1ScalarCmov(b, Secp256k1Const.secp256k1ScalarOne,
        Secp256k1.secp256k1ScalarIsZero(b));
    Secp256k1.secp256k1ECmultGen(ctx, gb, b);
    Secp256k1.secp256k1ScalarNegate(b, b);
    Secp256k1.secp256k1ScalarAdd(ctx.scalarOffset, b, diff);
    Secp256k1.secp256k1GeSetGej(ctx.geOffset, gb);
  }
}
