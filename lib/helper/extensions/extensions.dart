import 'dart:collection' show SplayTreeSet;
import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

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

extension ExtBytesHelper on BuBytes {
  BuBytes clone({bool immutable = false}) {
    return cloneBytes(immutable: immutable);
  }

  String toHex({bool lowerCase = true}) =>
      BytesUtils.toHexString(this, lowerCase: lowerCase);

  BigInt toBigInt({
    int? length,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) => BigintUtils.fromBytes(
    this,
    length: length,
    byteOrder: byteOrder,
    sign: sign,
  );

  String encode({StringEncoding encoding = StringEncoding.hex}) =>
      StringUtils.decode(this, encoding: encoding);

  bool isZero() => BytesUtils.isZeroConst(this);
}

extension ExtListHelper<T> on List<T> {
  List<T> get immutable {
    final value = this;
    if (value case BuBytes()) {
      return (value as BuBytes).cloneBytes(immutable: true) as List<T>;
    }
    return List<T>.unmodifiable(this);
  }

  List<T> clone({bool immutable = false}) {
    final value = this;
    if (value case BuBytes()) {
      return (value as BuBytes).cloneBytes(immutable: immutable) as List<T>;
    }
    if (value case SecretBytes()) {
      return (value as SecretBytes).toBytes(immutable: immutable) as List<T>;
    }
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
      throw CoreErrors.invalidOperationArguments(
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
      throw CoreErrors.invalidOperationArguments(
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
      throw CoreErrors.invalidOperationArguments(
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

  BuBytes get asImmutableBytes {
    return BuBytes.unsafe(toList());
  }

  BuBytes get toImutableBytes {
    return BuBytes.toBytes(this, immutable: true);
  }

  BuBytes get toBytes {
    return BuBytes.toBytes(this);
  }
}

extension ExtListIntHelper on List<int> {
  BuBytes get asBytes {
    final value = this;
    return switch (value) {
      BuBytes() => value,
      SecretBytes bytes => bytes.toBytes(),
      _ => BuBytes.from(value),
    };
  }

  BuBytes get asImmutableBytes {
    final value = this;
    return switch (value) {
      BuBytes() => value.cloneBytes(immutable: true),
      SecretBytes() => value.toBytes(immutable: true),
      _ => BuBytes.immutable(this),
    };
  }

  BuBytes get toImutableBytes {
    final value = this;
    if (value case BuBytes()) {
      return value.cloneBytes(immutable: true);
    }
    if (value case SecretBytes()) {
      return value.toBytes(immutable: true);
    }
    return BuBytes.toBytes(this, immutable: true);
  }

  BuBytes get toBytes {
    final value = this;
    if (value case BuBytes()) {
      return value.cloneBytes(immutable: false);
    }
    if (value case SecretBytes()) {
      return value.toBytes();
    }
    return BuBytes.toBytes(this, immutable: false);
  }

  void replace(List<int> other, {bool zero = false, int offset = 0}) {
    if (zero) BinaryOps.zero(this);
    setAll(offset, other);
  }

  void tryZero() {
    BinaryOps.tryZero(this);
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
      throw CoreErrors.invalidOperationArguments(
        "asU256",
        reason: "Invalid 256-bit unsigned integer.",
      );
    }
    return this;
  }

  BigInt get asU128 {
    if (isNegative || this > BinaryOps.maxU128) {
      throw CoreErrors.invalidOperationArguments(
        "asU128",
        reason: "Invalid 128-bit unsigned integer.",
      );
    }
    return this;
  }

  BigInt get asU64 {
    if (isNegative || this > BinaryOps.maxU64) {
      throw CoreErrors.invalidOperationArguments(
        "asU64",
        reason: "Invalid 64-bit unsigned integer.",
      );
    }
    return this;
  }

  BigInt get asU32 {
    if (isNegative || this > BinaryOps.maxUint32Big) {
      throw CoreErrors.invalidOperationArguments(
        "asU32",
        reason: "Invalid 32-bit unsigned integer.",
      );
    }
    return this;
  }

  BigInt get asI32 {
    if (this < BinaryOps.minInt32Big || this > BinaryOps.maxInt32Big) {
      throw CoreErrors.invalidOperationArguments(
        "asI32",
        reason: "Invalid 32-bit signed integer.",
      );
    }
    return this;
  }

  BigInt get asI64 {
    if (this > BinaryOps.maxInt64 || this < BinaryOps.minInt64) {
      throw CoreErrors.invalidOperationArguments(
        "asI64",
        reason: "Invalid 64-bit signed integer.",
      );
    }
    return this;
  }

  BigInt get asU16 {
    if (isNegative || this > BinaryOps.maskBig16) {
      throw CoreErrors.invalidOperationArguments(
        "asU16",
        reason: "Invalid 16-bit unsigned integer.",
      );
    }
    return this;
  }

  BigInt get asI16 {
    if (this < BinaryOps.minInt16Big || this > BinaryOps.maxInt16Big) {
      throw CoreErrors.invalidOperationArguments(
        "asI16",
        reason: "Invalid 16-bit signed integer.",
      );
    }
    return this;
  }

  BigInt get asI128 {
    if (this > BinaryOps.maxI128 || this < BinaryOps.minI128) {
      throw CoreErrors.invalidOperationArguments(
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
  int get asSafeInt {
    if (isSafeInt()) return toInt();
    throw CoreErrors.invalidOperationArguments(
      "toInt",
      reason: "Value is too large for type int.",
    );
  }

  int? get tryAsSafeInt {
    if (isSafeInt()) return toInt();
    return null;
  }

  BuBytes toU16LeBytes() => asU16.toLeBytes(length: 2);
  BuBytes toU16BeBytes() => asU16.toBeBytes(length: 2);

  BuBytes toI16LeBytes() => asI16.toLeBytes(length: 2, sign: true);
  BuBytes toI16BeBytes() => asI16.toBeBytes(length: 2, sign: true);

  BuBytes toU32LeBytes() => asU32.toLeBytes(length: 4);
  BuBytes toU32BeBytes() => asU32.toBeBytes(length: 4);

  BuBytes toI32LeBytes() => asI32.toLeBytes(length: 4, sign: true);
  BuBytes toI32BeBytes() => asI32.toBeBytes(length: 4, sign: true);

  BuBytes toU64LeBytes() => asU64.toLeBytes(length: 8);
  BuBytes toU64BeBytes() => asU64.toBeBytes(length: 8);

  BuBytes toU256LeBytes() => asU256.toLeBytes(length: 32);
  BuBytes toU256BeBytes() => asU256.toBeBytes(length: 32);

  BuBytes toI64LeBytes() => asI64.toLeBytes(length: 8, sign: true);
  BuBytes toI64BeBytes() => asI64.toBeBytes(length: 8, sign: true);

  BuBytes toLeBytes({int? length, bool sign = false}) => BigintUtils.toBytes(
    this,
    length: length,
    byteOrder: Endian.little,
    sign: sign,
  );
  BuBytes toBeBytes({int? length, bool sign = false}) => BigintUtils.toBytes(
    this,
    length: length,
    byteOrder: Endian.big,
    sign: sign,
  );
  BuBytes toBytes({
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
      throw CoreErrors.invalidOperationArguments(
        "asPositive",
        reason: "Invalid unsigned integer.",
      );
    }
    return this;
  }

  String get toHexaDecimal => "0x${toRadixString(16)}";

  bool isSafeInt() {
    if (isValidInt &&
        this >= BinaryOps.safeIntBigInt &&
        this <= BinaryOps.safeUintBigInt) {
      return true;
    }
    return false;
  }
}

extension ExtIntHelper on int {
  BuBytes toU32LeBytes() => asU32.toLeBytes(length: 4);
  BuBytes toU32BeBytes() => asU32.toBeBytes(length: 4);

  BuBytes toU16LeBytes() => asU16.toLeBytes(length: 2);
  BuBytes toU16BeBytes() => asU16.toBeBytes(length: 2);

  BuBytes toU64LeBytes() => asPositive.toLeBytes(length: 8);
  BuBytes toU64BeBytes() => asPositive.toBeBytes(length: 8);

  BuBytes toI32BeBytes() => asI32.toBeBytes(length: 4, sign: true);
  BuBytes toI32LeBytes() => asI32.toLeBytes(length: 4, sign: true);

  BuBytes toI16BeBytes() => asI16.toBeBytes(length: 2, sign: true);
  BuBytes toI16LeBytes() => asI16.toLeBytes(length: 2, sign: true);

  BuBytes toI64BeBytes() => toBeBytes(length: 8, sign: true);
  BuBytes toI64LeBytes() => toLeBytes(length: 8, sign: true);

  BuBytes toLeBytes({int? length, bool sign = false}) => IntUtils.toBytes(
    this,
    length: length,
    byteOrder: Endian.little,
    sign: sign,
  );

  BuBytes toBeBytes({int? length, bool sign = false}) {
    return IntUtils.toBytes(
      this,
      length: length,
      byteOrder: Endian.big,
      sign: sign,
    );
  }

  BuBytes toBytes({
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

  int get asI32 {
    if (this > BinaryOps.maxInt32 || this < BinaryOps.minInt32) {
      throw CoreErrors.invalidOperationArguments(
        "asI32",
        reason: "Invalid 32-bit signed integer.",
      );
    }
    return this;
  }

  int get asU32 {
    if (isNegative || this > BinaryOps.maxUint32) {
      throw CoreErrors.invalidOperationArguments(
        "asU32",
        reason: "Invalid 32-bit unsigned integer.",
      );
    }
    return this;
  }

  int get asU8 {
    if (isNegative || this > BinaryOps.mask8) {
      throw CoreErrors.invalidOperationArguments(
        "asU32",
        reason: "Invalid 8-bit unsigned integer.",
      );
    }
    return this;
  }

  int get asU16 {
    if (isNegative || this > BinaryOps.mask16) {
      throw CoreErrors.invalidOperationArguments(
        "asU16",
        reason: "Invalid 16-bit unsigned integer.",
      );
    }
    return this;
  }

  int get asI16 {
    if (this < BinaryOps.minInt16 || this > BinaryOps.maxInt16) {
      throw CoreErrors.invalidOperationArguments(
        "asI16",
        reason: "Invalid 16-bit signed integer.",
      );
    }
    return this;
  }

  int get asPositive {
    if (isNegative) {
      throw CoreErrors.invalidOperationArguments(
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

extension ExtSecretBytes on SecretBytes {
  /// Extracts the plaintext as a [BigInt] and destroys this secret in the
  /// same step. Same "read once, then gone" contract as [takeBytes].
  ///
  /// Caveat worth knowing: the returned `BigInt` is not itself zeroable —
  /// Dart's `BigInt` is immutable with internal digits outside your
  /// control, so the *value* can persist in memory for as long as the
  /// `BigInt` object is reachable. This only guarantees the
  /// `SecretBytes`'s own storage is wiped, not every representation you
  /// derive from it afterward.
  BigInt takeBigInt({
    int? length,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    final value = toBigInt(length: length, byteOrder: byteOrder, sign: sign);
    zero();
    return value;
  }

  String encode({StringEncoding encoding = StringEncoding.utf8}) =>
      useValue((k) => StringUtils.decode(k, encoding: encoding));

  String toHex({String prefix = '', bool lowerCase = true}) => useValue(
    (k) => BytesUtils.toHexString(k, prefix: prefix, lowerCase: lowerCase),
  );

  BigInt toBigInt({
    int? length,
    Endian byteOrder = Endian.big,
    bool sign = false,
    int offset = 0,
  }) => useValue(
    (k) => BigintUtils.fromBytes(
      k,
      length: length,
      byteOrder: byteOrder,
      sign: sign,
      offset: offset,
    ),
  );
}
