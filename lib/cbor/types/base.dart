import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/types/string.dart';
import 'package:blockchain_utils/compare/compare.dart';

/// An enum representing different types of base64 encoding used in CBOR.
enum CborBase64Types {
  /// Standard base64 encoding
  base64,

  /// URL-safe base64 encoding
  base64Url,

  /// Expected URL-safe base64 encoding
  base64UrlExpected,

  /// Expected standard base64 encoding
  base64Expected,

  /// Expected base16 (hexadecimal) encoding
  base16Expected;

  /// This property allows retrieving the CBOR tag associated with each CborBase64Types enum value.
  int get tag {
    switch (this) {
      case CborBase64Types.base16Expected:
        return CborTags.base16Expected;
      case CborBase64Types.base64:
        return CborTags.base64;
      case CborBase64Types.base64Expected:
        return CborTags.base64Expected;
      case CborBase64Types.base64UrlExpected:
        return CborTags.base64UrlExpected;
      default:
        return CborTags.base64Url;
    }
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) Base-URL value.
class CborBaseUrlValue implements CborString {
  /// Constructor for creating a CborBaseUrlValue instance with the provided parameters.
  /// It accepts the URL value, type, and an optional list of CBOR tags.
  const CborBaseUrlValue(this.value, this.type, [this.tags = const []]);

  /// The base-URL value as a string.
  @override
  final String value;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;

  /// The type of base64 encoding used in the URL value.
  final CborBase64Types type;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags.isEmpty ? [type.tag] : tags);
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

  /// overide equal operation
  @override
  operator ==(other) {
    if (other is! CborBaseUrlValue) return false;

    return value == other.value &&
        type.tag == other.type.tag &&
        bytesEqual(tags, other.tags);
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode ^ type.tag;
}
