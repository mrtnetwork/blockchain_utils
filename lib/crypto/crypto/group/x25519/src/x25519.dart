import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/fields.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Returns whether the 32-byte little-endian [u] is canonically below the
/// field prime p = 2^255 - 19, without BigInt: MSB-first byte comparison
/// over public input bytes (decode-time validation only).
/// p in LE bytes is `[0xED, 0xFF x30, 0x7F]`.
bool _isLessThanP(List<int> u) {
  assert(u.length == Ed25519KeysConst.pubKeyByteLen);
  if (u[31] != 0x7F) return u[31] < 0x7F;
  for (var i = 30; i >= 1; i--) {
    if (u[i] != 0xFF) return u[i] < 0xFF;
  }
  return u[0] < 0xED;
}

/// Represents an X25519 keypair used for elliptic curve Diffie-Hellman (ECDH).
class X25519Keypair {
  /// The 32-byte clamped private scalar.
  final BuBytes privateKey;

  /// The corresponding 32-byte public key (u-coordinate).
  final BuBytes publicKey;

  /// Hex-encodes [privateKey].
  String privateKeyHex() {
    return privateKey.toHex();
  }

  /// Hex-encodes [publicKey].
  String publicKeyHex() {
    return publicKey.toHex();
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
      throw CoreErrors.invalidOperationArguments(
        "X25519Keypair",
        name: "privateKey",
        reason: 'Invalid private key bytes length',
      );
    }
    if (publicKey.length != Ed25519KeysConst.pubKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "X25519Keypair",
        name: "publicKey",
        reason: 'Invalid public key bytes length',
      );
    }
    // BigInt-less canonical check (u < p); public input validation.
    if (!_isLessThanP(publicKey)) {
      throw CoreErrors.invalidOperationArguments(
        "X25519Keypair",
        name: "publicKey",
        reason: 'Invalid public key',
      );
    }
    if (validatePublicKey) {
      final key = X25519.scalarMultBase(privateKey);
      if (!BytesUtils.bytesEqual(key.publicKey, publicKey)) {
        throw CoreErrors.cryptoFailed(
          "X25519Keypair",
          reason: "Validation public key failed.",
        );
      }
    }
    return X25519Keypair._(privateKey: privateKey, publicKey: publicKey);
  }

  /// Generates a new X25519 keypair.
  ///
  /// Optionally accepts a 32-byte [seed] for deterministic key generation.
  /// If no seed is provided, uses cryptographically secure random bytes.
  factory X25519Keypair.generate({List<int>? seed}) {
    return X25519.scalarMultBase(seed ?? QuickCrypto.generateRandom());
  }

  BuBytes operator *(List<int> uBytes) {
    return X25519.scalarMult(privateKey, uBytes);
  }
}

/// Implements scalar multiplication on Curve25519 using the Montgomery ladder.
/// This is the basis for X25519 key agreement as described in RFC 7748.
class X25519 {
  static BuBytes fromEd25519Seed(List<int> seed) {
    if (seed.length != Ed25519KeysConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "X25519.fromEd25519Seed",
        reason: "Invalid seed bytes length.",
      );
    }
    final hash = QuickCrypto.sha512Hash(seed);
    return clampScalar(hash.sublist(0, Ed25519KeysConst.privKeyByteLen));
  }

  static BuBytes fromEd25519PublicKey(List<int> ed25519Pk) {
    // Birational map u = (1 + y) / (1 - y) on the Edwards field: fromBytes
    // yields z = 1, so the stored y limbs are already affine.
    final point = EdwardsLimbPoint.fromBytes(ed25519Pk);
    final y = point.y;
    if (y == Ed25519Fp.one) {
      throw CoreErrors.cryptoFailed(
        "X25519.fromEd25519PublicKey",
        reason: 'Invalid Ed25519 point: cannot invert (y == 1)',
      );
    }
    final u = (Ed25519Fp.one + y) * (Ed25519Fp.one - y).invert()!;
    return u.toBytes();
  }

  /// Clamp the scalar as per X25519 spec.
  static BuBytes clampScalar(List<int> scalar) {
    final s = BuBytes(scalar);
    s[0] &= 248;
    s[31] &= 127;
    s[31] |= 64;
    return s;
  }

  /// The Montgomery ladder core for scalar multiplication, over the
  /// fixed-limb field [Ed25519Fp] (2^255-19, the same field — and the same
  /// branchless limb arithmetic — as the other limb curves). Per-bit
  /// conditional swaps and the uniform ladder step are straight-line:
  /// selects blend [Uint64] 0/1 mask bits, never `bool`s on the secret
  /// scalar. Returns the u-coordinate of the resulting point.
  static BuBytes _montgomeryLadder(List<int> scalar, Ed25519Fp u) {
    final a24 = Ed25519Fp.from(Uint64(121666));
    final x1 = u;
    var x2 = Ed25519Fp.one;
    var z2 = Ed25519Fp.zero;
    var x3 = u;
    var z3 = Ed25519Fp.one;

    var swap = Uint64.zero;
    for (int t = 254; t >= 0; t--) {
      final kt = Uint64((scalar[t >> 3] >> (t & 7)) & 1);
      swap = swap ^ kt;
      // Branchless conditional swap of (x2, x3) and (z2, z3).
      final nx2 = Ed25519Fp.conditionalSelectMask(x2, x3, swap);
      final nz2 = Ed25519Fp.conditionalSelectMask(z2, z3, swap);
      x3 = Ed25519Fp.conditionalSelectMask(x3, x2, swap);
      z3 = Ed25519Fp.conditionalSelectMask(z3, z2, swap);
      x2 = nx2;
      z2 = nz2;
      swap = kt;

      final a = x2 + z2;
      final aa = a.square();
      final b = x2 - z2;
      final bb = b.square();
      final e = aa - bb;
      final c = x3 + z3;
      final d = x3 - z3;
      final da = d * a;
      final cb = c * b;
      final x5 = (da + cb).square();
      final z5 = x1 * (da - cb).square();
      final x4 = aa * bb;
      final z4 = e * (bb + a24 * e);

      x2 = x4;
      z2 = z4;
      x3 = x5;
      z3 = z5;
    }
    // Final conditional swap (RFC 7748): places the ladder output in x2.
    final fx2 = Ed25519Fp.conditionalSelectMask(x2, x3, swap);
    final fz2 = Ed25519Fp.conditionalSelectMask(z2, z3, swap);
    x3 = Ed25519Fp.conditionalSelectMask(x3, x2, swap);
    z3 = Ed25519Fp.conditionalSelectMask(z3, z2, swap);
    x2 = fx2;
    z2 = fz2;

    // u = 0 (or another zero-z2 edge) inverts to nothing: emit zeros).
    final z2inv = z2.invert() ?? Ed25519Fp.zero;
    return (x2 * z2inv).toBytes();
  }

  /// Perform scalar multiplication with the base point (u = 9).
  /// Returns the X25519 keypair.
  static X25519Keypair scalarMultBase(List<int> scalar) {
    if (scalar.length != Ed25519KeysConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "scalarMultBase",
        name: "scalar",
        reason: 'Incorrect scalar bytes length.',
      );
    }
    final clamped = clampScalar(scalar);
    final pk = _montgomeryLadder(clamped, Ed25519Fp.from(Uint64(9)));
    return X25519Keypair._(privateKey: clamped, publicKey: pk);
  }

  /// Perform scalar multiplication with an arbitrary public key (u-coordinate).
  /// Returns the shared secret.
  static BuBytes scalarMult(List<int> scalar, List<int> uBytes) {
    if (scalar.length != Ed25519KeysConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "scalarMult",
        name: "scalar",
        reason: 'Incorrect scalar bytes length.',
      );
    }
    if (uBytes.length != Ed25519KeysConst.pubKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "scalarMult",
        name: "uBytes",
        reason: 'Incorrect public key bytes length.',
      );
    }
    final clamped = clampScalar(scalar);
    // BigInt-less canonical check (u < p); public input validation.
    if (!_isLessThanP(uBytes)) {
      throw CoreErrors.cryptoFailed("scalarMult", reason: "Invalid public key.");
    }
    return _montgomeryLadder(clamped, Ed25519Fp.fromBytesUnchecked(uBytes));
  }
}
