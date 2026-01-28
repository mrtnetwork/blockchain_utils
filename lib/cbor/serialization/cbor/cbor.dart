import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

typedef CborKeyMapper<K> = K Function(CborObject);

/// Mixin for classes that can be serialized to CBOR.
abstract mixin class CborSerializable<T extends CborObject> {
  /// Convert this object to its CBOR representation.
  T toCbor();

  /// Convert a list of dynamic Dart values to a definite CBOR list.
  static CborListValue listFromDynamic(List<dynamic> items) {
    return CborListValue.definite(
      items.map((e) => CborObject.fromDynamic(e)).toList(),
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
        throw CborSerializableException.incorrectTagValue;
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

extension CborMapExtensions on CborMapValue {
  /// Convert this CBOR map to a Dart Map<[K], [V]> by mapping keys and values.
  ///
  /// [keyMapper]   → transforms each CBOR key to `K`
  /// [valueMapper] → transforms each CBOR value to `V`
  Map<K, V> toDartMap<K, V>(
    CborKeyMapper<K> keyMapper,
    CborKeyMapper<V> valueMapper,
  ) {
    final entries = value.entries.map(
      (e) => MapEntry<K, V>(keyMapper(e.key), valueMapper(e.value)),
    );
    return Map<K, V>.fromEntries(entries);
  }
}

extension CborListExtensions on CborListValue {
  /// Checks whether the element at [index] is of type [T].
  bool isTypeAt<T extends CborObject>(int index) {
    if (index >= value.length) {
      return null is T;
    }
    return value[index] is T;
  }

  /// Returns element at [index] as a list of [T].
  /// If [emptyOnNull] is true and index is out of bounds → returns `[]`.
  List<T> listAt<T extends CborObject>(int index, {bool emptyOnNull = false}) {
    if (emptyOnNull && index >= value.length) {
      return <T>[];
    }
    try {
      final CborListValue list = value[index] as CborListValue;
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
      final CborMapValue mapValue = value[index] as CborMapValue;
      return mapValue.value.cast<K, V>();
    } catch (_) {
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
      final CborObject obj = value[index];
      if (null is T && obj == const CborNullValue()) {
        return null as T;
      }
      return obj.value as T;
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
      final CborObject obj = value[index];
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
    final CborObject obj = value[index];
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
      final CborObject obj = value[index];
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
}

extension CborTagExtensions on CborTagValue {
  /// Extract the tag's inner CBOR value as type [T], or throw if mismatched.
  T asValue<T extends CborObject>() {
    if (value is! T) {
      throw CborSerializableException.castingFailed<T>(value);
    }
    return value as T;
  }
}
