import 'package:blockchain_utils/crypto/crypto/ec/curve/curve.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

abstract class ECPoint<
  SCALAR extends Object,
  POINT extends ECPoint<SCALAR, POINT>
> {
  const ECPoint();
  POINT operator +(POINT rhs);
  POINT operator *(SCALAR rhs);
  POINT operator -();
  List<int> toBytes();
  String toHex() {
    final bytes = toBytes();
    return BytesUtils.toHexString(bytes);
  }

  T cast<T extends ECPoint<SCALAR, POINT>>() {
    if (this is! T) throw CastFailedException<T>(value: this);
    return this as T;
  }
}

enum EncodeType { comprossed, hybrid, raw, uncompressed }

abstract class BaseProjectivePointNative
    extends ECPoint<BigInt, BaseProjectivePointNative> {
  abstract final CurveFp curve;
  abstract final BigInt? order;
  abstract final BigInt x;
  abstract final BigInt y;
  bool isZero();
  @override
  List<int> toBytes([EncodeType encodeType = EncodeType.comprossed]) {
    List<int> encode() {
      final xBytes = BigintUtils.toBytes(
        x,
        length: BigintUtils.bitlengthInBytes(curve.p),
      );
      final yBytes = BigintUtils.toBytes(
        y,
        length: BigintUtils.bitlengthInBytes(curve.p),
      );
      return [...xBytes, ...yBytes];
    }

    switch (encodeType) {
      case EncodeType.raw:
        return encode();
      case EncodeType.uncompressed:
        return [0x04, ...encode()];
      case EncodeType.hybrid:
        final raw = encode();
        int prefix = 0x06;
        if (y.isOdd) {
          prefix = 0x07;
        }
        return [prefix, ...raw];
      default:
        final List<int> xBytes = BigintUtils.toBytes(
          x,
          length: BigintUtils.bitlengthInBytes(curve.p),
        );
        int prefix = 0x02;
        if (y.isOdd) {
          prefix = 0x03;
        }
        return [prefix, ...xBytes];
    }
  }
}

abstract class ProjectivePointNative extends BaseProjectivePointNative {
  abstract final BigInt z;
  ProjectivePointNative double();
}

abstract class BaseExtendedPointNative
    extends ECPoint<BigInt, BaseExtendedPointNative> {
  abstract final CurveED curve;
  abstract final BigInt x;
  abstract final BigInt y;
}
