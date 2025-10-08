import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/types/int64.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/types/bigint.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Dcecimal value.
class CborDecimalFracValue extends CborObject<List<BigInt>> {
  /// Constructor for creating a CborDecimalFracValue instance with the provided parameters.
  /// It accepts the Bigint exponent and mantissa value.
  CborDecimalFracValue(this.exponent, this.mantissa)
      : super([exponent, mantissa].immutable);

  /// Create a CborBigFloatValue from two CborNumeric values representing the exponent and mantissa.
  factory CborDecimalFracValue.fromCborNumeric(
      CborNumeric exponent, CborNumeric mantissa) {
    return CborDecimalFracValue(CborNumeric.getCborNumericValue(exponent),
        CborNumeric.getCborNumericValue(mantissa));
  }

  /// exponent value
  final BigInt exponent;

  /// mantissa value
  final BigInt mantissa;

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
    return CompareUtils.iterableIsEqual(value, other.value);
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}
