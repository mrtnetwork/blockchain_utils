import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/crypto/crypto/chacha/chacha.dart';
import 'package:blockchain_utils/crypto/crypto/prng/rng.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

class ChaCha20Rng with Rng {
  final int streamId;
  final List<int> _key; // 32-byte seed
  ChaCha20Rng(List<int> seed, {this.streamId = 0})
    : assert(seed.length == 32),
      _key = seed.clone();
  List<int> _buffer = List<int>.filled(256, 0);
  int _bufferOffset = 256; // force refill on first use

  // 64-bit counter: counts 64-byte blocks generated
  int _blockCounter = 0;

  /// Internal refill of 4 ChaCha blocks (256 bytes)
  void _refill() {
    final out = List<int>.filled(256, 0);
    final nonce = [
      ...IntUtils.toBytes(_blockCounter, byteOrder: Endian.little, length: 8),
      ...IntUtils.toBytes(streamId, byteOrder: Endian.little, length: 8),
    ];
    final zeros = List<int>.filled(256, 0);
    ChaCha20.streamXOR(_key, nonce, zeros, out, nonceInplaceCounterLength: 8);

    _buffer = out;
    _bufferOffset = 0;
    _blockCounter += 4;
  }

  /// Returns [length] bytes from the RNG
  @override
  List<int> nextBytes(int length) {
    final out = List<int>.filled(length, 0);
    int written = 0;

    // Internally, always consume a multiple of 4 bytes
    final fil =
        length + ((4 - (length % 4)) % 4); // round up to nearest multiple of 4

    while (written < fil) {
      if (_bufferOffset >= _buffer.length) {
        _refill();
      }

      final remainingInBuffer = _buffer.length - _bufferOffset;
      final take = remainingInBuffer.clamp(0, fil - written);

      // Only copy bytes that fit into output array
      final toCopy = (written + take <= length) ? take : (length - written);
      if (toCopy > 0) {
        out.setRange(written, written + toCopy, _buffer, _bufferOffset);
      }

      _bufferOffset += take;
      written += take;
    }

    return out;
  }
}
