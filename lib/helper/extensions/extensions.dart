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
  List<T> exceptedLen(int len, {String? message}) {
    if (length != len) {
      throw ArgumentException(message ?? 'Invalid length. ',
          details: {"excepted": len, "length": length});
    }
    return this;
  }
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
}

extension BigIntHelper on BigInt {
  BigInt get asUint64 {
    if (isNegative || this > maxU64) {
      throw ArgumentException("Invalid Unsigned BigInt 64.", details: {
        "excepted": maxU64.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  BigInt get asInt64 {
    if (this > maxInt64 || this < minInt64) {
      throw ArgumentException("Invalid Signed BigInt 64.", details: {
        "excepted": maxU64.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }
}

extension IntHelper on int {
  int get asInt32 {
    if (this > maxInt32 || this < minInt32) {
      throw ArgumentException("Invalid Signed int 32.", details: {
        "excepted": mask32.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  int get asUint32 {
    if (isNegative || this > maxUint32) {
      throw ArgumentException("Invalid Unsigned int 32.", details: {
        "excepted": mask32.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }

  int get asUint8 {
    if (isNegative || this > mask8) {
      throw ArgumentException("Invalid Unsigned int 8.", details: {
        "excepted": mask32.bitLength,
        "bitLength": bitLength,
        "value": toString()
      });
    }
    return this;
  }
}
