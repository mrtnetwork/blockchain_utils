import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Common byte-level curve operations, shared across every supported curve.
/// [pointLen]/[scalarLen] vary per curve — e.g. 32 bytes for Ed25519, 48 for
/// BLS12-381 G1.
abstract interface class CurveApi {
  /// Compressed point length in bytes (curve-specific).
  int get pointLen;

  /// Scalar length in bytes (curve-specific).
  int get scalarLen;

  /// True if [scalar] is a canonically encoded scalar of [scalarLen] bytes, else false, never throws for length mismatch.
  bool scCheck(List<int> scalar);

  /// Scalar-times-generator; [scalar] is [scalarLen] bytes. Returns [pointLen] bytes. Throws on invalid scalar/point.
  BuBytes multBase(List<int> scalar);

  /// Scalar-times-point; [scalar] is [scalarLen] bytes, [point] is [pointLen] bytes. Returns [pointLen] bytes. Throws on invalid input.
  BuBytes mult(List<int> scalar, List<int> point);

  /// Point addition; both [pointLen] bytes. Returns [pointLen] bytes. Throws on invalid encoding.
  BuBytes add(List<int> a, List<int> b);

  /// Point subtraction; both [pointLen] bytes. Returns [pointLen] bytes. Throws on invalid encoding.
  BuBytes sub(List<int> a, List<int> b);

  /// Point negation; [pointLen] bytes. Returns [pointLen] bytes. Throws on invalid encoding.
  BuBytes neg(List<int> point);

  /// Scalar addition mod n; both [scalarLen] bytes. Returns [scalarLen] bytes. Throws on invalid scalar.
  BuBytes scAdd(List<int> a, List<int> b);

  /// Scalar subtraction mod n; both [scalarLen] bytes. Returns [scalarLen] bytes. Throws on invalid scalar.
  BuBytes scSub(List<int> a, List<int> b);

  /// Scalar multiplication mod n; both [scalarLen] bytes. Returns [scalarLen] bytes. Throws on invalid scalar.
  BuBytes scMul(List<int> a, List<int> b);

  /// Scalar negation mod n; [scalarLen] bytes. Returns [scalarLen] bytes. Throws on invalid scalar.
  BuBytes scNeg(List<int> s);

  /// Reduces arbitrary-length [s] mod n. Returns [scalarLen] bytes. Throws on empty input.
  BuBytes scReduce(List<int> s);

  /// Generator point. Returns [pointLen] bytes, never null.
  BuBytes generator();

  /// Identity (zero) point. Returns [pointLen] bytes, never null.
  BuBytes identity();

  /// Computes s1·p1 + s2·p2; scalars [scalarLen] bytes, points [pointLen] bytes. Returns [pointLen] bytes. Throws on invalid input.
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2);
}

/// Ed25519/EdDSA-specific curve operations, beyond the shared [CurveApi].
abstract interface class Ed25519CurveApi implements CurveApi {
  /// Reduces [scalar] (any length, 32-byte LE) then multiplies by base. Returns 32-byte compressed point. Throws on invalid input.
  BuBytes reduceMultBase(List<int> scalar);

  /// Point addition (variable-time); both 32-byte compressed. Returns 32-byte compressed point. Throws on invalid encoding.
  BuBytes addVar(List<int> a, List<int> b);

  /// a·A + b·B with precomputed tables [aI]/[bI] (from geDsmPrecompVar); scalars 32-byte LE. Returns 32-byte compressed point. Throws on invalid input.
  BuBytes geDoubleScalarMultPrecompPointVar(
    List<int> a,
    List<List<int>> aI,
    List<int> b,
    List<List<int>> bI,
  );

  /// a·B + b·P + c·Q with precomputed [bI]/[cI]; scalars 32-byte LE, points 32-byte compressed. Returns 32-byte compressed point. Throws on invalid input.
  BuBytes geTripleScalarMultBasePointVar({
    required List<int> a,
    required List<int> b,
    required List<List<int>> bI,
    required List<int> c,
    required List<List<int>> cI,
  });

  /// a·B + b·P; [a]/[b] 32-byte LE scalars, [g]/[b] 32-byte compressed points. Returns 32-byte compressed point. Throws on invalid input.
  BuBytes geDoubleScalarMultBasePointVar({
    required List<int> a,
    required List<int> g,
    required List<int> b,
  });

  /// a·A + b·B + c·C with precomputed [aI]/[bI]/[cI]; scalars 32-byte LE. Returns 32-byte compressed point. Throws on invalid input.
  BuBytes geTripleScalarMultPrecompPointVar(
    List<int> a,
    List<List<int>> aI,
    List<int> b,
    List<List<int>> bI,
    List<int> c,
    List<List<int>> cI,
  );

  /// Precomputes sliding-window table for [p] (32-byte compressed) for the *_PrecompPointVar multis. Returns table rows. Throws on invalid point.
  List<List<int>> geDsmPrecompVar(List<int> p);

  /// Scalar subtraction (variable-time); both 32-byte LE. Returns 32-byte scalar. Throws on invalid scalar.
  BuBytes scSubVar(List<int> a, List<int> b);

  /// Scalar multiplication (variable-time); both 32-byte LE. Returns 32-byte scalar. Throws on invalid scalar.
  BuBytes scMulVar(List<int> a, List<int> b);

  /// Scalar addition (variable-time); both 32-byte LE. Returns 32-byte scalar. Throws on invalid scalar.
  BuBytes scAddVar(List<int> a, List<int> b);

  /// Computes a·b + c; all 32-byte LE scalars. Returns 32-byte scalar. Throws on invalid scalar.
  BuBytes scMulAdd(List<int> a, List<int> b, List<int> c);

  /// Computes a·b − c; all 32-byte LE scalars. Returns 32-byte scalar. Throws on invalid scalar.
  BuBytes scMulSub(List<int> a, List<int> b, List<int> c);

  /// True if 32-byte LE [s] is non-zero (and canonical), else false, never throws for bad length.
  bool scIsNonZero(List<int> s);

  /// Reduces 64-byte [s] mod L. Returns 32-byte LE scalar. Throws on invalid length.
  BuBytes scReduce64(List<int> s);

  /// Multiplies [point] (32-byte compressed) by the cofactor 8. Returns 32-byte compressed point. Throws on invalid encoding.
  BuBytes mul8(List<int> point);

  /// Fused `mul8(mult(scalar, point))`: computes 8 * (scalar * point) without
  /// intermediate encoding; [scalar] and [point] are 32-byte LE/compressed.
  /// Returns 32-byte compressed point. Throws on invalid input.
  /// Constant-time on [scalar].
  BuBytes mul8Mult(List<int> scalar, List<int> point);

  /// Maps 32-byte [data] to a 32-byte compressed Edwards point (Elligator/hash-to-point). Throws on invalid length.
  BuBytes hashToEc(List<int> data);

  /// Computes s1·p1 + s2·p2; scalars 32-byte LE, points 32-byte compressed. Returns 32-byte compressed point. Throws on invalid input.
  BuBytes doubleScalarMult(
    List<int> s1,
    List<int> p1,
    List<int> s2,
    List<int> p2,
  );

  /// Computes scalar·scalar2 + scalar3 (variable-time); all 32-byte LE. Returns 32-byte scalar. Throws on invalid scalar.
  BuBytes scMulAddVar(List<int> scalar, List<int> scalar2, List<int> scalar3);
}

/// secp256k1 curve operations: compressed (33) + uncompressed (65) forms.
abstract interface class Secp256k1CurveApi implements CurveApi {
  /// Uncompressed point length (65).
  int get uncompressedLen;

  /// Either form → compressed. Strict validation on decode.
  BuBytes compress(List<int> point);

  /// Either form → uncompressed. Strict validation on decode.
  BuBytes uncompress(List<int> point);
}

/// secp256r1 (NIST P-256): compressed (33) + uncompressed (65) forms.
abstract interface class Secp256r1CurveApi implements CurveApi {
  /// Uncompressed point length (65).
  int get uncompressedLen;

  /// Either form → compressed. Strict validation on decode.
  BuBytes compress(List<int> point);

  /// Either form → uncompressed. Strict validation on decode.
  BuBytes uncompress(List<int> point);
}

/// BLS12-381 G1: compressed (48) + uncompressed (96) forms.
abstract interface class G1ProjectiveCurveApi implements CurveApi {
  /// Uncompressed point length (96).
  int get uncompressedLen;

  /// Either form → compressed. Strict validation on decode.
  BuBytes compress(List<int> point);

  /// Either form → uncompressed. Strict validation on decode.
  BuBytes uncompress(List<int> point);
}

/// BLS12-381 G2: compressed (96) + uncompressed (192) forms.
abstract interface class G2ProjectiveCurveApi implements CurveApi {
  /// Uncompressed point length (192).
  int get uncompressedLen;

  /// Either form → compressed. Strict validation on decode.
  BuBytes compress(List<int> point);

  /// Either form → uncompressed. Strict validation on decode.
  BuBytes uncompress(List<int> point);
}

/// BN254 (alt_bn128) G1 curve operations (no extras beyond [CurveApi]).
/// Points are 64-byte uncompressed (EIP-197), scalars 32-byte big-endian.
/// Only the native (Rust) implementation exists; the pure-Dart
/// implementation throws [UnsupportedError].
abstract interface class Bn254G1CurveApi implements CurveApi {}

/// BN254 (alt_bn128) G2 curve operations (no extras beyond [CurveApi]).
/// Points are 128-byte uncompressed (EIP-197 word order x1,x0,y1,y0),
/// scalars 32-byte big-endian. Only the native (Rust) implementation
/// exists; the pure-Dart implementation throws [UnsupportedError].
abstract interface class Bn254G2CurveApi implements CurveApi {}

/// JubJub curve operations, beyond the shared [CurveApi].
abstract interface class JubJubCurveApi implements CurveApi {
  /// Reduces 64-byte [s] mod the JubJub scalar order. Returns 32-byte scalar. Throws on invalid length.
  BuBytes scReduce64(List<int> s);

  /// Clears the JubJub cofactor (×8) of 32-byte [point].
  /// Returns the cleared point bytes, or `null` when the result is the
  /// identity (matches `groupHash` skip semantics). Throws on invalid point
  /// encoding or length.
  BuBytes? clearCofactor(List<int> point);
}

/// Pallas curve operations, beyond the shared [CurveApi].
abstract interface class PallasCurveApi implements CurveApi {
  /// Reduces 64-byte [s] mod the Pallas scalar order. Returns 32-byte scalar. Throws on invalid length.
  BuBytes scReduce64(List<int> s);

  /// RFC 9380-style hash-to-curve (SHA-256 SSWU + isogeny).
  /// [dst] default: `PALLAS_XMD:SHA-256_SSWU_RO_`
  BuBytes hashToCurve(List<int> msg, {List<int>? dst});

  /// Pasta / Halo2 `hash_to_curve`: BLAKE2b personalization prefix + message.
  /// Same as `PallasPoint.hashToCurve(domainPrefix:, message:)`.
  BuBytes hashToCurvePasta({
    required String domainPrefix,
    required List<int> message,
  });
}

/// Vesta curve operations, beyond the shared [CurveApi].
abstract interface class VestaCurveApi implements CurveApi {
  /// Reduces 64-byte [s] mod the Vesta scalar order. Returns 32-byte scalar. Throws on invalid length.
  BuBytes scReduce64(List<int> s);

  /// RFC 9380-style hash-to-curve over [msg] with optional [dst]. Returns compressed point bytes. Throws on crypto failure.
  BuBytes hashToCurve(List<int> msg, {List<int>? dst});
}

/// Ristretto group operations, beyond the shared [CurveApi].
abstract interface class RistrettoCurveApi implements CurveApi {
  /// Converts 32-byte Edwards compressed [edwards32] to 32-byte Ristretto bytes. Throws on invalid encoding.
  BuBytes pointFromEdwardBytes(List<int> edwards32);

  /// Converts 32-byte Ristretto [ristretto32] to 32-byte Edwards compressed bytes. Throws on invalid encoding.
  BuBytes toEdwardBytes(List<int> ristretto32);

  /// Computes a·b + c; all 32-byte LE scalars. Returns 32-byte scalar. Throws on invalid scalar.
  BuBytes scMulAdd(List<int> a, List<int> b, List<int> c);

  /// Computes a·b − c; all 32-byte LE scalars. Returns 32-byte scalar. Throws on invalid scalar.
  BuBytes scMulSub(List<int> a, List<int> b, List<int> c);

  /// Reduces 64-byte [s] mod L. Returns 32-byte LE scalar. Throws on invalid length.
  BuBytes scReduce64(List<int> s);
}

/// Validates lengths on every [CurveApi] call, then delegates to [inner].
///
/// Inner implementation should **not** re-validate; crypto failures surface as
/// [CryptoException].
class ValidatedCurveApi implements CurveApi {
  const ValidatedCurveApi(this.inner, {this.tag = 'CurveApi'});
  final CurveApi inner;
  final String tag;

  @override
  int get pointLen => inner.pointLen;

  @override
  int get scalarLen => inner.scalarLen;

  /// Throws if [s] isn't exactly [scalarLen] bytes.
  void validateScalar(List<int> s, String op) {
    ApiValidate.length(s, scalarLen, operation: '$tag.$op', name: 'scalar');
  }

  /// Throws if [p] isn't exactly [pointLen] bytes.
  void validatePoint(List<int> p, String op) {
    ApiValidate.length(p, pointLen, operation: '$tag.$op', name: 'point');
  }

  /// Runs [run], wrapping any non-crypto exception as [CryptoException].
  T call<T>(String op, T Function() run) {
    try {
      return run();
    } on BuError {
      rethrow;
    } catch (e) {
      throw CoreErrors.cryptoFailed('$tag.$op', reason: e.toString());
    }
  }

  @override
  bool scCheck(List<int> s) {
    if (s.length != scalarLen) return false;
    return call('scCheck', () => inner.scCheck(s));
  }

  @override
  BuBytes scReduce(List<int> s) {
    ApiValidate.nonEmpty(s, operation: '$tag.scReduce', name: 'scalar');
    return call('scReduce', () => inner.scReduce(s));
  }

  @override
  BuBytes scAdd(List<int> a, List<int> b) {
    validateScalar(a, 'scAdd');
    validateScalar(b, 'scAdd');
    return call('scAdd', () => inner.scAdd(a, b));
  }

  @override
  BuBytes scSub(List<int> a, List<int> b) {
    validateScalar(a, 'scSub');
    validateScalar(b, 'scSub');
    return call('scSub', () => inner.scSub(a, b));
  }

  @override
  BuBytes scMul(List<int> a, List<int> b) {
    validateScalar(a, 'scMul');
    validateScalar(b, 'scMul');
    return call('scMul', () => inner.scMul(a, b));
  }

  @override
  BuBytes scNeg(List<int> s) {
    validateScalar(s, 'scNeg');
    return call('scNeg', () => inner.scNeg(s));
  }

  @override
  BuBytes multBase(List<int> scalar) {
    validateScalar(scalar, 'multBase');
    return call('multBase', () => inner.multBase(scalar));
  }

  @override
  BuBytes mult(List<int> scalar, List<int> point) {
    validateScalar(scalar, 'mult');
    validatePoint(point, 'mult');
    return call('mult', () => inner.mult(scalar, point));
  }

  @override
  BuBytes add(List<int> a, List<int> b) {
    validatePoint(a, 'add');
    validatePoint(b, 'add');
    return call('add', () => inner.add(a, b));
  }

  @override
  BuBytes sub(List<int> a, List<int> b) {
    validatePoint(a, 'sub');
    validatePoint(b, 'sub');
    return call('sub', () => inner.sub(a, b));
  }

  @override
  BuBytes neg(List<int> point) {
    validatePoint(point, 'neg');
    return call('neg', () => inner.neg(point));
  }

  @override
  BuBytes generator() => call('generator', () => inner.generator());

  @override
  BuBytes identity() => call('identity', () => inner.identity());

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) {
    validateScalar(s1, 'mulAdd');
    validatePoint(p1, 'mulAdd');
    validateScalar(s2, 'mulAdd');
    validatePoint(p2, 'mulAdd');
    return call('mulAdd', () => inner.mulAdd(s1, p1, s2, p2));
  }
}
