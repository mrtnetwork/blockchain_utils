import 'package:blockchain_utils/encoding/base58/src/base58_base.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/base64/base64.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/encoding/json/json.dart';
import 'package:blockchain_utils/encoding/utf8/utf8.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/json/json.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// String encoding schemes supported by [StringUtils.encode]/[StringUtils.decode].
enum StringEncoding {
  /// 7-bit ASCII.
  ascii,

  /// UTF-8.
  utf8,

  /// Base64, standard alphabet.
  base64,

  /// Base64, URL-safe alphabet.
  base64UrlSafe,

  /// Base58.
  base58,

  /// Base58 with an appended checksum.
  base58Check,

  /// Hexadecimal.
  hex,
}

/// A utility class for working with strings and common string operations.
class StringUtils {
  /// Whether [input] contains only valid Base58 characters.
  static bool isBase58(String input) {
    final RegExp base58Regex = RegExp(
      r'^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$',
    );
    return base58Regex.hasMatch(input);
  }

  /// Whether [input] contains only valid Base64 characters.
  static bool isBase64(String input, {bool validatePadding = true}) {
    final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
    final hasMatch = base64Regex.hasMatch(input);
    if (hasMatch) {
      if (validatePadding) return input.length % 4 == 0;
      return true;
    }
    return false;
  }

  /// Whether [v] is a valid (even-length) hex string, with an optional
  /// `0x` prefix. If [lengthInBytes] is given, also checks the decoded length.
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

  /// Whether [v] is a valid hexadecimal number, with an optional `0x` prefix.
  static bool isHexadecimalNumber(String v) {
    final RegExp hexaDecimalRegex = RegExp(r'^(0x|0X)?[0-9A-Fa-f]+$');
    return hexaDecimalRegex.hasMatch(v);
  }

  /// Decodes [v] as hex if it looks like a hex string, otherwise UTF-8 encodes it.
  static BuBytes toBytes(String v) {
    if (isHexBytes(v)) {
      return BytesUtils.fromHexString(v);
    } else {
      return encode(v);
    }
  }

  /// Like [toBytes], but returns null instead of throwing (or if [v] is null).
  static BuBytes? tryToBytes(String? v) {
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

  /// Adds a `0x` prefix to [value], unless it already has one.
  static String add0x(String value) {
    if (value.toLowerCase().startsWith("0x")) {
      return value;
    }
    return "0x$value";
  }

  /// Encodes [value] into bytes using [encoding] (UTF-8 by default).
  static BuBytes encode(
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
          return Base58Decoder.decodeWithChecksum(value, base58alphabets);
        case StringEncoding.hex:
          return BytesUtils.fromHexString(value);
        case StringEncoding.ascii:
          final encode = ASCIIEncoder.encode(value);
          return encode;
      }
    } catch (e) {
      throw CoreErrors.invalidOperationArguments(
        "encode",
        name: "value",
        reason: "Failed to encode string to ${encoding.name} bytes",
      );
    }
  }

  /// Encodes a JSON-serializable [json] object into a list of bytes.
  static BuBytes encodeJson(
    Object json, {
    String? indent,
    bool toStringEncodable = false,
    Object? Function(dynamic)? toEncodable,
    JsonEncodeOptions? options,
  }) {
    if (toEncodable == null && toStringEncodable) {
      toEncodable = (e) => e.toString();
    }

    return JsonCodec.jsonEncodeBytes(
      json,
      indent: indent,
      options: options,
      toEncodable: toEncodable,
    );
  }

  /// Attempts to encode a JSON-serializable [json] object into a list of bytes,
  /// returning null if the conversion to JSON string fails.
  static BuBytes? tryEncodeJson(
    Object? json, {
    String? indent,
    bool toStringEncodable = false,
    Object? Function(dynamic)? toEncodable,
    JsonEncodeOptions? options,
  }) {
    if (json == null) return null;
    try {
      return encodeJson(
        json,
        indent: indent,
        toEncodable: toEncodable,
        toStringEncodable: toStringEncodable,
        options: options,
      );
    } catch (_) {
      return null;
    }
  }

  /// Like [encode], but returns null instead of throwing on failure
  /// (or if [value] is null).
  static BuBytes? tryEncode(
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

  /// Decodes [value] into a string using [encoding] (UTF-8 by default).
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
          return Base58Encoder.encodeWithChecksum(value, base58alphabets);
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
      throw CoreErrors.invalidOperationArguments(
        "decode",
        name: "value",
        reason: "Failed to decode bytes as ${encoding.name}",
      );
    }
  }

  /// Decodes a list of bytes [value] into a JSON object of type [T].
  static T decodeJson<T extends Object?>(
    List<int> value, {
    Object? Function(Object?, Object?)? reviver,
    JsonDecodeOptions? options,
  }) {
    final toString = decode(value);
    return toJson<T>(toString, reviver: reviver, options: options);
  }

  /// Attempts to decode a list of bytes [value] into a JSON object of type [T],
  /// returning `null` if decoding or parsing fails.
  static T? tryDecodeJson<T extends Object>(
    List<int> value, {
    Object? Function(Object?, Object?)? reviver,
    JsonDecodeOptions? options,
  }) {
    final toString = tryDecode(value);
    return tryToJson<T>(toString, reviver: reviver, options: options);
  }

  /// Like [decode], but returns null instead of throwing (or if [value] is null).
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
    JsonEncodeOptions? options,
  }) {
    if (toStringEncodable) {
      toEncodable ??= (c) => c.toString();
    }
    return JsonCodec.jsonEncode(
      data,
      toEncodable: toEncodable,
      options: options,
      indent: indent,
    );
  }

  /// Converts a JSON-encoded string to a Dart object represented as a Map.
  ///
  /// The input [data] is a JSON-encoded string.
  /// Returns a Map representing the Dart object.
  static T toJson<T extends Object?>(
    Object? data, {
    Object? Function(Object?, Object?)? reviver,
    JsonDecodeOptions? options,
  }) {
    if (data is! String) {
      try {
        return JsonParser.valueAs<T>(data);
      } catch (_) {
        throw CoreErrors.invalidOperationArguments(
          "toJson",
          name: "data",
          reason: "Invalid data encountered during JSON conversion.",
        );
      }
    }
    final decode = JsonCodec.jsonDecode(
      data,
      reviver: reviver,
      options: options,
    );
    try {
      return JsonParser.valueAs<T>(decode);
    } on BuError {
      rethrow;
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "toJson",
        name: "data",
        reason: "Failed to cast json to $T.",
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
    JsonEncodeOptions? options,
  }) {
    if (data == null) return null;
    try {
      return fromJson(
        data,
        indent: indent,
        toStringEncodable: toStringEncodable,
        toEncodable: toEncodable,
        options: options,
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
    JsonDecodeOptions? options,
  }) {
    if (data == null) return null;
    try {
      return toJson<T>(data, reviver: reviver, options: options);
    } catch (_) {
      return null;
    }
  }

  /// Whether [a] and [b] represent the same hex value (case/`0x`-prefix insensitive).
  static bool hexEqual(String a, String b) {
    return normalizeHex(a) == normalizeHex(b);
  }

  /// Lowercases [hexString] and normalizes its `0x` prefix per [with0x].
  static String _normalizeHex(String hexString, {bool with0x = false}) {
    final hex = strip0x(hexString.toLowerCase());
    if (with0x) return add0x(hex);
    return hex;
  }

  /// Like [_normalizeHex], but validates [hexString] first.
  static String normalizeHex(String hexString, {bool with0x = false}) {
    if (!isHexBytes(hexString)) {
      throw CoreErrors.invalidOperationArguments(
        "normalizeHex",
        name: "hexString",
        reason: "Invalid hex string.",
      );
    }
    return _normalizeHex(hexString, with0x: with0x);
  }

  /// Converts snake_case/kebab-case [input] to camelCase (or PascalCase if
  /// [capitalizeFirst] is true).
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

  /// Capitalizes or lowercases the first letter of [word] (see comment below
  /// for how all-caps acronyms are handled).
  static String _capitalizeWord(String word, {required bool capitalize}) {
    if (word.isEmpty) return word;
    final isShouting = word.length > 1 && word == word.toUpperCase();
    final tail =
        isShouting ? word.substring(1).toLowerCase() : word.substring(1);

    final first = capitalize ? word[0].toUpperCase() : word[0].toLowerCase();
    return '$first$tail';
  }

  /// Converts camelCase/PascalCase [input] to snake_case.
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

  /// Whether [ch] is an uppercase letter.
  static bool _isUpper(String ch) =>
      ch != ch.toLowerCase() && ch == ch.toUpperCase();

  /// Whether [ch] is a lowercase letter.
  static bool _isLower(String ch) =>
      ch != ch.toUpperCase() && ch == ch.toLowerCase();

  /// Whether [ch] is an ASCII digit '0'-'9'.
  static bool _isDigit(String ch) =>
      ch.length == 1 && ((ch.codeUnitAt(0) ^ 0x30) <= 9);
}
