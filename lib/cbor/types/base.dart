import 'package:blockchain_utils/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/types/string.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

/// An enum representing different types of base64 encoding used in CBOR.
class CborBase64Types {
  /// Standard base64 encoding
  static const CborBase64Types base64 = CborBase64Types._(CborTags.base64);

  /// URL-safe base64 encoding
  static const CborBase64Types base64Url = CborBase64Types._(
    CborTags.base64Url,
  );

  /// Expected URL-safe base64 encoding
  static const CborBase64Types base64UrlExpected = CborBase64Types._(
    CborTags.base64UrlExpected,
  );

  /// Expected standard base64 encoding
  static const CborBase64Types base64Expected = CborBase64Types._(
    CborTags.base64Expected,
  );

  /// Expected base16 (hexadecimal) encoding
  static const CborBase64Types base16Expected = CborBase64Types._(
    CborTags.base16Expected,
  );

  /// This property allows retrieving the CBOR tag associated with each CborBase64Types enum value.
  final List<int> tag;

  /// Constructor for creating a CborBase64Types enum value with the specified CBOR tag.
  const CborBase64Types._(this.tag);

  static const List<CborBase64Types> values = [
    base64,
    base64Url,
    base64UrlExpected,
    base64Expected,
    base16Expected,
  ];
}

/// A class representing a CBOR (Concise Binary Object Representation) Base-URL value.
class CborBaseUrlValue extends CborString<String> {
  /// Constructor for creating a CborBaseUrlValue instance with the provided parameters.
  /// It accepts the URL value, type, and an optional list of CBOR tags.
  const CborBaseUrlValue(super.value, this.type);

  factory CborBaseUrlValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// The type of base64 encoding used in the URL value.
  final CborBase64Types type;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(type.tag);
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

  @override
  String getValue() {
    return value;
  }

  @override
  List<dynamic> get variables => [value, type];
}
