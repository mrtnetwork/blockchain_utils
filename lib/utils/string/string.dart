import 'dart:convert' show ascii, utf8, JsonEncoder, jsonEncode, jsonDecode;
import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/base64/base64.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utf8/utf8.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/json/json.dart';

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

  hex,
}

/// A utility class for working with strings and common string operations.
class StringUtils {
  static bool isBase58(String input) {
    final RegExp base58Regex = RegExp(
      r'^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$',
    );
    return base58Regex.hasMatch(input);
  }

  static bool isBase64(String input, {bool validatePadding = true}) {
    final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
    final hasMatch = base64Regex.hasMatch(input);
    if (hasMatch) {
      if (validatePadding) return input.length % 4 == 0;
      return true;
    }
    return false;
  }

  static bool isHexBytes(String v, {int? lengthInBytes}) {
    assert(lengthInBytes == null || lengthInBytes >= 0);
    int start = 0;

    if (v.startsWith('0x') || v.startsWith('0X')) {
      start = 2;
    }

    final len = v.length - start;

    if ((len & 1) != 0) return false;

    if (lengthInBytes != null && len != lengthInBytes * 2) {
      return false;
    }

    for (var i = start; i < v.length; i++) {
      final c = v.codeUnitAt(i);

      if (!((c >= 48 && c <= 57) ||
          (c >= 65 && c <= 70) ||
          (c >= 97 && c <= 102))) {
        return false;
      }
    }

    return true;
  }

  static bool ixHexaDecimalNumber(String v) {
    final RegExp hexaDecimalRegex = RegExp(r'^(0x|0X)?[0-9A-Fa-f]+$');
    return hexaDecimalRegex.hasMatch(v);
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
  static List<int> encode(
    String value, {
    StringEncoding encoding = StringEncoding.utf8,
    bool validateB64Padding = true,
    bool allowUrlSafe = true,
    Base58Alphabets base58alphabets = Base58Alphabets.bitcoin,
  }) {
    try {
      switch (encoding) {
        case StringEncoding.utf8:
          final bytes = UTF8Encoder.encode(value);
          assert(BytesUtils.bytesEqual(bytes, utf8.encode(value)));
          return bytes;
        case StringEncoding.base64:
        case StringEncoding.base64UrlSafe:
          return B64Decoder.decode(
            value,
            validatePadding: validateB64Padding,
            urlSafe: allowUrlSafe,
          );
        case StringEncoding.base58:
          return Base58Decoder.decode(value, base58alphabets);
        case StringEncoding.base58Check:
          return Base58Decoder.checkDecode(value, base58alphabets);
        case StringEncoding.hex:
          return BytesUtils.fromHexString(value);
        case StringEncoding.ascii:
          final encode = ASCIIEncoder.encode(value);
          assert(BytesUtils.bytesEqual(encode, ascii.encode(value)));
          return encode;
      }
    } catch (e) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        name: "value",
        reason: "Failed to encode strong to ${encoding.name} bytes",
      );
    }
  }

  /// Encodes a JSON-serializable [json] object into a list of bytes.
  static List<int> encodeJson(
    Object json, {
    String? indent,
    bool toStringEncodable = false,
    Object? Function(dynamic)? toEncodable,
  }) {
    final value = fromJson(
      json,
      indent: indent,
      toStringEncodable: toStringEncodable,
      toEncodable: toEncodable,
    );
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
      return encodeJson(
        json,
        indent: indent,
        toEncodable: toEncodable,
        toStringEncodable: toStringEncodable,
      );
    } catch (_) {
      return null;
    }
  }

  /// Encodes the given [value] string into a list of bytes using the specified [type] if possible.
  ///
  /// The [type] parameter determines the encoding type to use, with UTF-8 being the default.
  /// Returns a list of bytes representing the encoded string.
  static List<int>? tryEncode(
    String? value, {
    StringEncoding encoding = StringEncoding.utf8,
    bool validateB64Padding = true,
    bool allowUrlSafe = true,
    Base58Alphabets base58alphabets = Base58Alphabets.bitcoin,
  }) {
    if (value == null) return null;
    try {
      return encode(
        value,
        encoding: encoding,
        allowUrlSafe: allowUrlSafe,
        validateB64Padding: validateB64Padding,
        base58alphabets: base58alphabets,
      );
    } catch (e) {
      return null;
    }
  }

  /// Decodes a list of bytes [value] into a string using the specified [type].
  ///
  /// The [type] parameter determines the decoding type to use, with UTF-8 being the default.
  /// Returns the decoded string.
  static String decode(
    List<int> value, {
    StringEncoding encoding = StringEncoding.utf8,
    bool allowInvalidOrMalformed = false,
    bool b64NoPadding = false,
    Base58Alphabets base58alphabets = Base58Alphabets.bitcoin,
  }) {
    value = value.asBytes;
    try {
      switch (encoding) {
        case StringEncoding.utf8:
          final decode = UTF8Decoder.decode(
            value,
            allowMalformed: allowInvalidOrMalformed,
          );
          return decode;

        case StringEncoding.base64:
          return B64Encoder.encode(value, noPadding: b64NoPadding);
        case StringEncoding.base64UrlSafe:
          return B64Encoder.encode(
            value,
            urlSafe: true,
            noPadding: b64NoPadding,
          );
        case StringEncoding.base58:
          return Base58Encoder.encode(value, base58alphabets);
        case StringEncoding.base58Check:
          return Base58Encoder.checkEncode(value, base58alphabets);
        case StringEncoding.hex:
          return BytesUtils.toHexString(value);
        case StringEncoding.ascii:
          final decode = ASCIIDecoder.decode(
            value,
            allowMalformed: allowInvalidOrMalformed,
          );

          return decode;
      }
    } catch (e) {
      throw ArgumentException.invalidOperationArguments(
        "decode",
        name: "value",
        reason: "Failed to decode bytes as ${encoding.name}",
      );
    }
  }

  /// Decodes a list of bytes [value] into a JSON object of type [T].
  static T decodeJson<T extends Object>(
    List<int> value, {
    Object? Function(Object?, Object?)? reviver,
  }) {
    final toString = decode(value);
    return toJson<T>(toString, reviver: reviver);
  }

  /// Attempts to decode a list of bytes [value] into a JSON object of type [T],
  /// returning `null` if decoding or parsing fails.
  static T? tryDecodeJson<T extends Object>(
    List<int> value, {
    Object? Function(Object?, Object?)? reviver,
  }) {
    final toString = tryDecode(value);
    return tryToJson<T>(toString, reviver: reviver);
  }

  /// Decodes a list of bytes [value] into a string using the specified [type] if possible.
  ///
  /// The [type] parameter determines the decoding type to use, with UTF-8 being the default.
  /// Returns the decoded string.
  static String? tryDecode(
    List<int>? value, {
    StringEncoding encoding = StringEncoding.utf8,
    bool allowInvalidOrMalformed = false,
    bool b64NoPadding = false,
    Base58Alphabets base58alphabets = Base58Alphabets.bitcoin,
  }) {
    if (value == null) return null;
    try {
      return decode(
        value,
        encoding: encoding,
        allowInvalidOrMalformed: allowInvalidOrMalformed,
        b64NoPadding: b64NoPadding,
        base58alphabets: base58alphabets,
      );
    } catch (e) {
      return null;
    }
  }

  /// Converts a Dart object represented as a Map to a JSON-encoded string.
  ///
  /// The input [data] is a Map representing the Dart object.
  static String fromJson(
    Object data, {
    String? indent,
    bool toStringEncodable = false,
    Object? Function(dynamic)? toEncodable,
  }) {
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
  static T toJson<T extends Object?>(
    Object? data, {
    Object? Function(Object?, Object?)? reviver,
  }) {
    if (data is! String) {
      try {
        return JsonParser.valueAs<T>(data);
      } catch (_) {
        throw ArgumentException.invalidOperationArguments(
          "toJson",
          name: "data",
          reason: "Invalid data encountered during JSON conversion.",
        );
      }
    }
    final decode = jsonDecode(data, reviver: reviver);
    try {
      return JsonParser.valueAs<T>(decode);
    } on JsonParserError {
      rethrow;
    } catch (_) {
      throw ArgumentException.invalidOperationArguments(
        "toJson",
        name: "data",
        reason: "Failed to casting json as $T.",
      );
    }
  }

  /// Converts a Dart object represented as a Map to a JSON-encoded string if possible.
  ///
  /// The input [data] is a Map representing the Dart object.
  static String? tryFromJson(
    Object? data, {
    String? indent,
    bool toStringEncodable = false,
    Object? Function(dynamic)? toEncodable,
  }) {
    try {
      return fromJson(
        data!,
        indent: indent,
        toStringEncodable: toStringEncodable,
        toEncodable: toEncodable,
      );
    } catch (e) {
      return null;
    }
  }

  /// Converts a JSON-encoded string to a Dart object represented as a Map if possible.
  ///
  /// The input [data] is a JSON-encoded string.
  /// Returns a Map representing the Dart object.
  static T? tryToJson<T extends Object?>(
    Object? data, {
    Object? Function(Object?, Object?)? reviver,
  }) {
    if (data == null) return null;
    try {
      return toJson<T>(data, reviver: reviver);
    } catch (_) {
      return null;
    }
  }

  static bool hexEqual(String a, String b) {
    return normalizeHex(a) == normalizeHex(b);
  }

  static String _normalizeHex(String hexString, {bool with0x = false}) {
    final hex = strip0x(hexString.toLowerCase());
    if (with0x) return add0x(hex);
    return hex;
  }

  static String normalizeHex(String hexString, {bool with0x = false}) {
    if (!isHexBytes(hexString)) {
      throw ArgumentException.invalidOperationArguments(
        "normalizeHex",
        name: "hexString",
        reason: "Invalid hex string.",
      );
    }
    return _normalizeHex(hexString, with0x: with0x);
  }

  static String snakeToCamel(String input, {required bool capitalizeFirst}) {
    if (input.isEmpty) return input;
    final parts =
        input.split(RegExp(r'[_\-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return input;

    final buf = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final shouldCapitalize = capitalizeFirst || i > 0;
      buf.write(_capitalizeWord(part, capitalize: shouldCapitalize));
    }
    return buf.toString();
  }

  static String _capitalizeWord(String word, {required bool capitalize}) {
    if (word.isEmpty) return word;

    // Proto enum values are conventionally SCREAMING_SNAKE_CASE, so a
    // word like "UNSPECIFIED" arrives here fully uppercase. If we only
    // touched the first letter (as you'd do for a word that's *already*
    // mixed-case, e.g. preserving a genuine acronym), every snake_case
    // segment after the first would stay shouting - "UNSPECIFIED" not
    // "Unspecified" - which breaks camelCase entirely.
    //
    // Heuristic: if the word is all-uppercase (and more than one letter,
    // so single-letter words/initials aren't affected), lowercase the
    // tail before re-capitalizing the first letter. Otherwise (already
    // mixed-case, e.g. a deliberate acronym like "ID" mid-word in a
    // genuinely camelCase source), leave the tail untouched.
    final isShouting = word.length > 1 && word == word.toUpperCase();
    final tail =
        isShouting ? word.substring(1).toLowerCase() : word.substring(1);

    final first = capitalize ? word[0].toUpperCase() : word[0].toLowerCase();
    return '$first$tail';
  }

  static String camelToSnake(String input) {
    if (input.isEmpty) return input;

    final buf = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (_isUpper(char) && i > 0) {
        final prev = input[i - 1];
        final next = i + 1 < input.length ? input[i + 1] : null;

        // Boundary #1: a lower->upper (or digit->upper) transition, e.g.
        // "userId" -> "user_Id", "item2Name" -> "item2_Name".
        final afterLowerOrDigit = _isLower(prev) || _isDigit(prev);

        // Boundary #2: the end of an acronym run followed by a lowercase
        // letter, e.g. "HTTPServer" -> "HTTP_Server" (split before the "S",
        // not before every capital in "HTTP"). Without this, "HTTPServer"
        // would come out "h_t_t_p_server" instead of "http_server".
        final endOfAcronym = _isUpper(prev) && next != null && _isLower(next);

        if (afterLowerOrDigit || endOfAcronym) {
          buf.write('_');
        }
      }

      buf.write(char.toLowerCase());
    }
    return buf.toString();
  }

  static bool _isUpper(String ch) =>
      ch != ch.toLowerCase() && ch == ch.toUpperCase();
  static bool _isLower(String ch) =>
      ch != ch.toUpperCase() && ch == ch.toLowerCase();
  static bool _isDigit(String ch) => ch.codeUnitAt(0) ^ 0x30 <= 9; // '0'-'9'
}
