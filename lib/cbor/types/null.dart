import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) null value.
class CborNullValue implements CborObject {
  /// Constructor for creating a CborNullValue instance with the provided parameters.
  const CborNullValue();

  /// value always is null
  @override
  dynamic get value => null;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushInt(MajorTags.simpleOrFloat, SimpleTags.simpleNull);
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
    return "null";
  }

  /// override equal operation
  @override
  operator ==(other) {
    if (other is! CborNullValue) return false;
    return true;
  }

  /// override hashcode
  @override
  int get hashCode => "null".hashCode;
}

/// A class representing a CBOR (Concise Binary Object Representation) undefined value.
class CborUndefinedValue implements CborObject {
  /// Constructor for creating a CborUndefinedValue instance with the provided parameters.
  const CborUndefinedValue();

  /// value always is null
  @override
  dynamic get value => null;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushInt(MajorTags.simpleOrFloat, SimpleTags.simpleUndefined);
    return bytes.toBytes();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return "undefined";
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// override equal operation
  @override
  operator ==(other) {
    if (other is! CborUndefinedValue) return false;
    return true;
  }

  /// override hashcode
  @override
  int get hashCode => "undefined".hashCode;
}
