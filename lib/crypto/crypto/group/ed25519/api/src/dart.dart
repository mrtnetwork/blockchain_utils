import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/ops.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [Ed25519CurveApi] backed by the limb implementation in this package
/// ([EdwardsLimbOps]): no `BigInt`, straight-line field arithmetic on
/// secret inputs (Dart JIT gives no machine-code CT guarantee; the
/// Rust/FFI backend stays the real constant-time path).
class DartEd25519CurveApi implements Ed25519CurveApi {
  static const int _len = 32;

  @override
  int get pointLen => _len;

  @override
  int get scalarLen => _len;

  @override
  bool scCheck(List<int> s) => EdwardsLimbOps.scCheck(s);

  @override
  BuBytes scReduce(List<int> s) {
    if (s.length == _len) return EdwardsLimbOps.scReduce32(s);
    return EdwardsLimbOps.scReduce64(s);
  }

  @override
  BuBytes scAdd(List<int> a, List<int> b) => EdwardsLimbOps.scAdd(a, b);

  @override
  BuBytes scSub(List<int> a, List<int> b) => EdwardsLimbOps.scSub(a, b);

  @override
  BuBytes scMul(List<int> a, List<int> b) => EdwardsLimbOps.scMul(a, b);

  @override
  BuBytes scNeg(List<int> s) => EdwardsLimbOps.scNeg(s);

  @override
  BuBytes multBase(List<int> scalar) => EdwardsLimbOps.multBase(scalar);

  @override
  BuBytes mult(List<int> scalar, List<int> point) =>
      EdwardsLimbOps.mult(scalar, point);

  @override
  BuBytes add(List<int> a, List<int> b) => EdwardsLimbOps.add(a, b);

  @override
  BuBytes sub(List<int> a, List<int> b) => EdwardsLimbOps.sub(a, b);

  @override
  BuBytes neg(List<int> point) => EdwardsLimbOps.neg(point);

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) =>
      EdwardsLimbOps.doubleScalarMult(s1, p1, s2, p2);

  @override
  BuBytes generator() => EdwardsLimbOps.generator();

  @override
  BuBytes identity() => EdwardsLimbOps.identity();

  @override
  BuBytes reduceMultBase(List<int> scalar) =>
      EdwardsLimbOps.reduceMultBase(scalar);

  @override
  BuBytes addVar(List<int> a, List<int> b) {
    return add(a, b);
  }

  @override
  BuBytes geDoubleScalarMultBasePointVar({
    required List<int> a,
    required List<int> g,
    required List<int> b,
  }) {
    return EdwardsLimbOps.doubleScalarMultBasePointVar(
      a: a,
      gABytes: g,
      b: b,
    );
  }

  @override
  BuBytes geDoubleScalarMultPrecompPointVar(
    List<int> a,
    List<List<int>> aI,
    List<int> b,
    List<List<int>> bI,
  ) {
    return EdwardsLimbOps.doubleScalarMultPrecompPointVar(a, aI, b, bI);
  }

  @override
  BuBytes geTripleScalarMultBasePointVar({
    required List<int> a,
    required List<int> b,
    required List<List<int>> bI,
    required List<int> c,
    required List<List<int>> cI,
  }) {
    return EdwardsLimbOps.tripleScalarMultBasePointVar(
      a: a,
      b: b,
      bIBytes: bI,
      c: c,
      cIBytes: cI,
    );
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
    return EdwardsLimbOps.tripleScalarMultPrecompPointVar(a, aI, b, bI, c, cI);
  }

  @override
  List<List<int>> geDsmPrecompVar(List<int> p) {
    return EdwardsLimbOps.dsmPrecompVar(p);
  }

  @override
  BuBytes scAddVar(List<int> a, List<int> b) {
    return EdwardsLimbOps.scAdd(a, b);
  }

  @override
  BuBytes scMulVar(List<int> a, List<int> b) {
    return EdwardsLimbOps.scMul(a, b);
  }

  @override
  BuBytes scSubVar(List<int> a, List<int> b) {
    return EdwardsLimbOps.scSub(a, b);
  }

  @override
  BuBytes scMulAdd(List<int> a, List<int> b, List<int> c) {
    return EdwardsLimbOps.scMulAdd(a, b, c);
  }

  @override
  BuBytes scMulSub(List<int> a, List<int> b, List<int> c) {
    return EdwardsLimbOps.scMulSub(a, b, c);
  }

  @override
  bool scIsNonZero(List<int> s) => EdwardsLimbOps.scIsNonZero(s);

  @override
  BuBytes scReduce64(List<int> s) {
    return EdwardsLimbOps.scReduce64(s);
  }

  @override
  BuBytes mul8(List<int> point) {
    return EdwardsLimbOps.mul8(point);
  }

  @override
  BuBytes mul8Mult(List<int> scalar, List<int> point) {
    return EdwardsLimbOps.mul8Mult(scalar, point);
  }

  @override
  BuBytes hashToEc(List<int> data) {
    final hashKey = QuickCrypto.keccak256Hash(data);
    return EdwardsLimbOps.hashToPoint(hashKey);
  }

  @override
  BuBytes doubleScalarMult(
    List<int> s1,
    List<int> p1,
    List<int> s2,
    List<int> p2,
  ) => mulAdd(s1, p1, s2, p2);

  @override
  BuBytes scMulAddVar(List<int> scalar, List<int> scalar2, List<int> scalar3) {
    return EdwardsLimbOps.scMulAdd(scalar, scalar2, scalar3);
  }
}
