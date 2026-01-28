part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// Implementation of the MD4 (Message Digest 4) hash function.
class MD4 implements SerializableHash<SH1State> {
  /// The initial constructor for the MD4 class.
  ///
  /// Initializes the MD4 hash function and resets it to its initial state.
  MD4() {
    reset();
  }

  /// Computes the MD4 hash (Message Digest 4) for the given input data.
  ///
  /// Parameters:
  /// - [data]: The input data for which the MD4 hash is computed.
  ///
  static List<int> hash(List<int> data) {
    /// Create an MD4 hash object.
    final h = MD4();

    /// Update the hash object with the input data.
    h.update(data);

    /// Compute the MD4 hash.
    final digest = h.digest();

    /// Clean up the hash object.
    h.clean();

    /// Return the MD4 hash.
    return digest;
  }

  final _buffer = List<int>.empty(growable: true);
  int _lengthInBytes = 0;

  /// store state
  final List<int> _state = List<int>.filled(4, 0);

  /// store chunk bytes
  final List<int> _currentChunk = List<int>.filled(16, 0);

  bool _finished = false;

  final _iv = const [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476];

  final _s = const [
    [3, 7, 11, 19],
    [3, 5, 9, 13],
    [3, 9, 11, 15],
  ];

  final _f = 0x00000000;

  final _g = 0x5a827999;

  final _h = 0x6ed9eba1;

  /// Returns the block size of the MD4 hash algorithm in bytes, which is 64 bytes.
  @override
  int get getBlockSize => 64;

  /// Returns the length of the MD4 hash digest in bytes, which is 16 bytes.
  @override
  int get getDigestLength => 16;

  /// Clears internal state and buffers, resetting the MD4 hash object to its initial state.
  @override
  void clean() {
    BinaryOps.zero(_state);
    BinaryOps.zero(_currentChunk);
    _buffer.clear();
    reset();
  }

  void _init() {
    _state.setAll(0, _iv);
  }

  /// Cleans and securely zeros a saved state object, resetting it to an empty state.
  @override
  void cleanSavedState(SH1State savedState) {
    savedState.buffer = [];
    savedState.state = _iv.clone();
    savedState.length = 0;
  }

  static int _ff(int x, int y, int z) {
    return (x & y) | ((~x) & z);
  }

  static int _gg(int x, int y, int z) {
    return (x & y) | (x & z) | (y & z);
  }

  static int _hh(int x, int y, int z) {
    return x ^ y ^ z;
  }

  static int _cc(
    int Function(int, int, int) f,
    int k,
    int a,
    int x,
    int y,
    int z,
    int m,
    int s,
  ) {
    return BinaryOps.rotl32((a + f(x, y, z) + m + k), s);
  }

  @override
  /// Computes the MD4 hash digest and returns it as a `List<int>`.
  List<int> digest() {
    final out = List<int>.filled(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Finalizes the hash computation and stores the result in the provided buffer.
  ///
  /// Parameters:
  /// - [out]: The buffer where the hash digest will be stored.
  @override
  Hash finish(List<int> out) {
    if (!_finished) {
      _finalize();
      _iterate();
      _finished = true;
    }
    for (var i = 0; i < _state.length; i++) {
      BinaryOps.writeUint32LE(_state[i], out, i * 4);
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
    BinaryOps.writeUint32LE(lowBits, _buffer, offset);
    BinaryOps.writeUint32LE(highBits, _buffer, offset + 4);
  }

  @override
  Hash reset() {
    _init();
    _finished = false;
    _lengthInBytes = 0;
    return this;
  }

  /// Restores the state of the MD4 hash computation from a saved state.
  ///
  /// Parameters:
  /// - [savedState]: The saved state to restore the hash computation from.
  ///
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

  /// Saves the current state of the MD4 hash computation.
  ///
  /// Returns:
  /// - A [SH1State] object containing the saved state of the hash computation.
  @override
  SH1State saveState() {
    return SH1State(
      buffer: _buffer.clone(),
      length: _lengthInBytes,
      state: _state.clone(),
    );
  }

  /// Updates the MD4 hash with the provided input data.
  ///
  /// Parameters:
  /// - [data]: The input data to be included in the hash computation.
  ///
  @override
  Hash update(List<int> data) {
    if (_finished) {
      throw CryptoException.failed("MD4.update", reason: "State was finished.");
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
        _currentChunk[j] = BinaryOps.readUint32LE(
          _buffer,
          i * getBlockSize + j * 4,
        );
      }
      _proccess(_currentChunk);
    }

    // Remove all pending data up to the last clean chunk break.
    _buffer.removeRange(0, pendingDataChunks * getBlockSize);
  }

  void _proccess(List<int> block) {
    int a = _state[0];
    int b = _state[1];
    int c = _state[2];
    int d = _state[3];

    // Round 1
    a = _cc(_ff, _f, a, b, c, d, block[0], _s[0][0]);
    d = _cc(_ff, _f, d, a, b, c, block[1], _s[0][1]);
    c = _cc(_ff, _f, c, d, a, b, block[2], _s[0][2]);
    b = _cc(_ff, _f, b, c, d, a, block[3], _s[0][3]);
    a = _cc(_ff, _f, a, b, c, d, block[4], _s[0][0]);
    d = _cc(_ff, _f, d, a, b, c, block[5], _s[0][1]);
    c = _cc(_ff, _f, c, d, a, b, block[6], _s[0][2]);
    b = _cc(_ff, _f, b, c, d, a, block[7], _s[0][3]);
    a = _cc(_ff, _f, a, b, c, d, block[8], _s[0][0]);
    d = _cc(_ff, _f, d, a, b, c, block[9], _s[0][1]);
    c = _cc(_ff, _f, c, d, a, b, block[10], _s[0][2]);
    b = _cc(_ff, _f, b, c, d, a, block[11], _s[0][3]);
    a = _cc(_ff, _f, a, b, c, d, block[12], _s[0][0]);
    d = _cc(_ff, _f, d, a, b, c, block[13], _s[0][1]);
    c = _cc(_ff, _f, c, d, a, b, block[14], _s[0][2]);
    b = _cc(_ff, _f, b, c, d, a, block[15], _s[0][3]);

    // Round 2
    a = _cc(_gg, _g, a, b, c, d, block[0], _s[1][0]);
    d = _cc(_gg, _g, d, a, b, c, block[4], _s[1][1]);
    c = _cc(_gg, _g, c, d, a, b, block[8], _s[1][2]);
    b = _cc(_gg, _g, b, c, d, a, block[12], _s[1][3]);
    a = _cc(_gg, _g, a, b, c, d, block[1], _s[1][0]);
    d = _cc(_gg, _g, d, a, b, c, block[5], _s[1][1]);
    c = _cc(_gg, _g, c, d, a, b, block[9], _s[1][2]);
    b = _cc(_gg, _g, b, c, d, a, block[13], _s[1][3]);
    a = _cc(_gg, _g, a, b, c, d, block[2], _s[1][0]);
    d = _cc(_gg, _g, d, a, b, c, block[6], _s[1][1]);
    c = _cc(_gg, _g, c, d, a, b, block[10], _s[1][2]);
    b = _cc(_gg, _g, b, c, d, a, block[14], _s[1][3]);
    a = _cc(_gg, _g, a, b, c, d, block[3], _s[1][0]);
    d = _cc(_gg, _g, d, a, b, c, block[7], _s[1][1]);
    c = _cc(_gg, _g, c, d, a, b, block[11], _s[1][2]);
    b = _cc(_gg, _g, b, c, d, a, block[15], _s[1][3]);

    // Round 3
    a = _cc(_hh, _h, a, b, c, d, block[0], _s[2][0]);
    d = _cc(_hh, _h, d, a, b, c, block[8], _s[2][1]);
    c = _cc(_hh, _h, c, d, a, b, block[4], _s[2][2]);
    b = _cc(_hh, _h, b, c, d, a, block[12], _s[2][3]);
    a = _cc(_hh, _h, a, b, c, d, block[2], _s[2][0]);
    d = _cc(_hh, _h, d, a, b, c, block[10], _s[2][1]);
    c = _cc(_hh, _h, c, d, a, b, block[6], _s[2][2]);
    b = _cc(_hh, _h, b, c, d, a, block[14], _s[2][3]);
    a = _cc(_hh, _h, a, b, c, d, block[1], _s[2][0]);
    d = _cc(_hh, _h, d, a, b, c, block[9], _s[2][1]);
    c = _cc(_hh, _h, c, d, a, b, block[5], _s[2][2]);
    b = _cc(_hh, _h, b, c, d, a, block[13], _s[2][3]);
    a = _cc(_hh, _h, a, b, c, d, block[3], _s[2][0]);
    d = _cc(_hh, _h, d, a, b, c, block[11], _s[2][1]);
    c = _cc(_hh, _h, c, d, a, b, block[7], _s[2][2]);
    b = _cc(_hh, _h, b, c, d, a, block[15], _s[2][3]);

    _state[0] = BinaryOps.add32(_state[0], a);
    _state[1] = BinaryOps.add32(_state[1], b);
    _state[2] = BinaryOps.add32(_state[2], c);
    _state[3] = BinaryOps.add32(_state[3], d);
  }
}
