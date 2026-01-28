/// An abstract class representing a block cipher for symmetric encryption and decryption.
///
/// Subclasses of this abstract class implement specific block cipher algorithms and provide
/// methods for encryption and decryption of data.
abstract class BlockCipher {
  /// Returns the size of the data block in bytes that the cipher operates on.
  int get blockSize;

  /// Encrypts a single block of data.
  List<int> encryptBlock(List<int> src, [List<int>? dst]);

  /// Decrypts a single block of data.
  List<int> decryptBlock(List<int> src, [List<int>? dst]);

  /// Clears any sensitive information or states held by the block cipher instance, ensuring
  /// that no secrets are left in memory after use.
  BlockCipher clean();
}

/// An abstract class representing a block mode.
abstract class BlockCipherMode {
  /// Encrypt N bytes (must be multiple of blockSize)
  List<int> process(List<int> src, [List<int>? dst]);

  /// Reset state (IV, counter, buffers)
  void clean();
}
