import 'dart:typed_data';
import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/cdsa.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Utility class for Ed25519-specific operations.
class Ed25519Utils {
  /// reduce scalar
  static List<int> scalarReduceVar(List<int> scalar) {
    final toint = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    final reduce = toint % Curves.generatorED25519.order!;
    final tobytes = BigintUtils.toBytes(reduce,
        order: Endian.little,
        length: BigintUtils.orderLen(Curves.generatorED25519.order!));
    return tobytes;
  }

  /// reduce scalar constant-time
  static List<int> scalarReduceConst(List<int> scalar) {
    List<int> r = List<int>.filled(Ed25519KeysConst.privKeyByteLen, 0);
    if (scalar.length == Ed25519KeysConst.privKeyByteLen) {
      CryptoOps.scReduce32Copy(r, scalar);
    } else if (scalar.length == Ed25519KeysConst.privKeyByteLen * 2) {
      CryptoOps.scReduce(r, scalar);
    } else {
      throw CryptoException("Invalid scalar length.");
    }
    return r;
  }

  /// check scalar is zero
  static bool scIsZero(List<int> scalar) {
    return CryptoOps.scIsNonZero(scalar) != 1;
  }

  /// check and convert scalar bytes to BigInteger
  static BigInt asScalarInt(List<int> scalar) {
    if (CryptoOps.scCheck(scalar) == 0) {
      return BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    }
    throw const CryptoException(
        "The provided scalar exceeds the allowed range.");
  }

  /// reduce scalar and mult with base.
  static List<int> scalarMultBase(List<int> scalar) {
    final List<int> ag = List<int>.filled(32, 0);
    final GroupElementP3 point = GroupElementP3();
    CryptoOps.scReduce32Copy(ag, scalar);
    CryptoOps.geScalarMultBase(point, ag);
    CryptoOps.geP3Tobytes(ag, point);
    return ag;
  }

  /// add two scalar r = a+b
  static List<int> add(List<int> scalar1, List<int> scalar2) {
    final out = List<int>.filled(32, 0);
    CryptoOps.scAdd(out, scalar1, scalar2);
    return out.asBytes;
  }

  /// sub two scalar r = a-b
  static List<int> sub(List<int> scalar1, List<int> scalar2) {
    final out = List<int>.filled(32, 0);
    CryptoOps.scSub(out, scalar1, scalar2);
    return out.asBytes;
  }

  /// Negates a scalar.
  static List<int> neg(List<int> scalar) {
    final out = List<int>.filled(32, 0);
    CryptoOps.scMulAdd(
        out, CryptoOpsConst.scMinusOne, scalar, CryptoOpsConst.zero);
    return out.asBytes;
  }

  /// mul two scalar r = a*b
  static List<int> mul(List<int> scalar1, List<int> scalar2) {
    final out = List<int>.filled(32, 0);
    CryptoOps.scMul(out, scalar1, scalar2);
    return out.asBytes;
  }

  /// mul and then add scalar r = a*b+c
  static List<int> mulAdd(
      List<int> scalar1, List<int> scalar2, List<int> scalar3) {
    final out = List<int>.filled(32, 0);
    CryptoOps.scMulAdd(out, scalar1, scalar2, scalar3);
    return out.asBytes;
  }

  /// mul and then sub scalar r = a*b-c
  static List<int> mulSub(
      List<int> scalar1, List<int> scalar2, List<int> scalar3) {
    final out = List<int>.filled(32, 0);
    CryptoOps.scMulSub(out, scalar1, scalar2, scalar3);
    return out.asBytes;
  }

  /// mul point with scalar r = P*a
  static List<int> pointScalarMult(List<int> point, List<int> scalar) {
    final pk = CryptoOps.geFromBytesVartime(point);
    GroupElementP2 r = GroupElementP2();
    CryptoOps.geScalarMult(r, scalar, pk);
    return CryptoOps.geTobytes_(r);
  }

  /// add two point r = P+P1
  static List<int> pointAdd(List<int> point1, List<int> point2) {
    final pk1 = CryptoOps.geFromBytesVartime(point1);
    GroupElementCached ec = GroupElementCached();
    CryptoOps.geP3ToCached(ec, pk1);
    final pk2 = CryptoOps.geFromBytesVartime(point2);
    GroupElementP1P1 r = GroupElementP1P1();
    CryptoOps.geAdd(r, pk2, ec);
    GroupElementP2 r1 = GroupElementP2();
    CryptoOps.geP1P1ToP2(r1, r);
    return CryptoOps.geTobytes_(r1);
  }

  /// convert valid ed25519 to EDPoint.
  static EDPoint asPoint(List<int> point) {
    try {
      return EDPoint.fromBytes(curve: Curves.curveEd25519, data: point);
    } catch (e) {
      throw CryptoException("Invalid ED25519 point bytes.");
    }
  }

  /// check scalar is valid
  static bool isValidScalar(List<int> bytes) {
    return CryptoOps.scCheck(bytes) == 0;
  }

  /// check bytes is valid ed25519 point.
  static bool isValidPoint(List<int> bytes) {
    final GroupElementP3 p = GroupElementP3();
    return CryptoOps.geFromBytesVartime_(p, bytes) == 0;
  }

  /// create 32 bytes zero.
  static List<int> zero() {
    return CryptoOpsConst.zero.clone();
  }

  /// generate public key from valid secret scalar bytes.
  static List<int> secretKeyToPubKey({required List<int> secretKey}) {
    if (CryptoOps.scCheck(secretKey) != 0) {
      throw const SquareRootError(
          "The provided scalar exceeds the allowed range.");
    }
    final List<int> pubKey = zero();
    final GroupElementP3 point = GroupElementP3();
    CryptoOps.geScalarMultBase(point, secretKey);

    CryptoOps.geP3Tobytes(pubKey, point);
    return pubKey;
  }

  /// mul scalar with 8 r = a*8;
  static List<int> scalarmult8Const(List<int> p) {
    final GroupElementP3 p3 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(p3, p) != 0) {
      throw const CryptoException("invalid point bytes");
    }
    final GroupElementP2 p2 = GroupElementP2();
    CryptoOps.geP3ToP2(p2, p3);
    final GroupElementP1P1 p1 = GroupElementP1P1();
    CryptoOps.geMul8(p1, p2);
    CryptoOps.geP1P1ToP2(p2, p1);
    final List<int> res = zero();
    CryptoOps.geToBytes(res, p2);
    return res;
  }

  static List<int> scMulFast(List<int> scalar, List<int> scalar2) {
    final a = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    final b = BigintUtils.fromBytes(scalar2, byteOrder: Endian.little);
    final r = (b * a) % Curves.generatorED25519.order!;
    return BigintUtils.toBytes(r, length: 32, order: Endian.little);
  }

  static List<int> scMulFastBigInt(List<int> scalar, BigInt scalar2) {
    final a = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    final r = (scalar2 * a) % Curves.generatorED25519.order!;
    return BigintUtils.toBytes(r, length: 32, order: Endian.little);
  }

  static List<int> scSubFast(List<int> scalar, List<int> scalar2) {
    final a = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    final b = BigintUtils.fromBytes(scalar2, byteOrder: Endian.little);
    final r = (a - b) % Curves.generatorED25519.order!;
    return BigintUtils.toBytes(r, length: 32, order: Endian.little);
  }

  static List<int> scSubFastBig(List<int> scalar, BigInt scalar2) {
    final a = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    final r = (a - scalar2) % Curves.generatorED25519.order!;
    return BigintUtils.toBytes(r, length: 32, order: Endian.little);
  }

  static List<int> scAddFast(List<int> scalar, List<int> scalar2) {
    final a = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    final b = BigintUtils.fromBytes(scalar2, byteOrder: Endian.little);
    final r = (a + b) % Curves.generatorED25519.order!;
    return BigintUtils.toBytes(r, length: 32, order: Endian.little);
  }

  static List<int> scAddFastBig(List<int> scalar, BigInt scalar2) {
    final a = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    final r = (a + scalar2) % Curves.generatorED25519.order!;
    return BigintUtils.toBytes(r, length: 32, order: Endian.little);
  }

  static BigInt scalarAsBig(List<int> scalar) {
    return BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
  }

  static List<int> scMulAddFast(
      List<int> scalar, List<int> scalar2, List<int> scalar3) {
    final a = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    final b = BigintUtils.fromBytes(scalar2, byteOrder: Endian.little);
    final c = BigintUtils.fromBytes(scalar3, byteOrder: Endian.little);
    final r = ((b * a) + c) % Curves.generatorED25519.order!;
    return BigintUtils.toBytes(r, length: 32, order: Endian.little);
  }

  static bool scCheckFast(List<int> scalar) {
    assert(scalar.length == 32, 'invalid scalar size');
    final order = Curves.generatorED25519.order!;
    final scalarInt = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    if (scalarInt >= order) {
      return false;
    }

    return true;
  }
}
