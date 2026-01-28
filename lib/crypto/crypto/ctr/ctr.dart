import 'package:blockchain_utils/crypto/crypto/blockcipher/blockcipher.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

/// Counter (CTR) mode for block ciphers.
///
class CTR {
  /// Counter value
  late final List<int> _counter;

  /// Encrypted block buffer
  late final List<int> _buffer;

  /// Buffer position
  int _bufpos = 0;

  /// Block cipher for encryption
  BlockCipher? _cipher;

  /// Returns the block size of the block cipher, or null if not set.
  int? get blockSize => _cipher?.blockSize;

  /// Creates a CTR instance with the given block cipher and initialization vector (IV).
  ///
  /// Parameters:
  /// - [cipher]: The block cipher used for encryption.
  /// - [iv]: The initialization vector for the CTR mode.
  CTR(BlockCipher cipher, List<int> iv) {
    _counter = List<int>.filled(cipher.blockSize, 0);

    _buffer = List<int>.filled(cipher.blockSize, 0);
    setCipher(cipher, iv);
  }

  /// Sets the block cipher and initialization vector (IV) for the Counter (CTR) mode.
  ///
  /// Parameters:
  /// - [cipher]: The block cipher to be used for encryption.
  /// - [iv]: The initialization vector (IV) for the CTR mode.
  ///
  /// Throws:
  /// - [ArgumentException] if the IV length is not equal to the block size of the cipher.
  CTR setCipher(BlockCipher cipher, List<int>? iv) {
    _cipher = null;

    if (iv != null && iv.length != _counter.length) {
      throw ArgumentException.invalidOperationArguments(
        "setCipher",
        name: "iv",
        reason: "Invalid iv bytes length.",
        expecteLen: _counter.length,
      );
    }
    _cipher = cipher;

    if (iv != null) {
      _counter.setAll(0, iv);
    }
    _bufpos = _buffer.length;
    return this;
  }

  /// Clears internal state and data in the Counter (CTR) mode instance for security and memory management.
  CTR clean() {
    BinaryOps.zero(_buffer);
    BinaryOps.zero(_counter);
    _bufpos = _buffer.length;
    _cipher = null;
    return this;
  }

  void _fillBuffer() {
    final cipher = _cipher;
    if (cipher == null) {
      throw CryptoException.failed("fillBuffer", reason: "State was cleaned.");
    }
    cipher.encryptBlock(_counter, _buffer);
    _bufpos = 0;
    _incrementCounter(_counter);
  }

  /// XORs source data with the keystream and writes the result to the destination.
  ///
  /// Parameters:
  /// - [src]: The source data to be XORed with the keystream.
  /// - [dst]: The destination where the XORed result will be written.
  void streamXOR(List<int> src, List<int> dst) {
    for (var i = 0; i < src.length; i++) {
      if (_bufpos == _buffer.length) {
        _fillBuffer();
      }
      dst[i] = (src[i] & BinaryOps.mask8) ^ _buffer[_bufpos++];
    }
  }

  /// Generates and writes keystream to the destination.
  ///
  /// Parameters:
  /// - [dst]: The destination  where the generated keystream will be written.
  void stream(List<int> dst) {
    for (var i = 0; i < dst.length; i++) {
      if (_bufpos == _buffer.length) {
        _fillBuffer();
      }
      dst[i] = _buffer[_bufpos++];
    }
  }
}

void _incrementCounter(List<int> counter) {
  var carry = 1;
  for (var i = counter.length - 1; i >= 0; i--) {
    carry = carry + (counter[i] & BinaryOps.mask8);
    counter[i] = carry & BinaryOps.mask8;
    carry >>= 8;
  }
  if (carry > 0) {
    throw CryptoException.failed(
      "incrementCounter",
      reason: "Counter overflow",
    );
  }
}
