import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/json/exception/exception.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class JsonParser {
  static bool _isNull<T extends Object?>() {
    if (null is T) return true;
    return false;
  }

  static bool isDynamic<T extends Object?>() {
    return Object is T;
  }

  static bool _isDouble<T extends Object?>() {
    return 3.14 is T;
  }

  static bool isString<T extends Object?>() {
    return '' is T;
  }

  static bool _isInt<T extends Object?>() {
    return 0 is T;
  }

  static bool _isNum<T extends Object?>() {
    return 0 is T && 0.0 is T;
  }

  static bool _isBigInt<T extends Object?>() {
    return BigInt.zero is T;
  }

  static bool _isBool<T extends Object?>() {
    return true is T;
  }

  static bool isList<T extends Object?>() {
    return <dynamic>[] is T;
  }

  static bool _isListString<T extends Object?>() {
    return <String>[] is T;
  }

  static bool _isListInt<T extends Object?>() {
    return <int>[] is T;
  }

  static bool _isListBigInt<T extends Object?>() {
    return <BigInt>[] is T;
  }

  static bool _isListDouble<T extends Object?>() {
    return <double>[] is T;
  }

  static bool _isListBool<T extends Object?>() {
    return <bool>[] is T;
  }

  static bool _isListOfListInt<T extends Object?>() {
    return <List<int>>[] is T;
  }

  static bool _isListOfListOfListInt<T extends Object?>() {
    return <List<List<int>>>[] is T;
  }

  static bool isMap<T extends Object?>() {
    return <dynamic, dynamic>{} is T;
  }

  static bool isMapStringDynamic<T extends Object?>() {
    return <String, dynamic>{} is T;
  }

  static bool _isListOfMap<T extends Object?>() {
    return <Map<dynamic, dynamic>>[] is T;
  }

  static bool isListOfMapStringDynamic<T extends Object?>() {
    return <Map<String, dynamic>>[] is T;
  }

  static bool _isListOfMapStringString<T extends Object?>() {
    return <Map<String, String>>[] is T;
  }

  static bool _isMapStringString<T extends Object?>() {
    return <String, String>{} is T;
  }

  //
  static bool _isSet<T extends Object?>() {
    return <dynamic>{} is T;
  }

  static bool _isSetInt<T extends Object?>() {
    return <int>{} is T;
  }

  static bool _isSetString<T extends Object?>() {
    return <String>{} is T;
  }

  static T valueAsBigInt<T extends BigInt?>(
    Object? value, {
    bool allowHex = false,
    bool? sign,
  }) {
    final v = (() {
      if (value is T) {
        return value;
      }
      if (value == null && _isNull<T>()) return null as T;
      final toBigint = BigintUtils.tryParse(value, allowHex: allowHex);
      if (toBigint == null) {
        throw JsonParserError("Failed to parse value as bigint.");
      }
      return toBigint as T;
    }());
    if (v == null) return v;
    if (sign != null && !sign && v.isNegative) {
      throw JsonParserError(
        "Invalid unsigned bigint.",
        details: {"value": v.toString()},
      );
    }
    return v;
  }

  static T valueAsInt<T extends int?>(
    Object? value, {
    bool allowHex = false,
    bool allowDouble = false,
  }) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    int? parse(num v) {
      if (v is int) return v;
      if (allowDouble == true) return v.toInt();
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
      throw JsonParserError(
        "Failed to parse value as int.",
        details: {"value": value.toString()},
      );
    }
    return toInt as T;
  }

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
      throw JsonParserError(
        "Failed to parse value as num.",
        details: {"value": value.toString()},
      );
    }
    return toInt as T;
  }

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
    throw JsonParserError("Failed to parse value as double.");
  }

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
      throw JsonParserError("Failed to parse value as string.");
    }
    return value as T;
  }

  static T valueAsBool<T extends bool?>(Object? value) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    if (value is bool) return value as T;
    if (value is String) {
      final boolStr = value.toLowerCase();
      if (boolStr == 'true') return true as T;
      if (boolStr == 'false') return false as T;
    }

    throw JsonParserError("Failed to parse value as boolean.");
  }

  static T valueAsBytes<T extends List<int>?>(
    Object? value, {
    bool allowHex = true,

    /// string encoding
    StringEncoding? encoding,
    bool allowJson = false,
  }) {
    if (value == null && _isNull<T>()) return null as T;
    if (value is List) {
      try {
        return value.cast<int>().asBytes as T;
      } catch (_) {
        throw JsonParserError("Failed to parse value as bytes.");
      }
    }

    if (value is String) {
      if (allowHex && StringUtils.isHexBytes(value)) {
        final toBytes = BytesUtils.tryFromHexString(value);
        if (toBytes != null) return toBytes as T;
      }
      if (encoding != null) {
        final toBytes = StringUtils.tryEncode(value, encoding: encoding);

        if (toBytes != null) return toBytes as T;
        throw JsonParserError("Failed to parse value as bytes.");
      }
    }
    if (allowJson && (value is List || value is Map)) {
      final toBytes = StringUtils.tryEncodeJson(value);
      if (toBytes != null) return toBytes as T;
    }

    throw JsonParserError("Failed to parse value as bytes.");
  }

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
    throw JsonParserError("Failed to parse value as map.");
  }

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
      } else if (_isListOfListOfListInt<T>()) {
        return valueEnsureAsList<List<List<int>>>(value) as T;
      }
    }
    throw JsonParserError("Failed to parse value as map.");
  }

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
    throw JsonParserError("Failed to parse value as set.");
  }

  static Map<KK, VV> valueEnsureAsMap<KK, VV>(Object? value) {
    if (value is Map<KK, VV>) return value;
    try {
      return Map<KK, VV>.from(value as Map);
    } catch (_) {
      throw JsonParserError("Failed to parse value as map.");
    }
  }

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
          if (_isListOfListInt()) {
            return value
                .map((e) => valueEnsureAsList<List<int>>(e))
                .toList()
                .cast<T>();
          }
          return value.map((e) => valueAs<T>(e)).toList();
        }
      } catch (_) {}
      return List<T>.from(value);
    } catch (e) {
      throw JsonParserError(
        "Failed to parse object as list<$T>",
        details: {"error": e.toString()},
      );
    }
  }

  static Set<T> valueEnsureAsSet<T>(Object? value) {
    if (value is Set<T>) return value;
    try {
      return Set<T>.from(value as Iterable);
    } catch (_) {
      throw JsonParserError("Failed to parse object as set<$T>");
    }
  }

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
      throw JsonParserError("Failed to parse value as $T");
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
    throw JsonParserError("Failed to parse object as $T");
  }

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

extension ExtJSONHelper<K, V> on Map<K, V> {
  Object? _checkItem<T extends Object?>(
    K key,
    T Function()? onMissing,
    bool acceptSnakeCase,
    bool acceptCamelCase,
  ) {
    V? value = this[key];
    if (value == null && key is String) {
      if (acceptSnakeCase) {
        value = this[StringUtils.camelToSnake(key)];
      } else if (acceptCamelCase) {
        value = this[StringUtils.snakeToCamel(key, capitalizeFirst: false)];
      }
    }
    if (value != null) return value;
    if (JsonParser._isNull<T>()) return value;
    if (onMissing != null) return onMissing();
    if (!containsKey(key)) throw JsonParserError("Missing key: '$key'.");
    throw JsonParserError("Null value for key: '$key'.");
  }

  E oneOf<E, T>({
    required List<K> keys,
    required E Function(K key, T e) parse,
  }) {
    for (final i in keys) {
      final result = valueTo<E?, T>(key: i, parse: (e) => parse(i, e));
      if (result != null) return result;
    }
    if (null is E) return null as E;
    throw JsonParserError(
      'No matching key found.',
      details: {'keys': keys.join(", "), 'data': toString()},
    );
  }

  void ensureKeyExists(K key) {
    if (containsKey(key)) return;
    throw JsonParserError("Missing key: '$key'.");
  }

  bool hasValue(K key) {
    final value = this[key];
    return value != null;
  }

  T valueAsBigInt<T extends BigInt?>(
    K key, {
    bool allowHex = false,
    T Function(JsonParserError err)? onError,
    T Function()? onMissing,
    bool? sign,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return value as T;
      return JsonParser.valueAsBigInt<T>(value, allowHex: allowHex, sign: sign);
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueAsInt<T extends int?>(
    K key, {
    bool allowHex = false,
    bool allowDouble = false,
    T Function(JsonParserError err)? onError,
    T Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return value as T;

      return JsonParser.valueAsInt<T>(
        value,
        allowDouble: allowDouble,
        allowHex: allowHex,
      );
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueAsNum<T extends num?>(
    K key, {
    bool allowHex = false,
    bool allowDouble = false,
    T Function(JsonParserError err)? onError,
    T Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return value as T;

      return JsonParser.valueAsNum<T>(
        value,
        allowDouble: allowDouble,
        allowHex: allowHex,
      );
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueAsDouble<T extends double?>(
    K key, {
    T Function(JsonParserError err)? onError,
    T Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return value as T;

      return JsonParser.valueAsDouble<T>(value);
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueAsString<T extends String?>(
    K key, {
    T Function(JsonParserError err)? onError,
    T Function()? onMissing,
    bool allowJson = false,
    bool allowHexEncoding = false,
    StringEncoding? bytesEncoding = StringEncoding.utf8,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return value as T;

      return JsonParser.valueAsString<T>(
        value,
        allowJson: allowJson,
        allowHexEncoding: allowHexEncoding,
        bytesEncoding: bytesEncoding,
      );
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueAsBool<T extends bool?>(
    K key, {
    T Function(JsonParserError err)? onError,
    T Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return value as T;
      return JsonParser.valueAsBool<T>(value);
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueAsBytes<T extends List<int>?>(
    K key, {
    bool allowHex = true,
    StringEncoding? encoding,
    bool allowJson = false,
    T Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
    T Function(JsonParserError err)? onError,
  }) {
    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return value as T;

      return JsonParser.valueAsBytes<T>(
        value,
        allowHex: allowHex,
        encoding: encoding,
        allowJson: allowJson,
      );
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueAsMap<T extends Map?>(
    K key, {
    T Function(JsonParserError err)? onError,
    T Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return value as T;

      return JsonParser.valueAsMap<T>(value);
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueAsList<T extends List?>(
    K key, {
    T Function(JsonParserError err)? onError,
    T Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return value as T;
      return JsonParser.valueAsList<T>(value);
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueAsSet<T extends Set?>(
    K key, {
    T Function(JsonParserError err)? onError,
    T Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return value as T;

      return JsonParser.valueAsSet<T>(value);
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  Map<KK, VV> valueEnsureAsMap<KK, VV>(
    K key, {
    Map<KK, VV> Function(JsonParserError err)? onError,
    Map<KK, VV> Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<Map>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      return JsonParser.valueEnsureAsMap<KK, VV>(value);
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  List<T> valueEnsureAsList<T>(
    K key, {
    List<T> Function(JsonParserError err)? onError,
    List<T> Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<List>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      return JsonParser.valueEnsureAsList<T>(value);
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  Set<T> valueEnsureAsSet<T>(
    K key, {
    Set<T> Function(JsonParserError err)? onError,
    Set<T> Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      final value = _checkItem<Set>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      return JsonParser.valueEnsureAsSet<T>(value);
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueAs<T extends Object?>(
    K key, {
    bool? allowHex,
    StringEncoding? encoding,
    bool asBytes = false,
    T Function()? onMissing,

    /// Also accepts the snake_case or camel_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,

    T Function(JsonParserError err)? onError,
  }) {
    assert(
      (allowHex == null && encoding == null) || asBytes,
      "allowHex and encoding must be use with asBytes",
    );

    try {
      final value = _checkItem<T>(
        key,
        onMissing,
        acceptSnakeCase,
        acceptCamelCase,
      );
      if (value == null) return null as T;
      return JsonParser.valueAs(
        value,
        allowHex: allowHex,
        asBytes: asBytes,
        encoding: encoding,
      );
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  T valueTo<T extends Object?, VV extends Object?>({
    required K key,
    required T Function(VV v) parse,
    bool? allowHex,
    StringEncoding? encoding,
    bool asBytes = false,
    T Function()? onMissing,
    T Function(JsonParserError err)? onError,

    /// Also accepts the snake_case version of [key] when looking up JSON fields.
    /// Only applicable when [K] is `String`.
    bool acceptSnakeCase = false,
    bool acceptCamelCase = false,
  }) {
    try {
      V? value = this[key];
      if (value == null && key is String) {
        if (acceptSnakeCase) {
          value = this[StringUtils.camelToSnake(key)];
        } else if (acceptCamelCase) {
          value = this[StringUtils.snakeToCamel(key, capitalizeFirst: false)];
        }
      }
      if (value == null) {
        if (JsonParser._isNull<VV>()) return parse(null as VV);
        if (JsonParser._isNull<T>()) return null as T;
        if (onMissing != null) return onMissing();
        if (!containsKey(key)) throw JsonParserError("Missing key: '$key'.");
        throw JsonParserError("Null value for key: '$key'.");
      }
      return JsonParser.valueTo(
        value: value,
        parse: parse,
        allowHex: allowHex,
        asBytes: asBytes,
        encoding: encoding,
      );
    } on JsonParserError catch (e) {
      if (onError != null) return onError(e);
      rethrow;
    }
  }
}

extension ExtCaseInsensitiveMapExtension<V> on Map<String, V> {
  bool hasValueForKeyIgnoreCase(String key) {
    final normalizedKey = key.toLowerCase();

    final matchKey = keys.firstWhereNullable(
      (k) => k.toLowerCase() == normalizedKey,
    );

    if (matchKey == null) return false;

    return this[matchKey] != null;
  }
}
