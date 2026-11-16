import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Counter (CTR) mode: turns a block cipher into a stream cipher by
/// encrypting successive counter values and XORing them with the data.
class CTR implements BuAesCtr {
  /// Counter value
  late final List<int> _counter;

  /// Encrypted block buffer
  late final List<int> _buffer;

  /// Buffer position
  int _bufpos = 0;

  /// Block cipher for encryption
  BuBlockCipher? _cipher;

  /// Returns the block size of the block cipher, or null if not set.
  int? get blockSize => _cipher?.blockSize;

  /// Creates a CTR instance over [cipher], starting the counter at [iv]
  /// (which must be [cipher]'s block size).
  CTR(BuBlockCipher cipher, List<int> iv) {
    _counter = List<int>.filled(cipher.blockSize, 0);

    _buffer = List<int>.filled(cipher.blockSize, 0);
    _setCipher(cipher, iv);
  }

  /// Sets the cipher and (optionally) resets the counter to [iv].
  /// Throws [BuError] if [iv]'s length isn't the block size.
  CTR _setCipher(BuBlockCipher cipher, List<int>? iv) {
    _cipher = null;

    if (iv != null && iv.length != _counter.length) {
      throw CoreErrors.invalidOperationArguments(
        "setCipher",
        name: "iv",
        reason: "Invalid iv bytes length.",
      );
    }
    _cipher = cipher;

    if (iv != null) {
      _counter.setAll(0, iv);
    }
    _bufpos = _buffer.length;
    return this;
  }

  /// Zeroes the counter and keystream buffer, and drops the cipher.
  @override
  CTR clean() {
    BinaryOps.zero(_buffer);
    BinaryOps.zero(_counter);
    _bufpos = _buffer.length;
    _cipher = null;
    return this;
  }

  /// Refills the keystream buffer by encrypting the counter, then bumps it.
  void _fillBuffer() {
    final cipher = _cipher;
    if (cipher == null) {
      throw CoreErrors.cryptoFailed("fillBuffer", reason: "State was cleaned.");
    }
    cipher.encryptBlock(_counter, _buffer);
    _bufpos = 0;
    _incrementCounter(_counter);
  }

  /// XORs [src] with the keystream (encrypt and decrypt are the same
  /// operation in CTR mode), writing [src].length bytes into [dst] if
  /// given ([dst] must hold at least [src].length bytes — GCM and Fortuna
  /// pass a longer buffer and fill the tail themselves).
  @override
  BuBytes process(List<int> src, [List<int>? dst]) {
    final out = BuBytes.unsafeMutable(dst ?? List<int>.filled(src.length, 0));
    if (out.length < src.length) {
      throw CoreErrors.invalidOperationArguments(
        "process",
        name: "dst",
        reason: "Invalid destination bytes length.",
      );
    }
    for (var i = 0; i < src.length; i++) {
      if (_bufpos == _buffer.length) {
        _fillBuffer();
      }
      out[i] = (src[i] & BinaryOps.mask8) ^ _buffer[_bufpos++];
    }
    return out;
  }
}

/// Increments the big-endian [counter] in place, throwing on overflow.
void _incrementCounter(List<int> counter) {
  var carry = 1;
  for (var i = counter.length - 1; i >= 0; i--) {
    carry = carry + (counter[i] & BinaryOps.mask8);
    counter[i] = carry & BinaryOps.mask8;
    carry >>= 8;
  }
  if (carry > 0) {
    throw CoreErrors.cryptoFailed(
      "incrementCounter",
      reason: "Counter overflow",
    );
  }
}
