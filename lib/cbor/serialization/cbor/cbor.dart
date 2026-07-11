import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';

typedef CbCborKeyMapper<K> = K Function(CborObject);

/// Mixin for classes that can be serialized to CBOR.
abstract mixin class CborSerializable<T extends CborObject> {
  /// Convert this object to its CBOR representation.
  T toCbor();

  /// Convert a list of dynamic Dart values to a definite CBOR list.
  static CborListValue listFromObjects(List<CborObject?> items) {
    return CborListValue.definite(
      items.map((e) => e ?? CborNullValue()).toList(),
    );
  }

  /// Convert any supported Dart value (int, BigInt, bytes, etc.) to a CBOR object.
  static T objectFromDynamic<T extends CborObject>(Object? value) {
    return CborObject.fromDynamic(value).cast<T>();
  }

  /// Decode or extract a CBOR tag, returning its inner value as [T].
  ///
  /// Provide one of:
  /// - [cborBytes]: raw CBOR bytes
  /// - [cborObject]: an existing CBOR object
  /// - [cborHex]: CBOR data encoded as a hex string
  ///
  /// Optionally, restrict to specific tag IDs via [tagIds].
  static T decodeTaggedValue<T extends CborObject>({
    List<int>? cborBytes,
    CborObject? cborObject,
    String? cborHex,
    List<int>? tagIds,
    bool Function(List<int> tags)? onValidateTags,
  }) {
    assert(
      cborBytes != null || cborObject != null || cborHex != null,
      "Either cborBytes, cborHex or cborObject must be provided",
    );

    if (cborObject == null) {
      cborBytes ??= BytesUtils.tryFromHexString(cborHex);
      if (cborBytes == null) {
        throw CborSerializableException.missingArguments;
      }

      try {
        cborObject = CborObject.fromCbor(cborBytes);
      } catch (_) {
        throw CborSerializableException.invalidCborEncodingBytes;
      }
    }

    try {
      final tag = cborObject.cast<CborTagValue>();
      if (tagIds != null && !BytesUtils.bytesEqual(tag.tags, tagIds)) {
        throw CborSerializableException.incorrectTagValue(tag: tag.tags);
      }
      if (onValidateTags != null && !onValidateTags(tag.tags)) {
        throw CborSerializableException.incorrectTagValue(tag: tag.tags);
      }
      return tag.asValue<T>();
    } on CborSerializableException {
      rethrow;
    } catch (_) {
      throw CborSerializableException.castingFailed<CborTagValue>(cborObject);
    }
  }

  /// Decode raw CBOR data and return it as [T].
  ///
  /// Accepts:
  /// - [cborBytes]: CBOR bytes
  /// - [cborObject]: existing CBOR object
  /// - [cborHex]: CBOR data encoded as hex string
  static T decode<T extends CborObject>({
    List<int>? cborBytes,
    CborObject? cborObject,
    String? cborHex,
  }) {
    assert(
      cborBytes != null || cborObject != null || cborHex != null,
      "Either cborBytes, cborHex or cborObject must be provided",
    );

    if (cborObject == null) {
      cborBytes ??= BytesUtils.tryFromHexString(cborHex);
      if (cborBytes == null) {
        throw CborSerializableException.missingArguments;
      }

      try {
        cborObject = CborObject.fromCbor(cborBytes);
      } catch (_) {
        throw CborSerializableException.invalidCborEncodingBytes;
      }
    }

    if (cborObject is! T) {
      throw CborSerializableException.castingFailed<T>(cborObject);
    }

    return cborObject;
  }
}

extension ExtCborMapExtensions on CborMapValue {
  T getIntKeyAs<T extends CborObject?>(int key) {
    final val = value[CborIntValue(key)];
    if (val == null && null is T) return null as T;
    if (null is T && val is CborNullValue) return null as T;
    if (val is! T) {
      throw CborSerializableException.castingFailed<T>(value);
    }
    return val;
  }

  /// Convert this CBOR map to a Dart Map<[K], [V]> by mapping keys and values.
  ///
  /// [keyMapper]   → transforms each CBOR key to `K`
  /// [valueMapper] → transforms each CBOR value to `V`
  Map<K, V> toDartMap<K, V>(
    CbCborKeyMapper<K> keyMapper,
    CbCborKeyMapper<V> valueMapper,
  ) {
    final entries = value.entries.map((e) {
      return MapEntry<K, V>(keyMapper(e.key), valueMapper(e.value));
    });
    return Map<K, V>.fromEntries(entries);
  }

  Map<T, E> asMap<T extends CborObject, E extends CborObject>([String? name]) {
    try {
      return JsonParser.valueEnsureAsMap<T, E>(value);
    } catch (_) {
      throw CborSerializableException.castingFailed<Map<T, E>>(
        value,
        operation: name,
      );
    }
  }
}

extension ExtCborListExtensions on CborIterableObject {
  /// Checks whether the element at [index] is of type [T].
  bool isTypeAt<T extends CborObject>(int index) {
    if (index >= value.length) {
      return null is T;
    }
    return value.elementAt(index) is T;
  }

  /// Returns element at [index] as a list of [T].
  /// If [emptyOnNull] is true and index is out of bounds → returns `[]`.
  List<T> listAt<T extends CborObject?>(int index, {bool emptyOnNull = false}) {
    if (emptyOnNull &&
        (index >= value.length || value.elementAt(index) is CborNullValue)) {
      return <T>[];
    }
    try {
      final list = value.elementAt(index).cast<CborListValue>();

      return list.value.cast<T>();
    } catch (_) {
      throw CborSerializableException.castingFailed<T>(
        value.elementAtOrNull(index)?.value,
      );
    }
  }

  /// Returns element at [index] as a typed map.
  Map<K, V> mapAt<K extends CborObject, V extends CborObject>(int index) {
    try {
      final CborMapValue mapValue = value.elementAt(index) as CborMapValue;
      return mapValue.value.cast<K, V>();
    } catch (_) {
      throw CborSerializableException.castingFailed<Map<K, V>>(
        value.elementAtOrNull(index),
      );
    }
  }

  Map<K, V> rawMapAt<K, V>(int index) {
    try {
      final CborMapValue mapValue = objectAt(index);
      return mapValue.toDartMap<K, V>(JsonParser.valueAs, JsonParser.valueAs);
    } catch (e) {
      throw CborSerializableException.castingFailed<Map<K, V>>(
        value.elementAtOrNull(index),
      );
    }
  }

  Map<K, V>? maybeRawMapAt<K, V>(int index) {
    try {
      final CborMapValue? mapValue = objectAt(index);
      if (mapValue == null) return null;
      return mapValue.toDartMap<K, V>(
        (e) => JsonParser.valueAs<K>(e.getValue()),
        (e) => JsonParser.valueAs<V>(e.getValue()),
      );
    } catch (s) {
      throw CborSerializableException.castingFailed<Map<K, V>>(
        value.elementAtOrNull(index),
      );
    }
  }

  /// Returns `true` if [index] is valid (within list bounds).
  bool hasIndex(int index) => index < value.length;

  /// Returns the raw underlying Dart value at [index] as type [T].
  T rawValueAt<T extends Object?>(int index) {
    if (!hasIndex(index)) {
      if (null is T) return null as T;
      throw CborSerializableException.missingListElement;
    }
    try {
      final CborObject obj = value.elementAt(index);
      if (null is T && obj == const CborNullValue()) {
        return null as T;
      }
      return JsonParser.valueAs<T>(obj.value);
    } catch (_) {
      throw CborSerializableException.castingFailed<T>(
        value.elementAtOrNull(index)?.value,
      );
    }
  }

  /// Returns the CBOR object at [index] as type [T].
  T objectAt<T extends CborObject?>(int index) {
    if (!hasIndex(index)) {
      if (null is T) return null as T;
      throw CborSerializableException.missingListElement;
    }
    try {
      final CborObject obj = value.elementAt(index);
      if (null is T && obj == const CborNullValue()) {
        return null as T;
      }
      return obj as T;
    } catch (_) {
      throw CborSerializableException.castingFailed<T>(
        value.elementAtOrNull(index)?.value,
      );
    }
  }

  /// Attempt to transform the CBOR object at [index] using [mapper] if it's type [T], or return null.
  E? maybeObjectAt<E, T extends CborObject>(int index, E Function(T e) mapper) {
    if (!hasIndex(index)) return null;
    final CborObject obj = value.elementAt(index);
    if (obj == const CborNullValue()) return null;
    if (obj is T) return mapper(obj);
    throw CborSerializableException.castingFailed<T>(
      value.elementAtOrNull(index),
    );
  }

  /// Attempt to transform the raw value at [index] using [mapper], or return null.
  E? maybeRawValueAt<E, T>(int index, E Function(T v) mapper) {
    if (!hasIndex(index)) return null;
    try {
      final CborObject obj = value.elementAt(index);
      if (obj == const CborNullValue()) return null;
      return mapper(obj.value as T);
    } catch (_) {
      throw CborSerializableException.castingFailed<T>(
        value.elementAtOrNull(index),
      );
    }
  }

  /// Return all raw values as a List<[T]>.
  List<T> allRawValuesAs<T>() => [
    for (var i = 0; i < value.length; i++) rawValueAt<T>(i),
  ];

  /// Return all CBOR objects as a List<[T]>.
  List<T> allObjectsAs<T extends CborObject>() => [
    for (var i = 0; i < value.length; i++) objectAt<T>(i),
  ];

  CborListValue<T> sublist<T extends CborObject>(int start, [int? end]) {
    if (start >= value.length || (end != null && end >= value.length)) {
      throw CborSerializableException(
        'Index out of bounds.',
        details: {
          'length': value.length.toString(),
          'Start': start.toString(),
          'End': end.toString(),
        },
      );
    }
    final values = allObjectsAs<T>();
    return CborListValue.definite(values.sublist(start, end).toList());
  }
}

extension ExtCborTagExtensions on CborTagValue {
  /// Extract the tag's inner CBOR value as type [T], or throw if mismatched.
  T asValue<T extends CborObject>({String? operation}) {
    if (value is! T) {
      throw CborSerializableException.castingFailed<T>(
        value,
        operation: operation,
      );
    }
    return value as T;
  }
}

extension ExtCborHelper on CborObject {
  /// Checks whether the value stored in the [CborObject] has the specified type [T].
  bool hasType<T>() {
    return this is T;
  }

  T as<T extends CborObject>({String? operation}) {
    if (this is! T) {
      throw CborSerializableException.castingFailed<T>(
        value,
        operation: operation,
      );
    }
    return this as T;
  }

  E objectTo<E, T extends CborObject>(E Function(T e) toe) {
    return toe(as<T>());
  }
}
