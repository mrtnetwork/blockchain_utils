import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A raw block cipher: encrypts/decrypts exactly one fixed-size block at a
/// time, with no mode of operation applied.
abstract class BlockCipher implements BuBlockCipher {
  /// Size of the data block in bytes that the cipher operates on.
  @override
  int get blockSize;

  /// Encrypts a single block of data.
  @override
  BuBytes encryptBlock(List<int> src, [List<int>? dst]);

  /// Decrypts a single block of data.
  @override
  BuBytes decryptBlock(List<int> src, [List<int>? dst]);

  /// Zeroes any key material or state held by this instance.
  @override
  BlockCipher clean();
}

/// A block cipher running in CBC mode. Unlike [BlockCipher], this is
/// stateful: each call chains off the previous block's ciphertext, so the
/// same instance must be used for a message's blocks in order.
abstract class BlockCipherCbc implements BuBlockCipherCbc {
  /// Size of the data block in bytes that the underlying cipher operates on.
  int get blockSize;

  /// Encrypts a single block, XORing it with the previous ciphertext block
  /// (or the IV, for the first block) first.
  @override
  BuBytes encrypt(List<int> src, [List<int>? dst]);

  /// Decrypts a single block, XORing the result with the previous
  /// ciphertext block (or the IV, for the first block).
  @override
  BuBytes decrypt(List<int> src, [List<int>? dst]);

  /// Zeroes any key material or state held by this instance.
  @override
  BlockCipherCbc clean();
}
