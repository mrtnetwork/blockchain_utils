import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [Secp256k1CurveApi] backed by a native (FFI/platform) implementation.
class NativeSecp256k1CurveApi implements Secp256k1CurveApi {
  const NativeSecp256k1CurveApi(this._api);

  /// `Connector.instance.curves.secp256k1` or `BuNativeCurve(BuCurveId.secp256k1, …)`
  final BuSecp256k1CurveApi _api;

  @override
  int get pointLen => _api.pointLen; // 33

  @override
  int get scalarLen => _api.scalarLen; // 32

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
  int get uncompressedLen => _api.uncompressedLen;

  @override
  BuBytes compress(List<int> point) =>
      _api.compress(point).unwrapOrThrowCryptoError();

  @override
  BuBytes uncompress(List<int> point) =>
      _api.uncompress(point).unwrapOrThrowCryptoError();
}
