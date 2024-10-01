import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';

extension ListHelper<T> on List<T> {
  List<T> get immutable => List<T>.unmodifiable(this);
  List<T> clone({bool immutable = false}) {
    if (immutable) return this.immutable;
    return List<T>.from(this);
  }

  List<T>? get emptyAsNull => isEmpty ? null : this;
}

extension ListIntHelper on List<int> {
  List<int> get asBytes {
    BytesUtils.validateBytes(this);
    return this;
  }

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
}
