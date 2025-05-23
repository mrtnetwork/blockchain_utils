import 'package:blockchain_utils/utils/utils.dart';

class AESLib {
  AESLib._() {
    initialize();
  }
  factory AESLib() {
    return _aes;
  }
  static final _aes = AESLib._();

  static const _powx = [
    0x01,
    0x02,
    0x04,
    0x08,
    0x10,
    0x20,
    0x40,
    0x80,
    0x1b,
    0x36,
    0x6c,
    0xd8,
    0xab,
    0x4d,
    0x9a,
    0x2f
  ];

  /// FIPS-197 Figure 7. S-box substitution values in hexadecimal format.
  static const _sbox0 = [
    0x63,
    0x7c,
    0x77,
    0x7b,
    0xf2,
    0x6b,
    0x6f,
    0xc5,
    0x30,
    0x01,
    0x67,
    0x2b,
    0xfe,
    0xd7,
    0xab,
    0x76,
    0xca,
    0x82,
    0xc9,
    0x7d,
    0xfa,
    0x59,
    0x47,
    0xf0,
    0xad,
    0xd4,
    0xa2,
    0xaf,
    0x9c,
    0xa4,
    0x72,
    0xc0,
    0xb7,
    0xfd,
    0x93,
    0x26,
    0x36,
    0x3f,
    0xf7,
    0xcc,
    0x34,
    0xa5,
    0xe5,
    0xf1,
    0x71,
    0xd8,
    0x31,
    0x15,
    0x04,
    0xc7,
    0x23,
    0xc3,
    0x18,
    0x96,
    0x05,
    0x9a,
    0x07,
    0x12,
    0x80,
    0xe2,
    0xeb,
    0x27,
    0xb2,
    0x75,
    0x09,
    0x83,
    0x2c,
    0x1a,
    0x1b,
    0x6e,
    0x5a,
    0xa0,
    0x52,
    0x3b,
    0xd6,
    0xb3,
    0x29,
    0xe3,
    0x2f,
    0x84,
    0x53,
    0xd1,
    0x00,
    0xed,
    0x20,
    0xfc,
    0xb1,
    0x5b,
    0x6a,
    0xcb,
    0xbe,
    0x39,
    0x4a,
    0x4c,
    0x58,
    0xcf,
    0xd0,
    0xef,
    0xaa,
    0xfb,
    0x43,
    0x4d,
    0x33,
    0x85,
    0x45,
    0xf9,
    0x02,
    0x7f,
    0x50,
    0x3c,
    0x9f,
    0xa8,
    0x51,
    0xa3,
    0x40,
    0x8f,
    0x92,
    0x9d,
    0x38,
    0xf5,
    0xbc,
    0xb6,
    0xda,
    0x21,
    0x10,
    mask8,
    0xf3,
    0xd2,
    0xcd,
    0x0c,
    0x13,
    0xec,
    0x5f,
    0x97,
    0x44,
    0x17,
    0xc4,
    0xa7,
    0x7e,
    0x3d,
    0x64,
    0x5d,
    0x19,
    0x73,
    0x60,
    0x81,
    0x4f,
    0xdc,
    0x22,
    0x2a,
    0x90,
    0x88,
    0x46,
    0xee,
    0xb8,
    0x14,
    0xde,
    0x5e,
    0x0b,
    0xdb,
    0xe0,
    0x32,
    0x3a,
    0x0a,
    0x49,
    0x06,
    0x24,
    0x5c,
    0xc2,
    0xd3,
    0xac,
    0x62,
    0x91,
    0x95,
    0xe4,
    0x79,
    0xe7,
    0xc8,
    0x37,
    0x6d,
    0x8d,
    0xd5,
    0x4e,
    0xa9,
    0x6c,
    0x56,
    0xf4,
    0xea,
    0x65,
    0x7a,
    0xae,
    0x08,
    0xba,
    0x78,
    0x25,
    0x2e,
    0x1c,
    0xa6,
    0xb4,
    0xc6,
    0xe8,
    0xdd,
    0x74,
    0x1f,
    0x4b,
    0xbd,
    0x8b,
    0x8a,
    0x70,
    0x3e,
    0xb5,
    0x66,
    0x48,
    0x03,
    0xf6,
    0x0e,
    0x61,
    0x35,
    0x57,
    0xb9,
    0x86,
    0xc1,
    0x1d,
    0x9e,
    0xe1,
    0xf8,
    0x98,
    0x11,
    0x69,
    0xd9,
    0x8e,
    0x94,
    0x9b,
    0x1e,
    0x87,
    0xe9,
    0xce,
    0x55,
    0x28,
    0xdf,
    0x8c,
    0xa1,
    0x89,
    0x0d,
    0xbf,
    0xe6,
    0x42,
    0x68,
    0x41,
    0x99,
    0x2d,
    0x0f,
    0xb0,
    0x54,
    0xbb,
    0x16
  ];

  /// FIPS-197 Figure 14.  Inverse S-box substitution values in hexadecimal format.
  static const _sbox1 = [
    0x52,
    0x09,
    0x6a,
    0xd5,
    0x30,
    0x36,
    0xa5,
    0x38,
    0xbf,
    0x40,
    0xa3,
    0x9e,
    0x81,
    0xf3,
    0xd7,
    0xfb,
    0x7c,
    0xe3,
    0x39,
    0x82,
    0x9b,
    0x2f,
    mask8,
    0x87,
    0x34,
    0x8e,
    0x43,
    0x44,
    0xc4,
    0xde,
    0xe9,
    0xcb,
    0x54,
    0x7b,
    0x94,
    0x32,
    0xa6,
    0xc2,
    0x23,
    0x3d,
    0xee,
    0x4c,
    0x95,
    0x0b,
    0x42,
    0xfa,
    0xc3,
    0x4e,
    0x08,
    0x2e,
    0xa1,
    0x66,
    0x28,
    0xd9,
    0x24,
    0xb2,
    0x76,
    0x5b,
    0xa2,
    0x49,
    0x6d,
    0x8b,
    0xd1,
    0x25,
    0x72,
    0xf8,
    0xf6,
    0x64,
    0x86,
    0x68,
    0x98,
    0x16,
    0xd4,
    0xa4,
    0x5c,
    0xcc,
    0x5d,
    0x65,
    0xb6,
    0x92,
    0x6c,
    0x70,
    0x48,
    0x50,
    0xfd,
    0xed,
    0xb9,
    0xda,
    0x5e,
    0x15,
    0x46,
    0x57,
    0xa7,
    0x8d,
    0x9d,
    0x84,
    0x90,
    0xd8,
    0xab,
    0x00,
    0x8c,
    0xbc,
    0xd3,
    0x0a,
    0xf7,
    0xe4,
    0x58,
    0x05,
    0xb8,
    0xb3,
    0x45,
    0x06,
    0xd0,
    0x2c,
    0x1e,
    0x8f,
    0xca,
    0x3f,
    0x0f,
    0x02,
    0xc1,
    0xaf,
    0xbd,
    0x03,
    0x01,
    0x13,
    0x8a,
    0x6b,
    0x3a,
    0x91,
    0x11,
    0x41,
    0x4f,
    0x67,
    0xdc,
    0xea,
    0x97,
    0xf2,
    0xcf,
    0xce,
    0xf0,
    0xb4,
    0xe6,
    0x73,
    0x96,
    0xac,
    0x74,
    0x22,
    0xe7,
    0xad,
    0x35,
    0x85,
    0xe2,
    0xf9,
    0x37,
    0xe8,
    0x1c,
    0x75,
    0xdf,
    0x6e,
    0x47,
    0xf1,
    0x1a,
    0x71,
    0x1d,
    0x29,
    0xc5,
    0x89,
    0x6f,
    0xb7,
    0x62,
    0x0e,
    0xaa,
    0x18,
    0xbe,
    0x1b,
    0xfc,
    0x56,
    0x3e,
    0x4b,
    0xc6,
    0xd2,
    0x79,
    0x20,
    0x9a,
    0xdb,
    0xc0,
    0xfe,
    0x78,
    0xcd,
    0x5a,
    0xf4,
    0x1f,
    0xdd,
    0xa8,
    0x33,
    0x88,
    0x07,
    0xc7,
    0x31,
    0xb1,
    0x12,
    0x10,
    0x59,
    0x27,
    0x80,
    0xec,
    0x5f,
    0x60,
    0x51,
    0x7f,
    0xa9,
    0x19,
    0xb5,
    0x4a,
    0x0d,
    0x2d,
    0xe5,
    0x7a,
    0x9f,
    0x93,
    0xc9,
    0x9c,
    0xef,
    0xa0,
    0xe0,
    0x3b,
    0x4d,
    0xae,
    0x2a,
    0xf5,
    0xb0,
    0xc8,
    0xeb,
    0xbb,
    0x3c,
    0x83,
    0x53,
    0x99,
    0x61,
    0x17,
    0x2b,
    0x04,
    0x7e,
    0xba,
    0x77,
    0xd6,
    0x26,
    0xe1,
    0x69,
    0x14,
    0x63,
    0x55,
    0x21,
    0x0c,
    0x7d
  ];

  final List<int> _te0 = List<int>.filled(256, 0),
      _te1 = List<int>.filled(256, 0),
      _te2 = List<int>.filled(256, 0),
      _te3 = List<int>.filled(256, 0);
  final List<int> _td0 = List<int>.filled(256, 0),
      _td1 = List<int>.filled(256, 0),
      _td2 = List<int>.filled(256, 0),
      _td3 = List<int>.filled(256, 0);

  void initialize() {
    const poly = (1 << 8) | (1 << 4) | (1 << 3) | (1 << 1) | (1 << 0);

    int mul(int b, int c) {
      int i = b;
      int j = c;
      int s = 0;
      for (int k = 1; k < 0x100 && j != 0; k <<= 1) {
        if ((j & k) != 0) {
          s ^= i;
          j ^= k;
        }
        i <<= 1;
        if ((i & 0x100) != 0) {
          i ^= poly;
        }
      }
      return s;
    }

    r24(int x) => rotl32(x, 24);
    for (int i = 0; i < 256; i++) {
      final s = _sbox0[i];
      int w = ((mul(s, 2) << 24) | (s << 16) | (s << 8) | mul(s, 3)) & mask32;
      _te0[i] = w;
      w = r24(w);
      _te1[i] = w;
      w = r24(w);
      _te2[i] = w;
      w = r24(w);
      _te3[i] = w;
      w = r24(w);
    }

    for (int i = 0; i < 256; i++) {
      final s = _sbox1[i];
      int w = (mul(s, 0xe) << 24) |
          (mul(s, 0x9) << 16) |
          (mul(s, 0xd) << 8) |
          mul(s, 0xb);
      _td0[i] = w;
      w = r24(w);
      _td1[i] = w;
      w = r24(w);
      _td2[i] = w;
      w = r24(w);
      _td3[i] = w;
      w = r24(w);
    }
  }

  int _subw(int w) {
    return ((_sbox0[(w >> 24) & mask8]) << 24) |
        ((_sbox0[(w >> 16) & mask8]) << 16) |
        ((_sbox0[(w >> 8) & mask8]) << 8) |
        (_sbox0[w & mask8]);
  }

  int _rotw(int w) {
    return (w << 8) | (w >> 24);
  }

  void expandKey(List<int> key, List<int> encKey, [List<int>? decKey]) {
    final nk = key.length ~/ 4;
    final n = encKey.length;

    for (int i = 0; i < nk; i++) {
      encKey[i] = readUint32BE(key, i * 4);
    }

    for (int i = nk; i < n; i++) {
      int t = encKey[i - 1];
      if (i % nk == 0) {
        t = _subw(_rotw(t)) ^ (_powx[i ~/ nk - 1] << 24);
      } else if (nk > 6 && i % nk == 4) {
        t = _subw(t);
      }
      encKey[i] = encKey[i - nk] ^ t;
    }

    if (decKey != null) {
      // Derive decryption key from encryption key.
      // Reverse the 4-word round key sets from enc to produce dec.
      // All sets but the first and last get the MixColumn transform applied.
      for (int i = 0; i < n; i += 4) {
        final ei = n - i - 4;
        for (int j = 0; j < 4; j++) {
          int x = encKey[ei + j];
          if (i > 0 && i + 4 < n) {
            x = _td0[_sbox0[(x >> 24) & mask8]] ^
                _td1[_sbox0[(x >> 16) & mask8]] ^
                _td2[_sbox0[(x >> 8) & mask8]] ^
                _td3[_sbox0[x & mask8]];
          }
          decKey[i + j] = x;
        }
      }
    }
  }

  void encryptBlock(List<int> xk, List<int> src, List<int> dst) {
    int s0 = readUint32BE(src, 0);
    int s1 = readUint32BE(src, 4);
    int s2 = readUint32BE(src, 8);
    int s3 = readUint32BE(src, 12);

    // First round just XORs input with key.
    s0 ^= xk[0];
    s1 ^= xk[1];
    s2 ^= xk[2];
    s3 ^= xk[3];

    int t0 = 0, t1 = 0, t2 = 0, t3 = 0;

    /// Middle rounds shuffle using tables.
    /// Number of rounds is set by the length of the expanded key.
    final nr = xk.length ~/ 4 - 2; // - 2: one above, one more below
    int k = 4;

    for (int r = 0; r < nr; r++) {
      t0 = xk[k + 0] ^
          _te0[(s0 >> 24) & mask8] ^
          _te1[(s1 >> 16) & mask8] ^
          _te2[(s2 >> 8) & mask8] ^
          _te3[s3 & mask8];

      t1 = xk[k + 1] ^
          _te0[(s1 >> 24) & mask8] ^
          _te1[(s2 >> 16) & mask8] ^
          _te2[(s3 >> 8) & mask8] ^
          _te3[s0 & mask8];

      t2 = xk[k + 2] ^
          _te0[(s2 >> 24) & mask8] ^
          _te1[(s3 >> 16) & mask8] ^
          _te2[(s0 >> 8) & mask8] ^
          _te3[s1 & mask8];

      t3 = xk[k + 3] ^
          _te0[(s3 >> 24) & mask8] ^
          _te1[(s0 >> 16) & mask8] ^
          _te2[(s1 >> 8) & mask8] ^
          _te3[s2 & mask8];

      k += 4;
      s0 = t0;
      s1 = t1;
      s2 = t2;
      s3 = t3;
    }

    /// Last round uses s-box directly and XORs to produce output.
    s0 = (_sbox0[t0 >> 24] << 24) |
        (_sbox0[(t1 >> 16) & mask8]) << 16 |
        (_sbox0[(t2 >> 8) & mask8]) << 8 |
        (_sbox0[t3 & mask8]);

    s1 = (_sbox0[t1 >> 24] << 24) |
        (_sbox0[(t2 >> 16) & mask8]) << 16 |
        (_sbox0[(t3 >> 8) & mask8]) << 8 |
        (_sbox0[t0 & mask8]);

    s2 = (_sbox0[t2 >> 24] << 24) |
        (_sbox0[(t3 >> 16) & mask8]) << 16 |
        (_sbox0[(t0 >> 8) & mask8]) << 8 |
        (_sbox0[t1 & mask8]);

    s3 = (_sbox0[t3 >> 24] << 24) |
        (_sbox0[(t0 >> 16) & mask8]) << 16 |
        (_sbox0[(t1 >> 8) & mask8]) << 8 |
        (_sbox0[t2 & mask8]);

    s0 ^= xk[k + 0];
    s1 ^= xk[k + 1];
    s2 ^= xk[k + 2];
    s3 ^= xk[k + 3];

    writeUint32BE(s0, dst, 0);
    writeUint32BE(s1, dst, 4);
    writeUint32BE(s2, dst, 8);
    writeUint32BE(s3, dst, 12);
  }

  void decryptBlock(List<int> xk, List<int> src, List<int> dst) {
    int s0 = readUint32BE(src, 0);
    int s1 = readUint32BE(src, 4);
    int s2 = readUint32BE(src, 8);
    int s3 = readUint32BE(src, 12);

    /// First round just XORs input with key.
    s0 ^= xk[0];
    s1 ^= xk[1];
    s2 ^= xk[2];
    s3 ^= xk[3];

    int t0 = 0, t1 = 0, t2 = 0, t3 = 0;

    /// Middle rounds shuffle using tables.
    /// Number of rounds is set by the length of the expanded key.
    final nr = xk.length ~/ 4 - 2; // - 2: one above, one more below
    int k = 4;

    for (int r = 0; r < nr; r++) {
      t0 = xk[k + 0] ^
          _td0[(s0 >> 24) & mask8] ^
          _td1[(s3 >> 16) & mask8] ^
          _td2[(s2 >> 8) & mask8] ^
          _td3[s1 & mask8];

      t1 = xk[k + 1] ^
          _td0[(s1 >> 24) & mask8] ^
          _td1[(s0 >> 16) & mask8] ^
          _td2[(s3 >> 8) & mask8] ^
          _td3[s2 & mask8];

      t2 = xk[k + 2] ^
          _td0[(s2 >> 24) & mask8] ^
          _td1[(s1 >> 16) & mask8] ^
          _td2[(s0 >> 8) & mask8] ^
          _td3[s3 & mask8];

      t3 = xk[k + 3] ^
          _td0[(s3 >> 24) & mask8] ^
          _td1[(s2 >> 16) & mask8] ^
          _td2[(s1 >> 8) & mask8] ^
          _td3[s0 & mask8];

      k += 4;
      s0 = t0;
      s1 = t1;
      s2 = t2;
      s3 = t3;
    }

    /// Last round uses s-box directly and XORs to produce output.
    s0 = (_sbox1[t0 >> 24] << 24) |
        (_sbox1[(t3 >> 16) & mask8]) << 16 |
        (_sbox1[(t2 >> 8) & mask8]) << 8 |
        (_sbox1[t1 & mask8]);

    s1 = (_sbox1[t1 >> 24] << 24) |
        (_sbox1[(t0 >> 16) & mask8]) << 16 |
        (_sbox1[(t3 >> 8) & mask8]) << 8 |
        (_sbox1[t2 & mask8]);

    s2 = (_sbox1[t2 >> 24] << 24) |
        (_sbox1[(t1 >> 16) & mask8]) << 16 |
        (_sbox1[(t0 >> 8) & mask8]) << 8 |
        (_sbox1[t3 & mask8]);

    s3 = (_sbox1[t3 >> 24] << 24) |
        (_sbox1[(t2 >> 16) & mask8]) << 16 |
        (_sbox1[(t1 >> 8) & mask8]) << 8 |
        (_sbox1[t0 & mask8]);

    s0 ^= xk[k + 0];
    s1 ^= xk[k + 1];
    s2 ^= xk[k + 2];
    s3 ^= xk[k + 3];

    writeUint32BE(s0, dst, 0);
    writeUint32BE(s1, dst, 4);
    writeUint32BE(s2, dst, 8);
    writeUint32BE(s3, dst, 12);
  }
}
