import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/pasta.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// [PallasCurveApi] backed by the pure-Dart implementation in this package
/// ([PallasPoint] with [VestaFq] as the scalar field).
class DartPallasCurveApi implements PallasCurveApi {
  static const int _len = 32;
  static const String _tag = 'Pallas';

  VestaFq _sc(List<int> s) {
    try {
      return VestaFq.fromBytes(s);
    } catch (e) {
      throw CoreErrors.cryptoFailed('$_tag.scalar', reason: '$e');
    }
  }

  VestaFq _scReduce32(List<int> s) {
    try {
      return VestaFq.fromBytesUnchecked(s);
    } catch (e) {
      throw CoreErrors.cryptoFailed('$_tag.scalar', reason: '$e');
    }
  }

  PallasPoint _pt(List<int> p) {
    try {
      return PallasPoint.fromBytes(p);
    } catch (e) {
      throw CoreErrors.cryptoFailed('$_tag.point', reason: '$e');
    }
  }

  @override
  int get pointLen => _len;

  @override
  int get scalarLen => _len;

  @override
  bool scCheck(List<int> s) {
    if (s.length != _len) return false;
    try {
      VestaFq.fromBytes(s);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  BuBytes scReduce(List<int> s) => _scReduce32(s).toBytes();

  @override
  BuBytes scReduce64(List<int> s) => VestaFq.fromBytes64(s).toBytes();

  @override
  BuBytes scAdd(List<int> a, List<int> b) => (_sc(a) + _sc(b)).toBytes();

  @override
  BuBytes scSub(List<int> a, List<int> b) => (_sc(a) - _sc(b)).toBytes();

  @override
  BuBytes scMul(List<int> a, List<int> b) => (_sc(a) * _sc(b)).toBytes();

  @override
  BuBytes scNeg(List<int> s) => (-_sc(s)).toBytes();

  @override
  BuBytes multBase(List<int> scalar) =>
      (PallasPoint.generator_ * _sc(scalar)).toBytes();

  @override
  BuBytes mult(List<int> scalar, List<int> point) =>
      (_pt(point) * _sc(scalar)).toBytes();

  @override
  BuBytes add(List<int> a, List<int> b) => (_pt(a) + _pt(b)).toBytes();

  @override
  BuBytes sub(List<int> a, List<int> b) => (_pt(a) - _pt(b)).toBytes();

  @override
  BuBytes neg(List<int> point) => (-_pt(point)).toBytes();

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) {
    final a = _pt(p1) * _sc(s1);
    final b = _pt(p2) * _sc(s2);
    return (a + b).toBytes();
  }

  @override
  BuBytes generator() => PallasPoint.generator_.toBytes();

  @override
  BuBytes identity() => PallasPoint.identity_.toBytes();

  /// Pasta / Sinsemilla-style H2C (matches connector `hashToCurvePasta`).
  @override
  BuBytes hashToCurvePasta({
    required String domainPrefix,
    required List<int> message,
  }) {
    return PallasPoint.hashToCurve(
      domainPrefix: domainPrefix,
      message: message,
    ).toBytes();
  }

  /// RFC 9380 XMD:SHA-256_SSWU path if exposed on the Dart point type;
  /// otherwise fall back to Pasta H2C with [dst] as domain prefix string.
  @override
  BuBytes hashToCurve(List<int> msg, {List<int>? dst}) {
    final prefix =
        dst == null ? 'PALLAS_XMD:SHA-256_SSWU_RO_' : StringUtils.decode(dst);
    // Prefer a dedicated RFC method if you have one, e.g.:
    // return PallasPoint.hashToCurveRfc(msg, dst: dst).toBytes();
    return hashToCurvePasta(domainPrefix: prefix, message: msg);
  }
}
