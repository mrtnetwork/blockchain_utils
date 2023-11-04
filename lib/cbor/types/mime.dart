import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/types/string.dart';
import 'package:blockchain_utils/compare/compare.dart';

/// A class representing a CBOR (Concise Binary Object Representation) mime value.
class CborMimeValue implements CborObject {
  /// Constructor for creating a CborMimeValue instance with the provided parameters.
  /// It accepts the string value and an optional list of CBOR tags.
  const CborMimeValue(this.value, [this.tags = const []]);

  /// value as string
  @override
  final String value;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags.isEmpty ? [CborTags.mime] : tags);
    final toBytes = CborStringValue(value);
    bytes.pushBytes(toBytes.encode());
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
    return value;
  }

  /// override equal operation
  @override
  operator ==(other) {
    if (other is! CborMimeValue) return false;
    return value == other.value && bytesEqual(tags, other.tags);
  }

  /// override hashcode
  @override
  int get hashCode => value.hashCode;
}
