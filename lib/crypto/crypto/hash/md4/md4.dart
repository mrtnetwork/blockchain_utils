part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// Implementation of the MD4 (Message Digest 4) hash function.
///
/// MD4 is a widely-used cryptographic hash function that produces a 128-bit (16-byte) hash value.
/// This class allows you to compute MD4 hashes for input data.
class MD4 implements SerializableHash<SH1State> {
  /// The initial constructor for the MD4 class.
  ///
  /// Initializes the MD4 hash function and resets it to its initial state.
  MD4() {
    reset();
  }

  /// Computes the MD4 hash (Message Digest 4) for the given input data.
  ///
  /// This static method creates an MD4 hash object, updates it with the provided data, computes the
  /// hash, and then cleans up the object. The resulting MD4 hash is a 128-bit (16-byte) value.
  ///
  /// Parameters:
  /// - [data]: The input data for which the MD4 hash is computed.
  ///
  /// Returns:
  /// A `List<int>` representing the 128-bit MD4 hash value.
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

  /// Returns the block size of the MD4 hash algorithm in bytes, which is 64 bytes.
  ///
  /// The block size is the size of the data block that the hash algorithm operates on.
  @override
  int get getBlockSize => 64;

  /// Returns the length of the MD4 hash digest in bytes, which is 16 bytes.
  ///
  /// The digest length is the size of the final hash result produced by the MD4 algorithm.
  @override
  int get getDigestLength => 16;

  /// Clears internal state and buffers, resetting the MD4 hash object to its initial state.
  ///
  /// This method securely zeros the internal state and buffers of the MD4 hash object,
  /// ensuring no sensitive data remains in memory. After cleaning, the object is reset
  /// to its initial state, ready for further use.
  @override
  void clean() {
    zero(_state);
    zero(_currentChunk);
    _buffer.clear();
    reset();
  }

  void _init() {
    _state[0] = 0x67452301;
    _state[1] = 0xefcdab89;
    _state[2] = 0x98badcfe;
    _state[3] = 0x10325476;
  }

  /// Cleans and securely zeros a saved state object, resetting it to an empty state.
  ///
  /// This method takes a [HashState] object, usually representing the state of an MD4 hash,
  /// and securely zeros the internal state and data within it. After cleaning, the object
  /// is reset to an empty state, ensuring that no sensitive data remains in memory.
  ///
  /// Params:
  /// - `savedState`: The [HashState] object to be cleaned and reset.
  @override
  void cleanSavedState(SH1State savedState) {
    savedState.buffer = List.empty();
    savedState.state = List<int>.from([
      0x67452301,
      0xefcdab89,
      0x98badcfe,
      0x10325476,
    ], growable: false);
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

  static int _cc(int Function(int, int, int) f, int k, int a, int x, int y,
      int z, int m, int s) {
    return rotl32((a + f(x, y, z) + m + k), s);
  }

  static const _s = [
    [3, 7, 11, 19],
    [3, 5, 9, 13],
    [3, 9, 11, 15]
  ];

  static const _f = 0x00000000;

  static const _g = 0x5a827999;

  static const _h = 0x6ed9eba1;

  @override

  /// Computes the MD4 hash digest and returns it as a `List<int>`.
  ///
  /// This method calculates the MD4 hash of the data processed so far and returns
  /// the resulting hash digest as a `List<int>`. It finalizes the hash computation
  /// if it hasn't been finished already and then returns the digest.
  ///
  /// Returns:
  /// - A `List<int>` containing the MD4 hash digest.
  List<int> digest() {
    final out = List<int>.filled(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Finalizes the hash computation and stores the result in the provided buffer.
  ///
  /// This method finalizes the hash computation, ensuring that all data has been processed,
  /// and stores the result in the provided 'out' buffer as a hash digest. If the hash computation
  /// has already been finished, it won't be reprocessed.
  ///
  /// Parameters:
  /// - [out]: The `List<int>` buffer where the hash digest will be stored.
  ///
  /// Returns:
  /// - The MD4 hash object after finalization.
  @override
  Hash finish(List<int> out) {
    if (!_finished) {
      _finalize();
      _iterate();
      _finished = true;
    }
    for (var i = 0; i < _state.length; i++) {
      writeUint32LE(_state[i], out, i * 4);
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
    final lowBits = lengthInBits & mask32;
    writeUint32LE(lowBits, _buffer, offset);
    writeUint32LE(highBits, _buffer, offset + 4);
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
  /// This method restores the MD4 hash computation state from a previously saved state,
  /// allowing the continuation of hashing from the saved point.
  ///
  /// Parameters:
  /// - [savedState]: The saved state to restore the hash computation from.
  ///
  /// Returns:
  /// - The MD4 hash object with the restored state.
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
  /// This method saves the current state of the MD4 hash computation, including
  /// the internal buffer, length, and state. The saved state can be used later
  /// to restore the hash computation to this point.
  ///
  /// Returns:
  /// - A [SH1State] object containing the saved state of the hash computation.
  @override
  SH1State saveState() {
    return SH1State(
        buffer: List<int>.from(_buffer.toList()),
        length: _lengthInBytes,
        state: List<int>.from(_state, growable: false));
  }

  /// Updates the MD4 hash with the provided input data.
  ///
  /// This method updates the MD4 hash by processing the input [data].
  /// If the hash computation is already finished, it will throw a [StateError].
  ///
  /// Parameters:
  /// - [data]: The input data to be included in the hash computation.
  ///
  /// Returns:
  /// - The updated [MD4] hash object.
  @override
  Hash update(List<int> data) {
    if (_finished) {
      throw const MessageException(
          "SHA512: can't update because hash was finished.");
    }
    _lengthInBytes += data.length;
    _buffer.addAll(BytesUtils.toBytes(data));
    _iterate();
    return this;
  }

  void _iterate() {
    final pendingDataChunks = _buffer.length ~/ getBlockSize;
    for (var i = 0; i < pendingDataChunks; i++) {
      // Copy words from the pending data buffer into the current chunk buffer.
      for (var j = 0; j < _currentChunk.length; j++) {
        _currentChunk[j] = readUint32LE(_buffer, i * getBlockSize + j * 4);
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

    _state[0] = add32(_state[0], a);
    _state[1] = add32(_state[1], b);
    _state[2] = add32(_state[2], c);
    _state[3] = add32(_state[3], d);
  }
}
