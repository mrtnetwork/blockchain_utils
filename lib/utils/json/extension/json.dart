import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';

extension JSONHelper<K, V> on Map<K, V> {
  void ensureKeyExists(K key) {
    if (containsKey(key)) return;
    throw JSONHelperException("Missing key: '$key'.");
  }

  bool _isNull<T extends Object?>() {
    if (null is T) return true;
    return false;
  }

  bool _isDynamic<T extends Object?>() {
    return Object is T;
  }

  bool _isBigInt<T extends Object?>() {
    return BigInt.zero is T;
  }

  bool _isBool<T extends Object?>() {
    return true is T;
  }

  bool _isInt<T extends Object?>() {
    return 0 is T;
  }

  bool _isListInt<T extends Object?>() {
    return <int>[] is T;
  }

  bool _isList<T extends Object?>() {
    return <dynamic>[] is T;
  }

  bool _isListString<T extends Object?>() {
    return <String>[] is T;
  }

  bool _isListOfMapStringDynamic<T extends Object?>() {
    return <Map<String, dynamic>>[] is T;
  }

  bool _isListOfMapStringString<T extends Object?>() {
    return <Map<String, String>>[] is T;
  }

  bool _isString<T extends Object?>() {
    return '' is T;
  }

  bool _isDouble<T extends Object?>() {
    return 0.0 is T;
  }

  bool _isMap<T extends Object?>() {
    return <dynamic, dynamic>{} is T;
  }

  bool _isMapStringDynamic<T extends Object?>() {
    return <String, dynamic>{} is T;
  }

  bool _isMapStringString<T extends Object?>() {
    return <String, String>{} is T;
  }

  //
  bool _isSet<T extends Object?>() {
    return <dynamic>{} is T;
  }

  bool _isSetInt<T extends Object?>() {
    return <int>{} is T;
  }

  bool _isSetString<T extends Object?>() {
    return <String>{} is T;
  }

  T valueAsBigInt<T extends BigInt?>(K key, {bool allowHex = false}) {
    final value = this[key];
    if (value == null && _isNull<T>()) return null as T;
    if (value is T) return value as T;
    ensureKeyExists(key);
    final toBigint = BigintUtils.tryParse(value, allowHex: allowHex);
    if (toBigint == null) {
      throw JSONHelperException("Key '$key' has invalid BigInt value.");
    }
    return toBigint as T;
  }

  T valueAsInt<T extends int?>(K key,
      {bool allowHex = false, bool allowDouble = false}) {
    final value = this[key];
    if (value == null && _isNull<T>()) return null as T;
    if (value is T) return value as T;
    ensureKeyExists(key);
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
      throw JSONHelperException("Key '$key' has invalid int value.");
    }
    return toInt as T;
  }

  T valueAsDouble<T extends double?>(K key) {
    final value = this[key];
    if (value == null && _isNull<T>()) return null as T;
    if (value is T) return value as T;
    ensureKeyExists(key);

    if (value is num) {
      return value.toDouble() as T;
    }

    if (value is String) {
      final v = double.tryParse(value);
      if (v != null) return v as T;
    }
    throw JSONHelperException("Key '$key' has invalid double value.");
  }

  T valueAsString<T extends String?>(K key) {
    final value = this[key];
    if (value == null && _isNull<T>()) return null as T;
    if (value is T) return value as T;
    ensureKeyExists(key);
    if (value is! String) {
      throw JSONHelperException("Key '$key' has invalid string value.");
    }
    return value as T;
  }

  T valueAsBool<T extends bool?>(K key) {
    final value = this[key];
    if (value == null && _isNull<T>()) return null as T;
    if (value is T) return value as T;
    ensureKeyExists(key);

    if (value is bool) return value as T;

    if (value is String) {
      final boolStr = value.toLowerCase();
      if (boolStr == 'true') return true as T;
      if (boolStr == 'false') return false as T;
    }

    throw JSONHelperException("Key '$key' has invalid bool value.");
  }

  T valueAsBytes<T extends List<int>?>(K key,
      {bool allowHex = true, StringEncoding? encoding}) {
    final value = this[key];
    if (value == null && _isNull<T>()) return null as T;
    ensureKeyExists(key);
    if (value is List) {
      try {
        return value.cast<int>().asBytes as T;
      } catch (_) {
        throw JSONHelperException("Key '$key' has invalid bytes value.");
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
        throw JSONHelperException(
            "Key '$key' has invalid ${encoding.name} value.");
      }
    }

    throw JSONHelperException("Key '$key' has invalid bytes value.");
  }

  T valueAsMap<T extends Map?>(K key) {
    final value = this[key];
    if (value == null && _isNull<T>()) return null as T;
    if (value is T) return value as T;
    ensureKeyExists(key);
    if (value is T) return value;

    if (!_isMap<T>()) {
      if (_isMapStringDynamic<T>()) {
        return valueEnsureAsMap<String, dynamic>(key) as T;
      }
      if (_isMapStringString<T>()) {
        return valueEnsureAsMap<String, String>(key) as T;
      }
    }
    throw JSONHelperException("Key '$key' has invalid map value.");
  }

  T valueAsList<T extends List?>(K key) {
    final value = this[key];
    if (value == null && _isNull<T>()) return null as T;
    if (value is T) return value as T;
    ensureKeyExists(key);
    if (!_isList<T>()) {
      if (_isListString<T>()) {
        return valueEnsureAsList<String>(key) as T;
      }
      if (_isListInt<T>()) {
        return valueEnsureAsList<int>(key) as T;
      }
      if (_isListOfMapStringDynamic<T>()) {
        return valueEnsureAsList<Map<String, dynamic>>(key) as T;
      }
      if (_isListOfMapStringString<T>()) {
        return valueEnsureAsList<Map<String, String>>(key) as T;
      }
    }
    throw JSONHelperException("Key '$key' has invalid list value.");
  }

  T valueAsSet<T extends Set?>(K key) {
    final value = this[key];
    if (value == null && _isNull<T>()) return null as T;
    if (value is T) return value as T;
    ensureKeyExists(key);
    if (!_isSet<T>()) {
      if (_isSetString<T>()) {
        return valueEnsureAsSet<String>(key) as T;
      }
      if (_isSetInt<T>()) {
        return valueEnsureAsSet<int>(key) as T;
      }
    }
    throw JSONHelperException("Key '$key' has invalid list value.");
  }

  Map<KK, VV> valueEnsureAsMap<KK, VV>(K key) {
    ensureKeyExists(key);
    final value = this[key];
    if (value is Map<KK, VV>) return value;
    try {
      return Map<KK, VV>.from(value as Map);
    } catch (_) {
      throw JSONHelperException("Key '$key' has invalid map value.");
    }
  }

  List<T> valueEnsureAsList<T>(K key) {
    ensureKeyExists(key);
    final value = this[key];
    if (value is List<T>) return value;
    try {
      final valueLust = value as List;
      if (!_isDynamic<T>()) {
        if (_isMap<T>()) {
          return valueLust
              .map((e) {
                if (e is T) return e;
                return Map.from(e);
              })
              .toList()
              .cast<T>();
        }
        if (_isMapStringDynamic<T>()) {
          return value
              .map((e) {
                if (e is T) return e;
                return Map<String, dynamic>.from(e);
              })
              .toList()
              .cast<T>();
        }
        if (_isMapStringString<T>()) {
          return value
              .map((e) {
                if (e is T) return e;
                return Map<String, String>.from(e);
              })
              .toList()
              .cast<T>();
        }
      }
      return List<T>.from(value as List);
    } catch (_) {
      throw JSONHelperException("Key '$key' has invalid list value.");
    }
  }

  Set<T> valueEnsureAsSet<T>(K key) {
    ensureKeyExists(key);
    final value = this[key];
    if (value is Set<T>) return value;
    try {
      return Set<T>.from(value as Iterable);
    } catch (_) {
      throw JSONHelperException("Key '$key' has invalid Set value.");
    }
  }

  T valueAs<T extends Object?>(K key,
      {bool? allowHex, StringEncoding? encoding, bool asBytes = false}) {
    assert((allowHex == null && encoding == null) || asBytes,
        "allowHex and encoding must be use with asBytes");
    // ensureKeyExists(key);
    final value = this[key];
    if (value == null) {
      if (_isNull<T>()) return null as T;
    }
    ensureKeyExists(key);
    if (value == null) {
      throw JSONHelperException("Key '$key' has invalid value.");
    }
    if (value is T) return value as T;
    if (_isDynamic<T>()) return value as T;
    if (_isBool<T>()) return valueAsBool<bool>(key) as T;
    if (_isBigInt<T>()) return valueAsBigInt<BigInt>(key) as T;
    if (_isInt<T>()) return valueAsInt<int>(key) as T;
    if (_isList<T>()) return valueAsList<List>(key) as T;
    if (_isListInt<T>()) {
      if (asBytes == true) {
        return valueAsBytes<List<int>>(key,
            allowHex: allowHex ?? true, encoding: encoding) as T;
      }
      return valueAsList<List<int>>(key) as T;
    }
    if (_isListString<T>()) {
      return valueEnsureAsList<String>(key) as T;
    }
    if (_isMap<T>()) {
      return valueAsMap(key) as T;
    }
    if (_isMapStringDynamic<T>()) {
      return valueEnsureAsMap<String, dynamic>(key) as T;
    }
    if (_isMapStringString<T>()) {
      return valueEnsureAsMap<String, String>(key) as T;
    }
    if (_isDouble<T>()) return valueAsDouble<double>(key) as T;
    if (_isString<T>()) return valueAsString<String>(key) as T;

    throw JSONHelperException("Key '$key' has invalid value.");
  }

  T valueTo<T extends Object?, VV extends Object?>(
      {required K key,
      required T Function(VV v) parse,
      bool? allowHex,
      StringEncoding? encoding,
      bool asBytes = false}) {
    // ensureKeyExists(key);
    final value = this[key];
    if (value == null) {
      if (_isNull<VV>()) return parse(null as VV);
      if (_isNull<T>()) return null as T;
    }
    ensureKeyExists(key);
    final VV r = valueAs<VV>(key,
        allowHex: allowHex, encoding: encoding, asBytes: asBytes);
    return parse(r);
  }
}
