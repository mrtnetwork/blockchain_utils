import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/compare/compare.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';

class Secp256k1Uint128 {
  BigInt _r = BigInt.zero;
  BigInt get r => _r;
  void set(BigInt r) {
    _r = r.toUnsigned128;
  }

  void setU64(BigInt r) {
    _r = r.toUnsigned64;
  }

  @override
  String toString() {
    return r.toString();
  }
}

class Secp256k1Int128 {
  BigInt _r = BigInt.zero;
  BigInt get r => _r;

  @override
  String toString() {
    return r.toString();
  }

  void set(BigInt r) {
    _r = r.toSigned128;
  }

  void setS64(BigInt r) {
    _r = r.toSigned64;
  }
}

class Secp256k1Scalar extends Iterable<BigInt> {
  List<BigInt> _d;
  factory Secp256k1Scalar() {
    return Secp256k1Scalar._();
  }
  Secp256k1Scalar._({List<BigInt>? d})
      : _d = d ?? List<BigInt>.filled(4, BigInt.zero);
  Secp256k1Scalar clone() {
    return Secp256k1Scalar._(d: _d.clone());
  }

  void setZero() {
    _d = List<BigInt>.filled(4, BigInt.zero);
  }

  BigInt operator [](int index) => _d[index];
  void operator []=(int index, BigInt value) {
    _d[index] = value.toUnsigned64;
  }

  factory Secp256k1Scalar.constants(BigInt d7, BigInt d6, BigInt d5, BigInt d4,
      BigInt d3, BigInt d2, BigInt d1, BigInt d0) {
    return Secp256k1Scalar._(
        d: [
      ((d1.toUnsigned64)) << 32 | (d0),
      ((d3.toUnsigned64)) << 32 | (d2),
      ((d5.toUnsigned64)) << 32 | (d4),
      ((d7.toUnsigned64)) << 32 | (d6)
    ].immutable);
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! Secp256k1Scalar) return false;
    return CompareUtils.iterableIsEqual(_d, other._d);
  }

  @override
  Iterator<BigInt> get iterator => _d.iterator;

  @override
  int get hashCode => HashCodeGenerator.generateHashCode(_d);

  void set(Secp256k1Scalar other) {
    _d = other._d.clone();
  }
}

class Secp256k1ModinvSigned {
  List<BigInt> _v;
  factory Secp256k1ModinvSigned({List<BigInt>? v}) {
    if (v != null && v.length != 5) {
      throw CryptoException(
          "Invalid modinv length: expected 5 BigInt values, but received ${v.length}.");
    }
    return Secp256k1ModinvSigned._(v: v);
  }
  Secp256k1ModinvSigned._({List<BigInt>? v})
      : _v = v ?? List<BigInt>.filled(5, BigInt.zero);
  Secp256k1ModinvSigned clone() {
    return Secp256k1ModinvSigned._(v: _v.clone());
  }

  factory Secp256k1ModinvSigned.constants(List<BigInt> v) {
    if (v.length != 5) {
      throw CryptoException(
          "Invalid modinv constant length: expected 5 BigInt values, but received ${v.length}.");
    }
    return Secp256k1ModinvSigned._(v: v.immutable);
  }

  BigInt operator [](int index) => _v[index];

  void operator []=(int index, BigInt value) {
    _v[index] = value.toSigned64;
  }

  void set(Secp256k1ModinvSigned other) {
    _v = other._v.clone();
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! Secp256k1Scalar) return false;
    return CompareUtils.iterableIsEqual(_v, other._d);
  }

  Iterator<BigInt> get iterator => _v.iterator;

  @override
  int get hashCode => HashCodeGenerator.generateHashCode(_v);
}

class Secp256k1ModinvInfo {
  final Secp256k1ModinvSigned modulus;
  final BigInt modulusInv;
  Secp256k1ModinvInfo({required this.modulus, required this.modulusInv});

  Secp256k1ModinvInfo copyWith(
      {BigInt? modulusInv, Secp256k1ModinvSigned? modulus}) {
    return Secp256k1ModinvInfo(
        modulus: this.modulus.clone(),
        modulusInv: modulusInv ?? this.modulusInv);
  }
}

class Secp256k1ModinvTrans {
  BigInt _u = BigInt.zero, _v = BigInt.zero, _q = BigInt.zero, _r = BigInt.zero;
  BigInt get u => _u;
  BigInt get v => _v;
  BigInt get q => _q;
  BigInt get r => _r;

  void set(BigInt u, BigInt v, BigInt q, BigInt r) {
    _u = u.toSigned64;
    _v = v.toSigned64;
    _q = q.toSigned64;
    _r = r.toSigned64;
  }
}

class Secp256k1Fe extends Iterable<BigInt> {
  List<BigInt> _n;
  factory Secp256k1Fe() {
    return Secp256k1Fe._();
  }
  Secp256k1Fe._({List<BigInt>? n})
      : _n = n ?? List<BigInt>.filled(5, BigInt.zero);

  Secp256k1Fe clone() {
    return Secp256k1Fe._(n: _n.clone());
  }

  void setZero() {
    _n = List<BigInt>.filled(5, BigInt.zero);
  }

  // You can add methods or constructors to initialize this class more effectively
  // For example, constructor to initialize n with specific values
  factory Secp256k1Fe._inner(BigInt d7, BigInt d6, BigInt d5, BigInt d4,
      BigInt d3, BigInt d2, BigInt d1, BigInt d0,
      {bool immutable = false}) {
    final r = [
      (d0) | (((d1) & 0xFFFFF.toBigInt) << 32),
      ((d1.toUnsigned64) >> 20) |
          (((d2.toUnsigned64)) << 12) |
          (((d3.toUnsigned64) & 0xFF.toBigInt) << 44),
      ((d3.toUnsigned64) >> 8) |
          (((d4.toUnsigned64) & 0xFFFFFFF.toBigInt) << 24),
      ((d4.toUnsigned64) >> 28) |
          (((d5.toUnsigned64)) << 4) |
          (((d6.toUnsigned64) & 0xFFFF.toBigInt) << 36),
      ((d6.toUnsigned64) >> 16) | (((d7.toUnsigned64)) << 16)
    ];
    return Secp256k1Fe._(n: immutable ? r.toImutableList : r);
  }
  factory Secp256k1Fe.constants(BigInt d7, BigInt d6, BigInt d5, BigInt d4,
      BigInt d3, BigInt d2, BigInt d1, BigInt d0) {
    return Secp256k1Fe._inner(d7, d6, d5, d4, d3, d2, d1, d0, immutable: true);
  }

  BigInt operator [](int index) => _n[index];

  void operator []=(int index, BigInt value) {
    _n[index] = value.toUnsigned64;
  }

  @override
  Iterator<BigInt> get iterator => _n.iterator;

  void set(Secp256k1Fe other) {
    _n = other._n.clone();
  }
}

class Secp256k1FeStorage extends Iterable<BigInt> {
  List<BigInt> _n;
  factory Secp256k1FeStorage() {
    return Secp256k1FeStorage._();
  }
  Secp256k1FeStorage._({List<BigInt>? n})
      : _n = n ?? List<BigInt>.filled(4, BigInt.zero);

  // You can add methods or constructors to initialize this class more effectively
  // For example, constructor to initialize n with specific values
  factory Secp256k1FeStorage.constants(BigInt d7, BigInt d6, BigInt d5,
      BigInt d4, BigInt d3, BigInt d2, BigInt d1, BigInt d0) {
    return Secp256k1FeStorage._(n: [
      (d0) | (((d1).toUnsigned64) << 32),
      (d2) | (((d3).toUnsigned64) << 32),
      (d4) | (((d5.toUnsigned64)) << 32),
      (d6) | (((d7.toUnsigned64)) << 32)
    ]);
  }

  BigInt operator [](int index) => _n[index];

  void operator []=(int index, BigInt value) {
    _n[index] = value.toUnsigned64;
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! Secp256k1FeStorage) return false;
    return CompareUtils.iterableIsEqual(_n, other._n);
  }

  @override
  Iterator<BigInt> get iterator => _n.iterator;

  @override
  int get hashCode => HashCodeGenerator.generateHashCode(_n);
}

class Secp256k1Ge {
  Secp256k1Fe x;
  Secp256k1Fe y;
  int infinity;
  Secp256k1Ge({Secp256k1Fe? x, Secp256k1Fe? y, this.infinity = 0})
      : x = x ?? Secp256k1Fe(),
        y = y ?? Secp256k1Fe();

  Secp256k1Ge clone() {
    return Secp256k1Ge(x: x.clone(), y: y.clone(), infinity: infinity);
  }

  void setInfinity() {
    x.setZero();
    y.setZero();
    infinity = 1;
  }

  void set(Secp256k1Ge other) {
    x = other.x.clone();
    y = other.y.clone();
    infinity = other.infinity;
  }

  factory Secp256k1Ge.constants(
      BigInt a,
      BigInt b,
      BigInt c,
      BigInt d,
      BigInt e,
      BigInt f,
      BigInt g,
      BigInt h,
      BigInt i,
      BigInt j,
      BigInt k,
      BigInt l,
      BigInt m,
      BigInt n,
      BigInt o,
      BigInt p) {
    return Secp256k1Ge(
        x: Secp256k1Fe.constants(a, b, c, d, e, f, g, h),
        y: Secp256k1Fe.constants((i), (j), (k), (l), (m), (n), (o), (p)),
        infinity: 0);
  }
  factory Secp256k1Ge.infinity() {
    return Secp256k1Ge(
        x: Secp256k1Fe.constants(BigInt.zero, BigInt.zero, BigInt.zero,
            BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero),
        y: Secp256k1Fe.constants(BigInt.zero, BigInt.zero, BigInt.zero,
            BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero),
        infinity: 1);
  }
}

class Secp256k1Gej {
  Secp256k1Fe x;
  Secp256k1Fe y;
  Secp256k1Fe z;
  Secp256k1Gej clone() {
    return Secp256k1Gej(
        x: x.clone(), y: y.clone(), z: z.clone(), infinity: infinity);
  }

  int infinity;
  Secp256k1Gej(
      {Secp256k1Fe? x, Secp256k1Fe? y, Secp256k1Fe? z, this.infinity = 0})
      : x = x ?? Secp256k1Fe(),
        y = y ?? Secp256k1Fe(),
        z = z ?? Secp256k1Fe();
  factory Secp256k1Gej.constants(
      BigInt a,
      BigInt b,
      BigInt c,
      BigInt d,
      BigInt e,
      BigInt f,
      BigInt g,
      BigInt h,
      BigInt i,
      BigInt j,
      BigInt k,
      BigInt l,
      BigInt m,
      BigInt n,
      BigInt o,
      BigInt p) {
    return Secp256k1Gej(
        x: Secp256k1Fe.constants(a, b, c, d, e, f, g, h),
        y: Secp256k1Fe.constants((i), (j), (k), (l), (m), (n), (o), (p)),
        z: Secp256k1Fe.constants(BigInt.zero, BigInt.zero, BigInt.zero,
            BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero, BigInt.one),
        infinity: 0);
  }

  factory Secp256k1Gej.infinity() {
    return Secp256k1Gej(
        x: Secp256k1Fe.constants(BigInt.zero, BigInt.zero, BigInt.zero,
            BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero),
        y: Secp256k1Fe.constants(BigInt.zero, BigInt.zero, BigInt.zero,
            BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero),
        z: Secp256k1Fe.constants(BigInt.zero, BigInt.zero, BigInt.zero,
            BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero),
        infinity: 1);
  }

  void set(Secp256k1Gej other) {
    x = other.x.clone();
    y = other.y.clone();
    z = other.z.clone();
    infinity = other.infinity;
  }
}

class Secp256k1GeStorage {
  final Secp256k1FeStorage x;
  final Secp256k1FeStorage y;
  Secp256k1GeStorage({Secp256k1FeStorage? x, Secp256k1FeStorage? y})
      : x = x ?? Secp256k1FeStorage(),
        y = y ?? Secp256k1FeStorage();
  factory Secp256k1GeStorage.constants(
      BigInt a,
      BigInt b,
      BigInt c,
      BigInt d,
      BigInt e,
      BigInt f,
      BigInt g,
      BigInt h,
      BigInt i,
      BigInt j,
      BigInt k,
      BigInt l,
      BigInt m,
      BigInt n,
      BigInt o,
      BigInt p) {
    return Secp256k1GeStorage(
      x: Secp256k1FeStorage.constants(a, b, c, d, e, f, g, h),
      y: Secp256k1FeStorage.constants((i), (j), (k), (l), (m), (n), (o), (p)),
    );
  }
}

class Secp256k1ECmultGenContext {
  final Secp256k1Scalar scalarOffset = Secp256k1Scalar();
  final Secp256k1Ge geOffset = Secp256k1Ge();

  Secp256k1Fe projBlind = Secp256k1Fe();

  void clean() {
    scalarOffset.setZero();
    geOffset.setInfinity();
    geOffset.infinity = 0;
    projBlind.setZero();
  }
}
