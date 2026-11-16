import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [ValidatedCurveApi] wrapper for an [Ed25519CurveApi] implementation.
class ValidatedEd25519CurveApi extends ValidatedCurveApi
    implements Ed25519CurveApi {
  ValidatedEd25519CurveApi(this._ed) : super(_ed, tag: 'Ed25519');
  final Ed25519CurveApi _ed;

  @override
  BuBytes reduceMultBase(List<int> scalar) {
    validateScalar(scalar, 'reduceMultBase');
    return call('reduceMultBase', () => _ed.reduceMultBase(scalar));
  }

  @override
  BuBytes addVar(List<int> a, List<int> b) {
    validatePoint(a, 'addVar');
    validatePoint(b, 'addVar');
    return call('addVar', () => _ed.addVar(a, b));
  }

  @override
  BuBytes hashToEc(List<int> data) {
    return call('hashToEc', () => _ed.hashToEc(data));
  }

  @override
  BuBytes mul8(List<int> point) {
    validatePoint(point, 'mul8');
    return call('mul8', () => _ed.mul8(point));
  }

  @override
  BuBytes mul8Mult(List<int> scalar, List<int> point) {
    validateScalar(scalar, 'mul8Mult');
    validatePoint(point, 'mul8Mult');
    return call('mul8Mult', () => _ed.mul8Mult(scalar, point));
  }

  @override
  BuBytes scReduce64(List<int> s) {
    ApiValidate.length(s, 64, operation: 'Ed25519.scReduce64', name: 'scalar');
    return call('scReduce64', () => _ed.scReduce64(s));
  }

  @override
  bool scIsNonZero(List<int> s) {
    validateScalar(s, 'scIsNonZero');
    return call('scIsNonZero', () => _ed.scIsNonZero(s));
  }

  @override
  BuBytes scMulAdd(List<int> a, List<int> b, List<int> c) {
    validateScalar(a, 'scMulAdd');
    validateScalar(b, 'scMulAdd');
    validateScalar(c, 'scMulAdd');
    return call('scMulAdd', () => _ed.scMulAdd(a, b, c));
  }

  @override
  BuBytes scMulSub(List<int> a, List<int> b, List<int> c) {
    validateScalar(a, 'scMulSub');
    validateScalar(b, 'scMulSub');
    validateScalar(c, 'scMulSub');
    return call('scMulSub', () => _ed.scMulSub(a, b, c));
  }

  @override
  BuBytes scAddVar(List<int> a, List<int> b) {
    validateScalar(a, 'scAddVar');
    validateScalar(b, 'scAddVar');
    return call('scAddVar', () => _ed.scAddVar(a, b));
  }

  @override
  BuBytes scSubVar(List<int> a, List<int> b) {
    validateScalar(a, 'scSubVar');
    validateScalar(b, 'scSubVar');
    return call('scSubVar', () => _ed.scSubVar(a, b));
  }

  @override
  BuBytes scMulVar(List<int> a, List<int> b) {
    validateScalar(a, 'scMulVar');
    validateScalar(b, 'scMulVar');
    return call('scMulVar', () => _ed.scMulVar(a, b));
  }

  @override
  BuBytes scMulAddVar(List<int> scalar, List<int> scalar2, List<int> scalar3) {
    validateScalar(scalar, 'scMulAddVar');
    validateScalar(scalar2, 'scMulAddVar');
    validateScalar(scalar3, 'scMulAddVar');
    return call('scMulAddVar', () => _ed.scMulAddVar(scalar, scalar2, scalar3));
  }

  @override
  BuBytes doubleScalarMult(
    List<int> s1,
    List<int> p1,
    List<int> s2,
    List<int> p2,
  ) {
    validateScalar(s1, 'doubleScalarMult');
    validatePoint(p1, 'doubleScalarMult');
    validateScalar(s2, 'doubleScalarMult');
    validatePoint(p2, 'doubleScalarMult');
    return call('doubleScalarMult', () => _ed.doubleScalarMult(s1, p1, s2, p2));
  }

  @override
  List<List<int>> geDsmPrecompVar(List<int> p) {
    validatePoint(p, 'geDsmPrecompVar');
    return call('geDsmPrecompVar', () => _ed.geDsmPrecompVar(p));
  }

  @override
  BuBytes geDoubleScalarMultPrecompPointVar(
    List<int> a,
    List<List<int>> aI,
    List<int> b,
    List<List<int>> bI,
  ) {
    validateScalar(a, 'geDoubleScalarMultPrecompPointVar');
    validateScalar(b, 'geDoubleScalarMultPrecompPointVar');
    return call(
      'geDoubleScalarMultPrecompPointVar',
      () => _ed.geDoubleScalarMultPrecompPointVar(a, aI, b, bI),
    );
  }

  @override
  BuBytes geDoubleScalarMultBasePointVar({
    required List<int> a,
    required List<int> g,
    required List<int> b,
  }) {
    validateScalar(a, 'geDoubleScalarMultBasePointVar');
    validateScalar(b, 'geDoubleScalarMultBasePointVar');
    validatePoint(g, 'geDoubleScalarMultBasePointVar');
    return call(
      'geDoubleScalarMultBasePointVar',
      () => _ed.geDoubleScalarMultBasePointVar(a: a, g: g, b: b),
    );
  }

  @override
  BuBytes geTripleScalarMultBasePointVar({
    required List<int> a,
    required List<int> b,
    required List<List<int>> bI,
    required List<int> c,
    required List<List<int>> cI,
  }) {
    validateScalar(a, 'geTripleScalarMultBasePointVar');
    validateScalar(b, 'geTripleScalarMultBasePointVar');
    validateScalar(c, 'geTripleScalarMultBasePointVar');
    return call(
      'geTripleScalarMultBasePointVar',
      () =>
          _ed.geTripleScalarMultBasePointVar(a: a, b: b, bI: bI, c: c, cI: cI),
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
    validateScalar(a, 'geTripleScalarMultPrecompPointVar');
    validateScalar(b, 'geTripleScalarMultPrecompPointVar');
    validateScalar(c, 'geTripleScalarMultPrecompPointVar');
    return call(
      'geTripleScalarMultPrecompPointVar',
      () => _ed.geTripleScalarMultPrecompPointVar(a, aI, b, bI, c, cI),
    );
  }
}
