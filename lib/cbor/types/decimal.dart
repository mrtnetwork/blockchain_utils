import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/types/bigint.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/types/int.dart';
import 'package:blockchain_utils/compare/compare.dart';
import 'int64.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Dcecimal value.
class CborDecimalFracValue implements CborObject {
  /// Constructor for creating a CborDecimalFracValue instance with the provided parameters.
  /// It accepts the Bigint exponent and mantissa value and an optional list of CBOR tags.
  const CborDecimalFracValue(this.exponent, this.mantissa,
      [this.tags = const []]);

  /// Create a CborBigFloatValue from two CborNumeric values representing the exponent and mantissa.
  factory CborDecimalFracValue.fromCborNumeric(
      CborNumeric exponent, CborNumeric mantissa,
      [List<int> tags = const []]) {
    return CborDecimalFracValue(CborNumeric.getCborNumericValue(exponent),
        CborNumeric.getCborNumericValue(mantissa), tags);
  }

  /// exponent value
  final BigInt exponent;

  /// mantissa value
  final BigInt mantissa;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;

  /// The decimal value as a list [exponent, mantissa].
  @override
  List<BigInt> get value => [exponent, mantissa];

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags.isEmpty ? [CborTags.decimalFrac] : tags);
    bytes.pushInt(MajorTags.array, 2);
    bytes.pushBytes(_encodeValue(exponent));
    bytes.pushBytes(_encodeValue(mantissa));
    return bytes.toBytes();
  }

  List<int> _encodeValue(BigInt value) {
    if (value.isValidInt) {
      return CborIntValue(value.toInt()).encode();
    } else if (value.bitLength > 64) {
      return CborBigIntValue(value).encode();
    }

    return CborInt64Value(value).encode();
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
    return iterableIsEqual(value, other.value) && bytesEqual(tags, other.tags);
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}
