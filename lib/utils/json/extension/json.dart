import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';

class JsonParser {
  static bool _isNull<T extends Object?>() {
    if (null is T) return true;
    return false;
  }

  static bool _isDynamic<T extends Object?>() {
    return Object is T;
  }

  static bool _isDouble<T extends Object?>() {
    return 3.14 is T;
  }

  static bool _isString<T extends Object?>() {
    return '' is T;
  }

  static bool _isInt<T extends Object?>() {
    return 0 is T;
  }

  static bool _isBigInt<T extends Object?>() {
    return BigInt.zero is T;
  }

  static bool _isBool<T extends Object?>() {
    return true is T;
  }

  static bool _isList<T extends Object?>() {
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

  static bool _isMap<T extends Object?>() {
    return <dynamic, dynamic>{} is T;
  }

  static bool _isMapStringDynamic<T extends Object?>() {
    return <String, dynamic>{} is T;
  }

  static bool _isListOfMap<T extends Object?>() {
    return <Map<dynamic, dynamic>>[] is T;
  }

  static bool _isListOfMapStringDynamic<T extends Object?>() {
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

  static T valueAsBigInt<T extends BigInt?>(Object? value,
      {bool allowHex = false}) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;
    final toBigint = BigintUtils.tryParse(value, allowHex: allowHex);
    if (toBigint == null) {
      throw JSONHelperException("Failed to parse value as bigint.");
    }
    return toBigint as T;
  }

  static T valueAsInt<T extends int?>(Object? value,
      {bool allowHex = false, bool allowDouble = false}) {
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
      throw JSONHelperException("Failed to parse value as int.",
          details: {"value": value});
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
    throw JSONHelperException("Failed to parse value as double.");
  }

  static T valueAsString<T extends String?>(Object? value) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    if (value is! String) {
      throw JSONHelperException("Failed to parse value as string.");
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

    throw JSONHelperException("Failed to parse value as boolean.");
  }

  static T valueAsBytes<T extends List<int>?>(Object? value,
      {bool allowHex = true, StringEncoding? encoding}) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;
    if (value is List) {
      try {
        return value.cast<int>().asBytes as T;
      } catch (_) {
        throw JSONHelperException("Failed to parse value as List of int.");
      }
    }

    if (value is String) {
      if (allowHex) {
        final toBytes = BytesUtils.tryFromHexString(value);
        if (toBytes != null) return toBytes as T;
      }
      if (encoding != null) {
        final toBytes = StringUtils.tryEncode(value, type: encoding);

        if (toBytes != null) return toBytes as T;
        throw JSONHelperException("Failed to parse value as List of int.");
      }
    }

    throw JSONHelperException("Failed to parse value as List of int.");
  }

  static T valueAsMap<T extends Map?>(Object? value) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    if (!_isMap<T>()) {
      if (_isMapStringDynamic<T>()) {
        return valueEnsureAsMap<String, dynamic>(value) as T;
      }
      if (_isMapStringString<T>()) {
        return valueEnsureAsMap<String, String>(value) as T;
      }
    }
    throw JSONHelperException("Failed to parse value as map.");
  }

  static T valueAsList<T extends List?>(Object? value) {
    if (value is T) return value;
    if (value == null && _isNull<T>()) return null as T;

    if (!_isList<T>()) {
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
      } else if (_isListOfMapStringDynamic<T>()) {
        return valueEnsureAsList<Map<String, dynamic>>(value) as T;
      } else if (_isListOfMapStringString<T>()) {
        return valueEnsureAsList<Map<String, String>>(value) as T;
      }
    }
    throw JSONHelperException("Failed to parse value as map.");
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
    throw JSONHelperException("Failed to parse value as set.");
  }

  static Map<KK, VV> valueEnsureAsMap<KK, VV>(Object? value) {
    if (value is Map<KK, VV>) return value;
    try {
      return Map<KK, VV>.from(value as Map);
    } catch (_) {
      throw JSONHelperException("Failed to parse value as map.");
    }
  }

  static List<T> valueEnsureAsList<T>(Object? value) {
    if (value is List<T>) return value;
    try {
      final valueList = value as List;
      if (!_isDynamic<T>()) {
        if (_isMap<T>()) {
          return valueList
              .map((e) {
                if (e is T) return e;
                return Map.from(e);
              })
              .toList()
              .cast<T>();
        }
        if (_isMapStringDynamic<T>()) {
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
      }
      return List<T>.from(value);
    } catch (_) {
      throw JSONHelperException("Failed to parse object as list<$T>");
    }
  }

  static Set<T> valueEnsureAsSet<T>(Object? value) {
    if (value is Set<T>) return value;
    try {
      return Set<T>.from(value as Iterable);
    } catch (_) {
      throw JSONHelperException("Failed to parse object as set<$T>");
    }
  }

  static T valueAs<T extends Object?>(Object? value,
      {bool? allowHex, StringEncoding? encoding, bool asBytes = false}) {
    assert((allowHex == null && encoding == null) || asBytes,
        "allowHex and encoding must be use with asBytes");
    if (value is T) {
      return value;
    }
    if (value == null) {
      if (_isNull<T>()) return null as T;
    }

    if (value == null) {
      throw JSONHelperException("Failed to parse value as $T");
    }
    if (value is T) return value as T;
    if (_isDynamic<T>()) {
      return value as T;
    } else if (_isDouble<T>()) {
      return valueAsDouble<double>(value) as T;
    } else if (_isString<T>()) {
      return valueAsString<String>(value) as T;
    } else if (_isInt<T>()) {
      return valueAsInt<int>(value) as T;
    } else if (_isBigInt<T>()) {
      return valueAsBigInt<BigInt>(value) as T;
    } else if (_isBool<T>()) {
      return valueAsBool<bool>(value) as T;
    } else if (_isMap<T>()) {
      return valueAsMap<Map<dynamic, dynamic>>(value) as T;
    } else if (_isMapStringDynamic<T>()) {
      return valueAsMap<Map<String, dynamic>>(value) as T;
    } else if (_isMapStringString<T>()) {
      return valueAsMap<Map<String, String>>(value) as T;
    } else if (_isList<T>()) {
      return valueAsList<List>(value) as T;
    } else if (_isListString<T>()) {
      return valueAsList<List<String>>(value) as T;
    } else if (_isListInt<T>()) {
      if (asBytes) {
        return valueAsBytes<List<int>>(value,
            allowHex: allowHex ?? true, encoding: encoding) as T;
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
    } else if (_isListOfMapStringDynamic<T>()) {
      return valueAsList<List<Map<String, dynamic>>>(value) as T;
    } else if (_isListOfMapStringString<T>()) {
      return valueAsList<List<Map<String, String>>>(value) as T;
    }

    throw JSONHelperException("Failed to parse object as $T");
  }

  static T valueTo<T extends Object?, VV extends Object?>(
      {required Object? value,
      required T Function(VV v) parse,
      bool? allowHex,
      StringEncoding? encoding,
      bool asBytes = false}) {
    if (value == null) {
      if (_isNull<VV>()) return parse(null as VV);
      if (_isNull<T>()) return null as T;
    }
    final VV r = valueAs<VV>(value,
        allowHex: allowHex, encoding: encoding, asBytes: asBytes);
    return parse(r);
  }
}

extension JSONHelper<K, V> on Map<K, V> {
  Object? _checkItem<T extends Object?>(K key) {
    final value = this[key];
    if (value != null) return value;
    if (JsonParser._isNull<T>()) return value;
    if (!containsKey(key)) throw JSONHelperException("Missing key: '$key'.");
    throw JSONHelperException("Null value for key: '$key'.");
  }

  void ensureKeyExists(K key) {
    if (containsKey(key)) return;
    throw JSONHelperException("Missing key: '$key'.");
  }

  T valueAsBigInt<T extends BigInt?>(K key, {bool allowHex = false}) {
    final value = _checkItem<T>(key);
    if (value == null) return value as T;
    return JsonParser.valueAsBigInt<T>(value, allowHex: allowHex);
  }

  T valueAsInt<T extends int?>(K key,
      {bool allowHex = false, bool allowDouble = false}) {
    final value = _checkItem<T>(key);
    if (value == null) return value as T;
    return JsonParser.valueAsInt<T>(value,
        allowDouble: allowDouble, allowHex: allowHex);
  }

  T valueAsDouble<T extends double?>(K key) {
    final value = _checkItem<T>(key);
    if (value == null) return value as T;
    return JsonParser.valueAsDouble<T>(value);
  }

  T valueAsString<T extends String?>(K key) {
    final value = _checkItem<T>(key);
    if (value == null) return value as T;
    return JsonParser.valueAsString<T>(value);
  }

  T valueAsBool<T extends bool?>(K key) {
    final value = _checkItem<T>(key);
    if (value == null) return value as T;
    return JsonParser.valueAsBool<T>(value);
  }

  T valueAsBytes<T extends List<int>?>(K key,
      {bool allowHex = true, StringEncoding? encoding}) {
    final value = _checkItem<T>(key);
    if (value == null) return value as T;
    return JsonParser.valueAsBytes<T>(value,
        allowHex: allowHex, encoding: encoding);
  }

  T valueAsMap<T extends Map?>(K key) {
    final value = _checkItem<T>(key);
    if (value == null) return value as T;
    return JsonParser.valueAsMap<T>(value);
  }

  T valueAsList<T extends List?>(K key) {
    final value = _checkItem<T>(key);
    if (value == null) return value as T;
    return JsonParser.valueAsList<T>(value);
  }

  T valueAsSet<T extends Set?>(K key) {
    final value = _checkItem<T>(key);
    if (value == null) return value as T;
    return JsonParser.valueAsSet<T>(value);
  }

  Map<KK, VV> valueEnsureAsMap<KK, VV>(K key) {
    final value = _checkItem<Map>(key);
    return JsonParser.valueEnsureAsMap<KK, VV>(value);
  }

  List<T> valueEnsureAsList<T>(K key) {
    final value = _checkItem<List>(key);
    return JsonParser.valueEnsureAsList<T>(value);
  }

  Set<T> valueEnsureAsSet<T>(K key) {
    final value = _checkItem<Set>(key);
    return JsonParser.valueEnsureAsSet<T>(value);
  }

  T valueAs<T extends Object?>(K key,
      {bool? allowHex, StringEncoding? encoding, bool asBytes = false}) {
    assert((allowHex == null && encoding == null) || asBytes,
        "allowHex and encoding must be use with asBytes");
    final value = _checkItem<T>(key);
    if (value == null) return null as T;
    return JsonParser.valueAs(value,
        allowHex: allowHex, asBytes: asBytes, encoding: encoding);
  }

  T valueTo<T extends Object?, VV extends Object?>(
      {required K key,
      required T Function(VV v) parse,
      bool? allowHex,
      StringEncoding? encoding,
      bool asBytes = false}) {
    final value = this[key];
    if (value == null) {
      if (JsonParser._isNull<VV>()) return parse(null as VV);
      if (JsonParser._isNull<T>()) return null as T;
    }
    ensureKeyExists(key);
    return JsonParser.valueTo(
        value: value,
        parse: parse,
        allowHex: allowHex,
        asBytes: asBytes,
        encoding: encoding);
  }
}
