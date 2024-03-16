import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/types/int64.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/types/bigint.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/compare/compare.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Dcecimal value.
class CborDecimalFracValue implements CborObject {
  /// Constructor for creating a CborDecimalFracValue instance with the provided parameters.
  /// It accepts the Bigint exponent and mantissa value.
  const CborDecimalFracValue(this.exponent, this.mantissa);

  /// Create a CborBigFloatValue from two CborNumeric values representing the exponent and mantissa.
  factory CborDecimalFracValue.fromCborNumeric(
    CborNumeric exponent,
    CborNumeric mantissa,
  ) {
    return CborDecimalFracValue(CborNumeric.getCborNumericValue(exponent),
        CborNumeric.getCborNumericValue(mantissa));
  }

  /// exponent value
  final BigInt exponent;

  /// mantissa value
  final BigInt mantissa;

  /// The decimal value as a list [exponent, mantissa].
  @override
  List<BigInt> get value => [exponent, mantissa];

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(CborTags.decimalFrac);
    bytes.pushInt(MajorTags.array, 2);
    bytes.pushBytes(_encodeValue(exponent));
    bytes.pushBytes(_encodeValue(mantissa));
    return bytes.toBytes();
  }

  List<int> _encodeValue(BigInt value) {
    if (value.bitLength > 64) {
      return CborBigIntValue(value).encode();
    }
    return CborSafeIntValue(value).encode();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value.join(", ");
  }

  /// overide equal operation
  @override
  operator ==(other) {
    if (other is! CborDecimalFracValue) return false;
    return iterableIsEqual(value, other.value);
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}
