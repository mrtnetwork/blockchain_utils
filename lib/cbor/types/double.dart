import 'package:blockchain_utils/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/utils/float_utils.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

/// A class representing a CBOR (Concise Binary Object Representation) float value.
class CborFloatValue extends CborObject<double> {
  /// Constructor for creating a CborFloatValue instance with the provided parameters.
  /// It accepts the double value.
  CborFloatValue(super.value) : _decodFloatType = null;

  factory CborFloatValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Create a CborFloatValue from a 16-byte double value.
  CborFloatValue.from16BytesFloat(super.value)
    : assert(
        FloatUtils.isLessThan(value, FloatLength.bytes16),
        "overflow bytes",
      ),
      _decodFloatType = FloatLength.bytes16;

  /// Create a CborFloatValue from a 32-byte double value.
  CborFloatValue.from32BytesFloat(super.value)
    : assert(
        FloatUtils.isLessThan(value, FloatLength.bytes32),
        "overflow bytes",
      ),
      _decodFloatType = FloatLength.bytes32;

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
  List<int> encode() {
    final bytes = CborBytesTracker();
    if (value.isNaN) {
      bytes.pushMajorTag(MajorTags.simpleOrFloat, NumBytes.two);
      bytes.pushBytes([0x7e, 0x00]);
      return bytes.toBytes();
    }
    final toBytes = _decodFloat.toBytes(_decodFloatType);

    bytes.pushMajorTag(MajorTags.simpleOrFloat, toBytes.$2.numBytes);
    bytes.pushBytes(toBytes.$1);
    return bytes.toBytes();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// value as string
  @override
  String toString() {
    return value.toString();
  }

  @override
  List<dynamic> get variables => [value, _decodFloatType];
}
