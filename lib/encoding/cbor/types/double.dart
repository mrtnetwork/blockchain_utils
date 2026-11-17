import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/encoding/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/encoding/cbor/utils/float_utils.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/encoding/cbor/core/cbor.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing a CBOR (Concise Binary Object Representation) float value.
class CborFloatValue extends CborObject<double> {
  /// Constructor for creating a CborFloatValue instance with the provided parameters.
  /// It accepts the double value.
  CborFloatValue(super.value) : _decodFloatType = null;

  factory CborFloatValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Create a CborFloatValue from a 16-bit double value.
  CborFloatValue.from16BytesFloat(super.value)
    : _decodFloatType = FloatLength.bytes16 {
    if (!FloatUtils.isLessThan(value, FloatLength.bytes16)) {
      throw BuError(
        DefaultErrorType.invalidLength,
        "Float value overflows 16-bit encoding.",
        details: {"value": value.toString()},
      );
    }
  }

  /// Create a CborFloatValue from a 32-bit double value.
  CborFloatValue.from32BytesFloat(super.value)
    : _decodFloatType = FloatLength.bytes32 {
    if (!FloatUtils.isLessThan(value, FloatLength.bytes32)) {
      throw BuError(
        DefaultErrorType.invalidLength,
        "Float value overflows 32-bit encoding.",
        details: {"value": value.toString()},
      );
    }
  }

  /// Constructor for creating a CborFloatValue instance with the provided parameters.
  /// It accepts the double value and an optional list of CBOR tags.
  CborFloatValue.from64BytesFloat(super.value)
    : _decodFloatType = FloatLength.bytes64;

  /// instance of FloatUtils for encode and decoding float
  late final FloatUtils _decodFloat = FloatUtils(value);

  /// the type of encode and decoding float
  final FloatLength? _decodFloatType;

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    final bytes = CborBytesTracker();
    if (value.isNaN) {
      bytes.pushMajorTag(MajorTags.simpleOrFloat, NumBytes.two);
      bytes.pushBytes([0x7e, 0x00]);
      return bytes.buffer();
    }
    final toBytes = _decodFloat.toBytes(_decodFloatType);

    bytes.pushMajorTag(MajorTags.simpleOrFloat, toBytes.$2.numBytes);
    bytes.pushBytes(toBytes.$1);
    return bytes.buffer();
  }

  @override
  String toString() {
    return "CborFloatValue($value)";
  }

  @override
  List<dynamic> get variables => [value, _decodFloatType];
}
