import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/params.dart';

/// Modular arithmetic in the ML-DSA prime field (q = 8380417).
class MLDSAOperator {
  static const int q = MLDSAParams.q;

  /// Reduce a into [0, q).
  /// Handles values that appear after multiplication (roughly |a| < 2^46).
  static int fieldReduce(int a) {
    // First bring into a manageable range
    a %= q;
    if (a < 0) a += q;
    return a;
  }

  /// Modular multiplication.
  static int fieldMul(int a, int b) {
    return fieldReduce(a * b);
  }

  /// Modular addition.
  static int fieldAdd(int a, int b) {
    var r = a + b;
    if (r >= q) r -= q;
    if (r < 0) r += q;
    return r;
  }

  /// Modular subtraction.
  static int fieldSub(int a, int b) {
    var r = a - b;
    if (r < 0) r += q;
    if (r >= q) r -= q;
    return r;
  }

  /// Conditional subtraction of q.
  static int fieldCSubQ(int a) {
    return a >= q ? a - q : a;
  }

  /// Centered representative in (-q/2, q/2].
  static int fieldCenter(int a) {
    final r = fieldReduce(a);
    return r > (q ~/ 2) ? r - q : r;
  }

  /// Freeze to [0, q).
  static int fieldFreeze(int a) {
    a %= q;
    if (a < 0) a += q;
    return a;
  }
}
