import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Converts loosely-typed JSON-decoded values (num/String/List/Map/etc.)
/// into strongly-typed Dart values, and detects a generic type parameter's
/// runtime shape via the `is T` trick used throughout this class.
class JsonParser {
  static const _buBytes = BuBytes.unsafe([]);

  /// Whether T is nullable.
  static bool _isNull<T extends Object?>() {
    if (null is T) return true;
    return false;
  }

  /// Whether T is `dynamic`/`Object?`.
  static bool isDynamic<T extends Object?>() {
    return Object is T;
  }

  /// Whether T is `double`.
  static bool _isDouble<T extends Object?>() {
    return 3.14 is T;
  }

  /// Whether T is `String`.
  static bool isString<T extends Object?>() {
    return '' is T;
  }

  /// Whether T is `int`.
  static bool _isInt<T extends Object?>() {
    return 0 is T;
  }

  /// Whether T is `num` (accepts both `int` and `double`).
  static bool _isNum<T extends Object?>() {
    return 0 is T && 0.0 is T;
  }

  /// Whether T is `BigInt`.
  static bool _isBigInt<T extends Object?>() {
    return BigInt.zero is T;
  }

  /// Whether T is `bool`.
  static bool _isBool<T extends Object?>() {
    return true is T;
  }

  /// Whether T is `List<dynamic>`.
  static bool isList<T extends Object?>() {
    return <dynamic>[] is T;
  }

  /// Whether T is `List<String>`.
  static bool _isListString<T extends Object?>() {
    return <String>[] is T;
  }

  /// Whether T is `List<int>`.
  static bool _isListInt<T extends Object?>() {
    return <int>[] is T;
  }

  static bool _isBuBytes<T extends Object?>() {
    return _buBytes is T;
  }

  /// Whether T is `List<BigInt>`.
  static bool _isListBigInt<T extends Object?>() {
    return <BigInt>[] is T;
  }

  /// Whether T is `List<double>`.
  static bool _isListDouble<T extends Object?>() {
    return <double>[] is T;
  }

  /// Whether T is `List<bool>`.
  static bool _isListBool<T extends Object?>() {
    return <bool>[] is T;
  }

  /// Whether T is `List<List<int>>`.
  static bool _isListOfListInt<T extends Object?>() {
    return <List<int>>[] is T;
  }

  /// Whether T is `List<List<List<int>>>`.
  static bool _isListOfListOfListInt<T extends Object?>() {
    return <List<List<int>>>[] is T;
  }

  /// Whether T is `List<List<List<int>>>`.
  static bool _isListOfBytes<T extends Object?>() {
    return <BuBytes>[] is T;
  }

  /// Whether T is `Map<dynamic, dynamic>`.
  static bool isMap<T extends Object?>() {
    return <dynamic, dynamic>{} is T;
  }

  /// Whether T is `Map<String, dynamic>`.
  static bool isMapStringDynamic<T extends Object?>() {
    return <String, dynamic>{} is T;
  }

  /// Whether T is `List<Map<dynamic, dynamic>>`.
  static bool _isListOfMap<T extends Object?>() {
    return <Map<dynamic, dynamic>>[] is T;
  }

  /// Whether T is `List<Map<String, dynamic>>`.
  static bool isListOfMapStringDynamic<T extends Object?>() {
    return <Map<String, dynamic>>[] is T;
  }

  /// Whether T is `List<Map<String, String>>`.
  static bool _isListOfMapStringString<T extends Object?>() {
    return <Map<String, String>>[] is T;
  }

  /// Whether T is `Map<String, String>`.
  static bool _isMapStringString<T extends Object?>() {
    return <String, String>{} is T;
  }

  /// Whether T is `Set<dynamic>`.
  static bool _isSet<T extends Object?>() {
    return <dynamic>{} is T;
  }

  /// Whether T is `Set<int>`.
  static bool _isSetInt<T extends Object?>() {
    return <int>{} is T;
  }

  /// Whether T is `Set<String>`.
  static bool _isSetString<T extends Object?>() {
    return <String>{} is T;
  }

  /// Coerces [value] (int/String/hex/decimal string) to a [BigInt].
  static T valueAsBigInt<T extends BigInt?>(
    Object? value, {
    bool allowHex = false,
    bool? sign,
    bool allowDecimals = false,
  }) {
    final T v = (() {
      if (value is T) {
        return value;
      }
      if (value == null && _isNull<T>()) return null as T;
      final toBigint = BigintUtils.tryParse(value, allowHex: allowHex);
      if (toBigint == null) {
        if (allowDecimals && value is String) {
          final decode = BigRational.tryParse(value);
          if (decode != null) return decode.toBigInt() as T;
        } else if (value is double && value == value.truncateToDouble()) {
          final decode = BigRational.tryParse(value.toString());
          if (decode != null) return decode.toBigInt() as T;
        }
        throw CoreErrors.jsonWrongType("Failed to parse value as bigint.");
      }
      return toBigint as T;
    }());
    if (v == null) return v;
    if (sign != null && !sign && v.isNegative) {
      throw CoreErrors.jsonWrongType(
        "Invalid unsigned bigint.",
        details: {"value": v.toString()},
      );
    }
    return v;
  }

  /// Coerces [value] (num/String/hex string) to an [int].
  static T valueAsInt<T extends int?>(
    Object? value, {
    bool allowHex = false,
    bool allowDouble = false,
  }) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    int? parse(num v) {
      if (v is int) return v;
      if (allowDouble) return v.toInt();
      if (!allowDouble && v == v.truncateToDouble()) {
        return v.toInt();
      }
      return null;
    }

    if (value is num) {
      final v = parse(value);
      if (v != null) return v as T;
    }

    if (value is String) {
      final n = num.tryParse(value);
      if (n != null) {
        final v = parse(n);
        if (v != null) return v as T;
      }
    }

    final toInt = IntUtils.tryParse(value, allowHex: allowHex);
    if (toInt == null) {
      throw CoreErrors.jsonWrongType(
        "Failed to parse value as int.",
        details: {"value": value.toString()},
      );
    }
    return toInt as T;
  }

  /// Coerces [value] (num/String/hex string) to a [num].
  static T valueAsNum<T extends num?>(
    Object? value, {
    bool allowHex = false,
    bool allowDouble = false,
  }) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    if (value is num) {
      return value as T;
    }

    if (value is String) {
      final n = num.tryParse(value);
      if (n != null) {
        return n as T;
      }
    }
    final toInt = IntUtils.tryParse(value, allowHex: allowHex);
    if (toInt == null) {
      throw CoreErrors.jsonWrongType(
        "Failed to parse value as num.",
        details: {"value": value.toString()},
      );
    }
    return toInt as T;
  }

  /// Coerces [value] (num/String) to a [double].
  static T valueAsDouble<T extends double?>(Object? value) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    if (value is num) {
      return value.toDouble() as T;
    }
    if (value is String) {
      final v = double.tryParse(value);
      if (v != null) return v as T;
    }
    throw CoreErrors.jsonWrongType("Failed to parse value as double.");
  }

  /// Coerces [value] to a [String] — decodes byte lists, optionally JSON-encodes lists/maps.
  static T valueAsString<T extends String?>(
    Object? value, {
    bool allowJson = false,
    bool allowHexEncoding = false,
    StringEncoding? bytesEncoding = StringEncoding.utf8,
  }) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;
    if (value is List<int> && BytesUtils.isBytes(value)) {
      if (bytesEncoding != null) {
        final decode = StringUtils.tryDecode(value, encoding: bytesEncoding);
        if (decode != null) {
          return decode as T;
        }
      }
      if (allowHexEncoding && value.length.isEven) {
        final decode = BytesUtils.toHexString(value);
        return decode as T;
      }
    }
    if (allowJson && (value is List || value is Map)) {
      final decode = StringUtils.tryEncodeJson(value);
      if (decode != null) {
        return decode as T;
      }
    }
    if (value is! String) {
      throw CoreErrors.jsonWrongType("Failed to parse value as string.");
    }
    return value as T;
  }

  /// Coerces [value] (bool or "true"/"false" string) to a [bool].
  static T valueAsBool<T extends bool?>(Object? value) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    if (value is bool) return value as T;
    if (value is String) {
      final boolStr = value.toLowerCase();
      if (boolStr == 'true') return true as T;
      if (boolStr == 'false') return false as T;
    }

    throw CoreErrors.jsonWrongType("Failed to parse value as boolean.");
  }

  /// Coerces [value] to a byte list — accepts a raw byte [List], a hex or
  /// [encoding]-decoded [String], or (with [allowJson]) a JSON-encoded list/map.
  static T valueAsBytes<T extends List<int>?>(
    Object? value, {
    bool allowHex = true,
    StringEncoding? encoding,
    bool allowJson = false,
  }) {
    if (value == null && _isNull<T>()) return null as T;
    if (value is List) {
      try {
        return value.cast<int>().asBytes as T;
      } catch (_) {
        throw CoreErrors.jsonWrongType("Failed to parse value as bytes.");
      }
    }

    if (value is String) {
      if (encoding != null) {
        final toBytes = StringUtils.tryEncode(value, encoding: encoding);
        if (toBytes != null) return toBytes as T;
      }
      if (allowHex && encoding != StringEncoding.hex) {
        final toBytes = BytesUtils.tryFromHexString(value);
        if (toBytes != null) return toBytes as T;
      }
      throw CoreErrors.jsonWrongType("Failed to parse value as bytes.");
    }
    if (allowJson && (value is List || value is Map)) {
      final toBytes = StringUtils.tryEncodeJson(value);
      if (toBytes != null) return toBytes as T;
    }

    throw CoreErrors.jsonWrongType("Failed to parse value as bytes.");
  }

  /// Coerces [value] to a `Map<String, dynamic>` or `Map<String, String>`,
  /// matching whichever T actually is.
  static T valueAsMap<T extends Map?>(Object? value) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    if (!isMap<T>()) {
      if (isMapStringDynamic<T>()) {
        return valueEnsureAsMap<String, dynamic>(value) as T;
      }
      if (_isMapStringString<T>()) {
        return valueEnsureAsMap<String, String>(value) as T;
      }
    }
    throw CoreErrors.jsonWrongType("Failed to parse value as map.");
  }

  /// Coerces [value] to whichever concrete `List<...>` shape T is.
  static T valueAsList<T extends List?>(Object? value) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    if (!isList<T>()) {
      if (_isListString<T>()) {
        return valueEnsureAsList<String>(value) as T;
      } else if (_isListInt<T>()) {
        return valueEnsureAsList<int>(value) as T;
      } else if (_isListBigInt<T>()) {
        return valueEnsureAsList<BigInt>(value) as T;
      } else if (_isListDouble<T>()) {
        return valueEnsureAsList<double>(value) as T;
      } else if (_isListBool<T>()) {
        return valueEnsureAsList<bool>(value) as T;
      } else if (_isListOfMap<T>()) {
        return valueEnsureAsList<Map>(value) as T;
      } else if (isListOfMapStringDynamic<T>()) {
        return valueEnsureAsList<Map<String, dynamic>>(value) as T;
      } else if (_isListOfMapStringString<T>()) {
        return valueEnsureAsList<Map<String, String>>(value) as T;
      } else if (_isListOfListInt<T>()) {
        return valueEnsureAsList<List<int>>(value) as T;
      } else if (_isListOfBytes<T>()) {
        return valueEnsureAsList<BuBytes>(value) as T;
      } else if (_isListOfListOfListInt<T>()) {
        return valueEnsureAsList<List<List<int>>>(value) as T;
      }
    }
    throw CoreErrors.jsonWrongType("Failed to parse value as $T.");
  }

  /// Coerces [value] to whichever concrete `Set<...>` shape T is.
  static T valueAsSet<T extends Set?>(Object? value) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;
    if (!_isSet<T>()) {
      if (_isSetString<T>()) {
        return valueEnsureAsSet<String>(value) as T;
      }
      if (_isSetInt<T>()) {
        return valueEnsureAsSet<int>(value) as T;
      }
    }
    throw CoreErrors.jsonWrongType("Failed to parse value as set.");
  }

  /// Casts [value] to `Map<KK, VV>`, rebuilding it if it isn't already one.
  static Map<KK, VV> valueEnsureAsMap<KK, VV>(Object? value) {
    if (value is Map<KK, VV>) return value;
    try {
      return Map<KK, VV>.from(value as Map);
    } catch (_) {
      throw CoreErrors.jsonWrongType("Failed to parse value as map.");
    }
  }

  /// Casts [value] to `List<T>`, converting each element if needed.
  static List<T> valueEnsureAsList<T>(Object? value) {
    if (value is List<T>) return value;
    try {
      final valueList = value as List;
      try {
        if (!isDynamic<T>()) {
          if (isMap<T>()) {
            return valueList
                .map((e) {
                  if (e is T) return e;
                  return Map.from(e);
                })
                .toList()
                .cast<T>();
          }
          if (isMapStringDynamic<T>()) {
            return valueList
                .map((e) {
                  if (e is T) return e;
                  return Map<String, dynamic>.from(e);
                })
                .toList()
                .cast<T>();
          }
          if (_isMapStringString<T>()) {
            return valueList
                .map((e) {
                  if (e is T) return e;
                  return Map<String, String>.from(e);
                })
                .toList()
                .cast<T>();
          }
          if (_isListOfListInt<T>()) {
            return value
                .map((e) => valueEnsureAsList<List<int>>(e))
                .toList()
                .cast<T>();
          }
          if (_isListOfBytes<T>()) {
            final result =
                value.map((e) => valueEnsureAsList<BuBytes>(e)).toList();
            return result.cast<T>();
          }
          if (_isBuBytes<T>()) {
            final result =
                value
                    .map((e) => valueEnsureAsList<int>(e))
                    .map((e) => e.asBytes)
                    .toList();
            return result.cast<T>();
          }

          return value.map((e) => valueAs<T>(e)).toList();
        }
      } catch (_) {}
      return List<T>.from(value);
    } catch (e) {
      throw CoreErrors.jsonWrongType(
        "Failed to parse object as list<$T>",
        details: {"error": e.toString()},
      );
    }
  }

  /// Casts [value] to `Set<T>`, rebuilding it if it isn't already one.
  static Set<T> valueEnsureAsSet<T>(Object? value) {
    if (value is Set<T>) return value;
    try {
      return Set<T>.from(value as Iterable);
    } catch (_) {
      throw CoreErrors.jsonWrongType("Failed to parse object as set<$T>");
    }
  }

  /// Central dispatcher: coerces [value] to whichever concrete type T is
  /// (num/String/List/Map/Set/etc.), by inspecting T's runtime shape.
  static T valueAs<T extends Object?>(
    Object? value, {
    bool? allowHex,
    StringEncoding? encoding,
    bool asBytes = false,
  }) {
    assert(
      (allowHex == null && encoding == null) || asBytes,
      "allowHex and encoding must be use with asBytes",
    );
    if (value is T) {
      return value;
    }
    if (value == null) {
      if (_isNull<T>()) return null as T;
    }
    if (value == null) {
      throw CoreErrors.jsonWrongType("Failed to parse value as $T");
    }
    if (value is T) return value as T;
    if (isDynamic<T>()) {
      return value as T;
    } else if (_isNum<T>()) {
      return valueAsNum<num>(value) as T;
    } else if (_isDouble<T>()) {
      return valueAsDouble<double>(value) as T;
    } else if (isString<T>()) {
      return valueAsString<String>(value) as T;
    } else if (_isInt<T>()) {
      return valueAsInt<int>(value) as T;
    } else if (_isBigInt<T>()) {
      return valueAsBigInt<BigInt>(value) as T;
    } else if (_isBool<T>()) {
      return valueAsBool<bool>(value) as T;
    } else if (isMap<T>()) {
      return valueAsMap<Map<dynamic, dynamic>>(value) as T;
    } else if (isMapStringDynamic<T>()) {
      return valueAsMap<Map<String, dynamic>>(value) as T;
    } else if (_isMapStringString<T>()) {
      return valueAsMap<Map<String, String>>(value) as T;
    } else if (isList<T>()) {
      return valueAsList<List>(value) as T;
    } else if (_isListString<T>()) {
      return valueAsList<List<String>>(value) as T;
    } else if (_isListInt<T>()) {
      if (asBytes) {
        return valueAsBytes<List<int>>(
              value,
              allowHex: allowHex ?? true,
              encoding: encoding,
            )
            as T;
      }
      return valueAsList<List<int>>(value) as T;
    } else if (_isBuBytes<T>()) {
      return valueAsBytes<BuBytes>(
            value,
            allowHex: allowHex ?? true,
            encoding: encoding,
          )
          as T;
    } else if (_isListBigInt<T>()) {
      return valueAsList<List<BigInt>>(value) as T;
    } else if (_isListBool<T>()) {
      return valueAsList<List<bool>>(value) as T;
    } else if (_isListDouble<T>()) {
      return valueAsList<List<double>>(value) as T;
    } else if (_isListOfMap<T>()) {
      return valueAsList<List<Map>>(value) as T;
    } else if (isListOfMapStringDynamic<T>()) {
      return valueAsList<List<Map<String, dynamic>>>(value) as T;
    } else if (_isListOfMapStringString<T>()) {
      return valueAsList<List<Map<String, String>>>(value) as T;
    } else if (_isListOfListOfListInt<T>()) {
      return valueEnsureAsList<List<List<int>>>(value) as T;
    }
    throw CoreErrors.jsonWrongType("Failed to parse object as $T");
  }

  /// Coerces [value] to `VV` via [valueAs], then applies [parse] to build a `T`.
  static T valueTo<T extends Object?, VV extends Object?>({
    required Object? value,
    required T Function(VV v) parse,
    bool? allowHex,
    StringEncoding? encoding,
    bool asBytes = false,
  }) {
    if (value == null) {
      if (_isNull<VV>()) return parse(null as VV);
      if (_isNull<T>()) return null as T;
    }
    final VV r = valueAs<VV>(
      value,
      allowHex: allowHex,
      encoding: encoding,
      asBytes: asBytes,
    );
    return parse(r);
  }
}

/// Typed field lookup/coercion helpers for JSON-decoded maps.
extension ExtJSONHelper<K, V> on Map<K, V> {
  String _normalizeKey(String key) {
    return key
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .toLowerCase();
  }

  /// Looks up [key] (optionally falling back to its snake_case/camelCase
  /// form), returning [onMissing]'s result or throwing if absent.
  Object? _checkItem<T extends Object?>(
    K key,
    T Function()? onMissing,
    bool normalizeKeys,
  ) {
    V? value = this[key];

    if (value != null) return value;

    if (normalizeKeys && key is String) {
      final normalizedKey = _normalizeKey(key);

      for (final entry in entries) {
        final key = entry.key;
        if (key is String && _normalizeKey(key) == normalizedKey) {
          value = entry.value;
          break;
        }
      }
    }

    if (value != null) return value;
    if (JsonParser._isNull<T>()) return value;
    if (onMissing != null) return onMissing();

    if (!containsKey(key)) {
      throw CoreErrors.jsonKeyNotFound(key);
    }

    throw BuError(DefaultErrorType.badJson,"Null value for key: '$key'.");
  }

  /// Tries each of [keys] in order, returning the first one present
  /// (parsed via [parse]).
  E oneOf<E, T>({
    required List<K> keys,
    required E Function(K key, T e) parse,
  }) {
    for (final i in keys) {
      final result = valueTo<E?, T>(key: i, parse: (e) => parse(i, e));
      if (result != null) return result;
    }
    if (null is E) return null as E;
    throw BuError(DefaultErrorType.notFound,
      'No matching key found.',
      details: {'keys': keys.join(", "), 'data': toString()},
    );
  }

  /// Throws if [key] isn't present in this map.
  void ensureKeyExists(K key) {
    if (containsKey(key)) return;
    throw CoreErrors.jsonKeyNotFound(key);
  }

  /// Whether [key] is present and its value isn't null.
  bool hasValue(K key) {
    final value = this[key];
    return value != null;
  }

  /// Reads [key] and coerces it to a BigInt.
  T valueAsBigInt<T extends BigInt?>(
    K key, {
    bool allowHex = false,
    T Function(BuError err)? onError,
    T Function()? onMissing,
    bool? sign,
    bool allowDecimals = false,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return value as T;
      return JsonParser.valueAsBigInt<T>(
        value,
        allowHex: allowHex,
        sign: sign,
        allowDecimals: allowDecimals,
      );
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and coerces it to an int.
  T valueAsInt<T extends int?>(
    K key, {
    bool allowHex = false,
    bool allowDouble = false,
    T Function(BuError err)? onError,
    T Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return value as T;

      return JsonParser.valueAsInt<T>(
        value,
        allowDouble: allowDouble,
        allowHex: allowHex,
      );
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and coerces it to a num.
  T valueAsNum<T extends num?>(
    K key, {
    bool allowHex = false,
    bool allowDouble = false,
    T Function(BuError err)? onError,
    T Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return value as T;

      return JsonParser.valueAsNum<T>(
        value,
        allowDouble: allowDouble,
        allowHex: allowHex,
      );
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and coerces it to a double.
  T valueAsDouble<T extends double?>(
    K key, {
    T Function(BuError err)? onError,
    T Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return value as T;

      return JsonParser.valueAsDouble<T>(value);
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and coerces it to a String.
  T valueAsString<T extends String?>(
    K key, {
    T Function(BuError err)? onError,
    T Function()? onMissing,
    bool allowJson = false,
    bool allowHexEncoding = false,
    StringEncoding? bytesEncoding = StringEncoding.utf8,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return value as T;

      return JsonParser.valueAsString<T>(
        value,
        allowJson: allowJson,
        allowHexEncoding: allowHexEncoding,
        bytesEncoding: bytesEncoding,
      );
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and coerces it to a bool.
  T valueAsBool<T extends bool?>(
    K key, {
    T Function(BuError err)? onError,
    T Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return value as T;
      return JsonParser.valueAsBool<T>(value);
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and coerces it to bytes.
  T valueAsBytes<T extends List<int>?>(
    K key, {
    bool allowHex = true,
    StringEncoding? encoding,
    bool allowJson = false,
    T Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
    T Function(BuError err)? onError,
  }) {
    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return value as T;

      return JsonParser.valueAsBytes<T>(
        value,
        allowHex: allowHex,
        encoding: encoding,
        allowJson: allowJson,
      );
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and coerces it to a Map.
  T valueAsMap<T extends Map?>(
    K key, {
    T Function(BuError err)? onError,
    T Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return value as T;

      return JsonParser.valueAsMap<T>(value);
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and coerces it to a List.
  T valueAsList<T extends List?>(
    K key, {
    T Function(BuError err)? onError,
    T Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return value as T;
      return JsonParser.valueAsList<T>(value);
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and coerces it to a Set.
  T valueAsSet<T extends Set?>(
    K key, {
    T Function(BuError err)? onError,
    T Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return value as T;

      return JsonParser.valueAsSet<T>(value);
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and casts it to `Map<KK, VV>`.
  Map<KK, VV> valueEnsureAsMap<KK, VV>(
    K key, {
    Map<KK, VV> Function(BuError err)? onError,
    Map<KK, VV> Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<Map>(key, onMissing, normalizeKeyLookup);
      return JsonParser.valueEnsureAsMap<KK, VV>(value);
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and casts it to `List<T>`.
  List<T> valueEnsureAsList<T>(
    K key, {
    List<T> Function(BuError err)? onError,
    List<T> Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<List>(key, onMissing, normalizeKeyLookup);
      return JsonParser.valueEnsureAsList<T>(value);
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and casts it to `Set<T>`.
  Set<T> valueEnsureAsSet<T>(
    K key, {
    Set<T> Function(BuError err)? onError,
    Set<T> Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      final value = _checkItem<Set>(key, onMissing, normalizeKeyLookup);
      return JsonParser.valueEnsureAsSet<T>(value);
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key] and coerces it to whichever concrete type T is.
  T valueAs<T extends Object?>(
    K key, {
    bool? allowHex,
    StringEncoding? encoding,
    bool asBytes = false,
    T Function()? onMissing,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,

    T Function(BuError err)? onError,
  }) {
    assert(
      (allowHex == null && encoding == null) || asBytes,
      "allowHex and encoding must be use with asBytes",
    );

    try {
      final value = _checkItem<T>(key, onMissing, normalizeKeyLookup);
      if (value == null) return null as T;
      return JsonParser.valueAs(
        value,
        allowHex: allowHex,
        asBytes: asBytes,
        encoding: encoding,
      );
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }

  /// Reads [key], coerces it to `VV`, then applies [parse] to build a `T`.
  T valueTo<T extends Object?, VV extends Object?>({
    required K key,
    required T Function(VV v) parse,
    bool? allowHex,
    StringEncoding? encoding,
    bool asBytes = false,
    T Function()? onMissing,
    T Function(BuError err)? onError,

    /// Only applicable when [K] is `String`.
    bool normalizeKeyLookup = false,
  }) {
    try {
      V? value = this[key];
      if (value == null && normalizeKeyLookup && key is String) {
        final normalizedKey = _normalizeKey(key);
        for (final entry in entries) {
          final key = entry.key;
          if (key is String && _normalizeKey(key) == normalizedKey) {
            value = entry.value;
            break;
          }
        }
      }
      if (value == null) {
        if (JsonParser._isNull<VV>()) return parse(null as VV);
        if (JsonParser._isNull<T>()) return null as T;
        if (onMissing != null) return onMissing();
        if (!containsKey(key)) throw CoreErrors.jsonKeyNotFound(key);
        throw BuError(DefaultErrorType.badJson,"Null value for key: '$key'.");
      }
      return JsonParser.valueTo(
        value: value,
        parse: parse,
        allowHex: allowHex,
        asBytes: asBytes,
        encoding: encoding,
      );
    } on BuError catch (e) {
      if (onError != null) return onError(e);
      throw CoreErrors.jsonErrorWithKey(e, key);
    }
  }
}

/// Case-insensitive key lookup for string-keyed maps.
extension ExtCaseInsensitiveMapExtension<V> on Map<String, V> {
  /// Whether this map has a non-null value for [key], ignoring case.
  bool hasValueForKeyIgnoreCase(String key) {
    final normalizedKey = key.toLowerCase();

    final matchKey = keys.firstWhereNullable(
      (k) => k.toLowerCase() == normalizedKey,
    );

    if (matchKey == null) return false;

    return this[matchKey] != null;
  }
}
