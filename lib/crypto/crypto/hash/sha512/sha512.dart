part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// The `SHA512` class implements the SHA-512 hash algorithm.
///
/// SHA-512 is a cryptographic hash function that takes an input message and
/// produces a 512-bit (64-byte) hash value known as the message digest.
///
/// To use the `SHA512` class for hashing, create an instance, update it with
/// data, and then retrieve the hash value using the `digest` method.
///
/// Example usage:
/// ```dart
/// final sha512 = SHA512();
/// sha512.update(data);
/// final hash = sha512.digest();
/// ```
class SHA512 implements SerializableHash<SHA512State> {
  /// Initializes a new instance of the SHA-512 hash algorithm.
  SHA512() {
    reset();
  }

  /// digest length
  static const int digestLength = 64;

  /// block size
  static const int blockSize = 128;

  @override
  int get getBlockSize => SHA512.blockSize;

  @override
  int get getDigestLength => SHA512.digestLength;

  final List<int> _stateHi = List<int>.filled(8, 0); // hash state, high bytes
  final List<int> _stateLo = List<int>.filled(8, 0); // hash state, low bytes
  final List<int> _tempHi =
      List<int>.filled(16, 0); // temporary state, high bytes
  final List<int> _tempLo =
      List<int>.filled(16, 0); // temporary state, low bytes
  final List<int> _buffer = List<int>.filled(256, 0); // buffer for data to hash
  int _bufferLength = 0; // number of bytes in buffer
  int _bytesHashed = 0; // number of total bytes hashed
  bool _finished = false; // indicates whether the hash was finalized

  void _initState() {
    _stateHi[0] = 0x6a09e667;
    _stateHi[1] = 0xbb67ae85;
    _stateHi[2] = 0x3c6ef372;
    _stateHi[3] = 0xa54ff53a;
    _stateHi[4] = 0x510e527f;
    _stateHi[5] = 0x9b05688c;
    _stateHi[6] = 0x1f83d9ab;
    _stateHi[7] = 0x5be0cd19;

    _stateLo[0] = 0xf3bcc908;
    _stateLo[1] = 0x84caa73b;
    _stateLo[2] = 0xfe94f82b;
    _stateLo[3] = 0x5f1d36f1;
    _stateLo[4] = 0xade682d1;
    _stateLo[5] = 0x2b3e6c1f;
    _stateLo[6] = 0xfb41bd6b;
    _stateLo[7] = 0x137e2179;
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
    zero(_tempHi);
    zero(_tempLo);
    reset();
  }

  /// Updates the hash computation with the given data.
  ///
  /// This method updates the hash computation with the provided [data] bytes. It appends the data to
  /// the internal buffer and processes it to update the hash state.
  ///
  /// If the hash has already been finished using the `finish` method, calling this method will result in an error.
  ///
  /// Parameters:
  /// - [data]: The List<int> containing the data to be hashed.
  ///
  /// Returns this [Hash] object for method chaining.
  @override
  SerializableHash update(List<int> data, {int? length}) {
    if (_finished) {
      throw const MessageException(
          "SHA512: can't update because hash was finished.");
    }
    int dataPos = 0;
    int dataLength = length ?? data.length;
    _bytesHashed += dataLength;

    if (_bufferLength > 0) {
      while (_bufferLength < getBlockSize && dataLength > 0) {
        _buffer[_bufferLength++] = data[dataPos++] & mask8;
        dataLength--;
      }

      if (_bufferLength == getBlockSize) {
        _hashBlocks(
            _tempHi, _tempLo, _stateHi, _stateLo, _buffer, 0, getBlockSize);
        _bufferLength = 0;
      }
    }

    if (dataLength >= getBlockSize) {
      dataPos = _hashBlocks(
          _tempHi, _tempLo, _stateHi, _stateLo, data, dataPos, dataLength);
      dataLength %= getBlockSize;
    }

    while (dataLength > 0) {
      _buffer[_bufferLength++] = data[dataPos++] & mask8;
      dataLength--;
    }

    return this;
  }

  /// Finalizes the hash computation and stores the hash state in the provided List<int> [out].
  ///
  /// This function completes the hash computation, finalizes the state, and stores the resulting
  /// hash in the provided [out] List<int>. If the hash has already been finished, this method
  /// will return the existing state without re-computing.
  ///
  /// Parameters:
  ///   - [out]: The List<int> in which the hash digest is stored.
  ///
  /// Returns the current instance of the hash algorithm.
  @override
  SerializableHash finish(List<int> out) {
    if (!_finished) {
      final bytesHashed = _bytesHashed;
      final left = _bufferLength;
      final bitLenHi = (bytesHashed ~/ 0x20000000).toInt();
      final bitLenLo = bytesHashed << 3;
      final padLength = (bytesHashed % 128 < 112) ? 128 : 256;

      _buffer[left] = 0x80;
      for (var i = left + 1; i < padLength - 8; i++) {
        _buffer[i] = 0;
      }

      writeUint32BE(bitLenHi, _buffer, padLength - 8);
      writeUint32BE(bitLenLo, _buffer, padLength - 4);

      _hashBlocks(_tempHi, _tempLo, _stateHi, _stateLo, _buffer, 0, padLength);

      _finished = true;
    }

    for (var i = 0; i < getDigestLength ~/ 8; i++) {
      writeUint32BE(_stateHi[i], out, i * 8);
      writeUint32BE(_stateLo[i], out, i * 8 + 4);
    }

    return this;
  }

  /// Generates the final hash digest by assembling and returning the hash state in a List<int>.
  ///
  /// This function produces the hash digest by combining the current hash state into a single
  /// List<int> output. It finalizes the hash if it hasn't been finished, effectively completing
  /// the hash computation and returning the result.
  ///
  /// Returns the List<int> containing the computed hash digest.
  @override
  List<int> digest() {
    final out = List<int>.filled(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Saves the current hash computation state into a serializable state object.
  ///
  /// This method saves the current state of the hash computation, including the data buffer,
  /// hash state, and etc, into a serializable state object.
  /// The saved state can be later restored using the `restoreState` method.
  ///
  /// Returns a [HashState] object containing the saved state information.
  @override
  SHA512State saveState() {
    if (_finished) {
      throw const MessageException("SHA256: cannot save finished state");
    }
    return SHA512State(
      stateHi: List<int>.from(_stateHi, growable: false),
      stateLo: List<int>.from(_stateLo, growable: false),
      buffer: (_bufferLength > 0) ? List<int>.from(_buffer) : null,
      bufferLength: _bufferLength,
      bytesHashed: _bytesHashed,
    );
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
  SerializableHash restoreState(SHA512State savedState) {
    _stateHi.setAll(0, savedState.stateHi);
    _stateLo.setAll(0, savedState.stateLo);
    _bufferLength = savedState.bufferLength;
    if (savedState.buffer != null) {
      _buffer.setAll(0, savedState.buffer!);
    }
    _bytesHashed = savedState.bytesHashed;
    _finished = false;
    return this;
  }

  /// Clean up and reset the saved state of the hash object to its initial state.
  /// This function erases the buffer and sets the state and length to the default values.
  /// It is used to ensure that a previously saved hash state is cleared and ready for reuse.
  ///
  /// [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(SHA512State savedState) {
    zero(savedState.stateHi);
    zero(savedState.stateLo);
    if (savedState.buffer != null) {
      zero(savedState.buffer!);
    }
    savedState.bufferLength = 0;
    savedState.bytesHashed = 0;
  }

  final _k = List<int>.unmodifiable(const [
    0x428a2f98,
    0xd728ae22,
    0x71374491,
    0x23ef65cd,
    0xb5c0fbcf,
    0xec4d3b2f,
    0xe9b5dba5,
    0x8189dbbc,
    0x3956c25b,
    0xf348b538,
    0x59f111f1,
    0xb605d019,
    0x923f82a4,
    0xaf194f9b,
    0xab1c5ed5,
    0xda6d8118,
    0xd807aa98,
    0xa3030242,
    0x12835b01,
    0x45706fbe,
    0x243185be,
    0x4ee4b28c,
    0x550c7dc3,
    0xd5ffb4e2,
    0x72be5d74,
    0xf27b896f,
    0x80deb1fe,
    0x3b1696b1,
    0x9bdc06a7,
    0x25c71235,
    0xc19bf174,
    0xcf692694,
    0xe49b69c1,
    0x9ef14ad2,
    0xefbe4786,
    0x384f25e3,
    0x0fc19dc6,
    0x8b8cd5b5,
    0x240ca1cc,
    0x77ac9c65,
    0x2de92c6f,
    0x592b0275,
    0x4a7484aa,
    0x6ea6e483,
    0x5cb0a9dc,
    0xbd41fbd4,
    0x76f988da,
    0x831153b5,
    0x983e5152,
    0xee66dfab,
    0xa831c66d,
    0x2db43210,
    0xb00327c8,
    0x98fb213f,
    0xbf597fc7,
    0xbeef0ee4,
    0xc6e00bf3,
    0x3da88fc2,
    0xd5a79147,
    0x930aa725,
    0x06ca6351,
    0xe003826f,
    0x14292967,
    0x0a0e6e70,
    0x27b70a85,
    0x46d22ffc,
    0x2e1b2138,
    0x5c26c926,
    0x4d2c6dfc,
    0x5ac42aed,
    0x53380d13,
    0x9d95b3df,
    0x650a7354,
    0x8baf63de,
    0x766a0abb,
    0x3c77b2a8,
    0x81c2c92e,
    0x47edaee6,
    0x92722c85,
    0x1482353b,
    0xa2bfe8a1,
    0x4cf10364,
    0xa81a664b,
    0xbc423001,
    0xc24b8b70,
    0xd0f89791,
    0xc76c51a3,
    0x0654be30,
    0xd192e819,
    0xd6ef5218,
    0xd6990624,
    0x5565a910,
    0xf40e3585,
    0x5771202a,
    0x106aa070,
    0x32bbd1b8,
    0x19a4c116,
    0xb8d2d0c8,
    0x1e376c08,
    0x5141ab53,
    0x2748774c,
    0xdf8eeb99,
    0x34b0bcb5,
    0xe19b48a8,
    0x391c0cb3,
    0xc5c95a63,
    0x4ed8aa4a,
    0xe3418acb,
    0x5b9cca4f,
    0x7763e373,
    0x682e6ff3,
    0xd6b2b8a3,
    0x748f82ee,
    0x5defb2fc,
    0x78a5636f,
    0x43172f60,
    0x84c87814,
    0xa1f0ab72,
    0x8cc70208,
    0x1a6439ec,
    0x90befffa,
    0x23631e28,
    0xa4506ceb,
    0xde82bde9,
    0xbef9a3f7,
    0xb2c67915,
    0xc67178f2,
    0xe372532b,
    0xca273ece,
    0xea26619c,
    0xd186b8c7,
    0x21c0c207,
    0xeada7dd6,
    0xcde0eb1e,
    0xf57d4f7f,
    0xee6ed178,
    0x06f067aa,
    0x72176fba,
    0x0a637dc5,
    0xa2c898a6,
    0x113f9804,
    0xbef90dae,
    0x1b710b35,
    0x131c471b,
    0x28db77f5,
    0x23047d84,
    0x32caab7b,
    0x40c72493,
    0x3c9ebe0a,
    0x15c9bebc,
    0x431d67c4,
    0x9c100d4c,
    0x4cc5d4be,
    0xcb3e42b6,
    0x597f299c,
    0xfc657e2a,
    0x5fcb6fab,
    0x3ad6faec,
    0x6c44198c,
    0x4a475817
  ]);

  int _sigma1A(int ah4, int al4) {
    ah4 &= mask32;
    al4 &= mask32;
    int one1 = (ah4 >> 14);
    int one2 = al4 << (32 - 14);
    int one = (one1 | one2);

    int two1 = ((ah4) >> 18);
    int two2 = (al4 << (32 - 18));
    int two = (two1 | two2);
    int three1 = (al4 >> 9);
    int three2 = (ah4 << 23);
    int three = (three1 | three2);
    int h = one ^ two ^ three;
    return h;
  }

  int _sigma1B(int ah0, int al0) {
    al0 &= mask32;
    ah0 &= mask32;
    int one1 = (ah0 >> 28) & mask32;
    int one2 = al0 << (32 - 28) & mask32;
    int one = (one1 | one2);
    int two1 = (al0 >> 2);
    int two2 = (ah0 << (32 - (34 - 32))) & mask32;
    int two = (two1 | two2);
    int three1 = (al0 >> 7);
    int three2 = (ah0 << (32 - (39 - 32))) & mask32;
    int three = (three1 | three2);
    int h = one ^ two ^ three;
    return h;
  }

  int _sigma0A(int th, int tl) {
    th &= mask32;
    tl &= mask32;
    int one = ((th >> 1) | (tl << (32 - 1))) & mask32;
    int two = ((th >> 8) | (tl << (32 - 8))) & mask32;
    int three = (th >> 7);
    int h = one ^ two ^ three;
    return h;
  }

  int _sigma0B(int th, int tl) {
    th &= mask32;
    tl &= mask32;
    int one = ((tl >> 1) | (th << (32 - 1))) & mask32;
    int two = ((tl >> 8) | (th << (32 - 8))) & mask32;
    int three = ((tl >> 7) | (th << (32 - 7))) & mask32;
    int h = one ^ two ^ three;
    return h;
  }

  int _sigma0C(int th, int tl) {
    th &= mask32;
    tl &= mask32;
    int one = ((th >> 19) | (tl << (32 - 19))) & mask32;
    int two = ((tl >> (61 - 32)) | (th << (32 - (61 - 32)))) & mask32;
    int three = (th >> 6) & mask32;
    int h = one ^ two ^ three;
    return h;
  }

  int _sigma0D(int th, int tl) {
    th &= mask32;
    tl &= mask32;
    int one = ((tl >> 19) | (th << (32 - 19))) & mask32;
    int two = ((th >> (61 - 32)) | (tl << (32 - (61 - 32)))) & mask32;
    int three = ((tl >> 6) | (th << (32 - 6))) & mask32;
    int h = one ^ two ^ three;
    return h;
  }

  int _hashBlocks(List<int> wh, List<int> wl, List<int> hh, List<int> hl,
      List<int> m, int pos, int len) {
    int ah0 = hh[0];
    int ah1 = hh[1];
    int ah2 = hh[2];
    int ah3 = hh[3];
    int ah4 = hh[4];
    int ah5 = hh[5];
    int ah6 = hh[6];
    int ah7 = hh[7];

    int al0 = hl[0];
    int al1 = hl[1];
    int al2 = hl[2];
    int al3 = hl[3];
    int al4 = hl[4];
    int al5 = hl[5];
    int al6 = hl[6];
    int al7 = hl[7];

    int h, l;
    int th, tl;
    int a, b, c, d;

    while (len >= 128) {
      for (int i = 0; i < 16; i++) {
        int j = 8 * i + pos;
        wh[i] = readUint32BE(m, j);
        wl[i] = readUint32BE(m, j + 4);
      }

      for (int i = 0; i < 80; i++) {
        int bh0 = ah0;
        int bh1 = ah1;
        int bh2 = ah2;
        int bh3 = ah3;
        int bh4 = ah4;
        int bh5 = ah5;
        int bh6 = ah6;
        int bh7 = ah7;

        int bl0 = al0;
        int bl1 = al1;
        int bl2 = al2;
        int bl3 = al3;
        int bl4 = al4;
        int bl5 = al5;
        int bl6 = al6;
        int bl7 = al7;

        // add
        h = ah7;
        l = al7;

        a = l & mask16;
        b = shr16(l);
        c = h & mask16;
        d = shr16(h);

        h = _sigma1A(ah4, al4);
        l = _sigma1A(al4, ah4);

        a += l & mask16;
        b += shr16(l);
        c += h & mask16;
        d += shr16(h);

        h = ((ah4 & ah5) ^ (~ah4 & ah6)) & mask32;
        l = ((al4 & al5) ^ (~al4 & al6)) & mask32;

        a += l & mask16;
        b += shr16(l);
        c += h & mask16;
        d += shr16(h);

        // K
        h = _k[i * 2];
        l = _k[i * 2 + 1];

        a += l & mask16;
        b += shr16(l);

        c += h & mask16;
        d += shr16(h);

        // w
        h = wh[i % 16];
        l = wl[i % 16];

        a += l & mask16;
        b += shr16(l);
        c += h & mask16;
        d += shr16(h);

        b += shr16(a);
        c += shr16(b);
        d += shr16(c);

        th = ((c & mask16) | (d << 16)) & mask32;
        tl = ((a & mask16) | (b << 16)) & mask32;

        // add
        h = th;
        l = tl;

        a = l & mask16;
        b = shr16(l);
        c = h & mask16;
        d = shr16(h);

        // Sigma0
        h = _sigma1B(ah0, al0);
        l = _sigma1B(al0, ah0);

        a += l & mask16;
        b += shr16(l);
        c += h & mask16;
        d += shr16(h);
        // Maj
        h = ((ah0 & ah1) ^ (ah0 & ah2) ^ (ah1 & ah2)) & mask32;
        l = ((al0 & al1) ^ (al0 & al2) ^ (al1 & al2)) & mask32;

        a += l & mask16;
        b += shr16(l);
        c += h & mask16;
        d += shr16(h);

        b += shr16(a);
        c += shr16(b);
        d += shr16(c);

        bh7 = ((c & mask16) | (d << 16)) & mask32;

        bl7 = ((a & mask16) | (b << 16)) & mask32;

        // add
        h = bh3;
        l = bl3;

        a = l & mask16;
        b = shr16(l);
        c = h & mask16;
        d = shr16(h);

        h = th;
        l = tl;

        a += l & mask16;
        b += shr16(l);
        c += h & mask16;
        d += shr16(h);

        b += shr16(a);
        c += shr16(b);
        d += shr16(c);

        bh3 = ((c & mask16) | (d << 16)) & mask32;
        bl3 = ((a & mask16) | (b << 16)) & mask32;
        ah1 = bh0;
        ah2 = bh1;
        ah3 = bh2;
        ah4 = bh3;
        ah5 = bh4;
        ah6 = bh5;
        ah7 = bh6;
        ah0 = bh7;

        al1 = bl0;
        al2 = bl1;
        al3 = bl2;
        al4 = bl3;
        al5 = bl4;
        al6 = bl5;
        al7 = bl6;
        al0 = bl7;

        if (i % 16 == 15) {
          for (int j = 0; j < 16; j++) {
            // add
            h = wh[j];
            l = wl[j];

            a = l & mask16;
            b = shr16(l);
            c = h & mask16;
            d = shr16(h);

            h = wh[(j + 9) % 16];
            l = wl[(j + 9) % 16];

            a += l & mask16;
            b += shr16(l);
            c += h & mask16;
            d += shr16(h);

            // sigma0
            th = wh[(j + 1) % 16];
            tl = wl[(j + 1) % 16];
            h = _sigma0A(th, tl);
            l = _sigma0B(th, tl);

            a += l & mask16;
            b += shr16(l);
            c += h & mask16;
            d += shr16(h);

            // sigma1
            th = wh[(j + 14) % 16];
            tl = wl[(j + 14) % 16];
            h = _sigma0C(th, tl);
            l = _sigma0D(th, tl);
            a += l & mask16;
            b += shr16(l);
            c += h & mask16;
            d += shr16(h);

            b += shr16(a);
            c += shr16(b);
            d += shr16(c);

            wh[j] = ((c & mask16) | (d << 16)) & mask32;
            wl[j] = ((a & mask16) | (b << 16)) & mask32;
          }
        }
      }

      // add
      h = ah0;
      l = al0;

      a = l & mask16;
      b = shr16(l);
      c = h & mask16;
      d = shr16(h);

      h = hh[0];
      l = hl[0];
      a += l & mask16;
      b += shr16(l);
      c += h & mask16;
      d += shr16(h);

      b += shr16(a);
      c += shr16(b);
      d += shr16(c);

      hh[0] = ah0 = ((c & mask16) | (d << 16)) & mask32;
      hl[0] = al0 = ((a & mask16) | (b << 16)) & mask32;

      h = ah1;
      l = al1;

      a = l & mask16;
      b = shr16(l);
      c = h & mask16;
      d = shr16(h);

      h = hh[1];
      l = hl[1];

      a += l & mask16;
      b += shr16(l);

      c += h & mask16;
      d += shr16(h);

      b += shr16(a);
      c += shr16(b);
      d += shr16(c);

      hh[1] = ah1 = ((c & mask16) | (d << 16)) & mask32;
      hl[1] = al1 = ((a & mask16) | (b << 16)) & mask32;
      h = ah2;
      l = al2;

      a = l & mask16;
      b = shr16(l);
      c = h & mask16;
      d = shr16(h);

      h = hh[2];
      l = hl[2];

      a += l & mask16;
      b += shr16(l);
      c += h & mask16;
      d += shr16(h);

      b += shr16(a);
      c += shr16(b);
      d += shr16(c);

      hh[2] = ah2 = ((c & mask16) | (d << 16)) & mask32;
      hl[2] = al2 = ((a & mask16) | (b << 16)) & mask32;

      h = ah3;
      l = al3;

      a = l & mask16;
      b = shr16(l);

      c = h & mask16;
      d = shr16(h);

      h = hh[3];
      l = hl[3];

      a += l & mask16;
      b += shr16(l);
      c += h & mask16;
      d += shr16(h);

      b += shr16(a);
      c += shr16(b);
      d += shr16(c);

      hh[3] = ah3 = ((c & mask16) | (d << 16)) & mask32;
      hl[3] = al3 = ((a & mask16) | (b << 16)) & mask32;

      h = ah4;
      l = al4;

      a = l & mask16;
      b = shr16(l);
      c = h & mask16;
      d = shr16(h);

      h = hh[4];
      l = hl[4];

      a += l & mask16;
      b += shr16(l);
      c += h & mask16;
      d += shr16(h);

      b += shr16(a);
      c += shr16(b);
      d += shr16(c);

      hh[4] = ah4 = ((c & mask16) | (d << 16)) & mask32;
      hl[4] = al4 = ((a & mask16) | (b << 16)) & mask32;

      h = ah5;
      l = al5;

      a = l & mask16;
      b = shr16(l);
      c = h & mask16;
      d = shr16(h);

      h = hh[5];
      l = hl[5];

      a += l & mask16;
      b += shr16(l);
      c += h & mask16;
      d += shr16(h);

      b += shr16(a);
      c += shr16(b);
      d += shr16(c);

      hh[5] = ah5 = ((c & mask16) | (d << 16)) & mask32;
      hl[5] = al5 = ((a & mask16) | (b << 16)) & mask32;
      h = ah6;
      l = al6;

      a = l & mask16;
      b = shr16(l);
      c = h & mask16;
      d = shr16(h);

      h = hh[6];
      l = hl[6];

      a += l & mask16;
      b += shr16(l);
      c += h & mask16;
      d += shr16(h);

      b += shr16(a);
      c += shr16(b);
      d += shr16(c);

      hh[6] = ah6 = ((c & mask16) | (d << 16)) & mask32;
      hl[6] = al6 = ((a & mask16) | (b << 16)) & mask32;
      h = ah7;
      l = al7;

      a = l & mask16;
      b = shr16(l);
      c = h & mask16;
      d = shr16(h);

      h = hh[7];
      l = hl[7];

      a += l & mask16;
      b += shr16(l);
      c += h & mask16;
      d += shr16(h);

      b += shr16(a);
      c += shr16(b);
      d += shr16(c);

      hh[7] = ah7 = ((c & mask16) | (d << 16)) & mask32;
      hl[7] = al7 = ((a & mask16) | (b << 16)) & mask32;
      pos += 128;
      len -= 128;
    }

    return pos;
  }

  /// Computes the SHA-512 hash of the provided data.
  static List<int> hash(List<int> data) {
    final h = SHA512();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}

/// The `SHA512State` class represents the state of a SHA-512 hash calculation.
///
/// This class is used to store the state of a SHA-512 hash, including the
/// high and low parts of the hash state, the current buffer, the buffer's
/// length, and the total number of bytes hashed.
///
/// Example usage:
/// ```dart
/// final state = SHA512State(
///   stateHi: Int32List(8),
///   stateLo: Int32List(8),
///   buffer:List<int>.filled(SHA512.blockSize),
///   bufferLength: 0,
///   bytesHashed: 0,
/// );
/// ```
///
/// It's typically used to save the state of a hash calculation to allow for
/// incremental hashing. This can be especially useful when hashing large
/// data in smaller chunks or when saving the intermediate state for further
/// updates.
class SHA512State implements HashState {
  final List<int> stateHi;
  final List<int> stateLo;
  final List<int>? buffer;
  int bufferLength;
  int bytesHashed;

  SHA512State({
    required this.stateHi,
    required this.stateLo,
    this.buffer,
    required this.bufferLength,
    required this.bytesHashed,
  });
}
