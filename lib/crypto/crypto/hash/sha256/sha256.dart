part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// The [SHA256] class represents the SHA-256 hash algorithm.
///
class SHA256 implements SerializableHash<SHA256State> {
  SHA256() {
    reset();
  }

  /// digest length
  @override
  int get getDigestLength => 32;

  /// block size
  @override
  int get getBlockSize => 64;

  final List<int> _state = List<int>.filled(8, 0);
  final List<int> _temp = List<int>.filled(64, 0);
  final List<int> _buffer = List<int>.filled(128, 0);
  int _bufferLength = 0;
  int _bytesHashed = 0;
  bool _finished = false;

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
  /// Parameters:
  /// - [data]: The Containing the data to be hashed.
  @override
  SerializableHash update(List<int> data, {int? length}) {
    if (_finished) {
      throw CryptoException.failed("SHA.update", reason: "State was finished.");
    }
    int dataLength = length ?? data.length;
    int dataPos = 0;
    _bytesHashed += dataLength;

    if (_bufferLength > 0) {
      while (_bufferLength < getBlockSize && dataLength > 0) {
        _buffer[_bufferLength++] = data[dataPos++] & BinaryOps.mask8;
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
      _buffer[_bufferLength++] = data[dataPos++] & BinaryOps.mask8;
      dataLength--;
    }
    return this;
  }

  /// Finalizes the hash computation and stores the hash state in the provided [out].
  ///
  /// Parameters:
  ///   - [out]: In which the hash digest is stored.
  ///
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

      BinaryOps.writeUint32BE(bitLenHi, _buffer, padLength - 8);
      BinaryOps.writeUint32BE(bitLenLo, _buffer, padLength - 4);

      _hashBlocks(_temp, _state, _buffer, 0, padLength);
      _finished = true;
    }
    for (var i = 0; i < getDigestLength ~/ 4; i++) {
      BinaryOps.writeUint32BE(_state[i], out, i * 4);
    }

    return this;
  }

  /// Generates the final hash digest by assembling and returning the hash state.
  @override
  List<int> digest() {
    final out = List<int>.filled(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Resets the hash computation to its initial state.
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
    BinaryOps.zero(_buffer);
    BinaryOps.zero(_temp);
    reset();
  }

  /// Restores the hash computation state from a previously saved state.
  ///
  /// Parameters:
  /// - [savedState]: The saved state to restore.
  ///
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
  @override
  SHA256State saveState() {
    if (_finished) {
      throw CryptoException.failed(
        "SHA.saveState",
        reason: "State was finished.",
      );
    }
    return SHA256State(
      state: _state.clone(),
      buffer: _bufferLength > 0 ? _buffer.clone() : null,
      bufferLength: _bufferLength,
      bytesHashed: _bytesHashed,
    );
  }

  /// Clean up and reset the saved state of the hash object to its initial state.
  ///
  /// - [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(SHA256State savedState) {
    BinaryOps.zero(savedState.state);
    if (savedState.buffer != null) {
      BinaryOps.zero(savedState.buffer!);
    }
    savedState.bufferLength = 0;
    savedState.bytesHashed = 0;
  }

  final _k = const [
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
    0xc67178f2,
  ];

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
        w[i] = BinaryOps.readUint32BE(p, j);
      }
      for (int i = 16; i < 64; i++) {
        int u = w[i - 2];
        final int t1 =
            BinaryOps.rotr32(u, 17) ^ BinaryOps.rotr32(u, 19) ^ (u >> 10);
        u = w[i - 15];
        final int t2 =
            BinaryOps.rotr32(u, 7) ^ BinaryOps.rotr32(u, 18) ^ (u >> 3);
        w[i] = BinaryOps.add32(
          BinaryOps.add32(BinaryOps.add32(t1, w[i - 7]), t2),
          w[i - 16],
        );
      }
      for (int i = 0; i < 64; i++) {
        final int t1 = BinaryOps.add32(
          BinaryOps.add32(
            BinaryOps.rotr32(e, 6) ^
                BinaryOps.rotr32(e, 11) ^
                BinaryOps.rotr32(e, 25),
            (e & f) ^ (~e & g),
          ),
          BinaryOps.add32(BinaryOps.add32(h, _k[i]), w[i]),
        );
        final int t2 = BinaryOps.add32(
          (BinaryOps.rotr32(a, 2) ^
              BinaryOps.rotr32(a, 13) ^
              BinaryOps.rotr32(a, 22)),
          (a & b) ^ (a & c) ^ (b & c),
        );
        h = g;
        g = f;
        f = e;
        e = BinaryOps.add32(d, t1);
        d = c;
        c = b;
        b = a;
        a = BinaryOps.add32(t1, t2);
      }
      v[0] = BinaryOps.add32(v[0], a);
      v[1] = BinaryOps.add32(v[1], b);
      v[2] = BinaryOps.add32(v[2], c);
      v[3] = BinaryOps.add32(v[3], d);
      v[4] = BinaryOps.add32(v[4], e);
      v[5] = BinaryOps.add32(v[5], f);
      v[6] = BinaryOps.add32(v[6], g);
      v[7] = BinaryOps.add32(v[7], h);
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
