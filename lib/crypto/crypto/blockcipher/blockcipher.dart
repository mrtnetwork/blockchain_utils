/// An abstract class representing a block cipher for symmetric encryption and decryption.
///
/// Block ciphers operate on fixed-size blocks of data, typically 128 bits (16 bytes) for AES.
/// They provide methods for key initialization, encryption, decryption, and memory cleanup.
///
/// Subclasses of this abstract class implement specific block cipher algorithms and provide
/// methods for encryption and decryption of data.
///
/// Key Initialization:
/// - The `setKey` method is used to initialize the cipher with an encryption key.
///
/// Encryption and Decryption:
/// - The `encryptBlock` method encrypts a single block of data.
/// - The `decryptBlock` method decrypts a single block of data.
///
/// Block Size:
/// - The `blockSize` property returns the size of the data block in bytes that the cipher operates on.
///
/// Memory Cleanup:
/// - The `clean` method can be used to securely zero any sensitive information or states held by
///   the block cipher instance, ensuring that no secrets are left in memory after use.
///
/// Note: This abstract class serves as a foundation for various block ciphers and should be
/// extended to support specific algorithms such as AES or DES.
abstract class BlockCipher {
  /// Returns the size of the data block in bytes that the cipher operates on.
  int get blockSize;

  /// Initializes the cipher with the provided encryption key.
  BlockCipher setKey(List<int> key);

  /// Encrypts a single block of data.
  List<int> encryptBlock(List<int> src, [List<int>? dst]);

  /// Decrypts a single block of data.
  List<int> decryptBlock(List<int> src, [List<int>? dst]);

  /// Clears any sensitive information or states held by the block cipher instance, ensuring
  /// that no secrets are left in memory after use.
  BlockCipher clean();
}
