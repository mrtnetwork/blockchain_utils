import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/compare/compare.dart';
import 'package:blockchain_utils/string/string.dart';

/// A class representing a CBOR (Concise Binary Object Representation) String value.
abstract class CborString implements CborObject {
  @override
  abstract final dynamic value;

  /// List of CBOR tags associated with the URL value.
  @override
  abstract final List<int> tags;

  List<int> _encode();

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    return _encode();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) string value.
class CborStringValue extends CborString {
  /// Constructor for creating a CborStringValue instance with the provided parameters.
  /// It accepts a string value and optional list of CBOR tags.
  CborStringValue(this.value, [this.tags = const []]);

  /// value as string
  @override
  final String value;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;

  @override
  List<int> _encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags);
    final toBytes = StringUtils.encode(value);
    bytes.pushInt(MajorTags.utf8String, toBytes.length);
    bytes.pushBytes(toBytes);
    return bytes.toBytes();
  }

  /// override equal operation
  @override
  operator ==(other) {
    if (other is! CborStringValue) return false;
    return value == other.value && bytesEqual(tags, other.tags);
  }

  /// override hashcode
  @override
  int get hashCode => value.hashCode;
}

/// A class representing a CBOR (Concise Binary Object Representation) string value with indefinite tag length.
class CborIndefiniteStringValue extends CborString {
  /// Constructor for creating a CborStringValue instance with the provided parameters.
  /// It accepts a List<String> value and optional list of CBOR tags.
  CborIndefiniteStringValue(this.value, [this.tags = const []]);

  /// value as List<String>
  @override
  final List<String> value;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;
  @override
  List<int> _encode() {
    final bytes = CborBytesTracker();
    bytes.pushIndefinite(MajorTags.utf8String);
    for (final v in value) {
      final toBytes = StringUtils.encode(v);
      bytes.pushInt(MajorTags.utf8String, toBytes.length);
      bytes.pushBytes(toBytes);
    }
    bytes.breakDynamic();
    return bytes.toBytes();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value.join(", ");
  }

  /// override equal operation
  @override
  operator ==(other) {
    if (other is! CborIndefiniteStringValue) return false;
    return iterableIsEqual<String>(value, other.value) &&
        bytesEqual(tags, other.tags);
  }

  /// override hashcode
  @override
  int get hashCode => value.hashCode;
}
