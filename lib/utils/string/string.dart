import 'dart:convert';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

/// An enumeration representing different string encoding options.
enum StringEncoding {
  /// The ASCII encoding option.
  /// This encoding represents characters using the ASCII character set,
  /// which uses 7-bit encoding and supports a limited character range.
  ascii,

  /// The UTF-8 encoding option.
  /// This encoding represents characters using the Unicode Transformation Format (UTF-8),
  /// which is a variable-length character encoding that supports a wide range of characters,
  /// including those from various languages and symbols.
  utf8,

  /// The base64 encoding option
  base64,
  base64UrlSafe
}

/// A utility class for working with strings and common string operations.
class StringUtils {
  static final RegExp _hexBytesRegex = RegExp(r'^(0x|0X)?([0-9A-Fa-f]{2})+$');
  static final RegExp _hexaDecimalRegex = RegExp(r'^(0x|0X)?[0-9A-Fa-f]+$');

  static bool isHexBytes(String v) {
    return _hexBytesRegex.hasMatch(v);
  }

  static bool ixHexaDecimalNumber(String v) {
    return _hexaDecimalRegex.hasMatch(v);
  }

  static List<int> toBytes(String v) {
    if (isHexBytes(v)) {
      return BytesUtils.fromHexString(v);
    } else {
      return encode(v);
    }
  }

  static List<int>? tryToBytes(String? v) {
    if (v == null) return null;
    try {
      return toBytes(v);
    } catch (_) {
      return null;
    }
  }

  /// Removes the '0x' prefix from a hexadecimal string if it exists.
  ///
  /// If the input [value] starts with '0x', this method returns the
  /// substring of [value] without those two characters. If [value]
  /// does not start with '0x', it returns the original [value].
  static String strip0x(String value) {
    if (value.toLowerCase().startsWith("0x")) {
      return value.substring(2);
    }
    return value;
  }

  /// Encodes the given [value] string into a list of bytes using the specified [type].
  ///
  /// The [type] parameter determines the encoding type to use, with UTF-8 being the default.
  /// Returns a list of bytes representing the encoded string.
  static List<int> encode(String value,
      {StringEncoding type = StringEncoding.utf8}) {
    switch (type) {
      case StringEncoding.utf8:
        return utf8.encode(value);
      case StringEncoding.base64:
      case StringEncoding.base64UrlSafe:
        return base64Decode(value);
      default:
        return ascii.encode(value);
    }
  }

  /// Encodes the given [value] string into a list of bytes using the specified [type] if possible.
  ///
  /// The [type] parameter determines the encoding type to use, with UTF-8 being the default.
  /// Returns a list of bytes representing the encoded string.
  static List<int>? tryEncode(String? value,
      {StringEncoding type = StringEncoding.utf8}) {
    if (value == null) return null;
    try {
      return encode(value, type: type);
    } catch (e) {
      return null;
    }
  }

  /// Decodes a list of bytes [value] into a string using the specified [type].
  ///
  /// The [type] parameter determines the decoding type to use, with UTF-8 being the default.
  /// Returns the decoded string.
  static String decode(List<int> value,
      {StringEncoding type = StringEncoding.utf8,
      bool allowInvalidOrMalformed = false}) {
    switch (type) {
      case StringEncoding.utf8:
        return utf8.decode(value, allowMalformed: allowInvalidOrMalformed);
      case StringEncoding.base64:
        return base64Encode(value);
      case StringEncoding.base64UrlSafe:
        return base64UrlEncode(value);
      default:
        return ascii.decode(value, allowInvalid: allowInvalidOrMalformed);
    }
  }

  /// Decodes a list of bytes [value] into a string using the specified [type] if possible.
  ///
  /// The [type] parameter determines the decoding type to use, with UTF-8 being the default.
  /// Returns the decoded string.
  static String? tryDecode(List<int>? value,
      {StringEncoding type = StringEncoding.utf8,
      bool allowInvalidOrMalformed = false}) {
    if (value == null) return null;
    try {
      return decode(value,
          type: type, allowInvalidOrMalformed: allowInvalidOrMalformed);
    } catch (e) {
      return null;
    }
  }

  /// Converts a Dart object represented as a Map to a JSON-encoded string.
  ///
  /// The input [data] is a Map representing the Dart object.
  static String fromJson(Object data,
      {String? indent,
      bool toStringEncodable = false,
      Object? Function(dynamic)? toEncodable}) {
    if (toStringEncodable) {
      toEncodable ??= (c) => c.toString();
    }
    if (indent != null) {
      return JsonEncoder.withIndent(indent, toEncodable).convert(data);
    }
    return jsonEncode(data, toEncodable: toEncodable);
  }

  /// Converts a JSON-encoded string to a Dart object represented as a Map.
  ///
  /// The input [data] is a JSON-encoded string.
  /// Returns a Map representing the Dart object.
  static T toJson<T>(Object? data,
      {Object? Function(Object?, Object?)? reviver}) {
    if (data is! String) {
      if (data is! T) {
        throw ArgumentException(
            "Invalid data encountered during JSON conversion.",
            details: {"data": data});
      }
      return data;
    }
    final decode = jsonDecode(data, reviver: reviver);
    if (decode is! T) {
      throw ArgumentException(
          "Invalid json casting. excepted: $T got: ${decode.runtimeType}");
    }
    return decode;
  }

  /// Converts a Dart object represented as a Map to a JSON-encoded string if possible.
  ///
  /// The input [data] is a Map representing the Dart object.
  static String? tryFromJson(Object? data,
      {String? indent,
      bool toStringEncodable = false,
      Object? Function(dynamic)? toEncodable}) {
    try {
      return fromJson(data!,
          indent: indent,
          toStringEncodable: toStringEncodable,
          toEncodable: toEncodable);
    } catch (e) {
      return null;
    }
  }

  /// Converts a JSON-encoded string to a Dart object represented as a Map if possible.
  ///
  /// The input [data] is a JSON-encoded string.
  /// Returns a Map representing the Dart object.
  static T? tryToJson<T>(Object? data,
      {Object? Function(Object?, Object?)? reviver}) {
    try {
      return toJson<T>(data, reviver: reviver);
    } catch (_) {
      return null;
    }
  }
}
