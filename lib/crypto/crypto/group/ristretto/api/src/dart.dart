import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/ristretto/point/ristretto.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [RistrettoCurveApi] backed by [RistrettoPoint] and the Ed25519 curve API
/// for scalar operations.
class DartRistrettoCurveApi implements RistrettoCurveApi {
  static const int _len = 32;

  Ed25519CurveApi get ed25519CurveApi => blockchainUtils.api.ed25519;

  @override
  int get pointLen => _len;

  @override
  int get scalarLen => _len;

  RistrettoPoint _pointFromBytes(List<int> bytes) {
    try {
      return RistrettoPoint.fromBytes(bytes);
    } catch (e) {
      throw CoreErrors.invalidOperationArguments(
        "Ristretto.pointFromBytes",
        reason: "Invalid ristretto point bytes.",
      );
    }
  }

  RistrettoPoint _pointFromEdwardBytes(List<int> bytes) {
    try {
      return RistrettoPoint.fromEdwardBytes(bytes);
    } catch (e) {
      throw CoreErrors.invalidOperationArguments(
        "Ristretto.pointFromEdwardBytes",
        reason: "Invalid ED25519 point bytes.",
      );
    }
  }

  @override
  bool scCheck(List<int> s) => ed25519CurveApi.scCheck(s);

  @override
  BuBytes scReduce(List<int> s) => ed25519CurveApi.scReduce(s);

  @override
  BuBytes scAdd(List<int> a, List<int> b) => ed25519CurveApi.scAdd(a, b);

  @override
  BuBytes scSub(List<int> a, List<int> b) => ed25519CurveApi.scSub(a, b);

  @override
  BuBytes scMul(List<int> a, List<int> b) => ed25519CurveApi.scMul(a, b);

  @override
  BuBytes scNeg(List<int> s) {
    return ed25519CurveApi.scNeg(s);
  }

  @override
  BuBytes multBase(List<int> scalar) {
    final mult = ed25519CurveApi.multBase(scalar);
    final r = _pointFromEdwardBytes(mult);
    return r.toBytes();
  }

  @override
  BuBytes mult(List<int> scalar, List<int> point) {
    final p = _pointFromBytes(point);
    final mult = ed25519CurveApi.mult(scalar, p.toEdwardBytes());
    return _pointFromEdwardBytes(mult).toBytes();
  }

  @override
  BuBytes add(List<int> a, List<int> b) {
    final p1 = _pointFromBytes(a);
    final p2 = _pointFromBytes(b);
    return (p1 + p2).toBytes();
  }

  @override
  BuBytes sub(List<int> a, List<int> b) {
    final p1 = _pointFromBytes(a);
    final p2 = _pointFromBytes(b);
    return (p1 + (-p2)).toBytes();
  }

  @override
  BuBytes neg(List<int> point) {
    final p1 = _pointFromBytes(point);
    return (-p1).toBytes();
  }

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) {
    // s1·P1 + s2·P2
    final a = mult(s1, p1);
    final b = mult(s2, p2);
    return add(a, b);
  }

  @override
  BuBytes generator() {
    // B = 1·B
    final one = BuBytes.fill(_len, 0);
    one[0] = 1;
    return multBase(one);
  }

  @override
  BuBytes identity() {
    // Ristretto identity encoding is 32 zero bytes (NOT the edwards
    // encoding of the identity point). Do not route through EDPoint.
    return BuBytes.fill(_len, 0);
  }

  @override
  BuBytes pointFromEdwardBytes(List<int> edwards32) {
    final p = _pointFromEdwardBytes(edwards32);
    return p.toBytes();
  }

  @override
  BuBytes toEdwardBytes(List<int> ristretto32) {
    final p = _pointFromBytes(ristretto32);
    return p.toEdwardBytes();
  }

  @override
  BuBytes scMulAdd(List<int> a, List<int> b, List<int> c) =>
      ed25519CurveApi.scMulAdd(a, b, c);

  @override
  BuBytes scMulSub(List<int> a, List<int> b, List<int> c) =>
      ed25519CurveApi.scMulSub(a, b, c);

  @override
  BuBytes scReduce64(List<int> s) {
    return ed25519CurveApi.scReduce64(s);
  }
}
