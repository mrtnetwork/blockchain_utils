import 'dart:collection' show SplayTreeSet;
import 'dart:typed_data';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

typedef CbItrableCondition<T> = bool Function(T);

extension ExtSetHelper<T> on Set<T> {
  Set<T> get immutable => Set<T>.unmodifiable(this);
  Set<T> clone({bool immutable = false}) {
    if (immutable) return this.immutable;
    return Set<T>.from(this);
  }
}

extension ExtIterableHelper<T> on Iterable<T> {
  Set<T> get toImutableSet => Set<T>.unmodifiable(this);
  List<T> get toImutableList => List<T>.unmodifiable(this);

  T? firstWhereNullable(bool Function(T) test, {T Function()? orElse}) {
    try {
      return firstWhere(test);
    } on StateError {
      if (orElse != null) return orElse();
      return null;
    }
  }

  SplayTreeSet<T> toSplayTreeSet() => SplayTreeSet<T>.from(this);
}

extension ExtListHelper<T> on List<T> {
  List<T> get immutable => List<T>.unmodifiable(this);
  List<T> clone({bool immutable = false}) {
    if (immutable) return this.immutable;
    return List<T>.from(this);
  }

  List<T>? get emptyAsNull => isEmpty ? null : this;
  List<T> max({
    required int length,
    required String operation,
    String? name,
    String? reason,
  }) {
    if (this.length > length) {
      throw ArgumentException.invalidOperationArguments(
        operation,
        name: name,
        reason:
            reason ??
            (name == null
                ? "Invalid array length"
                : "Invalid $name array length."),
      );
    }
    return this;
  }

  List<T> min({
    required int length,
    required String operation,
    String? name,
    String? reason,
    List<T> Function()? onErr,
  }) {
    if (this.length < length) {
      if (onErr != null) return onErr();
      throw ArgumentException.invalidOperationArguments(
        operation,
        name: name,
        reason:
            reason ??
            (name == null
                ? "Invalid array length"
                : "Invalid $name array length."),
      );
    }
    return this;
  }

  List<T> exc({
    required int length,
    required String operation,
    String? name,
    String? reason,
    List<T> Function()? onErr,
  }) {
    if (this.length != length) {
      if (onErr != null) return onErr();
      throw ArgumentException.invalidOperationArguments(
        operation,
        name: name,
        reason:
            reason ??
            (name == null
                ? "Invalid array length"
                : "Invalid $name array length."),
      );
    }
    return this;
  }
}

extension ExtIterableIntHelper on Iterable<int> {
  List<int> get immutable => List<int>.unmodifiable(this);

  List<int> get asImmutableBytes {
    BytesUtils.areBytesValid(this);
    return immutable;
  }

  List<int> get toImutableBytes {
    return BytesUtils.toBytes(this, unmodifiable: true);
  }

  List<int> get toBytes {
    return BytesUtils.toBytes(this);
  }
}

extension ExtListIntHelper on List<int> {
  List<int> get asBytes {
    BytesUtils.areBytesValid(
      this,
      onValidationFailed:
          () =>
              throw ArgumentException.invalidOperationArguments(
                "asBytes",
                reason: "Invalid bytes.",
              ),
    );
    return this;
  }

  List<int> get asImmutableBytes {
    BytesUtils.areBytesValid(
      this,
      onValidationFailed:
          () =>
              throw ArgumentException.invalidOperationArguments(
                "asBytes",
                reason: "Invalid bytes.",
              ),
    );
    return immutable;
  }

  List<int> get asImmutableBytesConst {
    BytesUtils.areBytesValidConst(
      this,
      onValidationFailed:
          () =>
              throw ArgumentException.invalidOperationArguments(
                "asBytes",
                reason: "Invalid bytes.",
              ),
    );
    return immutable;
  }

  List<int> get asBytesConst {
    BytesUtils.areBytesValidConst(
      this,
      onValidationFailed:
          () =>
              throw ArgumentException.invalidOperationArguments(
                "asBytes",
                reason: "Invalid bytes.",
              ),
    );
    return this;
  }

  List<int> get toImutableBytes {
    return BytesUtils.toBytes(this, unmodifiable: true);
  }

  List<int> get toBytes {
    return BytesUtils.toBytes(this);
  }
}

extension ExtMapHelper<K, V> on Map<K, V> {
  Map<K, V> get immutable => Map<K, V>.unmodifiable(this);
  Map<K, V> clone({bool immutable = false}) {
    if (immutable) return this.immutable;
    return Map<K, V>.from(this);
  }

  Map<K, V> get notNullValue => clone()..removeWhere((k, v) => v == null);

  Map<K, V>? get nullOnEmpty => isEmpty ? null : this;
}

extension ExtBigIntHelper on BigInt {
  BigInt get asU256 {
    if (isNegative || this > BinaryOps.maxU256) {
      throw ArgumentException.invalidOperationArguments(
        "asU256",
        reason: "Invalid 256-bit unsigned integer.",
      );
    }
    return this;
  }

  BigInt get asU128 {
    if (isNegative || this > BinaryOps.maxU128) {
      throw ArgumentException.invalidOperationArguments(
        "asU128",
        reason: "Invalid 128-bit unsigned integer.",
      );
    }
    return this;
  }

  BigInt get asU64 {
    if (isNegative || this > BinaryOps.maxU64) {
      throw ArgumentException.invalidOperationArguments(
        "asU64",
        reason: "Invalid 64-bit unsigned integer.",
      );
    }
    return this;
  }

  BigInt get asI64 {
    if (this > BinaryOps.maxInt64 || this < BinaryOps.minInt64) {
      throw ArgumentException.invalidOperationArguments(
        "asI64",
        reason: "Invalid 64-bit signed integer.",
      );
    }
    return this;
  }

  BigInt get asI128 {
    if (this > BinaryOps.maxI128 || this < BinaryOps.minI128) {
      throw ArgumentException.invalidOperationArguments(
        "asI128",
        reason: "Invalid 128-bit signed integer.",
      );
    }
    return this;
  }

  int get toI32 => toSigned(32).toInt();
  int get toU32 => (this & BinaryOps.maskBig32).toInt();
  int get toU8 => (this & BinaryOps.maskBig8).toInt();
  BigInt get toU64 => this & BinaryOps.maskBig64;
  BigInt get toU128 => toUnsigned(128);
  BigInt get toI128 => toSigned(128);
  BigInt get toI64 => toSigned(64);
  int get toIntOrThrow {
    if (isValidInt) return toInt();
    throw ArgumentException.invalidOperationArguments(
      "toInt",
      reason: "Value is too large for type int.",
    );
  }

  int? get toIntOrNull {
    if (isValidInt) return toInt();
    return null;
  }

  List<int> toU64LeBytes() => asU64.toLeBytes(length: 8);
  List<int> toU64BeBytes() => asU64.toBeBytes(length: 8);

  List<int> toU256LeBytes() => asU256.toLeBytes(length: 32);
  List<int> toU256BeBytes() => asU256.toBeBytes(length: 32);

  List<int> toI64LeBytes() => asI64.toLeBytes(length: 8);
  List<int> toI64BeBytes() => asI64.toBeBytes(length: 8);

  List<int> toLeBytes({int? length, bool sign = false}) => BigintUtils.toBytes(
    this,
    length: length,
    byteOrder: Endian.little,
    sign: sign,
  );
  List<int> toBeBytes({int? length}) =>
      BigintUtils.toBytes(this, length: length, byteOrder: Endian.big);
  List<int> toBytes({
    int? length,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) => BigintUtils.toBytes(
    this,
    length: length,
    byteOrder: byteOrder,
    sign: sign,
  );

  bool get toBool {
    return this == BigInt.zero ? false : true;
  }

  BigInt mod(BigInt m) {
    BigInt r = this % m;
    return r.isNegative ? r + m : r;
  }

  BigInt modAdd(BigInt other, BigInt m) {
    return (this + other).mod(m);
  }

  BigInt modSub(BigInt other, BigInt m) {
    return (this - other).mod(m);
  }

  BigInt get asPositive {
    if (isNegative) {
      throw ArgumentException.invalidOperationArguments(
        "asPositive",
        reason: "Invalid unsigned integer.",
      );
    }
    return this;
  }

  String get toHexaDecimal => "0x${toRadixString(16)}";
}

extension ExtIntHelper on int {
  int get asI32 {
    if (this > BinaryOps.maxInt32 || this < BinaryOps.minInt32) {
      throw ArgumentException.invalidOperationArguments(
        "asI128",
        reason: "Invalid 32-bit signed integer.",
      );
    }
    return this;
  }

  List<int> toU32LeBytes() => asU32.toLeBytes(length: 4);
  List<int> toU16LeBytes() => asU16.toLeBytes(length: 2);
  List<int> toU64LeBytes() => toLeBytes(length: 8);

  List<int> toU32BeBytes() => asU32.toBeBytes(length: 4);
  List<int> toU16BeBytes() => asU16.toBeBytes(length: 2);

  List<int> toLeBytes({int? length, bool sign = false}) => IntUtils.toBytes(
    this,
    length: length,
    byteOrder: Endian.little,
    sign: sign,
  );

  List<int> toBeBytes({int? length}) {
    return IntUtils.toBytes(this, length: length, byteOrder: Endian.big);
  }

  List<int> toBytes({
    int? length,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    return IntUtils.toBytes(
      this,
      length: length,
      byteOrder: byteOrder,
      sign: sign,
    );
  }

  int get asU32 {
    if (isNegative || this > BinaryOps.maxUint32) {
      throw ArgumentException.invalidOperationArguments(
        "asU32",
        reason: "Invalid 32-bit unsigned integer.",
      );
    }
    return this;
  }

  int get asU8 {
    if (isNegative || this > BinaryOps.mask8) {
      throw ArgumentException.invalidOperationArguments(
        "asU32",
        reason: "Invalid 8-bit unsigned integer.",
      );
    }
    return this;
  }

  int get asU16 {
    if (isNegative || this > BinaryOps.mask16) {
      throw ArgumentException.invalidOperationArguments(
        "asU32",
        reason: "Invalid 16-bit unsigned integer.",
      );
    }
    return this;
  }

  int get asPositive {
    if (isNegative) {
      throw ArgumentException.invalidOperationArguments(
        "asPositive",
        reason: "Invalid unsigned integer.",
      );
    }
    return this;
  }

  BigInt get toBigInt => BigInt.from(this);
  BigInt get toU64 => BigInt.from(this).toU64;
  int get toI32 => toSigned(32);
  int get toU32 => this & BinaryOps.mask32;
  int get toU24 => this & BinaryOps.mask24;
  int get toU8 => this & BinaryOps.mask8;
  bool get toBool {
    return this == 0 ? false : true;
  }

  String get toHexaDecimal => "0x${toRadixString(16)}";
}

extension ExtBoolHelper on bool {
  BigInt get toBigInt => this ? BigInt.one : BigInt.zero;
  int get toInt => this ? 1 : 0;
}
