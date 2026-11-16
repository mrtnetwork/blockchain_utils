/// A pure-Dart replacement for `dart:convert`'s `jsonEncode` / `jsonDecode`,
/// matching the official signatures (`toEncodable`, `reviver`).
///
/// With `options: null` (the default) both directions behave like vanilla
/// `dart:convert`. Two opt-in features exist, one per direction:
///
/// 1. Encode - [JsonEncodeOptions.bigIntEncoding] (only for `BigInt` values,
///    and only when no `toEncodable` is given):
///    - `BigIntEncoding.string`: the BigInt is written as a JSON string.
///    - `BigIntEncoding.intOrString`: if the BigInt fits a Dart `int` on the
///      current platform (signed 64-bit on the VM, +-(2^53-1) on the web)
///      it is written as a plain JSON number, exactly like
///      `jsonEncode(int)`; otherwise it is written as a JSON string.
///
/// 2. Decode - [JsonDecodeOptions.badStringAsBinary]: a JSON string whose
///    bytes are not valid UTF-8 decodes as a raw `List<int>` instead of
///    throwing. Nothing else about decoding differs from `dart:convert`
///    (an oversized integer literal decodes to a `double`, a lone `\uD800`
///    escape decodes to a String holding that lone surrogate).
///
/// Extras kept from before: `indent` for pretty-printing and [JsonBinary]
/// for writing raw bytes back out (only when `options` is non-null).
///
/// Everything is hand-implemented over `List<int>` bytes (no
/// `dart:typed_data`), so it behaves identically on native and web.
library;

import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

// import 'dart:convert' show utf8, Utf8Decoder;

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

/// How a `BigInt` is written by `jsonEncode` (encode side only).
enum BigIntEncoding {
  /// Always a JSON string.
  string,

  /// A plain JSON number when the BigInt fits a Dart `int` on this platform
  /// (64-bit on the VM, +-(2^53-1) on web), exactly what `jsonEncode(int)` would write;
  /// otherwise a JSON string.
  intOrString,
}

/// Marks raw bytes that should be written back out as a JSON string where
/// each byte is one UTF-16 code unit (0..255) — the same shape malformed
/// binary-in-a-string payloads normally arrive in. Only used on the
/// *encode* side; decode returns a plain `List<int>` for malformed strings
/// (see `JsonDecodeOptions.badStringAsBinary`). Wrap a decoded `List<int>`
/// in `JsonBinary(...)` if you need to round-trip it back out losslessly.
/// Like BigInt, this is only handled specially when you pass a non-null
/// `options` and no `toEncodable` — see the library doc comment above.
class JsonBinary {
  final List<int> bytes;
  const JsonBinary(this.bytes);

  @override
  String toString() => 'JsonBinary(${bytes.length} bytes)';

  @override
  bool operator ==(Object other) {
    if (other is! JsonBinary || other.bytes.length != bytes.length) {
      return false;
    }
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(bytes);
}

class JsonDecodeOptions {
  /// If true, a JSON string whose bytes are not valid UTF-8 decodes as a
  /// raw `List<int>` instead of throwing. If false, behaves like strict
  /// `dart:convert` and throws. Pass `options: null` (the default) for
  /// vanilla behavior.
  final bool badStringAsBinary;

  const JsonDecodeOptions({this.badStringAsBinary = true});
}

class JsonEncodeOptions {
  /// How to encode `BigInt` values. Only applied when no `toEncodable`
  /// is supplied to [jsonEncode] — see the library doc above.
  final BigIntEncoding bigIntEncoding;

  const JsonEncodeOptions({this.bigIntEncoding = BigIntEncoding.string});
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

// dart2js: `int` is a JS number, so ints are only exact up to 2^53-1.
// (`identical(0, 0.0)` is true only when compiled to JS.)
final bool _isJs = identical(0, 0.0);
final BigInt _maxExactJsInt = BigInt.from(9007199254740991);
final BigInt _minExactJsInt = BigInt.from(-9007199254740991);

/// True if [v] can be written as a raw JSON number exactly like a Dart `int`
/// would be on this platform. VM: signed 64-bit (`isValidInt`). Web: only
/// -(2^53-1)..2^53-1, because `BigInt.isValidInt` on dart2js is also true
/// for huge values (anything that converts to a finite double), where
/// `toInt()` is lossy and `int` prints in JS number format (e.g.
/// 4611686018427388000).
bool _bigIntEncodesAsInt(BigInt v) {
  if (_isJs) return v >= _minExactJsInt && v <= _maxExactJsInt;
  return v.isValidInt;
}

/// UTF-8 encodes one Unicode code point into `out`. Shared by the decoder
/// (for `\uXXXX` escapes) and the bytes encoder (for real string content).
void _appendUtf8CodePoint(List<int> out, int cp) {
  if (cp < 0x80) {
    out.add(cp);
  } else if (cp < 0x800) {
    out.add(0xC0 | (cp >> 6));
    out.add(0x80 | (cp & 0x3F));
  } else if (cp < 0x10000) {
    out.add(0xE0 | (cp >> 12));
    out.add(0x80 | ((cp >> 6) & 0x3F));
    out.add(0x80 | (cp & 0x3F));
  } else {
    out.add(0xF0 | (cp >> 18));
    out.add(0x80 | ((cp >> 12) & 0x3F));
    out.add(0x80 | ((cp >> 6) & 0x3F));
    out.add(0x80 | (cp & 0x3F));
  }
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
class JsonCodec {
  /// [options] is fully optional: leave it `null` (the default) for
  /// behavior identical to `dart:convert`'s `jsonEncode` - pass one to opt
  /// into the BigInt/JsonBinary features (see the library doc above).
  ///
  /// [indent], if given (e.g. `'  '` or `'\t'`), pretty-prints the output
  /// with a newline + that many indent units per nesting level, instead of
  /// the default compact single-line output.
  static String jsonEncode(
    Object? object, {
    Object? Function(Object? object)? toEncodable,
    JsonEncodeOptions? options,
    String? indent,
  }) {
    final buf = StringBuffer();
    _encodeValue(buf, object, toEncodable, options, <Object?>[], indent, 0);
    return buf.toString();
  }

  /// Encodes directly to raw bytes — no
  /// intermediate `String` involved. This is the direct binary-out
  /// counterpart to [jsonDecodeBytes]/[jsonDecode]. See [jsonEncode] for
  /// [options] and [indent].
  ///
  /// Prefer this over `jsonEncode(...).codeUnits` or manually re-encoding
  /// the resulting String for [JsonBinary] payloads: going through a Dart
  /// `String` means each byte becomes a UTF-16 code unit, and getting the
  /// original wire bytes back out afterwards requires remembering to
  /// `latin1.encode` it (never `utf8.encode`, which would re-expand bytes
  /// ≥ 0x80). Here, `JsonBinary` bytes are written straight into the output
  /// with no re-encoding step at all, and ordinary `String` values are
  /// UTF-8 encoded properly — so there's no encoding pitfall to remember.
  static BuBytes jsonEncodeBytes(
    Object? object, {
    Object? Function(Object? object)? toEncodable,
    JsonEncodeOptions? options,
    String? indent,
  }) {
    final out = BuBytes.empty();
    _encodeValueBytes(
      out,
      object,
      toEncodable,
      options,
      <Object?>[],
      indent,
      0,
    );
    return out;
  }

  /// [source] may be a `String`, or raw bytes (`List<int>`) e.g. straight off
  /// an HTTP response — passing bytes directly is what lets malformed-UTF-8
  /// string fields fall back to a raw `List<int>` instead of throwing.
  ///
  /// [reviver], if given, is called bottom-up for every decoded value —
  /// `reviver(key, value)` where `key` is the object property name (String),
  /// the array index (int), or `null` for the top-level value — exactly like
  /// `dart:convert`'s `jsonDecode(source, reviver: ...)`.
  ///
  /// [options] is fully optional: leave it `null` (the default) for
  /// behavior identical to `dart:convert`'s `jsonDecode` - an oversized
  /// integer literal becomes a `double` and a malformed-UTF-8 string throws,
  /// same as `dart:convert`. Pass one to opt into the BigInt/binary-string
  /// features (see the library doc above).
  static dynamic jsonDecode(
    Object source, {
    Object? Function(Object? key, Object? value)? reviver,
    JsonDecodeOptions? options,
  }) {
    final List<int> bytes;
    if (source is List<int>) {
      bytes = source;
    } else if (source is String) {
      bytes = StringUtils.encode(source);
    } else {
      throw CoreErrors.invalidOperationArguments(
        "jsonDecode",
        reason: 'Must be a String or List<int>',
      );
    }
    return jsonDecodeBytes(bytes, reviver: reviver, options: options);
  }

  /// Decodes JSON directly from raw bytes (`List<int>`) — no `String`
  /// conversion involved, so this is the direct binary-in counterpart to
  /// [jsonEncodeBytes]. This is exactly what [jsonDecode] does internally
  /// when given a `List<int>`; use this version when you always have bytes
  /// and want a signature that says so. See [jsonDecode] for [reviver] and
  /// [options].
  static dynamic jsonDecodeBytes(
    List<int> bytes, {
    Object? Function(Object? key, Object? value)? reviver,
    JsonDecodeOptions? options,
  }) {
    final parser = _JsonParser(bytes, options, reviver);
    final value = parser.parseValue();
    parser.skipWhitespace();
    if (!parser.isAtEnd) {
      throw CoreErrors.invalidOperationArguments(
        "jsonDecodeBytes",
        reason: 'Invalid json binary. Unexpected trailing character',
      );
    }
    return reviver == null ? value : reviver(null, value);
  }
}
// ---------------------------------------------------------------------------
// Encoding
// ---------------------------------------------------------------------------

void _checkCycle(List<Object?> seen, Object? value) {
  for (final s in seen) {
    if (identical(s, value)) throw CoreErrors.jsonCycleError(value);
  }
}

void _encodeValue(
  StringBuffer buf,
  Object? value,
  Object? Function(Object?)? toEncodable,
  JsonEncodeOptions? options,
  List<Object?> seen,
  String? indent,
  int depth,
) {
  if (value == null) {
    buf.write('null');
    return;
  }
  if (value is bool) {
    buf.write(value ? 'true' : 'false');
    return;
  }
  if (value is num) {
    if (value.isNaN || value.isInfinite) {
      throw CoreErrors.jsonFailed(
        'NaN/Infinity are not valid JSON',
        value: value,
      );
    }
    buf.write(value.toString());
    return;
  }
  if (value is String) {
    _encodeString(buf, value);
    return;
  }
  if (value is Map) {
    _checkCycle(seen, value);
    seen.add(value);
    if (value.isEmpty) {
      buf.write('{}');
    } else {
      buf.write('{');
      final childIndent = indent == null ? null : indent * (depth + 1);
      var first = true;
      value.forEach((k, v) {
        if (k is! String) {
          throw CoreErrors.jsonFailed(
            'JSON object keys must be Strings',
            value: k,
          );
        }
        if (!first) buf.write(',');
        first = false;
        if (childIndent != null) {
          buf.write('\n');
          buf.write(childIndent);
        }
        _encodeString(buf, k);
        buf.write(indent == null ? ':' : ': ');
        _encodeValue(buf, v, toEncodable, options, seen, indent, depth + 1);
      });
      if (indent != null) {
        buf.write('\n');
        buf.write(indent * depth);
      }
      buf.write('}');
    }
    seen.removeLast();
    return;
  }
  if (value is Iterable) {
    _checkCycle(seen, value);
    seen.add(value);
    if (value.isEmpty) {
      buf.write('[]');
    } else {
      buf.write('[');
      final childIndent = indent == null ? null : indent * (depth + 1);
      var first = true;
      for (final item in value) {
        if (!first) buf.write(',');
        first = false;
        if (childIndent != null) {
          buf.write('\n');
          buf.write(childIndent);
        }
        _encodeValue(buf, item, toEncodable, options, seen, indent, depth + 1);
      }
      if (indent != null) {
        buf.write('\n');
        buf.write(indent * depth);
      }
      buf.write(']');
    }
    seen.removeLast();
    return;
  }

  // Not natively representable (BigInt, JsonBinary, or a custom object).
  _checkCycle(seen, value);
  if (toEncodable != null) {
    // Official dart:convert semantics: hand off entirely to the caller's
    // callback - our BigInt/JsonBinary features are skipped on purpose.
    seen.add(value);
    _encodeValue(
      buf,
      toEncodable(value),
      toEncodable,
      options,
      seen,
      indent,
      depth,
    );
    seen.removeLast();
    return;
  }

  if (options != null) {
    if (value is BigInt) {
      _encodeBigInt(buf, value, options);
      return;
    }
    if (value is JsonBinary) {
      _encodeBinaryAsString(buf, value.bytes);
      return;
    }
  }

  // dart:convert default: call `toJson()` on the object.
  final json = _callToJson(value);
  seen.add(value);
  _encodeValue(buf, json, toEncodable, options, seen, indent, depth);
  seen.removeLast();
}

/// dart:convert's default `toEncodable`: `object.toJson()`. Anything
/// without a usable `toJson()` is an unsupported object.
Object? _callToJson(Object? value) {
  try {
    return (value as dynamic).toJson();
  } on NoSuchMethodError {
    throw CoreErrors.jsonFailed(null, value: value);
  } catch (e) {
    throw CoreErrors.jsonFailed('toJson() threw: $e', value: value);
  }
}

void _encodeBigInt(StringBuffer buf, BigInt value, JsonEncodeOptions options) {
  switch (options.bigIntEncoding) {
    case BigIntEncoding.string:
      buf.write('"');
      buf.write(value.toString());
      buf.write('"');
      break;
    case BigIntEncoding.intOrString:
      if (_bigIntEncodesAsInt(value)) {
        buf.write(value.toString()); // same text as a Dart int
      } else {
        buf.write('"');
        buf.write(value.toString());
        buf.write('"');
      }
      break;
  }
}

void _encodeString(StringBuffer buf, String s) {
  buf.write('"');
  final units = s.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (u >= 0xD800 && u <= 0xDFFF) {
      // Valid surrogate pair: written as-is. Lone surrogate: escaped as
      // \udXXX (lowercase hex), exactly like dart:convert.
      if (u <= 0xDBFF &&
          i + 1 < units.length &&
          units[i + 1] >= 0xDC00 &&
          units[i + 1] <= 0xDFFF) {
        buf.writeCharCode(u);
        buf.writeCharCode(units[i + 1]);
        i++;
      } else {
        buf.write('\\u');
        buf.write(u.toRadixString(16));
      }
      continue;
    }
    _writeEscapedCharCode(buf, u);
  }
  buf.write('"');
}

void _encodeBinaryAsString(StringBuffer buf, List<int> bytes) {
  buf.write('"');
  for (final b in bytes) {
    _writeEscapedCharCode(buf, b);
  }
  buf.write('"');
}

void _writeEscapedCharCode(StringBuffer buf, int code) {
  switch (code) {
    case 0x22:
      buf.write(r'\"');
      break;
    case 0x5C:
      buf.write(r'\\');
      break;
    case 0x08:
      buf.write(r'\b');
      break;
    case 0x0C:
      buf.write(r'\f');
      break;
    case 0x0A:
      buf.write(r'\n');
      break;
    case 0x0D:
      buf.write(r'\r');
      break;
    case 0x09:
      buf.write(r'\t');
      break;
    default:
      if (code < 0x20) {
        buf.write('\\u');
        buf.write(code.toRadixString(16).padLeft(4, '0'));
      } else {
        buf.writeCharCode(code);
      }
  }
}

// ---------------------------------------------------------------------------
// Encoding directly to bytes (List<int>) - jsonEncodeBytes
// ---------------------------------------------------------------------------

void _encodeValueBytes(
  List<int> out,
  Object? value,
  Object? Function(Object?)? toEncodable,
  JsonEncodeOptions? options,
  List<Object?> seen,
  String? indent,
  int depth,
) {
  if (value == null) {
    out.addAll(const [0x6E, 0x75, 0x6C, 0x6C]); // null
    return;
  }
  if (value is bool) {
    out.addAll(
      value
          ? const [0x74, 0x72, 0x75, 0x65] // true
          : const [0x66, 0x61, 0x6C, 0x73, 0x65],
    ); // false
    return;
  }
  if (value is num) {
    if (value.isNaN || value.isInfinite) {
      throw CoreErrors.jsonFailed(
        'NaN/Infinity are not valid JSON',
        value: value,
      );
    }
    out.addAll(value.toString().codeUnits); // always plain ASCII digits
    return;
  }
  if (value is String) {
    _writeStringBytes(out, value);
    return;
  }
  if (value is Map) {
    _checkCycle(seen, value);
    seen.add(value);
    if (value.isEmpty) {
      out.add(0x7B);
      out.add(0x7D);
    } else {
      out.add(0x7B); // {
      final childIndent = indent?.codeUnits;
      final childIndentRepeat = depth + 1;
      var first = true;
      value.forEach((k, v) {
        if (k is! String) {
          throw CoreErrors.jsonFailed(
            'JSON object keys must be Strings',
            value: k,
          );
        }
        if (!first) out.add(0x2C);
        first = false;
        if (childIndent != null) {
          out.add(0x0A);
          for (var r = 0; r < childIndentRepeat; r++) {
            out.addAll(childIndent);
          }
        }
        _writeStringBytes(out, k);
        out.add(0x3A); // :
        if (indent != null) out.add(0x20);
        _encodeValueBytes(
          out,
          v,
          toEncodable,
          options,
          seen,
          indent,
          depth + 1,
        );
      });
      if (indent != null) {
        out.add(0x0A);
        final closeIndent = indent.codeUnits;
        for (var r = 0; r < depth; r++) {
          out.addAll(closeIndent);
        }
      }
      out.add(0x7D); // }
    }
    seen.removeLast();
    return;
  }
  if (value is Iterable) {
    _checkCycle(seen, value);
    seen.add(value);
    if (value.isEmpty) {
      out.add(0x5B);
      out.add(0x5D);
    } else {
      out.add(0x5B); // [
      final childIndent = indent?.codeUnits;
      final childIndentRepeat = depth + 1;
      var first = true;
      for (final item in value) {
        if (!first) out.add(0x2C);
        first = false;
        if (childIndent != null) {
          out.add(0x0A);
          for (var r = 0; r < childIndentRepeat; r++) {
            out.addAll(childIndent);
          }
        }
        _encodeValueBytes(
          out,
          item,
          toEncodable,
          options,
          seen,
          indent,
          depth + 1,
        );
      }
      if (indent != null) {
        out.add(0x0A);
        final closeIndent = indent.codeUnits;
        for (var r = 0; r < depth; r++) {
          out.addAll(closeIndent);
        }
      }
      out.add(0x5D); // ]
    }
    seen.removeLast();
    return;
  }

  // Not natively representable (BigInt, JsonBinary, or a custom object).
  _checkCycle(seen, value);
  if (toEncodable != null) {
    seen.add(value);
    _encodeValueBytes(
      out,
      toEncodable(value),
      toEncodable,
      options,
      seen,
      indent,
      depth,
    );
    seen.removeLast();
    return;
  }

  if (options != null) {
    if (value is BigInt) {
      _encodeBigIntBytes(out, value, options);
      return;
    }
    if (value is JsonBinary) {
      _writeBinaryBytes(out, value.bytes);
      return;
    }
  }

  final json = _callToJson(value);
  seen.add(value);
  _encodeValueBytes(out, json, toEncodable, options, seen, indent, depth);
  seen.removeLast();
}

void _encodeBigIntBytes(
  List<int> out,
  BigInt value,
  JsonEncodeOptions options,
) {
  switch (options.bigIntEncoding) {
    case BigIntEncoding.string:
      out.add(0x22);
      out.addAll(value.toString().codeUnits);
      out.add(0x22);
      break;
    case BigIntEncoding.intOrString:
      if (_bigIntEncodesAsInt(value)) {
        out.addAll(value.toString().codeUnits); // same text as a Dart int
      } else {
        out.add(0x22);
        out.addAll(value.toString().codeUnits);
        out.add(0x22);
      }
      break;
  }
}

/// Writes a JSON string for real text: iterates Unicode code points (via
/// `.runes`, which already merges UTF-16 surrogate pairs) and UTF-8 encodes
/// each one - the correct behavior for actual String content.
void _writeStringBytes(List<int> out, String s) {
  out.add(0x22);
  for (final cp in s.runes) {
    if (cp >= 0xD800 && cp <= 0xDFFF) {
      // Lone surrogate (runes merges valid pairs): escape like dart:convert
      // instead of writing invalid UTF-8.
      out.addAll('\\u${cp.toRadixString(16)}'.codeUnits);
    } else if (!_writeJsonEscapeIfSpecial(out, cp)) {
      _appendUtf8CodePoint(out, cp);
    }
  }
  out.add(0x22);
}

/// Writes a JSON string for raw binary passthrough ([JsonBinary]): each
/// byte is written as-is with NO UTF-8 re-encoding - unlike the String-based
/// [jsonEncode]+`latin1.encode` path, there's no encoding step to get
/// wrong here, since we're already writing bytes.
void _writeBinaryBytes(List<int> out, List<int> bytes) {
  out.add(0x22);
  for (final b in bytes) {
    if (!_writeJsonEscapeIfSpecial(out, b)) {
      out.add(b);
    }
  }
  out.add(0x22);
}

/// Handles the JSON string escapes shared by both writers above (quote,
/// backslash, control chars). Returns false for anything else, meaning the
/// caller should write it as-is (raw byte) or UTF-8 encode it (code point).
bool _writeJsonEscapeIfSpecial(List<int> out, int code) {
  switch (code) {
    case 0x22:
      out.add(0x5C);
      out.add(0x22);
      return true;
    case 0x5C:
      out.add(0x5C);
      out.add(0x5C);
      return true;
    case 0x08:
      out.add(0x5C);
      out.add(0x62);
      return true;
    case 0x0C:
      out.add(0x5C);
      out.add(0x66);
      return true;
    case 0x0A:
      out.add(0x5C);
      out.add(0x6E);
      return true;
    case 0x0D:
      out.add(0x5C);
      out.add(0x72);
      return true;
    case 0x09:
      out.add(0x5C);
      out.add(0x74);
      return true;
    default:
      if (code < 0x20) {
        out.add(0x5C);
        out.add(0x75);
        out.addAll(code.toRadixString(16).padLeft(4, '0').codeUnits);
        return true;
      }
      return false;
  }
}

// ---------------------------------------------------------------------------
// Decoding
// ---------------------------------------------------------------------------

/// Strict UTF-8 decoder that additionally accepts 3-byte encoded surrogates
/// (WTF-8), so a lone `\uD800` escape can become a String like in
/// dart:convert. Returns null if the bytes are malformed.
String? _decodeWtf8(List<int> b) {
  final units = <int>[];
  var i = 0;
  while (i < b.length) {
    final c = b[i];
    int cp;
    int need;
    int lo;
    if (c < 0x80) {
      units.add(c);
      i++;
      continue;
    } else if (c >= 0xC2 && c <= 0xDF) {
      need = 1;
      cp = c & 0x1F;
      lo = 0x80;
    } else if (c >= 0xE0 && c <= 0xEF) {
      need = 2;
      cp = c & 0x0F;
      lo = 0x800;
    } else if (c >= 0xF0 && c <= 0xF4) {
      need = 3;
      cp = c & 0x07;
      lo = 0x10000;
    } else {
      return null;
    }
    if (i + need >= b.length) return null;
    for (var k = 1; k <= need; k++) {
      final cc = b[i + k];
      if ((cc & 0xC0) != 0x80) return null;
      cp = (cp << 6) | (cc & 0x3F);
    }
    if (cp < lo || cp > 0x10FFFF) return null;
    if (cp >= 0x10000) {
      cp -= 0x10000;
      units.add(0xD800 | (cp >> 10));
      units.add(0xDC00 | (cp & 0x3FF));
    } else {
      units.add(cp);
    }
    i += need + 1;
  }
  return String.fromCharCodes(units);
}

class _JsonParser {
  final List<int> bytes;
  final JsonDecodeOptions? options;
  final Object? Function(Object? key, Object? value)? reviver;
  int pos = 0;

  _JsonParser(this.bytes, this.options, this.reviver);

  bool get isAtEnd => pos >= bytes.length;
  BuError formatError([
    String reason = "",
    dynamic source,
    int? offset,
  ]) {
    final sourceStr = source.toString();
    return CoreErrors.invalidOperationArguments(
      "jsonDecode",
      reason: "Invalid json format.",
      details: {
        "source":
            sourceStr.length > 200
                ? '${sourceStr.substring(0, 200)}... (truncated, total ${sourceStr.length} chars)'
                : sourceStr,
        "offset": offset?.toString(),
        "error": reason,
      },
    );
  }

  void skipWhitespace() {
    while (pos < bytes.length) {
      final b = bytes[pos];
      if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) {
        pos++;
      } else {
        break;
      }
    }
  }

  dynamic parseValue() {
    skipWhitespace();
    if (isAtEnd) throw formatError('Unexpected end of input', bytes, pos);
    final b = bytes[pos];
    switch (b) {
      case 0x7B:
        return _parseObject();
      case 0x5B:
        return _parseArray();
      case 0x22:
        return _parseString();
      case 0x74:
        return _parseLiteral('true', true);
      case 0x66:
        return _parseLiteral('false', false);
      case 0x6E:
        return _parseLiteral('null', null);
      default:
        if (b == 0x2D || (b >= 0x30 && b <= 0x39)) {
          return _parseNumber();
        }
        throw formatError('Unexpected character', bytes, pos);
    }
  }

  dynamic _parseLiteral(String literal, dynamic value) {
    final lit = literal.codeUnits;
    if (pos + lit.length > bytes.length) {
      throw formatError('Unexpected end of input', bytes, pos);
    }
    for (var i = 0; i < lit.length; i++) {
      if (bytes[pos + i] != lit[i]) {
        throw formatError('Invalid literal', bytes, pos);
      }
    }
    pos += lit.length;
    return value;
  }

  Map<String, dynamic> _parseObject() {
    pos++; // {
    final map = <String, dynamic>{};
    skipWhitespace();
    if (!isAtEnd && bytes[pos] == 0x7D) {
      pos++;
      return map;
    }
    while (true) {
      skipWhitespace();
      if (isAtEnd || bytes[pos] != 0x22) {
        throw formatError('Expected string key', bytes, pos);
      }
      final rawKey = _parseString();
      final key =
          rawKey is String ? rawKey : String.fromCharCodes(rawKey as List<int>);
      skipWhitespace();
      if (isAtEnd || bytes[pos] != 0x3A) {
        throw formatError('Expected ":"', bytes, pos);
      }
      pos++; // :
      final rawValue = parseValue();
      map[key] = reviver == null ? rawValue : reviver!(key, rawValue);
      skipWhitespace();
      if (isAtEnd) throw formatError('Unexpected end of input', bytes, pos);
      if (bytes[pos] == 0x2C) {
        pos++;
        continue;
      }
      if (bytes[pos] == 0x7D) {
        pos++;
        break;
      }
      throw formatError('Expected "," or "}"', bytes, pos);
    }
    return map;
  }

  List<dynamic> _parseArray() {
    pos++; // [
    final list = <dynamic>[];
    skipWhitespace();
    if (!isAtEnd && bytes[pos] == 0x5D) {
      pos++;
      return list;
    }
    var index = 0;
    while (true) {
      final rawValue = parseValue();
      list.add(reviver == null ? rawValue : reviver!(index, rawValue));
      index++;
      skipWhitespace();
      if (isAtEnd) throw formatError('Unexpected end of input', bytes, pos);
      if (bytes[pos] == 0x2C) {
        pos++;
        continue;
      }
      if (bytes[pos] == 0x5D) {
        pos++;
        break;
      }
      throw formatError('Expected "," or "]"', bytes, pos);
    }
    return list;
  }

  /// Returns a `String` if the string's bytes are valid UTF-8. Otherwise,
  /// if `options.badStringAsBinary` is enabled, returns a raw `List<int>`;
  /// otherwise throws `formatError` (strict, like dart:convert - and
  /// what always happens when `options` is `null`).
  dynamic _parseString() {
    pos++; // opening quote
    final raw = <int>[];
    // True once a lone surrogate escape was stored (as WTF-8) in `raw`.
    var lone = false;
    void emit(int unit) {
      if (unit >= 0xD800 && unit <= 0xDFFF) lone = true;
      _appendUtf8CodePoint(raw, unit);
    }

    while (true) {
      if (isAtEnd) throw formatError('Unterminated string', bytes, pos);
      final b = bytes[pos];
      if (b == 0x22) {
        pos++;
        break;
      }
      if (b == 0x5C) {
        pos++;
        if (isAtEnd) throw formatError('Unterminated escape', bytes, pos);
        final esc = bytes[pos];
        switch (esc) {
          case 0x22:
            raw.add(0x22);
            pos++;
            break;
          case 0x5C:
            raw.add(0x5C);
            pos++;
            break;
          case 0x2F:
            raw.add(0x2F);
            pos++;
            break;
          case 0x62:
            raw.add(0x08);
            pos++;
            break;
          case 0x66:
            raw.add(0x0C);
            pos++;
            break;
          case 0x6E:
            raw.add(0x0A);
            pos++;
            break;
          case 0x72:
            raw.add(0x0D);
            pos++;
            break;
          case 0x74:
            raw.add(0x09);
            pos++;
            break;
          case 0x75: // \u
            pos++;
            final unit = _readHex4();
            if (unit >= 0xD800 &&
                unit <= 0xDBFF &&
                pos + 1 < bytes.length &&
                bytes[pos] == 0x5C &&
                bytes[pos + 1] == 0x75) {
              final savedPos = pos;
              pos += 2;
              final low = _readHex4();
              if (low >= 0xDC00 && low <= 0xDFFF) {
                final codepoint =
                    0x10000 + ((unit - 0xD800) << 10) + (low - 0xDC00);
                _appendUtf8CodePoint(raw, codepoint);
              } else {
                pos = savedPos;
                emit(unit);
              }
            } else {
              emit(unit);
            }
            break;
          default:
            throw formatError('Invalid escape character', bytes, pos);
        }
      } else {
        // dart:convert rejects raw control characters in strings. With
        // badStringAsBinary they are allowed, since raw binary payloads
        // (e.g. Monero RPC) can contain any byte.
        if (b < 0x20 && !(options?.badStringAsBinary ?? false)) {
          throw formatError('Control character in string', bytes, pos);
        }
        raw.add(b);
        pos++;
      }
    }
    if (lone) {
      // dart:convert returns a String holding the lone surrogate.
      final str = _decodeWtf8(raw);
      if (str != null) return str;
    } else {
      try {
        return StringUtils.decode(raw);
      } catch (_) {}
    }
    if (options?.badStringAsBinary ?? false) {
      return List<int>.from(raw);
    }
    throw formatError(
      'Bad UTF-8 encoding found while decoding string',
      bytes,
      pos,
    );
  }

  int _readHex4() {
    if (pos + 4 > bytes.length) {
      throw formatError('Invalid unicode escape', bytes, pos);
    }
    var value = 0;
    for (var i = 0; i < 4; i++) {
      final b = bytes[pos + i];
      int digit;
      if (b >= 0x30 && b <= 0x39) {
        digit = b - 0x30;
      } else if (b >= 0x41 && b <= 0x46) {
        digit = b - 0x41 + 10;
      } else if (b >= 0x61 && b <= 0x66) {
        digit = b - 0x61 + 10;
      } else {
        throw formatError(
          'Invalid hex digit in unicode escape',
          bytes,
          pos + i,
        );
      }
      value = (value << 4) | digit;
    }
    pos += 4;
    return value;
  }

  /// Matches `dart:convert`: strict JSON number grammar, integer literals
  /// become `int` when they fit the platform `int`, otherwise `double`.
  /// Never a BigInt, never a String.
  dynamic _parseNumber() {
    final start = pos;
    var isDouble = false;
    bool digit() => !isAtEnd && bytes[pos] >= 0x30 && bytes[pos] <= 0x39;
    if (!isAtEnd && bytes[pos] == 0x2D) pos++;
    if (!digit()) throw formatError('Invalid number', bytes, start);
    if (bytes[pos] == 0x30) {
      pos++; // a leading zero must stand alone ("01" is invalid)
    } else {
      while (digit()) {
        pos++;
      }
    }
    if (!isAtEnd && bytes[pos] == 0x2E) {
      isDouble = true;
      pos++;
      if (!digit()) throw formatError('Invalid number', bytes, start);
      while (digit()) {
        pos++;
      }
    }
    if (!isAtEnd && (bytes[pos] == 0x65 || bytes[pos] == 0x45)) {
      isDouble = true;
      pos++;
      if (!isAtEnd && (bytes[pos] == 0x2B || bytes[pos] == 0x2D)) pos++;
      if (!digit()) throw formatError('Invalid number', bytes, start);
      while (digit()) {
        pos++;
      }
    }
    final str = String.fromCharCodes(bytes.sublist(start, pos));
    if (isDouble) return double.parse(str);
    return int.tryParse(str) ?? double.parse(str);
  }
}
