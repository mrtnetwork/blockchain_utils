import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [Secp256r1CurveApi] backed by the limb-based [Secp256r1Point].
///
/// Scalars are 32-byte big-endian; points are 33-byte SEC1 compressed.
/// Infinity is the 33 zero-byte buffer on the wire, matching
/// [DartSecp256r1ProjectiveCurveApi] and [ProjectiveECCPoint].
class WeierstrassSecp256r1CurveApi implements Secp256r1CurveApi {
  static const int _pointLen = 33;
  static const int _scalarLen = 32;

  static Secp256r1Fr _fr(List<int> s) => Secp256r1Fr.fromBytes(s);

  static Secp256r1Point _pt(List<int> p) => Secp256r1Point.fromBytes(p);

  static bool _isZeroScalar(List<int> s) =>
      s.length == _scalarLen && s.every((e) => e == 0);

  @override
  int get pointLen => _pointLen;

  @override
  int get scalarLen => _scalarLen;

  @override
  int get uncompressedLen => 65;

  @override
  bool scCheck(List<int> scalar) {
    if (scalar.length != _scalarLen) return false;
    try {
      _fr(scalar);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  BuBytes scReduce(List<int> s) {
    // 32 bytes only (matching every other curve api; there is no scReduce64
    // for secp256r1). Reduction is field-internal via fromRaw.
    return Secp256r1Fr.fromBytesUnchecked(s, endian: Endian.big).toBytes();
  }

  @override
  BuBytes scAdd(List<int> a, List<int> b) => (_fr(a) + _fr(b)).toBytes();

  @override
  BuBytes scSub(List<int> a, List<int> b) => (_fr(a) + (-_fr(b))).toBytes();

  @override
  BuBytes scMul(List<int> a, List<int> b) => (_fr(a) * _fr(b)).toBytes();

  @override
  BuBytes scNeg(List<int> s) => (-_fr(s)).toBytes();

  @override
  BuBytes multBase(List<int> scalar) {
    if (_isZeroScalar(scalar)) return identity();
    return (Secp256r1Point.generator_ * _fr(scalar)).toBytes();
  }

  @override
  BuBytes mult(List<int> scalar, List<int> point) {
    if (_isZeroScalar(scalar)) return identity();
    return (_pt(point) * _fr(scalar)).toBytes();
  }

  @override
  BuBytes add(List<int> a, List<int> b) => (_pt(a) + _pt(b)).toBytes();

  @override
  BuBytes sub(List<int> a, List<int> b) => add(a, neg(b));

  @override
  BuBytes neg(List<int> point) => (-_pt(point)).toBytes();

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) =>
      add(mult(s1, p1), mult(s2, p2));

  @override
  BuBytes compress(List<int> point) {
    final p = _pt(point);
    if (p.isZero()) return identity();
    return p.toCompressed();
  }

  @override
  BuBytes uncompress(List<int> point) {
    final p = _pt(point);
    if (p.isZero()) return BuBytes.fill(uncompressedLen);
    return p.toUncompressed();
  }

  @override
  BuBytes generator() => Secp256r1Point.generator_.toBytes();

  @override
  BuBytes identity() => BuBytes.fill(_pointLen);
}
