import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// PBKDF2 (SHA-256/SHA-512), scrypt and HKDF key derivation.
///
/// HKDF follows the per-hash-method convention of PBKDF2
/// (`hkdfSha256DeriveKey` / `hkdfSha512DeriveKey`): one method per hash,
/// no hash-enum parameter. Only SHA-256/SHA-512 — both native transports
/// agree on these two (SHA-1 HKDF stays direct-class-only).
abstract interface class KeyDerivationApi {
  /// Derives [length] bytes with PBKDF2-HMAC-SHA256 from arbitrary [password]/[salt].
  /// [iterations] and [length] must be non-negative. Throws on negative values or backend failure.
  BuBytes pbkdf2Sha256DeriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  });

  /// Derives [length] bytes with PBKDF2-HMAC-SHA512 from arbitrary [password]/[salt].
  /// [iterations] and [length] must be non-negative. Throws on negative values or backend failure.
  BuBytes pbkdf2Sha512DeriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  });

  /// Derives [dkLen] bytes with scrypt from arbitrary [password]/[salt].
  /// [dkLen], [r], [n], [p] must be non-negative. Throws on negative values or backend failure.
  BuBytes scryptDeriveKey({
    required List<int> password,
    required List<int> salt,
    required int dkLen,
    required int r,
    required int n,
    required int p,
  });

  /// Strict RFC 5869 HKDF-SHA-256 (always Extract-then-Expand).
  /// Omitted [salt] defaults to 32 zero bytes (§2.2) on every backend;
  /// [info] may be empty. [length] must be 1..255*32. Throws on
  /// invalid arguments or backend failure.
  BuBytes hkdfSha256DeriveKey({
    required List<int> ikm,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  });

  /// Strict RFC 5869 HKDF-SHA-512 (always Extract-then-Expand).
  /// Omitted [salt] defaults to 64 zero bytes (§2.2) on every backend;
  /// [info] may be empty. [length] must be 1..255*64. Throws on
  /// invalid arguments or backend failure.
  BuBytes hkdfSha512DeriveKey({
    required List<int> ikm,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  });
}

/// [KeyDerivationApi] wrapper that rejects negative numeric arguments
/// before delegating.
class ValidatedKeyDerivationApi implements KeyDerivationApi {
  final KeyDerivationApi inner;
  const ValidatedKeyDerivationApi(this.inner);

  void _isValid(List<int> n, String operation) {
    if (n.any((e) => e.isNegative)) {
      throw CoreErrors.invalidOperationArguments(
        operation,
        reason: "Invalid arguments. Numbers must be non-negative.",
      );
    }
  }

  @override
  BuBytes pbkdf2Sha256DeriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    _isValid([iterations, length], "pbkdf2Sha256DeriveKey");
    return inner.pbkdf2Sha256DeriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
      length: length,
    );
  }

  @override
  BuBytes pbkdf2Sha512DeriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    _isValid([iterations, length], "pbkdf2Sha512DeriveKey");
    return inner.pbkdf2Sha512DeriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
      length: length,
    );
  }

  @override
  BuBytes scryptDeriveKey({
    required List<int> password,
    required List<int> salt,
    required int dkLen,
    required int r,
    required int n,
    required int p,
  }) {
    _isValid([dkLen, n, p, r], "scryptDeriveKey");
    return inner.scryptDeriveKey(
      password: password,
      salt: salt,
      dkLen: dkLen,
      n: n,
      p: p,
      r: r,
    );
  }

  @override
  BuBytes hkdfSha256DeriveKey({
    required List<int> ikm,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  }) {
    _checkLength(length, "hkdfSha256DeriveKey");
    return inner.hkdfSha256DeriveKey(
      ikm: ikm,
      length: length,
      salt: salt,
      info: info,
    );
  }

  @override
  BuBytes hkdfSha512DeriveKey({
    required List<int> ikm,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  }) {
    _checkLength(length, "hkdfSha512DeriveKey");
    return inner.hkdfSha512DeriveKey(
      ikm: ikm,
      length: length,
      salt: salt,
      info: info,
    );
  }

  void _checkLength(int length, String operation) {
    // L = 0 diverges by backend (Dart: empty OKM, native: error), so the
    // API requires L >= 1; the 255*HashLen ceiling is enforced per backend.
    if (length < 1) {
      throw CoreErrors.invalidOperationArguments(
        operation,
        name: "length",
        reason: "Invalid length. Must be positive.",
      );
    }
  }
}
