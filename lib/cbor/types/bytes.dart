import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) bytes value.
class CborBytesValue implements CborObject {
  /// Constructor for creating a CborBytesValue instance with the provided parameters.
  /// It accepts the bytes value.
  CborBytesValue(List<int> value) : value = value.asImmutableBytes;

  @override
  final List<int> value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushInt(MajorTags.byteString, value.length);
    bytes.pushBytes(value);
    return bytes.buffer();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// overide equal operation
  @override
  operator ==(other) {
    if (other is! CborBytesValue) return false;

    return BytesUtils.bytesEqual(other.value, value);
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return BytesUtils.toHexString(value);
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) bytes value with indefinite tag.
class CborDynamicBytesValue implements CborObject {
  /// Constructor for creating a CborDynamicBytesValue instance with the provided parameters.
  /// It accepts the bytes value.
  CborDynamicBytesValue(List<List<int>> value)
      : value = value.map((e) => e.asImmutableBytes).toList().immutable;

  @override
  final List<List<int>> value;
  // @override
  // List<List<int>> get value => _value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushIndefinite(MajorTags.byteString);
    for (final v in value) {
      bytes.pushInt(MajorTags.byteString, v.length);
      bytes.pushBytes(v);
    }
    bytes.breakDynamic();
    return bytes.buffer();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value.toString();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// overide equal operation
  @override
  operator ==(other) {
    if (other is! CborDynamicBytesValue) return false;

    return CompareUtils.iterableIsEqual(value, other.value);
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}
