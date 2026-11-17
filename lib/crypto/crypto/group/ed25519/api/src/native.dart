import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/ed25519/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/ops.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [Ed25519CurveApi] backed by a native (FFI/platform) implementation,
/// falling back to [DartEd25519CurveApi] for operations the native API
/// doesn't expose.
class NativeEd25519CurveApi implements Ed25519CurveApi {
  const NativeEd25519CurveApi(this._api);
  final BuEd25519CurveApi _api;

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
  BuBytes reduceMultBase(List<int> scalar) {
    return multBase(scReduce(scalar));
  }

  @override
  BuBytes addVar(List<int> a, List<int> b) {
    return _api.addVartime(a, b).unwrapOrThrowCryptoError();
  }

  /// Builds the odd-multiples table used by the *Var double/triple scalar mults.
  /// Returns [1P, 3P, 5P, 7P, 9P, 11P, 13P, 15P]
  @override
  List<List<int>> geDsmPrecompVar(List<int> p) {
    final result = _api.geDsmPrecomp(p).unwrapOrThrowCryptoError();
    return List.generate(8, (i) {
      final start = i * 32;

      return result.sublist(start, start + 32);
    });
  }

  /// Fixed-base odd-multiples table (B, 3B, …, 15B).
  /// Call once and cache if you use the *BasePoint methods heavily.
  List<List<int>> geBaseDsmPrecompVar() {
    return geDsmPrecompVar(generator());
  }

  @override
  BuBytes geDoubleScalarMultPrecompPointVar(
    List<int> a,
    List<List<int>> aI,
    List<int> b,
    List<List<int>> bI,
  ) {
    return _api
        .geDoubleScalarMultPrecomp(
          a,
          aI.expand((e) => e).toList(),
          b,
          bI.expand((e) => e).toList(),
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes geTripleScalarMultBasePointVar({
    required List<int> a,
    required List<int> b,
    required List<List<int>> bI,
    required List<int> c,
    required List<List<int>> cI,
    List<List<int>>? basePrecomp, // optional cached geBaseDsmPrecompVar(api)
  }) {
    return _api
        .geTripleScalarMultBase(
          a,
          b,
          bI.expand((e) => e).toList(),
          c,
          cI.expand((e) => e).toList(),
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes geDoubleScalarMultBasePointVar({
    required List<int> a,
    required List<int> g,
    required List<int> b,
    List<List<int>>? basePrecomp, // optional cached geBaseDsmPrecompVar(api)
  }) {
    return _api.geDoubleScalarMultBase(a, g, b).unwrapOrThrowCryptoError();
  }

  @override
  BuBytes geTripleScalarMultPrecompPointVar(
    List<int> a,
    List<List<int>> aI,
    List<int> b,
    List<List<int>> bI,
    List<int> c,
    List<List<int>> cI,
  ) {
    return _api
        .geTripleScalarMultPrecomp(
          a,
          aI.expand((e) => e).toList(),
          b,
          bI.expand((e) => e).toList(),
          c,
          cI.expand((e) => e).toList(),
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes scAddVar(List<int> a, List<int> b) {
    return scAdd(a, b);
  }

  @override
  BuBytes scMulVar(List<int> a, List<int> b) {
    return scMul(a, b);
  }

  @override
  BuBytes scSubVar(List<int> a, List<int> b) {
    return scSub(a, b);
  }

  @override
  BuBytes scMulAdd(List<int> a, List<int> b, List<int> c) =>
      scAdd(scMul(a, b), c);
  @override
  BuBytes scMulSub(List<int> a, List<int> b, List<int> c) =>
      scSub(c, scMul(a, b));
  @override
  bool scIsNonZero(List<int> s) => EdwardsLimbOps.scIsNonZero(s);

  @override
  BuBytes scReduce64(List<int> s) =>
      _api.scReduce64(s).unwrapOrThrowCryptoError();
  @override
  BuBytes mul8(List<int> point) => mult(const [
    8,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ], point);
  @override
  BuBytes mul8Mult(List<int> scalar, List<int> point) =>
      _api.mul8Mult(scalar, point).unwrapOrThrowCryptoError();
  @override
  BuBytes hashToEc(List<int> data) =>
      _api.hashToEc(data).unwrapOrThrowCryptoError();
  @override
  BuBytes doubleScalarMult(
    List<int> s1,
    List<int> p1,
    List<int> s2,
    List<int> p2,
  ) => mulAdd(s1, p1, s2, p2);

  @override
  BuBytes scMulAddVar(List<int> scalar, List<int> scalar2, List<int> scalar3) {
    return scMulAdd(scalar, scalar2, scalar3);
  }
}
