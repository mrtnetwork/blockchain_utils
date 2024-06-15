import 'package:blockchain_utils/crypto/crypto/blockcipher/blockcipher.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'aes_lib.dart' as aes_lib;

/// Represents an Advanced Encryption Standard (AES) block cipher.
///
/// The AES class implements the BlockCipher interface and provides methods for encryption
/// and decryption of data using the AES algorithm. It supports key lengths of 128, 192, and 256 bits.
///
/// Key Schedule:
/// - The key schedule is computed during key initialization using the `_lib` AES library.
///
/// Block Size:
/// - AES operates on 128-bit blocks of data.
///
/// Key Initialization:
/// - To initialize the cipher with a key, use the `setKey` method.
///
/// Encryption and Decryption:
/// - Use the `encryptBlock` method to encrypt a 128-bit block of data.
/// - Use the `decryptBlock` method to decrypt a 128-bit block of data (if the instance allows decryption).
///
/// Memory Cleanup:
/// - The `clean` method can be used to securely zero and release the internal key schedule data.
///
/// Note: This class should be used with caution, as it operates directly on byte arrays and requires proper
/// key management and memory cleanup to ensure security.
class AES implements BlockCipher {
  static final aes_lib.AESLib _lib = aes_lib.AESLib();

  /// Block size for AES cipher
  @override
  final blockSize = 16;

  /// The length of the encryption key
  late int _keyLen;

  /// The encryption key schedule
  List<int>? _encKey;

  /// The decryption key schedule
  List<int>? _decKey;

  /// Creates an AES cipher instance with the given encryption key.
  ///
  /// The `noDecryption` flag can be set to `true` to disable decryption functionality.
  AES(List<int> key, [bool noDecryption = false]) {
    _keyLen = key.length;
    setKey(key, noDecryption);
  }

  /// Initializes the AES cipher with the provided encryption key.
  ///
  /// This method sets the encryption key for the AES cipher instance, allowing it to be used for
  /// both encryption and decryption. The method enforces key size constraints and securely
  /// expands the key into internal key schedules for encryption and decryption if required.
  ///
  /// Parameters:
  /// - `key`: The encryption key as a List<int>. It must be 16, 24, or 32 bytes in length
  ///   for AES-128, AES-192, or AES-256, respectively.
  /// - `noDecryption`: An optional boolean flag. If set to `true`, it disables decryption functionality
  ///   by securely wiping the decryption key schedule.
  ///
  /// Throws:
  /// - `ArgumentException` if the provided key size is invalid or if the instance was previously
  ///   initialized with a different key size.
  ///
  /// Returns:
  /// - The same AES instance after key initialization, supporting method chaining.
  @override
  AES setKey(List<int> key, [bool noDecryption = false]) {
    if (key.length != 16 && key.length != 24 && key.length != 32) {
      throw const ArgumentException(
          "AES: wrong key size (must be 16, 24, or 32)");
    }
    if (_keyLen != key.length) {
      throw const ArgumentException("AES: initialized with different key size");
    }

    _encKey ??= List<int>.filled(key.length + 28, 0, growable: false);
    if (noDecryption) {
      if (_decKey != null) {
        zero(_decKey!);
        _decKey = null;
      }
    } else {
      _decKey ??= List<int>.filled(key.length + 28, 0, growable: false);
    }
    _lib.expandKey(key, _encKey!, _decKey);
    return this;
  }

  /// Clears and releases internal key schedule data for security and memory management.
  ///
  /// This method securely zeros and releases the internal encryption and decryption key schedules
  /// to ensure that no sensitive key data is left in memory. It is an essential step for maintaining
  /// the security of the AES cipher instance after use.
  ///
  /// Returns:
  /// - The same AES instance after cleaning for method chaining.
  @override
  AES clean() {
    if (_encKey != null) {
      zero(_encKey!);
      _encKey = null;
    }
    if (_decKey != null) {
      zero(_decKey!);
      _decKey = null;
    }
    return this;
  }

  /// This method takes a source block of plaintext, encrypts it using the encryption key schedule,
  /// and returns the resulting ciphertext. Optionally, you can provide a destination block (`dst`)
  /// to write the encrypted data into. If not provided, a new List<int> is created to hold the result.
  ///
  /// Parameters:
  /// - `src`: The source block of plaintext to be encrypted, which must have a length of 16 bytes.
  /// - `dst`: An optional destination block to store the encrypted ciphertext. If not provided,
  ///   a new block is created.
  ///
  /// Throws:
  /// - `ArgumentException` if the source or destination block size is not 16 bytes.
  /// - `StateError` if the encryption key is not available, indicating that the instance is not properly initialized.
  ///
  /// Returns:
  /// - The encrypted ciphertext block as a List<int>.
  @override
  List<int> encryptBlock(List<int> src, [List<int>? dst]) {
    final out = dst ?? List<int>.filled(blockSize, 0);
    if (src.length != blockSize) {
      throw const ArgumentException("AES: invalid source block size");
    }
    if (out.length != blockSize) {
      throw const ArgumentException("AES: invalid destination block size");
    }

    if (_encKey == null) {
      throw const MessageException("AES: encryption key is not available");
    }
    _lib.encryptBlock(_encKey!, src, out);

    return out;
  }

  /// This method takes a source block of ciphertext, decrypts it using the decryption key schedule,
  /// and returns the resulting plaintext. Optionally, you can provide a destination block (`dst`)
  /// to write the decrypted data into. If not provided, a new List<int> is created to hold the result.
  ///
  /// Parameters:
  /// - `src`: The source block of ciphertext to be decrypted, which must have a length of 16 bytes.
  /// - `dst`: An optional destination block to store the decrypted plaintext. If not provided,
  ///   a new block is created.
  ///
  /// Throws:
  /// - `ArgumentException` if the source or destination block size is not 16 bytes.
  /// - `StateError` if the instance was created with the `noDecryption` option, indicating that
  ///   decryption is not supported by this instance.
  ///
  /// Returns:
  /// - The decrypted plaintext block as a List<int>.
  @override
  List<int> decryptBlock(List<int> src, [List<int>? dst]) {
    final out = dst ?? List<int>.filled(blockSize, 0);
    if (src.length != blockSize) {
      throw const ArgumentException("AES: invaiid source block size");
    }
    if (out.length != blockSize) {
      throw const ArgumentException("AES: invalid destination block size");
    }

    if (_decKey == null) {
      throw const MessageException(
          "AES: decrypting with an instance created with noDecryption option");
    } else {
      _lib.decryptBlock(_decKey!, src, out);
    }

    return out;
  }
}
