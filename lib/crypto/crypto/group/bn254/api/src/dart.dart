import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fr.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/g1.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/g2.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Scalar order r (big-endian) shared by G1/G2 byte APIs.
final BigInt _bn254R = BigInt.parse(
  '30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001',
  radix: 16,
);

BuBytes _be(BigInt v, int length) {
  final out = List<int>.filled(length, 0);
  var t = v;
  for (int i = length - 1; i >= 0; i--) {
    out[i] = (t & BigInt.from(0xff)).toInt();
    t >>= 8;
  }
  return BuBytes(out);
}

Bn254Fr _sc(String tag, List<int> s) {
  try {
    return Bn254Fr.fromBytes(s);
  } catch (_) {
    throw CoreErrors.cryptoFailed(
      '$tag.scalar',
      reason: 'Invalid scalar bytes.',
    );
  }
}

BuBytes _scReduce(String tag, List<int> s) {
  if (s.isEmpty) {
    throw CoreErrors.cryptoFailed(
      '$tag.scReduce',
      reason: 'Invalid scalar length.',
    );
  }
  BigInt v = BigInt.zero;
  for (final b in s) {
    v = (v << 8) | BigInt.from(b);
  }
  return _be(v % _bn254R, 32);
}

/// Pure-Dart BN254 (alt_bn128) **G1** curve API.
///
/// - Points: 64-byte uncompressed EIP-197 (`x || y`, zeros = infinity)
/// - Scalars: 32-byte big-endian `< r`
class DartBn254G1CurveApi implements Bn254G1CurveApi {
  static const int _pointLen = 64;
  static const int _scalarLen = 32;

  @override
  int get pointLen => _pointLen;

  @override
  int get scalarLen => _scalarLen;

  Bn254G1Projective _pt(List<int> p) {
    try {
      return Bn254G1Projective.fromBytes(p);
    } catch (e) {
      throw CoreErrors.cryptoFailed('Bn254G1.fromBytes', reason: '$e');
    }
  }

  @override
  bool scCheck(List<int> scalar) {
    if (scalar.length != _scalarLen) return false;
    try {
      _sc('Bn254G1', scalar);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  BuBytes scReduce(List<int> s) => _scReduce('Bn254G1', s);

  @override
  BuBytes scAdd(List<int> a, List<int> b) =>
      (_sc('Bn254G1', a) + _sc('Bn254G1', b)).toBytes();

  @override
  BuBytes scSub(List<int> a, List<int> b) =>
      (_sc('Bn254G1', a) - _sc('Bn254G1', b)).toBytes();

  @override
  BuBytes scMul(List<int> a, List<int> b) =>
      (_sc('Bn254G1', a) * _sc('Bn254G1', b)).toBytes();

  @override
  BuBytes scNeg(List<int> s) => (-_sc('Bn254G1', s)).toBytes();

  @override
  BuBytes generator() => Bn254G1AffinePoint.generator.toBytes();

  @override
  BuBytes identity() => Bn254G1AffinePoint.identity.toBytes();

  @override
  BuBytes multBase(List<int> scalar) {
    _sc('Bn254G1', scalar);
    return Bn254G1Projective.generator.multiply(scalar).toBytes();
  }

  @override
  BuBytes mult(List<int> scalar, List<int> point) {
    _sc('Bn254G1', scalar);
    return _pt(point).multiply(scalar).toBytes();
  }

  @override
  BuBytes add(List<int> a, List<int> b) => (_pt(a) + _pt(b)).toBytes();

  @override
  BuBytes sub(List<int> a, List<int> b) => (_pt(a) - _pt(b)).toBytes();

  @override
  BuBytes neg(List<int> point) => (-_pt(point)).toBytes();

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) =>
      add(mult(s1, p1), mult(s2, p2));
}

/// Pure-Dart BN254 (alt_bn128) **G2** curve API.
///
/// - Points: 128-byte uncompressed EIP-197 (`x1 || x0 || y1 || y0`,
///   zeros = infinity)
/// - Scalars: 32-byte big-endian `< r`
class DartBn254G2CurveApi implements Bn254G2CurveApi {
  static const int _pointLen = 128;
  static const int _scalarLen = 32;

  @override
  int get pointLen => _pointLen;

  @override
  int get scalarLen => _scalarLen;

  Bn254G2Projective _pt(List<int> p) {
    try {
      return Bn254G2Projective.fromBytes(p);
    } catch (e) {
      throw CoreErrors.cryptoFailed('Bn254G2.fromBytes', reason: '$e');
    }
  }

  @override
  bool scCheck(List<int> scalar) {
    if (scalar.length != _scalarLen) return false;
    try {
      _sc('Bn254G2', scalar);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  BuBytes scReduce(List<int> s) => _scReduce('Bn254G2', s);

  @override
  BuBytes scAdd(List<int> a, List<int> b) =>
      (_sc('Bn254G2', a) + _sc('Bn254G2', b)).toBytes();

  @override
  BuBytes scSub(List<int> a, List<int> b) =>
      (_sc('Bn254G2', a) - _sc('Bn254G2', b)).toBytes();

  @override
  BuBytes scMul(List<int> a, List<int> b) =>
      (_sc('Bn254G2', a) * _sc('Bn254G2', b)).toBytes();

  @override
  BuBytes scNeg(List<int> s) => (-_sc('Bn254G2', s)).toBytes();

  @override
  BuBytes generator() => Bn254G2AffinePoint.generator.toBytes();

  @override
  BuBytes identity() => Bn254G2AffinePoint.identity.toBytes();

  @override
  BuBytes multBase(List<int> scalar) {
    _sc('Bn254G2', scalar);
    return Bn254G2Projective.generator.multiply(scalar).toBytes();
  }

  @override
  BuBytes mult(List<int> scalar, List<int> point) {
    _sc('Bn254G2', scalar);
    return _pt(point).multiply(scalar).toBytes();
  }

  @override
  BuBytes add(List<int> a, List<int> b) => (_pt(a) + _pt(b)).toBytes();

  @override
  BuBytes sub(List<int> a, List<int> b) => (_pt(a) - _pt(b)).toBytes();

  @override
  BuBytes neg(List<int> point) => (-_pt(point)).toBytes();

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) =>
      add(mult(s1, p1), mult(s2, p2));
}
