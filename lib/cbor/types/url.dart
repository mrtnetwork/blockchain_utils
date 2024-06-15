import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/types/string.dart';

/// A class representing a CBOR (Concise Binary Object Representation) uri value.
class CborUriValue implements CborString {
  /// Constructor for creating a CborUriValue instance with the provided parameters.
  /// It accepts string value of uri.
  const CborUriValue(this.value);

  /// value as string
  @override
  final String value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(CborTags.uri);
    final toBytes = CborStringValue(value);
    bytes.pushBytes(toBytes.encode());
    return bytes.toBytes();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value;
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// override equal operation
  @override
  operator ==(other) {
    if (other is! CborUriValue) return false;
    return value == other.value;
  }

  /// override hashcode
  @override
  int get hashCode => value.hashCode;
}
