/// An abstract class representing an Authenticated Encryption with Associated Data (AEAD) cipher.
///
/// AEAD ciphers provide both encryption and authentication of data, ensuring its integrity
/// and confidentiality. These ciphers work with a secret key, a nonce (number used once),
/// and optionally, associated data. They produce ciphertext and a tag.
///
/// Subclasses of this abstract class implement specific AEAD algorithms and provide methods
/// for encryption and decryption. The AEAD interface enforces the following key properties:
///
/// - `nonceLength`: Returns the length (in bytes) of the nonce required by the AEAD algorithm.
///
/// - `tagLength`: Returns the length (in bytes) of the authentication tag produced by the AEAD algorithm.
///
/// - `encrypt`: Encrypts the provided plaintext along with a nonce, and optional associated data.
///   Returns the ciphertext and may write the result into the `dst` `List<int>` if provided.
///
/// - `decrypt`: Decrypts the provided ciphertext along with a nonce, and optional associated data.
///   Returns the plaintext and may write the result into the `dst` `List<int>` if provided. Returns `null`
///   if decryption fails due to authentication failure.
///
/// - `clean`: Clears any sensitive information or states held by the AEAD instance, ensuring that
///   no secrets are left in memory after use.
abstract class AEAD {
  /// Returns the length (in bytes) of the nonce required by the AEAD algorithm.
  int get nonceLength;

  /// Returns the length (in bytes) of the authentication tag produced by the AEAD algorithm.
  int get tagLength;

  /// Encrypts the provided plaintext along with a nonce, and optional associated data.
  /// Returns the ciphertext and may write the result into the `dst` `List<int>` if provided.
  List<int> encrypt(List<int> nonce, List<int> plaintext,
      {List<int>? associatedData, List<int>? dst});

  /// Decrypts the provided ciphertext along with a nonce, and optional associated data.
  /// Returns the plaintext and may write the result into the `dst` `List<int>` if provided.
  /// Returns `null` if decryption fails due to authentication failure.
  List<int>? decrypt(List<int> nonce, List<int> ciphertext,
      {List<int>? associatedData, List<int>? dst});

  /// Clears any sensitive information or states held by the AEAD instance, ensuring that
  /// no secrets are left in memory after use.
  AEAD clean();
}
