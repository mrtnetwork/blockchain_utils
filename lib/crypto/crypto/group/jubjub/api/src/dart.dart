import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/jubjub.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Pure-Dart Jubjub curve API (Uint64 Montgomery [JubJubFr] / [JubJubPoint]).
///
/// Wire format matches Zcash / connector:
/// - points: 32-byte LE *v* with sign(*u*) in high bit of last byte
/// - scalars: 32-byte LE canonical Fr
class DartJubJubCurveApi implements JubJubCurveApi {
  static const int _len = 32;
  static const String _tag = 'JubJub';

  @override
  int get pointLen => _len;

  @override
  int get scalarLen => _len;

  JubJubFr _fr32(List<int> s) {
    try {
      return JubJubFr.fromBytes(s);
    } catch (e) {
      throw CoreErrors.cryptoFailed(
        '$_tag.scalar',
        reason: 'invalid or non-canonical 32-byte Fr: $e',
      );
    }
  }

  /// Accept any 32-byte LE integer and reduce mod r (via wide path).
  JubJubFr _frReduce32(List<int> s) {
    if (s.length != _len) {
      throw CoreErrors.cryptoFailed(
        '$_tag.scReduce',
        reason: 'expected 32 bytes, got ${s.length}',
      );
    }
    return JubJubFr.fromBytesUnchecked(s);
  }

  JubJubFr _frReduce64(List<int> s) {
    if (s.length != 64) {
      throw CoreErrors.cryptoFailed(
        '$_tag.scReduce64',
        reason: 'expected 64 bytes, got ${s.length}',
      );
    }
    return JubJubFr.fromBytes64(s);
  }

  JubJubPoint _pt(List<int> p) {
    try {
      return JubJubPoint.fromBytes(p);
    } catch (e) {
      throw CoreErrors.cryptoFailed(
        '$_tag.point',
        reason: 'invalid Jubjub point encoding: $e',
      );
    }
  }

  BuBytes _ptOut(BaseRedJubJubPoint p) => p.toBytes().asBytes;

  BuBytes _frOut(JubJubFr f) => f.toBytes().asBytes;

  @override
  bool scCheck(List<int> s) {
    if (s.length != _len) return false;
    try {
      JubJubFr.fromBytes(s); // rejects ≥ r and wrong length
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  BuBytes scReduce(List<int> s) => _frOut(_frReduce32(s));

  @override
  BuBytes scReduce64(List<int> s) => _frOut(_frReduce64(s));

  @override
  BuBytes scAdd(List<int> a, List<int> b) => _frOut(_fr32(a) + _fr32(b));

  @override
  BuBytes scSub(List<int> a, List<int> b) => _frOut(_fr32(a) - _fr32(b));

  @override
  BuBytes scMul(List<int> a, List<int> b) => _frOut(_fr32(a) * _fr32(b));

  @override
  BuBytes scNeg(List<int> s) => _frOut(-_fr32(s));

  @override
  BuBytes multBase(List<int> scalar) {
    final s = _fr32(scalar);
    final g = JubJubAffinePoint.generator().toExtended();
    return _ptOut(g * s);
  }

  @override
  BuBytes mult(List<int> scalar, List<int> point) {
    final s = _fr32(scalar);
    final p = _pt(point);
    return _ptOut(p * s);
  }

  @override
  BuBytes add(List<int> a, List<int> b) => _ptOut(_pt(a) + _pt(b));

  @override
  BuBytes sub(List<int> a, List<int> b) => _ptOut(_pt(a) - _pt(b));

  @override
  BuBytes neg(List<int> point) => _ptOut(-_pt(point));

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) {
    final a = _pt(p1) * _fr32(s1);
    final b = _pt(p2) * _fr32(s2);
    return _ptOut(a + b);
  }

  @override
  BuBytes generator() => JubJubAffinePoint.generator().toBytes().asBytes;

  @override
  BuBytes identity() => JubJubPoint.identity().toBytes().asBytes;

  @override
  BuBytes? clearCofactor(List<int> point) {
    final p = _pt(point).mulByCofactor();
    if (p.isIdentity()) return null;
    return p.toBytes().asBytes;
  }
}
