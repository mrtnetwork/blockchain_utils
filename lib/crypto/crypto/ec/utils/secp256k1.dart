import 'package:blockchain_utils/crypto/crypto/ec/cdsa.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

class Secp256k1Utils {
  static Secp256k1ECmultGenContext? _context;
  static Secp256k1ECmultGenContext getOrinitalizeBlindEcMultContext({
    List<int>? seed,
  }) {
    final context = _context ??= initalizeBlindEcMultContext(seed: seed);
    return context;
  }

  /// generate ecmult blind context for ecmult using blind alg.
  static Secp256k1ECmultGenContext initalizeBlindEcMultContext({
    List<int>? seed,
  }) {
    final context = Secp256k1ECmultGenContext();
    secp256k1ECmultGenBlind(context, null);
    secp256k1ECmultGenBlind(context, seed ?? QuickCrypto.generateRandom());
    return context;
  }

  /// convert bytes 32 to scalar.
  static Secp256k1Scalar scalarFromBytes(
    List<int> scalarBytes, {
    bool secp = true,
    bool validate = true,
  }) {
    Secp256k1Scalar scalar = Secp256k1Scalar();
    final orverflow = Secp256k1.secp256k1ScalarSetB32(scalar, scalarBytes);

    if ((secp && orverflow == 1) ||
        (validate && Secp256k1.secp256k1ScalarIsZero(scalar).toBool)) {
      throw ArgumentException.invalidOperationArguments(
        "scalarFromBytes",
        name: "scalarBytes",
        reason: "Invalid scalar bytes.",
      );
    }
    return scalar;
  }

  static List<int> geToBytes(Secp256k1Ge element) {
    final p = secp256k1ECkeyPubkeySerialize(element, true);

    if (p == null) {
      throw ArgumentException.invalidOperationArguments(
        "geToEcPoint",
        name: "element",
        reason: "Invalid point data.",
      );
    }
    return p;
  }

  static ProjectiveECCPoint geToEcPoint(Secp256k1Ge element) {
    final p = geToBytes(element);
    return ProjectiveECCPoint.fromBytes(curve: Curves.curveSecp256k1, data: p);
  }

  /// check scalar is valid and not zero
  static bool scCheckFromBytes(List<int> scalarBytes) {
    final scalar = scalarFromBytes(scalarBytes);
    return Secp256k1.secp256k1ScalarCheckOverflow(scalar) == 0 &&
        Secp256k1.secp256k1ScalarIsZero(scalar) == 0;
  }

  /// check scalar is valid and not zero
  static bool scCheck(BaseSecp256k1Scalar scalar) {
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
  static List<int> scalarToBytes(
    Secp256k1Scalar scalar, {
    bool validate = true,
    bool clean = false,
  }) {
    try {
      if (validate && Secp256k1.secp256k1ScalarIsZero(scalar).toBool) {
        throw ArgumentException.invalidOperationArguments(
          "scalarToBytes",
          name: "scalar",
          reason: "Invalid scalar.",
        );
      }
      final List<int> bytes = List<int>.filled(32, 0);
      Secp256k1.secp256k1ScalarGetB32(bytes, scalar);
      return bytes;
    } finally {
      if (clean) scalar.fillZero();
    }
  }

  /// create field from bytes
  static List<int> feFromBytes(Secp256k1Fe f) {
    final List<int> bytes = List<int>.filled(32, 0);
    Secp256k1.secp256k1FeGetB32(bytes, f);
    return bytes;
  }

  static List<int>? generatePublicKeyBlind({
    List<int>? scalarBytes,
    Secp256k1Scalar? scalar,
    Secp256k1ECmultGenContext? context,
    bool secp = true,
  }) {
    final g = secp256k1MultBase(
      scalarBytes: scalarBytes,
      scalar: scalar,
      context: context,
      secp: secp,
    );
    return secp256k1ECkeyPubkeySerialize(g, true);
  }

  /// convert ge to public key
  static List<int>? secp256k1ECkeyPubkeySerialize(
    Secp256k1Ge elem,
    bool compressed,
  ) {
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
    Secp256k1ECmultGenContext ctx,
    List<int>? seed32,
  ) {
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
        ctx.scalarOffset,
        Secp256k1Const.secp256k1ScalarOne,
        diff,
      );
      ctx.fillBlindFe(Secp256k1Const.secp256k1FeOne);
      return;
    }

    /// The prior blinding value (if not reset) is chained forward by including it in the hash.
    Secp256k1.secp256k1ScalarGetB32(keydata, ctx.scalarOffset);
    keydata.setAll(32, seed32.take(32));
    nonce32 = RFC6979.generateSecp256k1KBytes(
      secexp: keydata.sublist(0, 32),
      hashFunc: () => SHA256(),
      data: keydata.sublist(32),
    );

    /// Compute projective blinding factor (cannot be 0).
    Secp256k1.secp256k1FeSetB32Mod(f, nonce32);
    Secp256k1.secp256k1FeCmov(
      f,
      Secp256k1Const.secp256k1FeOne,
      Secp256k1.secp256k1FeNormalizesToZero(f),
    );
    ctx.fillBlindFe(f);
    nonce32 = RFC6979.generateSecp256k1KBytes(
      secexp: keydata.sublist(0, 32),
      hashFunc: () => SHA256(),
      data: keydata.sublist(32),
      retryGn: 1,
    );
    Secp256k1.secp256k1ScalarSetB32(b, nonce32);
    Secp256k1.secp256k1ScalarCmov(
      b,
      Secp256k1Const.secp256k1ScalarOne,
      Secp256k1.secp256k1ScalarIsZero(b),
    );
    Secp256k1.secp256k1ECmultGen(ctx, gb, b);
    Secp256k1.secp256k1ScalarNegate(b, b);
    Secp256k1.secp256k1ScalarAdd(ctx.scalarOffset, b, diff);
    Secp256k1.secp256k1GeSetGej(ctx.geOffset, gb);
  }

  static Secp256k1Ge? loadPublicKey(List<int> pub) {
    final ge = Secp256k1Ge();
    if (Secp256k1.secp256k1EckeyPubkeyParse(ge, pub)) {
      Secp256k1GeStorage storage = Secp256k1GeStorage();
      Secp256k1.secp256k1GeToStorage(storage, ge);
      final r = Secp256k1Ge();
      Secp256k1.secp256k1GeFromStorage(r, storage);
      return r;
    }
    return null;
  }

  static Secp256k1Ge secp256k1MultBase({
    List<int>? scalarBytes,
    Secp256k1Scalar? scalar,
    Secp256k1ECmultGenContext? context,
    bool secp = true,
  }) {
    if (scalar == null && scalarBytes == null) {
      throw ArgumentException.invalidOperationArguments(
        "secp256k1MultBase",
        name: "scalar",
        reason: "Missing scalar.",
      );
    }
    bool hasScalar = scalar != null;
    scalar ??= scalarFromBytes(scalarBytes!, secp: secp);
    context ??= getOrinitalizeBlindEcMultContext();
    if (secp &&
        hasScalar &&
        Secp256k1.secp256k1ScalarCheckOverflow(scalar) == 1) {
      throw ArgumentException.invalidOperationArguments(
        "secp256k1MultBase",
        name: "scalar",
        reason: "Invalid scalar bytes.",
      );
    }
    Secp256k1Gej R = Secp256k1Gej();
    Secp256k1.secp256k1ECmultGen(context, R, scalar);
    Secp256k1Ge mid1 = Secp256k1Ge();
    Secp256k1.secp256k1GeSetGej(mid1, R);
    R.setZero();
    if (!hasScalar) scalar.fillZero();
    return mid1;
  }

  static Secp256k1Gej secp256k1Mult({
    List<int>? scalarBytes,
    BaseSecp256k1Scalar? scalar,
    Secp256k1Ge? point,
    List<int>? pointBytes,
    bool checkScalar = true,
  }) {
    if (scalar == null && scalarBytes == null) {
      throw ArgumentException.invalidOperationArguments(
        "secp256k1Mult",
        name: "scalar",
        reason: "Missing scalar or scalar bytes.",
      );
    }
    if (point == null && pointBytes == null) {
      throw ArgumentException.invalidOperationArguments(
        "secp256k1Mult",
        name: "point",
        reason: "Missing point or point bytes.",
      );
    }
    point ??= loadPublicKey(pointBytes!);
    if (point == null) {
      throw ArgumentException.invalidOperationArguments(
        "secp256k1Mult",
        name: "point",
        reason: "Invalid point bytes.",
      );
    }
    bool hasScalar = scalar != null;
    scalar ??= scalarFromBytes(scalarBytes!);
    if (checkScalar && !scCheck(scalar)) {
      throw ArgumentException.invalidOperationArguments(
        "secp256k1MultBase",
        name: "scalar",
        reason: "Invalid scalar bytes.",
      );
    }
    Secp256k1Gej R = Secp256k1Gej();
    Secp256k1.secp256k1ECmultConst(R, point, scalar);
    if (scalar case Secp256k1Scalar()) {
      if (!hasScalar) {
        scalar.fillZero();
      }
    }
    return R;
  }
}
