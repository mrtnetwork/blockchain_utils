import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/salsa20.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/xsalsa20poly1305.dart';
import 'package:blockchain_utils/crypto/crypto/group/x25519/x25519.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// NaCl `crypto_box`: X25519 key agreement + XSalsa20-Poly1305.
///
/// Key agreement follows `crypto_box_beforenm`: the X25519 shared secret
/// is passed through HSalsa20 with a 16-byte zero nonce to derive the
/// 32-byte transport key, which is then used as a [XSalsa20Poly1305] key.
/// All-zero shared secrets (low-order peer points) are rejected, matching
/// libsodium.
///
/// Wire format matches `crypto_box_easy` / tweetnacl `nacl.box` /
/// RustCrypto `SalsaBox`: the 16-byte authenticator comes FIRST
/// (`TAG || CIPHERTEXT`), and the nonce-prefixed helpers produce
/// `NONCE || TAG || CIPHERTEXT` exactly as TON Connect `SessionCrypto`
/// expects on the bridge (verified against tweetnacl and pytonconnect
/// golden vectors).
///
/// Pure-Dart, web-safe. All methods are static; the peer public key is an
/// explicit parameter of every call because each message may target a
/// different peer.
class SalsaBox {
  /// X25519 key length in bytes (secret key, public key, shared secret).
  static const int keyLength = 32;

  static const int _nonceLen = 24;
  static const int _tagLen = 16;

  /// Nonce length in bytes (strict 24-byte, shared with XSalsa20).
  static int get nonceLength => _nonceLen;

  /// Authentication tag length in bytes.
  static int get tagLength => _tagLen;

  /// Minimum length of a nonce-prefixed (`NONCE || TAG || CIPHERTEXT`) blob.
  static int get minPrefixedLength => _nonceLen + _tagLen;

  static void _ensureKeys(List<int> peerPublicKey, List<int> secretKey) {
    if (peerPublicKey.length != keyLength) {
      throw CoreErrors.invalidOperationArguments(
        "SalsaBox",
        name: "peerPublicKey",
        reason: "Invalid peer public key bytes length.",
      );
    }
    if (secretKey.length != keyLength) {
      throw CoreErrors.invalidOperationArguments(
        "SalsaBox",
        name: "secretKey",
        reason: "Invalid secret key bytes length.",
      );
    }
  }

  static void _ensureNonce(List<int> nonce, String where) {
    if (nonce.length != _nonceLen) {
      throw CoreErrors.invalidOperationArguments(
        where,
        name: "nonce",
        reason: "Invalid nonce bytes length.",
      );
    }
  }

  /// Derives the 32-byte transport key (`crypto_box_beforenm`).
  ///
  /// Throws [CryptoException] when the X25519 shared secret is all zero
  /// (invalid/low-order peer public key), matching libsodium which refuses
  /// to encrypt under a zero shared secret.
  static BuBytes beforenm({
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    _ensureKeys(peerPublicKey, secretKey);
    final shared = X25519.scalarMult(secretKey, peerPublicKey);
    try {
      if (shared.isZero()) {
        throw CoreErrors.cryptoFailed(
          "SalsaBox.beforenm",
          reason: "Invalid peer public key.",
        );
      }
      final zeros = List<int>.filled(16, 0);
      final sessionKey = Salsa20.hsalsa20(shared, zeros);
      BinaryOps.zero(zeros);
      return sessionKey;
    } finally {
      shared.forceZero();
    }
  }

  /// Encrypts [plaintext] for [peerPublicKey] with the 24-byte [nonce]:
  /// `16-byte tag || ciphertext` (`crypto_box_easy` detached format,
  /// authenticator first).
  static BuBytes encrypt(
    List<int> nonce,
    List<int> plaintext, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    _ensureNonce(nonce, "SalsaBox.encrypt");
    final sessionKey = beforenm(
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
    try {
      final box = XSalsa20Poly1305(sessionKey);
      try {
        return box.encrypt(nonce, plaintext);
      } finally {
        box.clean();
      }
    } finally {
      sessionKey.forceZero();
    }
  }

  /// Decrypts [sealed] (`TAG || CIPHERTEXT`) from [peerPublicKey].
  /// Returns the plaintext, or `null` on authentication failure.
  static BuBytes? decrypt(
    List<int> nonce,
    List<int> sealed, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    _ensureNonce(nonce, "SalsaBox.decrypt");
    final sessionKey = beforenm(
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
    try {
      final box = XSalsa20Poly1305(sessionKey);
      try {
        return box.decrypt(nonce, sealed);
      } finally {
        box.clean();
      }
    } finally {
      sessionKey.forceZero();
    }
  }

  /// Encrypts and prefixes the nonce: `NONCE || TAG || CIPHERTEXT`.
  ///
  /// A fresh random nonce is generated via [QuickCrypto] when omitted
  /// (web-safe Fortuna PRNG). Pass an explicit 24-byte [nonce] for
  /// deterministic test vectors.
  static BuBytes seal(
    List<int> plaintext, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
    List<int>? nonce,
  }) {
    final n = nonce ?? QuickCrypto.generateRandom(length: _nonceLen);
    _ensureNonce(n, "SalsaBox.seal");
    final sealed = encrypt(
      n,
      plaintext,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
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
  static BuBytes? open(
    List<int> prefixed, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    if (prefixed.length < minPrefixedLength) {
      return null;
    }
    final nonce = prefixed.sublist(0, _nonceLen);
    final sealed = prefixed.sublist(_nonceLen);
    return decrypt(
      nonce,
      sealed,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }
}
