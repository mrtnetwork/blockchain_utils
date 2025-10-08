import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curve.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/utils.dart';

/// An enumeration representing different types of encoding for elliptic curve points.
enum EncodeType { comprossed, hybrid, raw, uncompressed }

/// An abstract class representing an elliptic curve point.
abstract class AbstractPoint {
  /// Converts the elliptic curve point to a byte array with the specified encoding type.
  /// The default encoding type is 'compressed'.
  List<int> toBytes([EncodeType encodeType = EncodeType.comprossed]) {
    if (this is EDPoint) {
      return _edwardsEncode();
    }
    switch (encodeType) {
      case EncodeType.raw:
        return _encode();
      case EncodeType.uncompressed:
        return List<int>.from([0x04, ..._encode()]);
      case EncodeType.hybrid:
        return _hybridEncode();
      default:
        return _compressedEncode();
    }
  }

  /// Encodes the elliptic curve point as a hexadecimal string with the specified encoding type.
  /// The default encoding type is 'compressed'.
  String toHex([EncodeType encodeType = EncodeType.comprossed]) {
    final bytes = toBytes(encodeType);
    return BytesUtils.toHexString(bytes);
  }

  /// Internal method to encode an Edwards curve point.
  List<int> _edwardsEncode() {
    final ed = this as EDPoint;
    ed.scale();
    final encLen = (curve.p.bitLength + 1 + 7) ~/ 8;
    final yStr = BigintUtils.toBytes(y, length: encLen, order: Endian.little);
    if (x % BigInt.two == BigInt.one) {
      yStr[yStr.length - 1] |= 0x80;
    }
    return yStr;
  }

  /// Internal method to encode an elliptic curve point in hybrid form.
  List<int> _hybridEncode() {
    final raw = _encode();
    int prefix = 0x06;
    if (y.isOdd) {
      prefix = 0x07;
    }
    return [prefix, ...raw];
  }

  /// Internal method to encode an elliptic curve point in compressed form.
  List<int> _compressedEncode() {
    final List<int> xBytes =
        BigintUtils.toBytes(x, length: BigintUtils.orderLen(curve.p));
    int prefix = 0x02;
    if (y.isOdd) {
      prefix = 0x03;
    }
    return [prefix, ...xBytes];
  }

  /// Internal method to encode an elliptic curve point.
  List<int> _encode() {
    final xBytes =
        BigintUtils.toBytes(x, length: BigintUtils.orderLen(curve.p));
    final yBytes =
        BigintUtils.toBytes(y, length: BigintUtils.orderLen(curve.p));
    return [...xBytes, ...yBytes];
  }

  /// An abstract property representing the elliptic curve associated with the point.
  abstract final Curve curve;

  /// A property indicating if the point is at infinity.
  bool get isInfinity;

  /// A property representing the x-coordinate of the point.
  BigInt get x;

  /// A property representing the y-coordinate of the point.
  BigInt get y;

  /// A property representing the order of the point.
  BigInt? get order;

  /// Multiplies the point by a scalar.
  AbstractPoint operator *(BigInt other);

  /// Adds another point to this point.
  AbstractPoint operator +(AbstractPoint other);

  /// Doubles a point
  AbstractPoint doublePoint();

  /// Creates an elliptic curve point from its byte representation.
  static Tuple<BigInt, BigInt> fromBytes(
    Curve curve,
    List<int> data, {
    bool validateEncoding = true,
    EncodeType? encodeType,
  }) {
    if (curve is CurveED) {
      return _fromEdwards(curve, data);
    }
    final keyLen = data.length;
    final rawEncodingLength = 2 * BigintUtils.orderLen(curve.p);
    if (encodeType == null) {
      if (keyLen == rawEncodingLength) {
        encodeType = EncodeType.raw;
      } else if (keyLen == rawEncodingLength + 1) {
        final prefix = data[0];
        if (prefix == 0x04) {
          encodeType = EncodeType.uncompressed;
        } else if (prefix == 0x06 || prefix == 0x07) {
          encodeType = EncodeType.hybrid;
        } else {
          throw const CryptoException("invalid key length");
        }
      } else if (keyLen == rawEncodingLength ~/ 2 + 1) {
        encodeType = EncodeType.comprossed;
      } else {
        throw const CryptoException("invalid key length");
      }
    }
    curve as CurveFp;
    switch (encodeType) {
      case EncodeType.comprossed:
        return _fromCompressed(data, curve);
      case EncodeType.uncompressed:
        return _fromRawEncoding(data.sublist(1), rawEncodingLength);
      case EncodeType.hybrid:
        return _fromHybrid(data, rawEncodingLength);
      default:
        return _fromRawEncoding(data, rawEncodingLength);
    }
  }

  /// Creates an elliptic curve point from a byte representation using the Edwards curve.
  static Tuple<BigInt, BigInt> _fromEdwards(CurveED curve, List<int> data) {
    data = List<int>.from(data);
    final p = curve.p;
    final expLen = (p.bitLength + 1 + 7) ~/ 8;

    if (data.length != expLen) {
      throw const CryptoException(
          "AffinePointt length doesn't match the curve.");
    }

    final x0 = (data[expLen - 1] & 0x80) >> 7;
    data[expLen - 1] &= 0x80 - 1;

    final y = BigintUtils.fromBytes(data, byteOrder: Endian.little);

    final x2 = (y * y - BigInt.from(1)) *
        BigintUtils.inverseMod(
          curve.d * y * y - curve.a,
          p,
        ) %
        p;
    BigInt x = ECDSAUtils.modularSquareRootPrime(x2, p);
    if (x.isOdd != (x0 == 1)) {
      x = (-x) % p;
    }

    return Tuple(x, y);
  }

  /// Creates an elliptic curve point from a raw byte encoding.
  static Tuple<BigInt, BigInt> _fromRawEncoding(
      List<int> data, int rawEncodingLength) {
    assert(data.length == rawEncodingLength);

    final xs = data.sublist(0, rawEncodingLength ~/ 2);
    final ys = data.sublist(rawEncodingLength ~/ 2);

    assert(xs.length == rawEncodingLength ~/ 2);
    assert(ys.length == rawEncodingLength ~/ 2);

    final coordX = BigintUtils.fromBytes(xs);
    final coordY = BigintUtils.fromBytes(ys);

    return Tuple(coordX, coordY);
  }

  /// Creates an elliptic curve point from a compressed byte encoding.
  static Tuple<BigInt, BigInt> _fromCompressed(List<int> data, CurveFp curve) {
    if (data[0] != 0x02 && data[0] != 0x03) {
      throw const CryptoException('Malformed compressed point encoding');
    }

    final isEven = data[0] == 0x02;
    final x = BigintUtils.fromBytes(data.sublist(1));
    final p = curve.p;

    final alpha = (x.modPow(BigInt.from(3), p) + curve.a * x + curve.b) % p;

    final beta = ECDSAUtils.modularSquareRootPrime(alpha, p);
    final betaEven = (beta & BigInt.one == BigInt.zero) ? false : true;
    if (isEven == betaEven) {
      final y = p - beta;
      return Tuple(x, y);
    } else {
      return Tuple(x, beta);
    }
  }

  /// Creates an elliptic curve point from a hybrid byte encoding.
  static Tuple<BigInt, BigInt> _fromHybrid(
      List<int> data, int rawEncodingLength) {
    assert(data[0] == 0x06 || data[0] == 0x07);

    // Primarily use the uncompressed as it's easiest to handle
    final result = _fromRawEncoding(data.sublist(1), rawEncodingLength);
    final x = result.item1;
    final y = result.item2;
    final prefix = y & BigInt.one;
    // Validate if it's self-consistent if we're asked to do that
    if (((prefix == BigInt.one && data[0] != 0x07) ||
        (prefix == BigInt.zero && data[0] != 0x06))) {
      throw const CryptoException('Inconsistent hybrid point encoding');
    }

    return Tuple(x, y);
  }

  T cast<T extends AbstractPoint>() {
    if (this is! T) {
      throw CryptoException("Cannot cast $runtimeType to $T");
    }
    return this as T;
  }

  @override
  String toString() {
    return "($x, $y)";
  }
}
