part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// A class that represents the MD5 hash algorithm, which is used to compute
/// MD5 message digests. This class implements the [SerializableHash] interface.
///
/// The MD5 algorithm produces a 128-bit (16-byte) message digest of input data.
///
/// Example usage:
/// ```dart
/// final md5 = MD5();
/// md5.update(`List<int>`.from('Hello, world!'.codeUnits));
/// final digest = md5.digest();
/// md5.clean(); // Clean up resources after use.
/// ```
class MD5 implements SerializableHash<SH1State> {
  /// Creates a new MD5 instance.
  MD5() {
    reset();
  }

  /// Computes the MD5 hash of the provided [data] and returns the 128-bit (16-byte)
  /// MD5 message digest as a [`List<int>`].
  ///
  /// This static method is a convenient way to compute an MD5 hash for a given
  /// data without creating an instance of the [MD5] class.
  ///
  /// Example usage:
  /// ```dart
  /// final data = `List<int>`.from('Hello, MD5!'.codeUnits);
  /// final digest = MD5.hash(data);
  /// ```
  ///
  /// Note: It is recommended to clean up resources using the `clean` method after
  /// using the [MD5] hash instance.
  static List<int> hash(List<int> data) {
    final h = MD5();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }

  final _buffer = List<int>.empty(growable: true); //Uint8Buffer();
  int _lengthInBytes = 0;

  /// store state
  final List<int> _state = List<int>.filled(4, 0);

  /// store chunk bytes
  final List<int> _currentChunk = List<int>.filled(16, 0);

  bool _finished = false;

  /// Clean up the internal state and reset hash object to its initial state.
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

  /// Clean up and reset the saved state of the hash object to its initial state.
  /// This function erases the buffer and sets the state and length to the default values.
  /// It is used to ensure that a previously saved hash state is cleared and ready for reuse.
  ///
  /// [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(SH1State savedState) {
    savedState.buffer = List.empty();
    savedState.state = List.unmodifiable([
      0x67452301,
      0xefcdab89,
      0x98badcfe,
      0x10325476,
    ]);
    savedState.length = 0;
  }

  static int _ff(int x, int y, int z) {
    return ((x & y) | (~x & z)) & mask32;
  }

  static int _gg(int x, int y, int z) {
    return ((x & z) | (y & ~z)) & mask32;
  }

  static int _hh(int x, int y, int z) {
    return (x ^ y ^ z) & mask32;
  }

  static int _ii(int x, int y, int z) {
    return (y ^ (x | ~z)) & mask32;
  }

  static int _cc(int Function(int, int, int) f, int k, int a, int x, int y,
      int z, int m, int s) {
    return (add32(rotl32(add32(add32(add32(a, f(x, y, z)), m), k), s), x));
  }

  static final List<int> _t = List<int>.generate(64, (i) {
    return ((math.sin(i + 1) * 0x100000000).abs()).toInt();
  });

  static const _s = [
    [7, 12, 17, 22],
    [5, 9, 14, 20],
    [4, 11, 16, 23],
    [6, 10, 15, 21]
  ];

  /// Generates the final hash digest by assembling and returning the hash state in a `List<int>`.
  ///
  /// This function produces the hash digest by combining the current hash state into a single
  /// `List<int>` output. It finalizes the hash if it hasn't been finished, effectively completing
  /// the hash computation and returning the result.
  ///
  /// Returns the `List<int>` containing the computed hash digest.
  @override
  List<int> digest() {
    final out = List<int>.filled(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Finalizes the hash computation and stores the hash state in the provided `List<int>` [out].
  ///
  /// This function completes the hash computation, finalizes the state, and stores the resulting
  /// hash in the provided [out] `List<int>`. If the hash has already been finished, this method
  /// will return the existing state without re-computing.
  ///
  /// Parameters:
  ///   - [out]: The `List<int>` in which the hash digest is stored.
  ///
  /// Returns the current instance of the hash algorithm.
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

    // Add the full length of the input data as a 64-bit value at the end of the
    // hash. Note: we're only writing out 64 bits, so skip ahead 8 if the
    // signature is 128-bit.
    final offset = _buffer.length;

    _buffer.addAll(List<int>.filled(8, 0));
    // var byteData = _buffer.buffer.asByteData();

    // We're essentially doing byteData.setUint64(offset, lengthInBits, _endian)
    // here, but that method isn't supported on dart2js so we implement it
    // manually instead.
    final highBits = lengthInBits ~/ 0x100000000; // >> 32
    final lowBits = lengthInBits & mask32;
    // byteData.setUint32(offset, lowBits, Endian.little);
    // byteData.setUint32(offset + 4, highBits, Endian.little);
    writeUint32LE(lowBits, _buffer, offset);
    writeUint32LE(highBits, _buffer, offset + 4);
  }

  @override
  int get getBlockSize => 64;

  @override
  int get getDigestLength => 16;

  /// Resets the hash computation to its initial state.
  ///
  /// This method initializes the hash computation to its initial state, clearing any previously
  /// processed data. After calling this method, you can start a new hash computation.
  ///
  /// Returns the current instance of the hash algorithm with the initial stat
  @override
  Hash reset() {
    _init();
    _finished = false;
    _lengthInBytes = 0;
    return this;
  }

  /// Restores the hash computation state from a previously saved state.
  ///
  /// This method allows you to restore the hash computation state to a previously saved state.
  /// It is useful when you want to continue hashing data from a certain point, or if you want
  /// to combine multiple hash computations.
  ///
  /// Parameters:
  /// - `savedState`: The saved state to restore.
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
  ///
  /// This method saves the current state of the hash computation, including the data buffer,
  /// hash state, and etc, into a serializable state object.
  /// The saved state can be later restored using the `restoreState` method.
  ///
  /// Returns a [HashState] object containing the saved state information.
  @override
  SH1State saveState() {
    return SH1State(
        buffer: List<int>.from(_buffer.toList()),
        length: _lengthInBytes,
        state: List.unmodifiable(_state));
  }

  /// Updates the hash computation with the given data.
  ///
  /// This method updates the hash computation with the provided [data] bytes. It appends the data to
  /// the internal buffer and processes it to update the hash state.
  ///
  /// If the hash has already been finished using the `finish` method, calling this method will result in an error.
  ///
  /// Parameters:
  /// - [data]: The `List<int>` containing the data to be hashed.
  ///
  /// Returns this [Hash] object for method chaining.
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
    // Working variables
    int a = _state[0] | 0;
    int b = _state[1] | 0;
    int c = _state[2] | 0;
    int d = _state[3] | 0;

    // Round 1
    a = _cc(_ff, _t[0], a, b, c, d, block[0], _s[0][0]);
    d = _cc(_ff, _t[1], d, a, b, c, block[1], _s[0][1]);
    c = _cc(_ff, _t[2], c, d, a, b, block[2], _s[0][2]);
    b = _cc(_ff, _t[3], b, c, d, a, block[3], _s[0][3]);
    a = _cc(_ff, _t[4], a, b, c, d, block[4], _s[0][0]);
    d = _cc(_ff, _t[5], d, a, b, c, block[5], _s[0][1]);
    c = _cc(_ff, _t[6], c, d, a, b, block[6], _s[0][2]);
    b = _cc(_ff, _t[7], b, c, d, a, block[7], _s[0][3]);
    a = _cc(_ff, _t[8], a, b, c, d, block[8], _s[0][0]);
    d = _cc(_ff, _t[9], d, a, b, c, block[9], _s[0][1]);
    c = _cc(_ff, _t[10], c, d, a, b, block[10], _s[0][2]);
    b = _cc(_ff, _t[11], b, c, d, a, block[11], _s[0][3]);
    a = _cc(_ff, _t[12], a, b, c, d, block[12], _s[0][0]);
    d = _cc(_ff, _t[13], d, a, b, c, block[13], _s[0][1]);
    c = _cc(_ff, _t[14], c, d, a, b, block[14], _s[0][2]);
    b = _cc(_ff, _t[15], b, c, d, a, block[15], _s[0][3]);

    // Round 2
    a = _cc(_gg, _t[16], a, b, c, d, block[1], _s[1][0]);
    d = _cc(_gg, _t[17], d, a, b, c, block[6], _s[1][1]);
    c = _cc(_gg, _t[18], c, d, a, b, block[11], _s[1][2]);
    b = _cc(_gg, _t[19], b, c, d, a, block[0], _s[1][3]);
    a = _cc(_gg, _t[20], a, b, c, d, block[5], _s[1][0]);
    d = _cc(_gg, _t[21], d, a, b, c, block[10], _s[1][1]);
    c = _cc(_gg, _t[22], c, d, a, b, block[15], _s[1][2]);
    b = _cc(_gg, _t[23], b, c, d, a, block[4], _s[1][3]);
    a = _cc(_gg, _t[24], a, b, c, d, block[9], _s[1][0]);
    d = _cc(_gg, _t[25], d, a, b, c, block[14], _s[1][1]);
    c = _cc(_gg, _t[26], c, d, a, b, block[3], _s[1][2]);
    b = _cc(_gg, _t[27], b, c, d, a, block[8], _s[1][3]);
    a = _cc(_gg, _t[28], a, b, c, d, block[13], _s[1][0]);
    d = _cc(_gg, _t[29], d, a, b, c, block[2], _s[1][1]);
    c = _cc(_gg, _t[30], c, d, a, b, block[7], _s[1][2]);
    b = _cc(_gg, _t[31], b, c, d, a, block[12], _s[1][3]);

    // Round 3
    a = _cc(_hh, _t[32], a, b, c, d, block[5], _s[2][0]);
    d = _cc(_hh, _t[33], d, a, b, c, block[8], _s[2][1]);
    c = _cc(_hh, _t[34], c, d, a, b, block[11], _s[2][2]);
    b = _cc(_hh, _t[35], b, c, d, a, block[14], _s[2][3]);
    a = _cc(_hh, _t[36], a, b, c, d, block[1], _s[2][0]);
    d = _cc(_hh, _t[37], d, a, b, c, block[4], _s[2][1]);
    c = _cc(_hh, _t[38], c, d, a, b, block[7], _s[2][2]);
    b = _cc(_hh, _t[39], b, c, d, a, block[10], _s[2][3]);
    a = _cc(_hh, _t[40], a, b, c, d, block[13], _s[2][0]);
    d = _cc(_hh, _t[41], d, a, b, c, block[0], _s[2][1]);
    c = _cc(_hh, _t[42], c, d, a, b, block[3], _s[2][2]);
    b = _cc(_hh, _t[43], b, c, d, a, block[6], _s[2][3]);
    a = _cc(_hh, _t[44], a, b, c, d, block[9], _s[2][0]);
    d = _cc(_hh, _t[45], d, a, b, c, block[12], _s[2][1]);
    c = _cc(_hh, _t[46], c, d, a, b, block[15], _s[2][2]);
    b = _cc(_hh, _t[47], b, c, d, a, block[2], _s[2][3]);

    // Round 4
    a = _cc(_ii, _t[48], a, b, c, d, block[0], _s[3][0]);
    d = _cc(_ii, _t[49], d, a, b, c, block[7], _s[3][1]);
    c = _cc(_ii, _t[50], c, d, a, b, block[14], _s[3][2]);
    b = _cc(_ii, _t[51], b, c, d, a, block[5], _s[3][3]);
    a = _cc(_ii, _t[52], a, b, c, d, block[12], _s[3][0]);
    d = _cc(_ii, _t[53], d, a, b, c, block[3], _s[3][1]);
    c = _cc(_ii, _t[54], c, d, a, b, block[10], _s[3][2]);
    b = _cc(_ii, _t[55], b, c, d, a, block[1], _s[3][3]);
    a = _cc(_ii, _t[56], a, b, c, d, block[8], _s[3][0]);
    d = _cc(_ii, _t[57], d, a, b, c, block[15], _s[3][1]);
    c = _cc(_ii, _t[58], c, d, a, b, block[6], _s[3][2]);
    b = _cc(_ii, _t[59], b, c, d, a, block[13], _s[3][3]);
    a = _cc(_ii, _t[60], a, b, c, d, block[4], _s[3][0]);
    d = _cc(_ii, _t[61], d, a, b, c, block[11], _s[3][1]);
    c = _cc(_ii, _t[62], c, d, a, b, block[2], _s[3][2]);
    b = _cc(_ii, _t[63], b, c, d, a, block[9], _s[3][3]);

    _state[0] = add32(_state[0], a);
    _state[1] = add32(_state[1], b);
    _state[2] = add32(_state[2], c);
    _state[3] = add32(_state[3], d);
  }
}
