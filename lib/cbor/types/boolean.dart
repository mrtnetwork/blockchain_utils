import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) boolean value.
class CborBoleanValue implements CborObject {
  /// Constructor for creating a CborBoleanValue instance with the provided parameters.
  /// It accepts the boolean value.
  const CborBoleanValue(this.value);

  /// The value as a boolean.
  @override
  final bool value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushInt(MajorTags.simpleOrFloat,
        value ? SimpleTags.simpleTrue : SimpleTags.simpleFalse);
    return bytes.toBytes();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value.toString();
  }

  /// overide equal operation
  @override
  operator ==(other) {
    if (other is! CborBoleanValue) return false;

    return value == other.value;
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}
