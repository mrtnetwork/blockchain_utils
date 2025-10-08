import 'dart:convert';
import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/base64/base64.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
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
  base64UrlSafe,

  base58,
  base58Check,

  hex
}

/// A utility class for working with strings and common string operations.
class StringUtils {
  static final RegExp _hexBytesRegex = RegExp(r'^(0x|0X)?([0-9A-Fa-f]{2})+$');
  static final RegExp _hexaDecimalRegex = RegExp(r'^(0x|0X)?[0-9A-Fa-f]+$');
  static final RegExp _base58Regex = RegExp(
      r'^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$');
  static final RegExp _base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');

  static bool isBase58(String input) {
    return _base58Regex.hasMatch(input);
  }

  static bool isBase64(String input, {bool validatePadding = true}) {
    final hasMatch = _base64Regex.hasMatch(input);
    if (hasMatch) {
      if (validatePadding) return input.length % 4 == 0;
      return true;
    }
    return false;
  }

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

  /// add the '0x' prefix to a hexadecimal string if it exists.
  static String add0x(String value) {
    if (value.toLowerCase().startsWith("0x")) {
      return value;
    }
    return "0x$value";
  }

  /// Encodes the given [value] string into a list of bytes using the specified [type].
  ///
  /// The [type] parameter determines the encoding type to use, with UTF-8 being the default.
  /// Returns a list of bytes representing the encoded string.
  static List<int> encode(String value,
      {StringEncoding type = StringEncoding.utf8,
      bool validateB64Padding = true,
      bool allowUrlSafe = true,
      Base58Alphabets base58alphabets = Base58Alphabets.bitcoin}) {
    try {
      switch (type) {
        case StringEncoding.utf8:
          return utf8.encode(value);
        case StringEncoding.base64:
        case StringEncoding.base64UrlSafe:
          return B64Decoder.decode(value,
              validatePadding: validateB64Padding, urlSafe: allowUrlSafe);
        case StringEncoding.base58:
          return Base58Decoder.decode(value, base58alphabets);
        case StringEncoding.base58Check:
          return Base58Decoder.checkDecode(value, base58alphabets);
        case StringEncoding.hex:
          return BytesUtils.fromHexString(value);
        case StringEncoding.ascii:
          return ascii.encode(value);
      }
    } catch (e) {
      throw ArgumentException("Failed to convert string as ${type.name} bytes.",
          details: {"error": e.toString()});
    }
  }

  /// Encodes a JSON-serializable [json] object into a list of bytes.
  static List<int> encodeJson(Object json,
      {String? indent,
      bool toStringEncodable = false,
      Object? Function(dynamic)? toEncodable}) {
    final value = fromJson(json,
        indent: indent,
        toStringEncodable: toStringEncodable,
        toEncodable: toEncodable);
    return encode(value);
  }

  /// Attempts to encode a JSON-serializable [json] object into a list of bytes,
  /// returning null if the conversion to JSON string fails.
  static List<int>? tryEncodeJson(
    Object? json, {
    String? indent,
    bool toStringEncodable = false,
    Object? Function(dynamic)? toEncodable,
  }) {
    if (json == null) return null;
    try {
      return encodeJson(json,
          indent: indent,
          toEncodable: toEncodable,
          toStringEncodable: toStringEncodable);
    } catch (_) {
      return null;
    }
  }

  /// Encodes the given [value] string into a list of bytes using the specified [type] if possible.
  ///
  /// The [type] parameter determines the encoding type to use, with UTF-8 being the default.
  /// Returns a list of bytes representing the encoded string.
  static List<int>? tryEncode(String? value,
      {StringEncoding type = StringEncoding.utf8,
      bool validateB64Padding = true,
      bool allowUrlSafe = true,
      Base58Alphabets base58alphabets = Base58Alphabets.bitcoin}) {
    if (value == null) return null;
    try {
      return encode(value,
          type: type,
          allowUrlSafe: allowUrlSafe,
          validateB64Padding: validateB64Padding,
          base58alphabets: base58alphabets);
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
      bool allowInvalidOrMalformed = false,
      bool b64NoPadding = false,
      Base58Alphabets base58alphabets = Base58Alphabets.bitcoin}) {
    value = value.asBytes;
    try {
      switch (type) {
        case StringEncoding.utf8:
          return utf8.decode(value, allowMalformed: allowInvalidOrMalformed);
        case StringEncoding.base64:
          return B64Encoder.encode(value, noPadding: b64NoPadding);
        case StringEncoding.base64UrlSafe:
          return B64Encoder.encode(value,
              urlSafe: true, noPadding: b64NoPadding);
        case StringEncoding.base58:
          return Base58Encoder.encode(value, base58alphabets);
        case StringEncoding.base58Check:
          return Base58Encoder.checkEncode(value, base58alphabets);
        case StringEncoding.hex:
          return BytesUtils.toHexString(value);
        case StringEncoding.ascii:
          return ascii.decode(value, allowInvalid: allowInvalidOrMalformed);
      }
    } catch (e) {
      throw ArgumentException("Failed to convert bytes as ${type.name}",
          details: {"error": e.toString()});
    }
  }

  /// Decodes a list of bytes [value] into a JSON object of type [T].
  static T decodeJson<T extends Object>(List<int> value,
      {Object? Function(Object?, Object?)? reviver}) {
    final toString = decode(value);
    return toJson<T>(toString, reviver: reviver);
  }

  /// Attempts to decode a list of bytes [value] into a JSON object of type [T],
  /// returning `null` if decoding or parsing fails.
  static T? tryDecodeJson<T extends Object>(List<int> value,
      {Object? Function(Object?, Object?)? reviver}) {
    final toString = tryDecode(value);
    return tryToJson<T>(toString, reviver: reviver);
  }

  /// Decodes a list of bytes [value] into a string using the specified [type] if possible.
  ///
  /// The [type] parameter determines the decoding type to use, with UTF-8 being the default.
  /// Returns the decoded string.
  static String? tryDecode(List<int>? value,
      {StringEncoding type = StringEncoding.utf8,
      bool allowInvalidOrMalformed = false,
      bool b64NoPadding = false,
      Base58Alphabets base58alphabets = Base58Alphabets.bitcoin}) {
    if (value == null) return null;
    try {
      return decode(value,
          type: type,
          allowInvalidOrMalformed: allowInvalidOrMalformed,
          b64NoPadding: b64NoPadding,
          base58alphabets: base58alphabets);
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
  static T toJson<T extends Object?>(Object? data,
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
          "Invalid json casting. expected: $T got: ${decode.runtimeType}");
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
  static T? tryToJson<T extends Object?>(Object? data,
      {Object? Function(Object?, Object?)? reviver}) {
    if (data == null) return null;
    try {
      return toJson<T>(data, reviver: reviver);
    } catch (_) {
      return null;
    }
  }

  static bool hexEqual(String a, String b) {
    if (!isHexBytes(a) || !isHexBytes(b)) {
      throw ArgumentException("Invalid hex string.");
    }
    return strip0x(a.toLowerCase()) == strip0x(b.toLowerCase());
  }

  static String normalizeHex(String hexString) {
    if (!isHexBytes(hexString)) {
      throw ArgumentException("Invalid hex string.");
    }
    return strip0x(hexString.toLowerCase());
  }
}
