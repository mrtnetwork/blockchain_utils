import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/pasta.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'dart:typed_data';
import 'package:blockchain_utils/utils/string/string.dart';

/// [VestaCurveApi] backed by the pure-Dart implementation in this package
/// ([VestaPoint] with [PallasFp] as the scalar field).
///
/// Mirrors [DartPallasCurveApi]: scalar arithmetic over the scalar field
/// ([PallasFp], little-endian 32-byte encodings), point arithmetic over
/// [VestaPoint].
///
/// NOTE (same caveat as Pallas): [hashToCurve]/[hashToCurvePasta] use the
/// Pasta/Blake2b field-hash construction, while the native connector path
/// ([NativeVestaCurveApi]) uses RFC 9380 XMD. The two disagree by algorithm;
/// only the base [CurveApi] operations are covered by the parity suite.
class DartVestaCurveApi implements VestaCurveApi {
  static const int _len = 32;
  static const String _tag = 'Vesta';

  PallasFp _sc(List<int> s) {
    try {
      return PallasFp.fromBytes(s);
    } catch (e) {
      throw CoreErrors.cryptoFailed('$_tag.scalar', reason: '$e');
    }
  }

  PallasFp _scReduce32(List<int> s) {
    try {
      if (s.length != _len) {
        throw CoreErrors.invalidOperationArguments(
          '$_tag.scalar',
          name: 's',
          reason: 'Invalid scalar length ${s.length}.',
        );
      }
      return PallasFp.fromRaw(
        List<Uint64>.generate(
          4,
          (i) => Uint64.fromBytes(s, endian: Endian.little, offset: i * 8),
        ),
      );
    } catch (e) {
      throw CoreErrors.cryptoFailed('$_tag.scalar', reason: '$e');
    }
  }

  VestaPoint _pt(List<int> p) {
    try {
      return VestaPoint.fromBytes(p);
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
      PallasFp.fromBytes(s);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  BuBytes scReduce(List<int> s) => _scReduce32(s).toBytes();

  @override
  BuBytes scReduce64(List<int> s) => PallasFp.fromBytes64(s).toBytes();

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
      (VestaPoint.generator_ * _sc(scalar)).toBytes();

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
  BuBytes generator() => VestaPoint.generator_.toBytes();

  @override
  BuBytes identity() => VestaPoint.identity_.toBytes();

  /// Pasta / Sinsemilla-style H2C (Blake2b field hash, not RFC 9380 XMD —
  /// see class doc). [dst] is interpreted as a domain-prefix string.
  @override
  BuBytes hashToCurve(List<int> msg, {List<int>? dst}) {
    final prefix =
        dst == null ? 'VESTA_XMD:SHA-256_SSWU_RO_' : StringUtils.decode(dst);
    return hashToCurvePasta(domainPrefix: prefix, message: msg);
  }

  BuBytes hashToCurvePasta({
    required String domainPrefix,
    required List<int> message,
  }) {
    return VestaPoint.hashToCurve(
      domainPrefix: domainPrefix,
      message: message,
    ).toBytes();
  }
}
