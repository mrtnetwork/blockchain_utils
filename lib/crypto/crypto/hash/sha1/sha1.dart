part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// A class representing the SHA-1 (Secure Hash Algorithm 1) hash algorithm.
///
/// SHA-1 produces a 160-bit (20-byte) hash digest.
class SHA1 implements SerializableHash<SH1State> {
  /// Initializes an instance of the SHA-1 hash.
  SHA1() {
    reset();
  }
  final _buffer = List<int>.empty(growable: true);
  int _lengthInBytes = 0;

  final List<int> _temp = List<int>.filled(80, 0);
  final List<int> _state = List<int>.filled(5, 0);
  final List<int> _currentChunk = List<int>.filled(16, 0);

  bool _finished = false;

  /// Clean up the internal state and reset hash object to its initial state.
  @override
  void clean() {
    BinaryOps.zero(_temp);
    BinaryOps.zero(_state);
    BinaryOps.zero(_currentChunk);
    _buffer.clear();
    reset();
  }

  final _iv = const [
    0x67452301,
    0xEFCDAB89,
    0x98BADCFE,
    0x10325476,
    0xC3D2E1F0,
  ];

  void _init() {
    _state.setAll(0, _iv);
  }

  /// Clean up and reset the saved state of the hash object to its initial state.
  /// - [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(SH1State savedState) {
    savedState.buffer = [];
    savedState.state = _iv.clone();
    savedState.length = 0;
  }

  /// Generates the final hash digest by assembling and returning the hash state.
  @override
  List<int> digest() {
    final out = List<int>.filled(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Finalizes the hash computation and stores the hash state in the provided [out].
  ///
  /// Parameters:
  ///   - [out]: In which the hash digest is stored.
  ///
  @override
  Hash finish(List<int> out) {
    if (!_finished) {
      _finalize();
      _iterate();
      _finished = true;
    }
    for (var i = 0; i < _state.length; i++) {
      BinaryOps.writeUint32BE(_state[i], out, i * 4);
    }
    return this;
  }

  void _finalize() {
    _buffer.add(0x80);

    final contentsLength = _lengthInBytes + 1 + 8;
    final finalizedLength = (contentsLength + getBlockSize - 1) & -getBlockSize;
    for (var i = 0; i < finalizedLength - contentsLength; i++) {
      _buffer.add(0);
    }

    final lengthInBits = _lengthInBytes * 8;

    final offset = _buffer.length;

    _buffer.addAll(List<int>.filled(8, 0));

    final highBits = lengthInBits ~/ 0x100000000; // >> 32
    final lowBits = lengthInBits & BinaryOps.mask32;
    BinaryOps.writeUint32BE(highBits, _buffer, offset);
    BinaryOps.writeUint32BE(lowBits, _buffer, offset + 4);
  }

  void _proccess(List<int> chunk) {
    assert(chunk.length == 16);

    var a = _state[0];
    var b = _state[1];
    var c = _state[2];
    var d = _state[3];
    var e = _state[4];

    for (var i = 0; i < 80; i++) {
      if (i < 16) {
        _temp[i] = chunk[i];
      } else {
        _temp[i] = BinaryOps.rotl32(
          _temp[i - 3] ^ _temp[i - 8] ^ _temp[i - 14] ^ _temp[i - 16],
          1,
        );
      }

      var newA = BinaryOps.add32(
        BinaryOps.add32(BinaryOps.rotl32(a, 5), e),
        _temp[i],
      );
      if (i < 20) {
        newA = BinaryOps.add32(
          BinaryOps.add32(newA, (b & c) | (~b & d)),
          0x5A827999,
        );
      } else if (i < 40) {
        newA = BinaryOps.add32(BinaryOps.add32(newA, b ^ c ^ d), 0x6ED9EBA1);
      } else if (i < 60) {
        newA = BinaryOps.add32(
          BinaryOps.add32(newA, (b & c) | (b & d) | (c & d)),
          0x8F1BBCDC,
        );
      } else {
        newA = BinaryOps.add32(BinaryOps.add32(newA, b ^ c ^ d), 0xCA62C1D6);
      }

      e = d;
      d = c;
      c = BinaryOps.rotl32(b, 30);
      b = a;
      a = newA & BinaryOps.mask32;
    }

    _state[0] = BinaryOps.add32(a, _state[0]);
    _state[1] = BinaryOps.add32(b, _state[1]);
    _state[2] = BinaryOps.add32(c, _state[2]);
    _state[3] = BinaryOps.add32(d, _state[3]);
    _state[4] = BinaryOps.add32(e, _state[4]);
  }

  @override
  int get getBlockSize => 64;

  @override
  int get getDigestLength => _state.length * 4;

  /// Resets the hash computation to its initial state.
  ///
  /// Returns the current instance of the hash algorithm with the initial stat
  @override
  SHA1 reset() {
    _init();
    _finished = false;
    _lengthInBytes = 0;
    return this;
  }

  /// Restores the hash computation state from a previously saved state.
  ///
  /// Parameters:
  /// - [savedState]: The saved state to restore.
  ///
  /// Returns the current instance of the hash algorithm with the restored state.
  @override
  SerializableHash restoreState(SH1State savedState) {
    _buffer.clear();
    _buffer.addAll(savedState.buffer);
    _state.setAll(0, savedState.state);
    _lengthInBytes = savedState.length;
    _iterate();
    _finished = false;
    return this;
  }

  /// Saves the current hash computation state into a serializable state object.
  @override
  SH1State saveState() {
    return SH1State(
      buffer: _buffer.clone(),
      length: _lengthInBytes,
      state: _state.clone(),
    );
  }

  /// Updates the hash computation with the given data.
  ///
  /// Parameters:
  /// - [data]: Containing the data to be hashed.
  @override
  SHA1 update(List<int> data) {
    if (_finished) {
      throw CryptoException.failed(
        "SHA1.update",
        reason: "State was finished.",
      );
    }
    _lengthInBytes += data.length;
    _buffer.addAll(data.asBytes);
    _iterate();
    return this;
  }

  void _iterate() {
    final pendingDataChunks = _buffer.length ~/ getBlockSize;
    for (int i = 0; i < pendingDataChunks; i++) {
      // Copy words from the pending data buffer into the current chunk buffer.
      for (int j = 0; j < _currentChunk.length; j++) {
        _currentChunk[j] = BinaryOps.readUint32BE(
          _buffer,
          i * getBlockSize + j * 4,
        );
      }
      _proccess(_currentChunk);
    }

    // Remove all pending data up to the last clean chunk break.
    _buffer.removeRange(0, pendingDataChunks * getBlockSize);
  }

  /// Computes the SHA1 hash of the provided data.
  static List<int> hash(List<int> data) {
    final h = SHA1();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}

/// The [SH1State] class represents the state of the SHA-1 hash algorithm.
class SH1State implements HashState {
  SH1State({required this.buffer, required this.length, required this.state});

  /// The buffer storing data to be hashed.
  List<int> buffer;

  /// The length of the data in bytes.
  int length;

  /// The state of the SHA-1 hash.
  List<int> state;
}
