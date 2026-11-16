import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Contract for an Authenticated Encryption with Associated Data (AEAD)
/// cipher — encryption that also authenticates the ciphertext and any
/// associated (unencrypted) data.
abstract class AEAD implements BuAead {
  /// Returns the length (in bytes) of the nonce required by the AEAD algorithm.
  @override
  int get nonceLength;

  /// Returns the length (in bytes) of the authentication tag produced by the AEAD algorithm.
  @override
  int get tagLength;

  /// Encrypts the provided plaintext along with a nonce, and optional associated data.
  /// Returns the ciphertext and may write the result into the [dst] if provided.
  @override
  BuBytes encrypt(
    List<int> nonce,
    List<int> plaintext, {
    List<int>? associatedData,
    List<int>? dst,
  });

  /// Decrypts the provided ciphertext along with a nonce, and optional associated data.
  /// Returns the plaintext and may write the result into the [dst] if provided.
  /// Returns `null` if decryption fails due to authentication failure.
  @override
  BuBytes? decrypt(
    List<int> nonce,
    List<int> ciphertext, {
    List<int>? associatedData,
    List<int>? dst,
  });

  /// Clears any sensitive information or states held by the AEAD instance, ensuring that
  /// no secrets are left in memory after use.
  @override
  AEAD clean();
}
