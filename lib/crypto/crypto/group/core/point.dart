import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Contract every elliptic-curve point implementation follows.
abstract class ECPoint<
  SCALAR extends Object,
  POINT extends ECPoint<SCALAR, POINT>
> {
  const ECPoint();
  POINT operator +(POINT rhs);
  POINT operator *(SCALAR rhs);
  POINT operator -();
  BuBytes toBytes();

  /// Casts this point to [T], throwing [CastFailedException] on mismatch.
  T cast<T extends ECPoint<SCALAR, POINT>>() {
    if (this is! T)
      throw BuError(
        DefaultErrorType.castFailed,
        "Failed to cast value",
        details: {"expected": "T", "value": runtimeType.toString()},
      );
    return this as T;
  }
}

/// A placeholder [ECPoint] for curves/operations that aren't implemented;
/// every operation throws.
class UnsupportedEcPoint extends ECPoint<Object, UnsupportedEcPoint> {
  @override
  UnsupportedEcPoint operator *(Object rhs) {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  UnsupportedEcPoint operator +(UnsupportedEcPoint rhs) {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  BuBytes toBytes() {
    throw CoreErrors.cryptoOperationNotSupported;
  }

  @override
  UnsupportedEcPoint operator -() {
    throw CoreErrors.cryptoOperationNotSupported;
  }
}
