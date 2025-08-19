import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) String value.
abstract class CborString<T> extends CborObject<T> {
  const CborString(super.value);
  List<int> _encode();

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    return _encode();
  }

  String getValue();

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) string value.
class CborStringValue extends CborString<String> {
  final CborLengthEncoding lengthEncoding;

  /// Constructor for creating a CborStringValue instance with the provided parameters.
  /// It accepts a string value and optional list of CBOR tags.
  CborStringValue(super.value,
      {this.lengthEncoding = CborLengthEncoding.canonical});

  @override
  List<int> _encode() {
    final bytes = CborBytesTracker();
    final toBytes = StringUtils.encode(value);
    bytes.pushInt(MajorTags.utf8String, toBytes.length,
        lengthEncdoing: lengthEncoding);
    bytes.pushBytes(toBytes);
    return bytes.buffer();
  }

  /// override equal operation
  @override
  operator ==(other) {
    if (other is! CborStringValue) return false;
    return value == other.value;
  }

  /// override hashcode
  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return value;
  }

  @override
  String getValue() {
    return value;
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) string value with indefinite tag length.
class CborIndefiniteStringValue extends CborString<List<String>> {
  /// Constructor for creating a CborStringValue instance with the provided parameters.
  /// It accepts a `List<String>` value.
  CborIndefiniteStringValue(List<String> value) : super(value.immutable);

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
    return CompareUtils.iterableIsEqual<String>(value, other.value);
  }

  /// override hashcode
  @override
  int get hashCode => value.hashCode;

  @override
  String getValue() {
    return value.join();
  }
}
