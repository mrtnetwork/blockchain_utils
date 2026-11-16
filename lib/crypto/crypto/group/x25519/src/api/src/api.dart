import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// X25519 (Curve25519 Diffie-Hellman, RFC 7748) operations.
abstract interface class X25519Api {
  /// Multiplies 32-byte [scalar] (clamped) by 32-byte LE [u] coordinate via the RFC 7748 ladder. Returns the 32-byte shared u-coordinate. Throws on invalid lengths or non-canonical [u].
  BuBytes x25519({required List<int> scalar, required List<int> u});
  /// Derives the 32-byte public key from 32-byte [privateKey] (clamped scalar-mult with base point u = 9). Throws on invalid length.
  BuBytes publicKey(List<int> privateKey);
  /// Computes the 32-byte shared secret from 32-byte [privateKey] and 32-byte [peerPublic]. Throws on invalid lengths or an all-zero (low-order) result.
  BuBytes diffieHellman({
    required List<int> privateKey,
    required List<int> peerPublic,
  });
  /// Converts a 32-byte ed25519 public key (compressed Edwards y) to its 32-byte Montgomery u-coordinate `(1+y)/(1-y)`. Throws on invalid points.
  BuBytes fromEd25519PublicKey(List<int> ed25519Pk);
  /// Derives the 32-byte clamped X25519 scalar from a 32-byte ed25519 [seed] (SHA-512, clamp first half). Throws on invalid length.
  BuBytes fromEd25519Seed(List<int> seed);
}
