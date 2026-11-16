import 'package:blockchain_utils/encoding/cbor/core/cbor.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';
import 'package:blockchain_utils/encoding/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// A class representing a CBOR (Concise Binary Object Representation) String value.
abstract class CborString<T> extends CborObject<T> {
  const CborString(super.value);
  BuBytes _encode();

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    return _encode();
  }

  @override
  String getValue();

  @override
  String toString() {
    return "CborString(${getValue()})";
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) string value.
class CborStringValue extends CborString<String> {
  final CborLengthEncoding lengthEncoding;

  factory CborStringValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Constructor for creating a CborStringValue instance with the provided parameters.
  /// It accepts a string value and optional list of CBOR tags.
  CborStringValue(
    super.value, {
    this.lengthEncoding = CborLengthEncoding.canonical,
  });

  @override
  BuBytes _encode() {
    final bytes = CborBytesTracker();
    final toBytes = StringUtils.encode(value);
    bytes.pushInt(
      MajorTags.utf8String,
      toBytes.length,
      lengthEncoding: lengthEncoding,
    );
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
  String getValue() {
    return value;
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) string value with indefinite tag length.
class CborIndefiniteStringValue extends CborString<List<String>> {
  CborIndefiniteStringValue(List<String> value) : super(value.immutable);

  factory CborIndefiniteStringValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  @override
  BuBytes _encode() {
    final bytes = CborBytesTracker();
    bytes.pushIndefinite(MajorTags.utf8String);
    for (final v in value) {
      final toBytes = StringUtils.encode(v);
      bytes.pushInt(MajorTags.utf8String, toBytes.length);
      bytes.pushBytes(toBytes);
    }
    bytes.breakDynamic();
    return bytes.buffer();
  }

  @override
  String getValue() {
    return value.join();
  }
}
