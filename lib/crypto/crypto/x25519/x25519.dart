import 'dart:typed_data';

import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/crypto/ec/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

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
  factory X25519Keypair({
    required List<int> privateKey,
    required List<int> publicKey,
    bool validatePublicKey = false,
  }) {
    if (privateKey.length != Ed25519KeysConst.privKeyByteLen) {
      throw ArgumentException.invalidOperationArguments(
        "X25519Keypair",
        name: "privateKey",
        reason: 'Invalid private key bytes length',
      );
    }
    if (publicKey.length != Ed25519KeysConst.pubKeyByteLen) {
      throw ArgumentException.invalidOperationArguments(
        "X25519Keypair",
        name: "publicKey",
        reason: 'Invalid public key bytes length',
      );
    }
    final u = BigintUtils.fromBytes(publicKey, byteOrder: Endian.little);
    if (u >= X25519KeyConst.p) {
      throw ArgumentException.invalidOperationArguments(
        "X25519Keypair",
        name: "uBytes",
        reason: 'Invalid public key',
      );
    }
    if (validatePublicKey) {
      final key = X25519.scalarMultBase(privateKey);
      if (!BytesUtils.bytesEqual(key.publicKey, publicKey)) {
        throw CryptoException.failed(
          "X25519Keypair",
          reason: "Validation public key failed.",
        );
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
  static BigInt get p => Curves.curveEd25519.p;
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
    final BigInt a24 = BigInt.from(121666);
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

      final z4 = _fieldMul(E, _fieldAdd(bb, _fieldMul(a24, E)));

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

    return BigintUtils.toBytes(
      xOut,
      length: Ed25519KeysConst.pubKeyByteLen,
      order: Endian.little,
    );
  }

  /// Perform scalar multiplication with the base point (u = 9).
  /// Returns the X25519 keypair.
  static X25519Keypair scalarMultBase(List<int> scalar) {
    final BigInt baseU = BigInt.from(9);
    if (scalar.length != Ed25519KeysConst.privKeyByteLen) {
      throw ArgumentException.invalidOperationArguments(
        "scalarMultBase",
        name: "scalar",
        reason: 'Incorrect scalar bytes length.',
      );
    }
    final clamped = _clampScalar(scalar);
    final pk = _montgomeryLadder(clamped, baseU);
    return X25519Keypair._(privateKey: clamped, publicKey: pk);
  }

  /// Perform scalar multiplication with an arbitrary public key (u-coordinate).
  /// Returns the shared secret.
  static List<int> scalarMult(List<int> scalar, List<int> uBytes) {
    if (scalar.length != Ed25519KeysConst.privKeyByteLen) {
      throw ArgumentException.invalidOperationArguments(
        "scalarMultBase",
        name: "scalar",
        reason: 'Incorrect scalar bytes length.',
      );
    }
    if (uBytes.length != Ed25519KeysConst.pubKeyByteLen) {
      throw ArgumentException.invalidOperationArguments(
        "scalarMultBase",
        name: "uBytes",
        reason: 'Incorrect public key bytes length.',
      );
    }
    final clamped = _clampScalar(scalar);
    final u = BigintUtils.fromBytes(uBytes, byteOrder: Endian.little);
    if (u >= X25519KeyConst.p) {
      throw CryptoException.failed("scalarMult", reason: "Invalid public key.");
    }
    return _montgomeryLadder(clamped, u);
  }
}
