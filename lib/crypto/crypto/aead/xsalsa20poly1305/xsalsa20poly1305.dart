import 'package:blockchain_utils/crypto/crypto/aead/core/aead.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/aead/chacha20poly1305/poly1305.dart';
import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/salsa20.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// XSalsa20-Poly1305 authenticated encryption (NaCl `crypto_secretbox`).
///
/// Construction: `subkey = HSalsa20(key, nonce[0:16])`, then Salsa20 with
/// `subkey` and `nonce[16:24]`. The first 32 keystream bytes are the
/// one-time Poly1305 key, the remainder encrypts the message. The tag
/// authenticates the ciphertext only.
///
/// Framing (NaCl order): `encrypt` returns the 16-byte tag FIRST, then the
/// ciphertext (`TAG || CIPHERTEXT`), exactly like `crypto_secretbox_easy`
/// (tweetnacl, libsodium, RustCrypto `crypto_box`). This deliberately
/// differs from [ChaCha20Poly1305]/AES-GCM in this package, which append
/// the tag (`CIPHERTEXT || TAG`) per RFC 8439 / NIST. Do not mix the two
/// orders: a NaCl peer expects the authenticator up front, which is also
/// what TON Connect `SessionCrypto` bridge payloads carry.
///
/// This is **not** a hash: it lives under `aead/` next to
/// [ChaCha20Poly1305].
///
/// Pure-Dart, web-safe. Key is 32 bytes, nonce is strictly 24 bytes:
/// any other nonce length throws instead of being padded, because silent
/// padding would break cross-implementation compatibility.
class XSalsa20Poly1305 implements AEAD {
  /// Required key length in bytes.
  static const int keyLength = 32;

  static const int _nonceLen = 24;
  static const int _tagLen = 16;

  /// Overhead of the detached construction: `TAG || CIPHERTEXT`
  /// is `plaintext + 16` bytes.
  static const int overhead = _tagLen;

  /// Overhead of the nonce-prefixed framing
  /// (`NONCE || TAG || CIPHERTEXT`).
  static const int prefixedOverhead = _nonceLen + _tagLen;

  late final BuBytes _key;

  /// Creates an instance with the given 32-byte [key].
  XSalsa20Poly1305(List<int> key) {
    if (key.length != keyLength) {
      throw CoreErrors.invalidOperationArguments(
        "XSalsa20Poly1305",
        name: "key",
        reason: "Invalid key bytes length.",
      );
    }
    _key = BuBytes(key);
  }

  @override
  int get nonceLength => _nonceLen;

  @override
  int get tagLength => _tagLen;

  static void _ensureNonce(List<int> nonce, String where) {
    if (nonce.length != _nonceLen) {
      throw CoreErrors.invalidOperationArguments(
        where,
        name: "nonce",
        reason: "Invalid nonce bytes length.",
      );
    }
  }

  static void _rejectAssociatedData(List<int>? associatedData, String where) {
    if (associatedData != null && associatedData.isNotEmpty) {
      throw CoreErrors.invalidOperationArguments(
        where,
        name: "associatedData",
        reason:
            "XSalsa20-Poly1305 (NaCl secretbox) authenticates the ciphertext only; use ChaCha20-Poly1305 or AES-GCM for associated data.",
      );
    }
  }

  /// Encrypts [plaintext] with the 24-byte [nonce].
  /// Returns the 16-byte tag followed by the ciphertext (`TAG || CIPHERTEXT`,
  /// NaCl `crypto_secretbox_easy` order).
  @override
  BuBytes encrypt(
    List<int> nonce,
    List<int> plaintext, {
    List<int>? associatedData,
    List<int>? dst,
  }) {
    _ensureNonce(nonce, "encrypt");
    _rejectAssociatedData(associatedData, "encrypt");
    final resultLength = plaintext.length + tagLength;
    final BuBytes result = BuBytes.unsafeMutable(
      dst ?? List<int>.filled(resultLength, 0),
    );
    if (result.length != resultLength) {
      throw CoreErrors.invalidOperationArguments(
        "encrypt",
        name: "dst",
        reason: "Invalid destination bytes length.",
      );
    }
    final stream = Salsa20.xsalsa20Stream(_key, nonce, 32 + plaintext.length);
    try {
      // Separate copy (sublist clones): wipe it here, not just the stream.
      final polyKey = stream.sublist(0, 32);
      try {
        for (int i = 0; i < plaintext.length; i++) {
          result[tagLength + i] =
              (plaintext[i] & BinaryOps.mask8) ^ (stream[32 + i] & BinaryOps.mask8);
        }
        final cipherText = result.sublist(tagLength, resultLength);
        final h = Poly1305(polyKey);
        h.update(cipherText);
        final tag = h.digest();
        h.clean();
        result.setRange(0, tagLength, tag);
        BinaryOps.zero(tag);
        return result;
      } finally {
        BinaryOps.zero(polyKey);
      }
    } finally {
      stream.forceZero();
    }
  }

  /// Decrypts [sealed] (`TAG || CIPHERTEXT`) with the 24-byte [nonce].
  /// Returns the plaintext, or `null` on authentication failure.
  ///
  /// The tag comparison is constant-time.
  @override
  BuBytes? decrypt(
    List<int> nonce,
    List<int> sealed, {
    List<int>? associatedData,
    List<int>? dst,
  }) {
    _ensureNonce(nonce, "decrypt");
    _rejectAssociatedData(associatedData, "decrypt");
    if (sealed.length < tagLength) {
      return null;
    }
    final messageLength = sealed.length - tagLength;
    final receivedTag = sealed.sublist(0, tagLength);
    final cipherText = sealed.sublist(tagLength);
    final stream = Salsa20.xsalsa20Stream(_key, nonce, 32 + messageLength);
    try {
      // Separate copy (sublist clones): wipe it here, not just the stream.
      final polyKey = stream.sublist(0, 32);
      try {
        final h = Poly1305(polyKey);
        h.update(cipherText);
        final calculatedTag = h.digest();
        h.clean();
        final valid = BytesUtils.bytesEqualConst(calculatedTag, receivedTag);
        BinaryOps.zero(calculatedTag);
        if (!valid) {
          return null;
        }
        final BuBytes result = BuBytes.unsafeMutable(
          dst ?? List<int>.filled(messageLength, 0),
        );
        if (result.length != messageLength) {
          throw CoreErrors.invalidOperationArguments(
            "decrypt",
            name: "dst",
            reason: "Invalid destination bytes length.",
          );
        }
        for (int i = 0; i < messageLength; i++) {
          result[i] =
              (cipherText[i] & BinaryOps.mask8) ^ (stream[32 + i] & BinaryOps.mask8);
        }
        return result;
      } finally {
        BinaryOps.zero(polyKey);
      }
    } finally {
      stream.forceZero();
    }
  }

  /// Encrypts [plaintext] and prefixes the nonce:
  /// `NONCE || TAG || CIPHERTEXT`.
  ///
  /// A fresh random [nonce] is generated via [QuickCrypto] when omitted
  /// (web-safe Fortuna PRNG). Pass an explicit 24-byte [nonce] for
  /// deterministic vectors/tests.
  BuBytes seal(List<int> plaintext, {List<int>? nonce}) {
    final n = nonce ?? QuickCrypto.generateRandom(length: nonceLength);
    _ensureNonce(n, "seal");
    final sealed = encrypt(n, plaintext);
    try {
      return BuBytes.concat([n, sealed]);
    } finally {
      sealed.forceZero();
      if (nonce == null) {
        BinaryOps.zero(n);
      }
    }
  }

  /// Opens a `NONCE || TAG || CIPHERTEXT` blob produced by [seal].
  /// Returns the plaintext, or `null` when truncated or unauthenticated.
  BuBytes? open(List<int> prefixed) {
    if (prefixed.length < prefixedOverhead) {
      return null;
    }
    final nonce = prefixed.sublist(0, nonceLength);
    final sealed = prefixed.sublist(nonceLength);
    return decrypt(nonce, sealed);
  }

  /// Securely zeroes the key.
  @override
  XSalsa20Poly1305 clean() {
    _key.forceZero();
    return this;
  }
}
