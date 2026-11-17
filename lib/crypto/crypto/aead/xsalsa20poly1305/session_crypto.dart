import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/salsa_box.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/x25519/x25519.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Serializable TON Connect session keypair (hex strings, no `0x` prefix).
///
/// Pass it back into [SessionCrypto.fromKeypair] to resume a session
/// across restarts, mirroring `SessionCrypto.stringifyKeypair()` from
/// `@tonconnect/protocol`.
class TonConnectKeyPair {
  /// 32-byte public key, lowercase hex (also the bridge `client_id`).
  final String publicKey;

  /// 32-byte secret key, lowercase hex. Keep confidential.
  final String secretKey;

  const TonConnectKeyPair({required this.publicKey, required this.secretKey});
}

/// TON Connect session cryptography (`SessionCrypto` in `@tonconnect/protocol`).
///
/// End-to-end encryption for the TON Connect HTTP bridge on top of NaCl
/// `crypto_box` (X25519 + XSalsa20-Poly1305). The bridge stays untrusted:
/// every message carries a fresh 24-byte random nonce and is framed as
/// `NONCE || TAG || CIPHERTEXT` (NaCl order: the 16-byte Poly1305
/// authenticator comes first, then the ciphertext).
///
/// Protocol roles are symmetric: each side encrypts what it sends with the
/// peer's public key and decrypts what it receives with the sender's
/// public key. `sessionId` is this side's public key as 64 lowercase hex
/// chars and is used as the bridge `client_id`.
///
/// Transport calls ([encrypt]/[decrypt]) are routed through [QuickCrypto],
/// hence through the active backend (pure-Dart or native Rust) with
/// byte-identical results; like any backend call, a backend must be
/// selected first. Key handling (X25519) stays pure-Dart and needs no
/// backend. Web-safe. Interop is locked by the tweetnacl / pytonconnect
/// golden vectors in `test/crypto/xsalsa20_poly1305/`.
class SessionCrypto {
  /// Session key length in bytes.
  static const int keyLength = SalsaBox.keyLength;

  /// Per-message nonce length in bytes.
  static const int nonceLength = 24;

  /// Poly1305 tag length in bytes (inside the ciphertext).
  static const int tagLength = 16;

  /// Minimum length of a bridge payload (`NONCE || TAG || CIPHERTEXT`).
  static const int minMessageLength = 40;

  final X25519Keypair _keypair;

  SessionCrypto._(this._keypair);

  /// Creates a fresh session, generating a random 32-byte secret key with
  /// [QuickCrypto] (web-safe Fortuna PRNG), or derives the session from an
  /// explicit [secretKey] (e.g. fixed vectors/tests).
  factory SessionCrypto.generate({List<int>? secretKey}) {
    final sk = secretKey ?? QuickCrypto.generateRandom(length: keyLength);
    if (sk.length != keyLength) {
      throw CoreErrors.invalidOperationArguments(
        "SessionCrypto",
        name: "secretKey",
        reason: "Invalid secret key bytes length.",
      );
    }
    return SessionCrypto._(X25519.scalarMultBase(sk));
  }

  /// Restores a persisted session, verifying the public key matches the
  /// secret key (throws [CryptoException] on mismatch, mirroring
  /// `SessionCrypto::from_persisted` in `ton-connect-core`).
  factory SessionCrypto.fromKeypair({
    required List<int> publicKey,
    required List<int> secretKey,
  }) {
    if (publicKey.length != keyLength || secretKey.length != keyLength) {
      throw CoreErrors.invalidOperationArguments(
        "SessionCrypto",
        name: "keypair",
        reason: "Invalid session keypair bytes length.",
      );
    }
    final derived = X25519.scalarMultBase(secretKey);
    if (!BytesUtils.bytesEqual(derived.publicKey, publicKey)) {
      throw CoreErrors.cryptoFailed(
        "SessionCrypto",
        reason: "Persisted session public and secret keys do not match.",
      );
    }
    return SessionCrypto._(
      X25519Keypair(privateKey: derived.privateKey, publicKey: publicKey),
    );
  }

  /// Bridge-level `client_id`: the public key as 64 lowercase hex chars.
  String get sessionId => _keypair.publicKey.toHex();

  /// This session's public key (32 bytes).
  BuBytes get publicKey => _keypair.publicKey;

  /// Encrypts [plaintext] for [peerPublicKey], returning
  /// `NONCE || TAG || CIPHERTEXT`. A fresh random nonce is generated per
  /// call; pass [nonce] only for deterministic vectors/tests.
  ///
  /// Routed through [QuickCrypto] and therefore the active backend
  /// (pure-Dart or native Rust): a backend must be selected first
  /// (tests do this via `BlockchainUtilsTestApi`; apps via
  /// `blockchainUtils.setDartApi()` / `setRustApi()`).
  BuBytes encrypt(
    List<int> peerPublicKey,
    List<int> plaintext, {
    List<int>? nonce,
  }) {
    return QuickCrypto.salsaBoxSeal(
      peerPublicKey: peerPublicKey,
      secretKey: _keypair.privateKey,
      plainText: plaintext,
      nonce: nonce,
    );
  }

  /// Encrypts a UTF-8 [message] for [peerPublicKey] (TON Connect `encrypt`
  /// takes a string). Returns raw `NONCE || TAG || CIPHERTEXT` bytes;
  /// base64-encode them for the bridge `POST /message` body.
  BuBytes encryptString(
    List<int> peerPublicKey,
    String message, {
    List<int>? nonce,
  }) {
    return encrypt(peerPublicKey, StringUtils.encode(message), nonce: nonce);
  }

  /// Same as [encryptString] but base64-encoded for the bridge body.
  String encryptToBase64(
    List<int> peerPublicKey,
    String message, {
    List<int>? nonce,
  }) {
    final sealed = encryptString(peerPublicKey, message, nonce: nonce);
    try {
      return StringUtils.decode(sealed, encoding: StringEncoding.base64);
    } finally {
      sealed.forceZero();
    }
  }

  /// Decrypts a `NONCE || TAG || CIPHERTEXT` bridge [payload] from
  /// [senderPublicKey]. Returns the plaintext, or `null` when truncated
  /// or unauthenticated (never throws on attacker input).
  ///
  /// Routed through [QuickCrypto] and therefore the active backend
  /// (see [encrypt]).
  BuBytes? decrypt(List<int> senderPublicKey, List<int> payload) {
    return QuickCrypto.salsaBoxOpen(
      peerPublicKey: senderPublicKey,
      secretKey: _keypair.privateKey,
      sealed: payload,
    );
  }

  /// Decrypts [payload] and UTF-8 decodes it (TON Connect `decrypt`
  /// returns a string). Returns `null` on authentication failure or when
  /// the plaintext is not valid UTF-8 (never throws on attacker input).
  String? decryptString(List<int> senderPublicKey, List<int> payload) {
    final plain = decrypt(senderPublicKey, payload);
    if (plain == null) return null;
    try {
      return StringUtils.tryDecode(plain);
    } finally {
      plain.forceZero();
    }
  }

  /// Decrypts a base64 bridge payload. Returns `null` on bad base64,
  /// truncation, or authentication failure.
  String? decryptFromBase64(List<int> senderPublicKey, String payload) {
    final raw = StringUtils.tryEncode(payload, encoding: StringEncoding.base64);
    if (raw == null) return null;
    return decryptString(senderPublicKey, raw);
  }

  /// Exports the keypair as hex strings for persistent storage.
  TonConnectKeyPair stringifyKeypair() {
    return TonConnectKeyPair(
      publicKey: _keypair.publicKey.toHex(),
      secretKey: _keypair.privateKey.toHex(),
    );
  }

  /// Best-effort wipe of the session secret key.
  void clean() {
    _keypair.privateKey.forceZero();
  }
}
