part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// The `SHA256` class represents the SHA-256 hash algorithm.
///
/// SHA-256 is a cryptographic hash function that produces a 256-bit (32-byte) hash
/// value from an input message. It's commonly used in various security applications.
/// This class implements the SHA-256 algorithm and provides a standard interface
/// for hashing data and producing digests.
class SHA256 implements SerializableHash<SHA256State> {
  static const int digestLength = 32;
  static const int blockSize = 64;
  SHA256() {
    reset();
  }

  /// digest length
  @override
  int get getDigestLength => digestLength;

  /// block size
  @override
  int get getBlockSize => blockSize;

  // Note: `List<int>` is used instead of Uint32List for performance reasons.
  final List<int> _state = List<int>.filled(8, 0); // hash state
  final List<int> _temp = List<int>.filled(64, 0); // temporary state
  final List<int> _buffer = List<int>.filled(128, 0); // buffer for data to hash
  int _bufferLength = 0; // number of bytes in buffer
  int _bytesHashed = 0; // number of total bytes hashed
  bool _finished = false; // indicates whether the hash was finalized

  // Rest of your class implementation goes here...
  void _initState() {
    _state[0] = 0x6a09e667;
    _state[1] = 0xbb67ae85;
    _state[2] = 0x3c6ef372;
    _state[3] = 0xa54ff53a;
    _state[4] = 0x510e527f;
    _state[5] = 0x9b05688c;
    _state[6] = 0x1f83d9ab;
    _state[7] = 0x5be0cd19;
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
  SerializableHash update(List<int> data, {int? length}) {
    if (_finished) {
      throw const MessageException(
          "SHA256: can't update because hash was finished.");
    }
    int dataLength = length ?? data.length;
    int dataPos = 0;
    _bytesHashed += dataLength;

    if (_bufferLength > 0) {
      while (_bufferLength < getBlockSize && dataLength > 0) {
        _buffer[_bufferLength++] = data[dataPos++] & mask8;
        dataLength--;
      }

      if (_bufferLength == getBlockSize) {
        _hashBlocks(_temp, _state, _buffer, 0, getBlockSize);

        _bufferLength = 0;
      }
    }

    if (dataLength >= getBlockSize) {
      dataPos = _hashBlocks(_temp, _state, data, dataPos, dataLength);

      dataLength %= getBlockSize;
    }

    while (dataLength > 0) {
      _buffer[_bufferLength++] = data[dataPos++] & mask8;
      dataLength--;
    }
    return this;
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
  SerializableHash finish(List<int> out) {
    if (!_finished) {
      final bytesHashed = _bytesHashed;
      final left = _bufferLength;
      final bitLenHi = (bytesHashed ~/ 0x20000000) & 0xFFFFFFFF;
      final bitLenLo = bytesHashed << 3;
      final padLength = (bytesHashed % 64 < 56) ? 64 : 128;

      _buffer[left] = 0x80;
      for (var i = left + 1; i < padLength - 8; i++) {
        _buffer[i] = 0;
      }

      writeUint32BE(bitLenHi, _buffer, padLength - 8);
      writeUint32BE(bitLenLo, _buffer, padLength - 4);

      _hashBlocks(_temp, _state, _buffer, 0, padLength);
      _finished = true;
    }
    for (var i = 0; i < getDigestLength ~/ 4; i++) {
      writeUint32BE(_state[i], out, i * 4);
    }

    return this;
  }

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

  /// Resets the hash computation to its initial state.
  ///
  /// This method initializes the hash computation to its initial state, clearing any previously
  /// processed data. After calling this method, you can start a new hash computation.
  ///
  /// Returns the current instance of the hash algorithm with the initial stat
  @override
  SerializableHash reset() {
    _initState();
    _bufferLength = 0;
    _bytesHashed = 0;
    _finished = false;

    return this;
  }

  /// Clean up the internal state and reset hash object to its initial state.
  @override
  void clean() {
    zero(_buffer);
    zero(_temp);
    reset();
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
  SerializableHash restoreState(SHA256State savedState) {
    _state.setAll(0, savedState.state);
    _bufferLength = savedState.bufferLength;
    if (savedState.buffer != null) {
      _buffer.setRange(0, savedState.buffer!.length, savedState.buffer!);
    }
    _bytesHashed = savedState.bytesHashed;
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
  SHA256State saveState() {
    if (_finished) {
      throw const MessageException("SHA256: cannot save finished state");
    }
    return SHA256State(
      state: List<int>.from(_state, growable: false),
      buffer:
          _bufferLength > 0 ? List<int>.from(_buffer, growable: false) : null,
      bufferLength: _bufferLength,
      bytesHashed: _bytesHashed,
    );
  }

  /// Clean up and reset the saved state of the hash object to its initial state.
  /// This function erases the buffer and sets the state and length to the default values.
  /// It is used to ensure that a previously saved hash state is cleared and ready for reuse.
  ///
  /// [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(SHA256State savedState) {
    zero(savedState.state);
    if (savedState.buffer != null) {
      zero(savedState.buffer!);
    }
    savedState.bufferLength = 0;
    savedState.bytesHashed = 0;
  }

  final _k = List<int>.unmodifiable(const [
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2
  ]);

  int _hashBlocks(List<int> w, List<int> v, List<int> p, int pos, int len) {
    while (len >= 64) {
      int a = v[0];
      int b = v[1];
      int c = v[2];
      int d = v[3];
      int e = v[4];
      int f = v[5];
      int g = v[6];
      int h = v[7];
      for (int i = 0; i < 16; i++) {
        final int j = pos + i * 4;
        w[i] = readUint32BE(p, j);
      }
      for (int i = 16; i < 64; i++) {
        int u = w[i - 2];
        final int t1 = rotr32(u, 17) ^ rotr32(u, 19) ^ (u >> 10);
        u = w[i - 15];
        final int t2 = rotr32(u, 7) ^ rotr32(u, 18) ^ (u >> 3);
        w[i] = add32(add32(add32(t1, w[i - 7]), t2), w[i - 16]);
      }
      for (int i = 0; i < 64; i++) {
        final int t1 = add32(
            add32(rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25),
                (e & f) ^ (~e & g)),
            add32(add32(h, _k[i]), w[i]));
        final int t2 = add32((rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22)),
            (a & b) ^ (a & c) ^ (b & c));
        h = g;
        g = f;
        f = e;
        e = add32(d, t1);
        d = c;
        c = b;
        b = a;
        a = add32(t1, t2);
      }
      v[0] = add32(v[0], a);
      v[1] = add32(v[1], b);
      v[2] = add32(v[2], c);
      v[3] = add32(v[3], d);
      v[4] = add32(v[4], e);
      v[5] = add32(v[5], f);
      v[6] = add32(v[6], g);
      v[7] = add32(v[7], h);
      pos += 64;
      len -= 64;
    }
    return pos;
  }

  /// Computes the SHA-256 hash of the provided data.
  static List<int> hash(List<int> data) {
    final h = SHA256();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}

class SHA256State implements HashState {
  final List<int> state;
  final List<int>? buffer;
  int bufferLength;
  int bytesHashed;

  SHA256State({
    required this.state,
    this.buffer,
    required this.bufferLength,
    required this.bytesHashed,
  });
}
