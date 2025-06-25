import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Represents an X25519 keypair used for elliptic curve Diffie-Hellman (ECDH).
class X25519Keypair {
  /// The 32-byte clamped private scalar.
  final List<int> privateKey;

  /// The corresponding 32-byte public key (u-coordinate).
  final List<int> publicKey;

  String privateKeyHex() {
    return BytesUtils.toHexString(privateKey);
  }

  String publicKeyHex() {
    return BytesUtils.toHexString(publicKey);
  }

  X25519Keypair._({required List<int> privateKey, required List<int> publicKey})
      : privateKey = privateKey.asImmutableBytes,
        publicKey = publicKey.asImmutableBytes;

  /// Public constructor with validation of key lengths and public key canonicality.
  factory X25519Keypair(
      {required List<int> privateKey,
      required List<int> publicKey,
      bool validatePublicKey = false}) {
    if (privateKey.length != X25519KeyConst.privateKeyLength) {
      throw CryptoException('invalid private key bytes length');
    }
    if (publicKey.length != X25519KeyConst.publickKeyLength) {
      throw CryptoException('invalid public key bytes length');
    }
    final u = BigintUtils.fromBytes(publicKey, byteOrder: Endian.little);
    if (u >= X25519KeyConst.p) {
      throw CryptoException('uBytes is not a canonical field element');
    }
    if (validatePublicKey) {
      final key = X25519.scalarMultBase(privateKey);
      if (!BytesUtils.bytesEqual(key.publicKey, publicKey)) {
        throw CryptoException('invalid public.');
      }
    }
    return X25519Keypair._(privateKey: privateKey, publicKey: publicKey);
  }

  /// Generates a new X25519 keypair.
  ///
  /// Optionally accepts a [seed] for deterministic key generation (e.g. from a mnemonic).
  /// If no seed is provided, uses cryptographically secure random bytes.
  factory X25519Keypair.generate({List<int>? seed}) {
    return X25519.scalarMultBase(seed ?? QuickCrypto.generateRandom());
  }
}

class X25519KeyConst {
  static const int privateKeyLength = 32;
  static const int publickKeyLength = 32;
  static final BigInt p = Curves.curveEd25519.p;
  static final BigInt baseU = BigInt.from(9);
  static final BigInt a24 = BigInt.from(121666);
}

/// Implements scalar multiplication on Curve25519 using the Montgomery ladder.
/// This is the basis for X25519 key agreement as described in RFC 7748.
class X25519 {
  /// Clamp the scalar as per X25519 spec.
  static List<int> _clampScalar(List<int> scalar) {
    scalar = List.from(scalar);
    scalar[0] &= 248;
    scalar[31] &= 127;
    scalar[31] |= 64;
    return scalar;
  }

  static BigInt _modP(BigInt x) =>
      (x % X25519KeyConst.p + X25519KeyConst.p) % X25519KeyConst.p;

  static BigInt _fieldAdd(BigInt a, BigInt b) => _modP(a + b);

  static BigInt _fieldSub(BigInt a, BigInt b) => _modP(a - b);

  static BigInt _fieldMul(BigInt a, BigInt b) => _modP(a * b);

  static BigInt _fieldInv(BigInt a) =>
      a.modPow(X25519KeyConst.p - BigInt.from(2), X25519KeyConst.p);

  /// The Montgomery ladder core for constant-time scalar multiplication.
  /// Returns the u-coordinate of the resulting point.
  static List<int> _montgomeryLadder(List<int> scalar, BigInt u) {
    BigInt x1 = u;
    BigInt x2 = BigInt.one;
    BigInt z2 = BigInt.zero;
    BigInt x3 = u;
    BigInt z3 = BigInt.one;

    int swap = 0;

    BigInt scalarInt = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    for (int t = 254; t >= 0; t--) {
      int kt = ((scalarInt >> t) & BigInt.one).toInt();
      swap ^= kt;
      if (swap == 1) {
        // Swap (x2, x3) and (z2, z3)
        BigInt tmp = x2;
        x2 = x3;
        x3 = tmp;
        tmp = z2;
        z2 = z3;
        z3 = tmp;
      }
      swap = kt;

      final A = _fieldAdd(x2, z2);
      final aa = _fieldMul(A, A);
      final B = _fieldSub(x2, z2);
      final bb = _fieldMul(B, B);
      final E = _fieldSub(aa, bb);
      final C = _fieldAdd(x3, z3);
      final D = _fieldSub(x3, z3);
      final da = _fieldMul(D, A);
      final cb = _fieldMul(C, B);
      final x5 = _fieldMul(_fieldAdd(da, cb), _fieldAdd(da, cb));
      final z5 = _fieldMul(x1, _fieldMul(_fieldSub(da, cb), _fieldSub(da, cb)));
      final x4 = _fieldMul(aa, bb);
      final z4 = _fieldMul(E, _fieldAdd(bb, _fieldMul(X25519KeyConst.a24, E)));

      x2 = x4;
      z2 = z4;
      x3 = x5;
      z3 = z5;
    }

    if (swap == 1) {
      BigInt tmp = x2;
      x2 = x3;
      x3 = tmp;
      tmp = z2;
      z2 = z3;
      z3 = tmp;
    }

    BigInt z2inv = _fieldInv(z2);
    BigInt xOut = _fieldMul(x2, z2inv);

    return BigintUtils.toBytes(xOut,
        length: X25519KeyConst.publickKeyLength, order: Endian.little);
  }

  /// Perform scalar multiplication with the base point (u = 9).
  /// Returns the X25519 keypair.
  static X25519Keypair scalarMultBase(List<int> scalar) {
    if (scalar.length != X25519KeyConst.privateKeyLength) {
      throw CryptoException('invalid scalar bytes length');
    }
    final clamped = _clampScalar(scalar);
    final pk = _montgomeryLadder(clamped, X25519KeyConst.baseU);
    return X25519Keypair._(privateKey: clamped, publicKey: pk);
  }

  /// Perform scalar multiplication with an arbitrary public key (u-coordinate).
  /// Returns the shared secret.
  static List<int> scalarMult(List<int> scalar, List<int> uBytes) {
    if (scalar.length != X25519KeyConst.privateKeyLength) {
      throw CryptoException('invalid scalar bytes length');
    }
    if (uBytes.length != X25519KeyConst.publickKeyLength) {
      throw CryptoException('invalid u bytes length');
    }
    final clamped = _clampScalar(scalar);
    final u = BigintUtils.fromBytes(uBytes, byteOrder: Endian.little);
    if (u >= X25519KeyConst.p) {
      throw CryptoException('uBytes is not a canonical field element');
    }
    return _montgomeryLadder(clamped, u);
  }
}
