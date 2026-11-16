import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [JubJubCurveApi] backed by a native (FFI/platform) implementation.
class NativeJubJubCurveApi implements JubJubCurveApi {
  final BuJubjubCurveApi _api;
  const NativeJubJubCurveApi(this._api);


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
  BuBytes neg(List<int> point) =>
      _api.neg(point).unwrapOrThrowCryptoError();

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
  BuBytes scNeg(List<int> s) =>
      _api.scNeg(s).unwrapOrThrowCryptoError();

  @override
  BuBytes scReduce(List<int> s) =>
      _api.scReduce(s).unwrapOrThrowCryptoError();

  @override
  BuBytes scReduce64(List<int> s) =>
      _api.scReduce64(s).unwrapOrThrowCryptoError();
  @override
  BuBytes generator() =>
      _api.generator().unwrapOrThrowCryptoError();

  @override
  BuBytes identity() =>
      _api.identity().unwrapOrThrowCryptoError();

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) =>
      _api.mulAdd(s1, p1, s2, p2).unwrapOrThrowCryptoError();

  /// JubJub cofactor (8) as 32-byte LE scalar: `curveMul(8, p)` is
  /// exactly `mulByCofactor` (triple-double), so no new Rust binding.
  static final List<int> _cofactor8 = List<int>.filled(32, 0)..[0] = 8;

  @override
  BuBytes? clearCofactor(List<int> point) {
    final cleared = _api
        .mult(_cofactor8, point)
        .unwrapOrThrowCryptoError();
    final id = _api
        .identity()
        .unwrapOrThrowCryptoError();
    if (BytesUtils.bytesEqual(cleared, id)) return null;
    return cleared;
  }
}
