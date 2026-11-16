import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/g2.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Pure-Dart BLS12-381 **G2** curve API.
///
/// - Points: 96-byte compressed G2
/// - Scalars: 32-byte big-endian Fr (BLS12-381 subgroup order, matches Rust)
class DartG2ProjectiveCurveApi implements G2ProjectiveCurveApi {
  static const int _pointLen = 96;
  static const int _scalarLen = 32;

  @override
  int get pointLen => _pointLen;

  @override
  int get scalarLen => _scalarLen;

  JubJubFq _sc(List<int> s) {
    try {
      return JubJubFq.fromBytes(s, endian: Endian.big);
    } catch (_) {
      throw CoreErrors.cryptoFailed(
        'G2.scalar',
        reason: 'Invalid scalar bytes.',
      );
    }
  }

  BuBytes _scOut(JubJubFq scalar) {
    return BuBytes(scalar.toBytes().reversed.toList());
  }

  G2Projective _pt(List<int> p) {
    try {
      return G2Projective.fromBytes(p);
    } catch (e) {
      throw CoreErrors.cryptoFailed('G2.fromBytes', reason: '$e');
    }
  }

  G2Projective _ptFast(List<int> p) {
    try {
      return G2Projective.fromBytes(p);
    } catch (e) {
      throw CoreErrors.cryptoFailed('G2.fromBytes', reason: '$e');
    }
  }

  BuBytes _ptOut(BaseBls12Point p) => p.toBytes(mode: CryptoKeyEncoding.base);

  BuBytes _ptOutUncompressed(BaseBls12Point p) =>
      p.toBytes(mode: CryptoKeyEncoding.uncompressed);

  G2Projective _mul(G2Projective p, List<int> scalarBe32) {
    final scalar = _sc(scalarBe32);
    return p * scalar;
  }

  @override
  bool scCheck(List<int> s) {
    if (s.length != _scalarLen) return false;
    try {
      _sc(s);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  BuBytes scReduce(List<int> s) {
    // Real mod-r reduction (matches Rust): widen BE bytes to 64 LE bytes.
    if (s.length != _scalarLen) {
      throw CoreErrors.cryptoFailed(
        'G2.scReduce',
        reason: 'Invalid scalar length.',
      );
    }
    return _scOut(JubJubFq.fromBytesUnchecked(s, endian: Endian.big));
  }

  @override
  BuBytes scAdd(List<int> a, List<int> b) => _scOut(_sc(a) + _sc(b));

  @override
  BuBytes scSub(List<int> a, List<int> b) => _scOut(_sc(a) - _sc(b));

  @override
  BuBytes scMul(List<int> a, List<int> b) => _scOut(_sc(a) * _sc(b));

  @override
  BuBytes scNeg(List<int> s) => _scOut(-_sc(s));

  @override
  BuBytes generator() => _ptOut(G2Projective.generator);

  @override
  BuBytes identity() => _ptOut(G2Projective.identity);
  @override
  BuBytes multBase(List<int> scalar) {
    final bytes = _scOut(_sc(scalar));
    return _ptOut(_mul(G2Projective.generator, bytes));
  }

  @override
  BuBytes mult(List<int> scalar, List<int> point) {
    final bytes = _scOut(_sc(scalar));
    return _ptOut(_mul(_pt(point), bytes));
  }

  @override
  BuBytes add(List<int> a, List<int> b) => _ptOut(_ptFast(a) + _ptFast(b));

  @override
  BuBytes sub(List<int> a, List<int> b) => _ptOut(_ptFast(a) - _ptFast(b));

  @override
  BuBytes neg(List<int> point) => _ptOut(-_ptFast(point));

  @override
  BuBytes mulAdd(List<int> s1, List<int> p1, List<int> s2, List<int> p2) =>
      add(mult(s1, p1), mult(s2, p2));

  @override
  int get uncompressedLen => 192;

  @override
  BuBytes compress(List<int> point) => _ptOut(_pt(point));

  @override
  BuBytes uncompress(List<int> point) => _ptOutUncompressed(_pt(point));
}
