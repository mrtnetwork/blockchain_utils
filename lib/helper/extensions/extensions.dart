import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/utils.dart';

typedef ItrableCondition<T> = bool Function(T);

extension SetHelper<T> on Set<T> {
  Set<T> get immutable => Set<T>.unmodifiable(this);
  Set<T> clone({bool immutable = false}) {
    if (immutable) return this.immutable;
    return Set<T>.from(this);
  }
}

extension IterableHelper<T> on Iterable<T> {
  Set<T> get toImutableSet => Set<T>.unmodifiable(this);
  List<T> get toImutableList => List<T>.unmodifiable(this);
  T? firstWhereNullable(bool Function(T) test, {T Function()? orElse}) {
    try {
      return firstWhere(test);
    } on StateError {
      return null;
    }
  }
}

extension ListHelper<T> on List<T> {
  List<T> get immutable => List<T>.unmodifiable(this);
  List<T> clone({bool immutable = false}) {
    if (immutable) return this.immutable;
    return List<T>.from(this);
  }

  List<T>? get emptyAsNull => isEmpty ? null : this;
  List<T> max(int length, {String? name}) {
    if (this.length > length) {
      throw ArgumentException(
          "Incorrect ${name == null ? '' : '$name '}array length.",
          details: {'maximum': length, 'length': this.length});
    }
    return this;
  }

  List<T> min(int length, {String? name}) {
    if (this.length < length) {
      throw ArgumentException(
          "Incorrect ${name == null ? '' : '$name '}array length.",
          details: {'minimum': length, 'length': this.length});
    }
    return this;
  }

  List<T> exc(int length, {String? name}) {
    if (this.length != length) {
      throw ArgumentException(
          "Incorrect ${name == null ? '' : '$name '}array length.",
          details: {'expected': length, 'length': this.length});
    }
    return this;
  }
  // List<T> exceptedLen(int len, {String? message}) {
  //   if (length != len) {
  //     throw ArgumentException(message ?? 'List length mismatch. ',
  //         details: {"expected": len, "actual": length});
  //   }
  //   return this;
  // }

  // List<T> max(int len, {String? message}) {
  //   if (length > len) {
  //     throw ArgumentException(message ?? 'List too long.',
  //         details: {"max": len, "actual": length});
  //   }
  //   return this;
  // }
}

extension IterableIntHelper on Iterable<int> {
  List<int> get immutable => List<int>.unmodifiable(this);

  List<int> get asImmutableBytes {
    BytesUtils.validateBytes(this);
    return immutable;
  }

  List<int> get toImutableBytes {
    return BytesUtils.toBytes(this, unmodifiable: true);
  }

  List<int> get toBytes {
    return BytesUtils.toBytes(this);
  }
}

extension ListIntHelper on List<int> {
  List<int> get asBytes {
    BytesUtils.validateListOfBytes(this);
    return this;
  }

  List<int> get asImmutableBytes {
    BytesUtils.validateListOfBytes(this);
    return immutable;
  }

  List<int> get toImutableBytes {
    return BytesUtils.toBytes(this, unmodifiable: true);
  }

  List<int> get toBytes {
    return BytesUtils.toBytes(this);
  }
}

extension MapHelper<K, V> on Map<K, V> {
  Map<K, V> get immutable => Map<K, V>.unmodifiable(this);
  Map<K, V> clone({bool immutable = false}) {
    if (immutable) return this.immutable;
    return Map<K, V>.from(this);
  }

  Map<K, V> get notNullValue => clone()..removeWhere((k, v) => v == null);
}

extension BigIntHelper on BigInt {
  BigInt get asUint256 {
    if (isNegative || this > maxU256) {
      throw ArgumentException("Invalid Unsigned BigInt 256.", details: {
        "expected": maxU256.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  BigInt get asUint128 {
    if (isNegative || this > maxU128) {
      throw ArgumentException("Invalid Unsigned BigInt 128.", details: {
        "expected": maxU128.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  BigInt get asUint64 {
    if (isNegative || this > maxU64) {
      throw ArgumentException("Invalid Unsigned BigInt 64.", details: {
        "expected": maxU64.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  BigInt get asInt64 {
    if (this > maxInt64 || this < minInt64) {
      throw ArgumentException("Invalid Signed BigInt 64.", details: {
        "expected": maxU64.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  int get toSignedInt32 => toSigned(32).toInt();
  int get toUnSignedInt32 => toUnsigned(32).toInt();
  int get toUnsignedInt8 => toUnsigned(8).toInt();
  BigInt get toUnsigned64 => toUnsigned(64);
  BigInt get toUnsigned128 => toUnsigned(128);
  BigInt get toSigned128 => toSigned(128);
  BigInt get toSigned64 => toSigned(64);
  bool get toBool {
    // assert(this == BigInt.one || this == BigInt.zero);
    return this == BigInt.zero ? false : true;
  }
}

extension IntHelper on int {
  int get asInt32 {
    if (this > maxInt32 || this < minInt32) {
      throw ArgumentException("Invalid Signed int 32.", details: {
        "expected": mask32.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  int get asUint32 {
    if (isNegative || this > maxUint32) {
      throw ArgumentException("Invalid Unsigned int 32.", details: {
        "expected": mask32.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  int get asUint8 {
    if (isNegative || this > mask8) {
      throw ArgumentException("Invalid Unsigned int 8.", details: {
        "expected": mask32.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  int get asUint16 {
    if (isNegative || this > mask16) {
      throw ArgumentException("Invalid Unsigned int 16.", details: {
        "expected": mask16.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  BigInt get toBigInt => BigInt.from(this);
  BigInt get toUnsignedBigInt64 => BigInt.from(this).toUnsigned64;
  int get toSigned32 => toSigned(32);
  int get toUnSigned32 => toUnsigned(32);
  bool get toBool {
    // assert(this == 0 || this == 1);
    return this == 0 ? false : true;
  }
}

extension BoolHelper on bool {
  BigInt get toBigInt => this ? BigInt.one : BigInt.zero;
  int get toInt => this ? 1 : 0;
}
