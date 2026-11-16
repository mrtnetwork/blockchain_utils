import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/aead/aead.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/aes.dart';

/// Constructs AEAD ciphers (ChaCha20-Poly1305, XSalsa20-Poly1305, AES-GCM)
///
/// from raw keys.
abstract interface class AEADApi {
  /// Creates ChaCha20-Poly1305 AEAD from 32-byte [key]. Throws on invalid length.
  BuAead chacha20Poly1305(List<int> key);

  /// Creates XSalsa20-Poly1305 AEAD (NaCl secretbox) from 32-byte [key].
  /// Strict 24-byte nonce. Throws on invalid length.
  BuAead xsalsa20Poly1305(List<int> key);

  /// Creates AES-GCM AEAD from [aesKey] of 16, 24 or 32 bytes. Throws on invalid length.
  BuAead aesGCM(List<int> aesKey);

  /// NaCl `crypto_box_beforenm`: derives the 32-byte transport key from
  /// 32-byte [peerPublicKey] and 32-byte [secretKey]. Throws on invalid
  /// lengths; throws [CryptoException] on a zero shared secret.
  BuBytes salsaBoxBeforenm({
    required List<int> peerPublicKey,
    required List<int> secretKey,
  });

  /// NaCl `crypto_box_easy` detached encrypt with explicit 24-byte [nonce]:
  /// returns `TAG || CIPHERTEXT` (authenticator first). Throws on invalid
  /// lengths.
  BuBytes salsaBoxEncrypt(
    List<int> nonce,
    List<int> plaintext, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  });

  /// NaCl `crypto_box_open_easy` detached decrypt with explicit 24-byte
  /// [nonce]. Returns plaintext, or `null` on authentication failure.
  /// Throws on invalid key/nonce lengths (never on attacker ciphertext).
  BuBytes? salsaBoxDecrypt(
    List<int> nonce,
    List<int> sealed, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  });

  /// NaCl box with explicit 24-byte [nonce], nonce-prefixed framing:
  /// returns `NONCE || TAG || CIPHERTEXT`. Throws on invalid lengths.
  BuBytes salsaBoxSeal(
    List<int> nonce,
    List<int> plaintext, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  });

  /// Opens a `NONCE || TAG || CIPHERTEXT` blob. Returns plaintext, or
  /// `null` when truncated or unauthenticated. Throws on invalid key
  /// lengths (never on attacker input).
  BuBytes? salsaBoxOpen(
    List<int> prefixed, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  });
}

/// [AEADApi] wrapper that validates key length before delegating.
class ValidatedAEADApi implements AEADApi {
  final AEADApi _inner;
  const ValidatedAEADApi(this._inner);

  @override
  BuAead aesGCM(List<int> aesKey) {
    ApiValidate.oneOfLengths(
      aesKey,
      AES.allowedKeysLength,
      operation: "aesGCM",
      name: "aesKey",
    );
    return _inner.aesGCM(aesKey);
  }

  @override
  BuAead chacha20Poly1305(List<int> key) {
    ApiValidate.length(
      key,
      ChaCha20Poly1305.keyLength,
      operation: "chacha20Poly1305",
      name: "key",
    );

    return _inner.chacha20Poly1305(key);
  }

  @override
  BuAead xsalsa20Poly1305(List<int> key) {
    ApiValidate.length(
      key,
      XSalsa20Poly1305.keyLength,
      operation: "xsalsa20Poly1305",
      name: "key",
    );

    return _inner.xsalsa20Poly1305(key);
  }

  @override
  BuBytes salsaBoxBeforenm({
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    ApiValidate.length(
      peerPublicKey,
      SalsaBox.keyLength,
      operation: "salsaBoxBeforenm",
      name: "peerPublicKey",
    );
    ApiValidate.length(
      secretKey,
      SalsaBox.keyLength,
      operation: "salsaBoxBeforenm",
      name: "secretKey",
    );
    return _inner.salsaBoxBeforenm(
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  @override
  BuBytes salsaBoxEncrypt(
    List<int> nonce,
    List<int> plaintext, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    ApiValidate.length(
      nonce,
      SalsaBox.nonceLength,
      operation: "salsaBoxEncrypt",
      name: "nonce",
    );
    ApiValidate.length(
      peerPublicKey,
      SalsaBox.keyLength,
      operation: "salsaBoxEncrypt",
      name: "peerPublicKey",
    );
    ApiValidate.length(
      secretKey,
      SalsaBox.keyLength,
      operation: "salsaBoxEncrypt",
      name: "secretKey",
    );
    return _inner.salsaBoxEncrypt(
      nonce,
      plaintext,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  @override
  BuBytes? salsaBoxDecrypt(
    List<int> nonce,
    List<int> sealed, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    ApiValidate.length(
      nonce,
      SalsaBox.nonceLength,
      operation: "salsaBoxDecrypt",
      name: "nonce",
    );
    ApiValidate.length(
      peerPublicKey,
      SalsaBox.keyLength,
      operation: "salsaBoxDecrypt",
      name: "peerPublicKey",
    );
    ApiValidate.length(
      secretKey,
      SalsaBox.keyLength,
      operation: "salsaBoxDecrypt",
      name: "secretKey",
    );
    return _inner.salsaBoxDecrypt(
      nonce,
      sealed,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  @override
  BuBytes salsaBoxSeal(
    List<int> nonce,
    List<int> plaintext, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    ApiValidate.length(
      nonce,
      SalsaBox.nonceLength,
      operation: "salsaBoxSeal",
      name: "nonce",
    );
    ApiValidate.length(
      peerPublicKey,
      SalsaBox.keyLength,
      operation: "salsaBoxSeal",
      name: "peerPublicKey",
    );
    ApiValidate.length(
      secretKey,
      SalsaBox.keyLength,
      operation: "salsaBoxSeal",
      name: "secretKey",
    );
    return _inner.salsaBoxSeal(
      nonce,
      plaintext,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  @override
  BuBytes? salsaBoxOpen(
    List<int> prefixed, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    ApiValidate.length(
      peerPublicKey,
      SalsaBox.keyLength,
      operation: "salsaBoxOpen",
      name: "peerPublicKey",
    );
    ApiValidate.length(
      secretKey,
      SalsaBox.keyLength,
      operation: "salsaBoxOpen",
      name: "secretKey",
    );
    return _inner.salsaBoxOpen(
      prefixed,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }
}
