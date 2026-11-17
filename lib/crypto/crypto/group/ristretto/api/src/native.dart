import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [RistrettoCurveApi] backed by a native (FFI/platform) implementation.
class NativeRistrettoCurveApi implements RistrettoCurveApi {
  const NativeRistrettoCurveApi(this._api);

  final BuRistrettoCurveApi _api;

  @override
  int get pointLen => _api.pointLen;

  @override
  int get scalarLen => _api.scalarLen;

  @override
  bool scCheck(List<int> s) => _api.scCheck(s);

  @override
  BuBytes multBase(List<int> scalar) =>
      _api.multBase(scalar).unwrapOrThrowCryptoError();

  @override
  BuBytes mult(List<int> scalar, List<int> point) =>
      _api.mult(scalar, point).unwrapOrThrowCryptoError();

  @override
  BuBytes add(List<int> a, List<int> b) =>
      _api.add(a, b).unwrapOrThrowCryptoError();

  @override
  BuBytes sub(List<int> a, List<int> b) =>
      _api.sub(a, b).unwrapOrThrowCryptoError();

  @override
  BuBytes neg(List<int> point) => _api.neg(point).unwrapOrThrowCryptoError();

  @override
  BuBytes scAdd(List<int> a, List<int> b) =>
      _api.scAdd(a, b).unwrapOrThrowCryptoError();

  @override
  BuBytes scSub(List<int> a, List<int> b) =>
      _api.scSub(a, b).unwrapOrThrowCryptoError();

  @override
  BuBytes scMul(List<int> a, List<int> b) =>
      _api.scMul(a, b).unwrapOrThrowCryptoError();

  @override
  BuBytes scNeg(List<int> s) => _api.scNeg(s).unwrapOrThrowCryptoError();

  @override
  BuBytes scReduce(List<int> s) => _api.scReduce(s).unwrapOrThrowCryptoError();

  @override
  BuBytes generator() => _api.generator().unwrapOrThrowCryptoError();

  @override
  BuBytes identity() => _api.identity().unwrapOrThrowCryptoError();

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) =>
      _api.mulAdd(s1, p1, s2, p2).unwrapOrThrowCryptoError();

  @override
  BuBytes pointFromEdwardBytes(List<int> edwards32) {
    return _api.pointFromEdwardBytes(edwards32).unwrapOrThrowCryptoError();
  }

  @override
  BuBytes toEdwardBytes(List<int> ristretto32) {
    return _api.toEdwardBytes(ristretto32).unwrapOrThrowCryptoError();
  }

  @override
  BuBytes scMulAdd(List<int> a, List<int> b, List<int> c) =>
      scAdd(scMul(a, b), c);

  @override
  BuBytes scMulSub(List<int> a, List<int> b, List<int> c) =>
      scSub(c, scMul(a, b));

  @override
  BuBytes scReduce64(List<int> s) {
    return _api.scReduce64(s).unwrapOrThrowCryptoError();
  }
}
