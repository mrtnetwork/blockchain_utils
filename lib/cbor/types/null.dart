import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/compare/compare.dart';

/// A class representing a CBOR (Concise Binary Object Representation) null value.
class CborNullValue implements CborObject {
  /// Constructor for creating a CborNullValue instance with the provided parameters.
  /// It accepts optional list of CBOR tags.
  const CborNullValue([this.tags = const []]);

  /// value always is null
  @override
  dynamic get value => null;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags);
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
    return bytesEqual(tags, other.tags);
  }

  /// override hashcode
  @override
  int get hashCode => "null".hashCode;
}

/// A class representing a CBOR (Concise Binary Object Representation) undefined value.
class CborUndefinedValue implements CborObject {
  /// Constructor for creating a CborUndefinedValue instance with the provided parameters.
  /// It accepts optional list of CBOR tags.
  const CborUndefinedValue([this.tags = const []]);

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;

  /// value always is null
  @override
  dynamic get value => null;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags);
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
    return bytesEqual(tags, other.tags);
  }

  /// override hashcode
  @override
  int get hashCode => "undefined".hashCode;
}
