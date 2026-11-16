part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// The Keccak-f[1600] permutation.
class _Keccak {
  /// temporary space for permutation (high bits)
  final List<int> _sh = List<int>.filled(25, 0);

  /// temporary space for permutation (low bits)
  final List<int> _sl = List<int>.filled(25, 0);

  /// hash state
  final List<int> _state = List<int>.filled(200, 0);

  /// position in state to XOR bytes into
  int _pos = 0;

  /// whether the hash was finalized
  bool _finished = false;

  bool _cleaned = false;

  /// block size
  late int _blockSize;
  int get blockSize => _blockSize;
  _Keccak([int capacity = 32]) {
    if (capacity <= 0 || capacity > 128) {
      throw CoreErrors.invalidOperationArguments(
        "Keccak",
        name: "capacity",
        reason: "Incorrect capacity.",
      );
    }

    _blockSize = 200 - capacity;
  }

  /// Resets the hash computation to its initial state.
  ///
  /// This method initializes the hash computation to its initial state, clearing any previously
  /// processed data. After calling this method, you can start a new hash computation.
  ///
  /// Returns the current instance of the hash algorithm with the initial stat
  _Keccak reset() {
    _ensureAlive("reset", _cleaned, null);
    BinaryOps.zero(_sh);
    BinaryOps.zero(_sl);
    BinaryOps.zero(_state);
    _pos = 0;
    _finished = false;
    return this;
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
  _Keccak update(List<int> data) {
    _ensureAlive("update", _cleaned, _finished);
    for (var i = 0; i < data.length; i++) {
      _state[_pos++] ^= data[i] & BinaryOps.mask8;

      if (_pos >= blockSize) {
        _keccakf(_sh, _sl, _state);
        _pos = 0;
      }
    }

    return this;
  }

  /// Clean up the internal state and reset hash object to its initial state.
  void clean() {
    if (!_cleaned) {
      reset();
      _cleaned = true;
    }
  }

  void _padAndPermute(int? paddingByte) {
    if (paddingByte != null) {
      _state[_pos] ^= paddingByte;
      _state[blockSize - 1] ^= 0x80;
    }

    // Permute state.
    _keccakf(_sh, _sl, _state);

    // Set finished flag to true.
    _finished = true;
    _pos = 0;
  }

  void _squeeze(List<int> dst) {
    for (var i = 0; i < dst.length; i++) {
      if (_pos == blockSize) {
        _keccakf(_sh, _sl, _state);
        _pos = 0;
      }
      dst[i] = _state[_pos++];
    }
  }

  static const _hi = [
    0x00000000,
    0x00000000,
    0x80000000,
    0x80000000,
    0x00000000,
    0x00000000,
    0x80000000,
    0x80000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x00000000,
    0x80000000,
    0x80000000,
    0x80000000,
    0x80000000,
    0x80000000,
    0x00000000,
    0x80000000,
    0x80000000,
    0x80000000,
    0x00000000,
    0x80000000,
  ];

  static const _lo = [
    0x00000001,
    0x00008082,
    0x0000808a,
    0x80008000,
    0x0000808b,
    0x80000001,
    0x80008081,
    0x00008009,
    0x0000008a,
    0x00000088,
    0x80008009,
    0x8000000a,
    0x8000808b,
    0x0000008b,
    0x00008089,
    0x00008003,
    0x00008002,
    0x00000080,
    0x0000800a,
    0x8000000a,
    0x80008081,
    0x00008080,
    0x80000001,
    0x80008008,
  ];
  static void _keccakf(List<int> sh, List<int> sl, List<int> buf) {
    int bch0, bch1, bch2, bch3, bch4;
    int bcl0, bcl1, bcl2, bcl3, bcl4;
    int th, tl;

    for (int i = 0; i < 25; i++) {
      sl[i] = BinaryOps.readUint32LE(buf, i * 8);
      sh[i] = BinaryOps.readUint32LE(buf, i * 8 + 4);
    }
    for (int r = 0; r < 24; r++) {
      // Theta
      bch0 = sh[0] ^ sh[5] ^ sh[10] ^ sh[15] ^ sh[20];
      bch1 = sh[1] ^ sh[6] ^ sh[11] ^ sh[16] ^ sh[21];
      bch2 = sh[2] ^ sh[7] ^ sh[12] ^ sh[17] ^ sh[22];
      bch3 = sh[3] ^ sh[8] ^ sh[13] ^ sh[18] ^ sh[23];
      bch4 = sh[4] ^ sh[9] ^ sh[14] ^ sh[19] ^ sh[24];
      bcl0 = sl[0] ^ sl[5] ^ sl[10] ^ sl[15] ^ sl[20];
      bcl1 = sl[1] ^ sl[6] ^ sl[11] ^ sl[16] ^ sl[21];
      bcl2 = sl[2] ^ sl[7] ^ sl[12] ^ sl[17] ^ sl[22];
      bcl3 = sl[3] ^ sl[8] ^ sl[13] ^ sl[18] ^ sl[23];
      bcl4 = sl[4] ^ sl[9] ^ sl[14] ^ sl[19] ^ sl[24];
      th = bch4 ^ ((bch1 << 1) | (bcl1 & BinaryOps.mask32) >> (32 - 1));
      tl = bcl4 ^ ((bcl1 << 1) | (bch1 & BinaryOps.mask32) >> (32 - 1));

      sh[0] ^= th;
      sh[5] ^= th;
      sh[10] ^= th;
      sh[15] ^= th;
      sh[20] ^= th;
      sl[0] ^= tl;
      sl[5] ^= tl;
      sl[10] ^= tl;
      sl[15] ^= tl;
      sl[20] ^= tl;
      th = bch0 ^ ((bch2 << 1) | (bcl2 & BinaryOps.mask32) >> (32 - 1));
      tl = bcl0 ^ ((bcl2 << 1) | (bch2 & BinaryOps.mask32) >> (32 - 1));

      sh[1] ^= th;
      sh[6] ^= th;
      sh[11] ^= th;
      sh[16] ^= th;
      sh[21] ^= th;
      sl[1] ^= tl;
      sl[6] ^= tl;
      sl[11] ^= tl;
      sl[16] ^= tl;
      sl[21] ^= tl;
      th = bch1 ^ ((bch3 << 1) | (bcl3 & BinaryOps.mask32) >> (32 - 1));
      tl = bcl1 ^ ((bcl3 << 1) | (bch3 & BinaryOps.mask32) >> (32 - 1));

      sh[2] ^= th;
      sh[7] ^= th;
      sh[12] ^= th;
      sh[17] ^= th;
      sh[22] ^= th;
      sl[2] ^= tl;
      sl[7] ^= tl;
      sl[12] ^= tl;
      sl[17] ^= tl;
      sl[22] ^= tl;
      th = bch2 ^ ((bch4 << 1) | (bcl4 & BinaryOps.mask32) >> (32 - 1));
      tl = bcl2 ^ ((bcl4 << 1) | (bch4 & BinaryOps.mask32) >> (32 - 1));

      sh[3] ^= th;
      sl[3] ^= tl;
      sh[8] ^= th;
      sl[8] ^= tl;
      sh[13] ^= th;
      sl[13] ^= tl;
      sh[18] ^= th;
      sl[18] ^= tl;
      sh[23] ^= th;
      sl[23] ^= tl;
      th = bch3 ^ ((bch0 << 1) | (bcl0 & BinaryOps.mask32) >> (32 - 1));
      tl = bcl3 ^ ((bcl0 << 1) | (bch0 & BinaryOps.mask32) >> (32 - 1));

      sh[4] ^= th;
      sh[9] ^= th;
      sh[14] ^= th;
      sh[19] ^= th;
      sh[24] ^= th;
      sl[4] ^= tl;
      sl[9] ^= tl;
      sl[14] ^= tl;
      sl[19] ^= tl;
      sl[24] ^= tl;
      // Rho Pi
      th = sh[1];
      tl = sl[1];
      bch0 = sh[10];
      bcl0 = sl[10];
      sh[10] = (th << 1) | (tl & BinaryOps.mask32) >> (32 - 1);
      sl[10] = (tl << 1) | (th & BinaryOps.mask32) >> (32 - 1);

      th = bch0;
      tl = bcl0;
      bch0 = sh[7];
      bcl0 = sl[7];
      sh[7] = (th << 3) | (tl & BinaryOps.mask32) >> (32 - 3);
      sl[7] = (tl << 3) | (th & BinaryOps.mask32) >> (32 - 3);
      th = bch0;
      tl = bcl0;

      bch0 = sh[11];
      bcl0 = sl[11];
      sh[11] = (th << 6) | (tl & BinaryOps.mask32) >> (32 - 6);
      sl[11] = (tl << 6) | (th & BinaryOps.mask32) >> (32 - 6);
      th = bch0;
      tl = bcl0;
      bch0 = sh[17];
      bcl0 = sl[17];
      sh[17] = (th << 10) | (tl & BinaryOps.mask32) >> (32 - 10);
      sl[17] = (tl << 10) | (th & BinaryOps.mask32) >> (32 - 10);
      th = bch0;
      tl = bcl0;
      bch0 = sh[18];
      bcl0 = sl[18];
      sh[18] = (th << 15) | (tl & BinaryOps.mask32) >> (32 - 15);
      sl[18] = (tl << 15) | (th & BinaryOps.mask32) >> (32 - 15);
      th = bch0;
      tl = bcl0;
      bch0 = sh[3];
      bcl0 = sl[3];
      sh[3] = (th << 21) | (tl & BinaryOps.mask32) >> (32 - 21);
      sl[3] = (tl << 21) | (th & BinaryOps.mask32) >> (32 - 21);
      th = bch0;
      tl = bcl0;
      bch0 = sh[5];
      bcl0 = sl[5];
      sh[5] = (th << 28) | (tl & BinaryOps.mask32) >> (32 - 28);
      sl[5] = (tl << 28) | (th & BinaryOps.mask32) >> (32 - 28);
      th = bch0;
      tl = bcl0;
      bch0 = sh[16];
      bcl0 = sl[16];
      sh[16] = (tl << 4) | (th & BinaryOps.mask32) >> (32 - 4);
      sl[16] = (th << 4) | (tl & BinaryOps.mask32) >> (32 - 4);
      th = bch0;
      tl = bcl0;
      bch0 = sh[8];
      bcl0 = sl[8];
      sh[8] = (tl << 13) | (th & BinaryOps.mask32) >> (32 - 13);
      sl[8] = (th << 13) | (tl & BinaryOps.mask32) >> (32 - 13);
      th = bch0;
      tl = bcl0;
      bch0 = sh[21];
      bcl0 = sl[21];
      sh[21] = (tl << 23) | (th & BinaryOps.mask32) >> (32 - 23);
      sl[21] = (th << 23) | (tl & BinaryOps.mask32) >> (32 - 23);
      th = bch0;
      tl = bcl0;
      bch0 = sh[24];
      bcl0 = sl[24];
      sh[24] = (th << 2) | (tl & BinaryOps.mask32) >> (32 - 2);
      sl[24] = (tl << 2) | (th & BinaryOps.mask32) >> (32 - 2);
      th = bch0;
      tl = bcl0;
      bch0 = sh[4];
      bcl0 = sl[4];
      sh[4] = (th << 14) | (tl & BinaryOps.mask32) >> (32 - 14);
      sl[4] = (tl << 14) | (th & BinaryOps.mask32) >> (32 - 14);
      th = bch0;
      tl = bcl0;
      bch0 = sh[15];
      bcl0 = sl[15];
      sh[15] = (th << 27) | (tl & BinaryOps.mask32) >> (32 - 27);
      sl[15] = (tl << 27) | (th & BinaryOps.mask32) >> (32 - 27);
      th = bch0;
      tl = bcl0;
      bch0 = sh[23];
      bcl0 = sl[23];
      sh[23] = (tl << 9) | (th & BinaryOps.mask32) >> (32 - 9);
      sl[23] = (th << 9) | (tl & BinaryOps.mask32) >> (32 - 9);
      th = bch0;
      tl = bcl0;
      bch0 = sh[19];
      bcl0 = sl[19];
      sh[19] = (tl << 24) | (th & BinaryOps.mask32) >> (32 - 24);
      sl[19] = (th << 24) | (tl & BinaryOps.mask32) >> (32 - 24);
      th = bch0;
      tl = bcl0;
      bch0 = sh[13];
      bcl0 = sl[13];
      sh[13] = (th << 8) | (tl & BinaryOps.mask32) >> (32 - 8);
      sl[13] = (tl << 8) | (th & BinaryOps.mask32) >> (32 - 8);
      th = bch0;
      tl = bcl0;
      bch0 = sh[12];
      bcl0 = sl[12];
      sh[12] = (th << 25) | (tl & BinaryOps.mask32) >> (32 - 25);
      sl[12] = (tl << 25) | (th & BinaryOps.mask32) >> (32 - 25);
      th = bch0;
      tl = bcl0;
      bch0 = sh[2];
      bcl0 = sl[2];
      sh[2] = (tl << 11) | (th & BinaryOps.mask32) >> (32 - 11);
      sl[2] = (th << 11) | (tl & BinaryOps.mask32) >> (32 - 11);
      th = bch0;
      tl = bcl0;
      bch0 = sh[20];
      bcl0 = sl[20];
      sh[20] = (tl << 30) | (th & BinaryOps.mask32) >> (32 - 30);
      sl[20] = (th << 30) | (tl & BinaryOps.mask32) >> (32 - 30);
      th = bch0;
      tl = bcl0;
      bch0 = sh[14];
      bcl0 = sl[14];
      sh[14] = (th << 18) | (tl & BinaryOps.mask32) >> (32 - 18);
      sl[14] = (tl << 18) | (th & BinaryOps.mask32) >> (32 - 18);
      th = bch0;
      tl = bcl0;
      bch0 = sh[22];
      bcl0 = sl[22];
      sh[22] = (tl << 7) | (th & BinaryOps.mask32) >> (32 - 7);
      sl[22] = (th << 7) | (tl & BinaryOps.mask32) >> (32 - 7);
      th = bch0;
      tl = bcl0;
      bch0 = sh[9];
      bcl0 = sl[9];
      sh[9] = (tl << 29) | (th & BinaryOps.mask32) >> (32 - 29);
      sl[9] = (th << 29) | (tl & BinaryOps.mask32) >> (32 - 29);
      th = bch0;
      tl = bcl0;
      bch0 = sh[6];
      bcl0 = sl[6];
      sh[6] = (th << 20) | (tl & BinaryOps.mask32) >> (32 - 20);
      sl[6] = (tl << 20) | (th & BinaryOps.mask32) >> (32 - 20);
      th = bch0;
      tl = bcl0;
      bch0 = sh[1];
      bcl0 = sl[1];
      sh[1] = (tl << 12) | (th & BinaryOps.mask32) >> (32 - 12);
      sl[1] = (th << 12) | (tl & BinaryOps.mask32) >> (32 - 12);

      th = bch0;
      tl = bcl0;
      // Chi
      bch0 = sh[0];
      bch1 = sh[1];
      bch2 = sh[2];
      bch3 = sh[3];
      bch4 = sh[4];
      sh[0] ^= (~bch1) & bch2;
      sh[1] ^= (~bch2) & bch3;
      sh[2] ^= (~bch3) & bch4;
      sh[3] ^= (~bch4) & bch0;
      sh[4] ^= (~bch0) & bch1;
      bcl0 = sl[0];
      bcl1 = sl[1];
      bcl2 = sl[2];
      bcl3 = sl[3];
      bcl4 = sl[4];
      sl[0] ^= (~bcl1) & bcl2;
      sl[1] ^= (~bcl2) & bcl3;
      sl[2] ^= (~bcl3) & bcl4;
      sl[3] ^= (~bcl4) & bcl0;
      sl[4] ^= (~bcl0) & bcl1;
      bch0 = sh[5];
      bch1 = sh[6];
      bch2 = sh[7];
      bch3 = sh[8];
      bch4 = sh[9];
      sh[5] ^= (~bch1) & bch2;
      sh[6] ^= (~bch2) & bch3;
      sh[7] ^= (~bch3) & bch4;
      sh[8] ^= (~bch4) & bch0;
      sh[9] ^= (~bch0) & bch1;
      bcl0 = sl[5];
      bcl1 = sl[6];
      bcl2 = sl[7];
      bcl3 = sl[8];
      bcl4 = sl[9];
      sl[5] ^= (~bcl1) & bcl2;
      sl[6] ^= (~bcl2) & bcl3;
      sl[7] ^= (~bcl3) & bcl4;
      sl[8] ^= (~bcl4) & bcl0;
      sl[9] ^= (~bcl0) & bcl1;
      bch0 = sh[10];
      bch1 = sh[11];
      bch2 = sh[12];
      bch3 = sh[13];
      bch4 = sh[14];
      sh[10] ^= (~bch1) & bch2;
      sh[11] ^= (~bch2) & bch3;
      sh[12] ^= (~bch3) & bch4;
      sh[13] ^= (~bch4) & bch0;
      sh[14] ^= (~bch0) & bch1;
      bcl0 = sl[10];
      bcl1 = sl[11];
      bcl2 = sl[12];
      bcl3 = sl[13];
      bcl4 = sl[14];
      sl[10] ^= (~bcl1) & bcl2;
      sl[11] ^= (~bcl2) & bcl3;
      sl[12] ^= (~bcl3) & bcl4;
      sl[13] ^= (~bcl4) & bcl0;
      sl[14] ^= (~bcl0) & bcl1;
      bch0 = sh[15];
      bch1 = sh[16];
      bch2 = sh[17];
      bch3 = sh[18];
      bch4 = sh[19];
      sh[15] ^= (~bch1) & bch2;
      sh[16] ^= (~bch2) & bch3;
      sh[17] ^= (~bch3) & bch4;
      sh[18] ^= (~bch4) & bch0;
      sh[19] ^= (~bch0) & bch1;
      bcl0 = sl[15];
      bcl1 = sl[16];
      bcl2 = sl[17];
      bcl3 = sl[18];
      bcl4 = sl[19];
      sl[15] ^= (~bcl1) & bcl2;
      sl[16] ^= (~bcl2) & bcl3;
      sl[17] ^= (~bcl3) & bcl4;
      sl[18] ^= (~bcl4) & bcl0;
      sl[19] ^= (~bcl0) & bcl1;
      bch0 = sh[20];
      bch1 = sh[21];
      bch2 = sh[22];
      bch3 = sh[23];
      bch4 = sh[24];
      sh[20] ^= (~bch1) & bch2;
      sh[21] ^= (~bch2) & bch3;
      sh[22] ^= (~bch3) & bch4;
      sh[23] ^= (~bch4) & bch0;
      sh[24] ^= (~bch0) & bch1;
      bcl0 = sl[20];
      bcl1 = sl[21];
      bcl2 = sl[22];
      bcl3 = sl[23];
      bcl4 = sl[24];
      sl[20] ^= (~bcl1) & bcl2;
      sl[21] ^= (~bcl2) & bcl3;
      sl[22] ^= (~bcl3) & bcl4;
      sl[23] ^= (~bcl4) & bcl0;
      sl[24] ^= (~bcl0) & bcl1;
      //  Iota
      sh[0] ^= _hi[r];
      sl[0] ^= _lo[r];
    }

    for (int i = 0; i < 25; i++) {
      BinaryOps.writeUint32LE(sl[i], buf, i * 8);
      BinaryOps.writeUint32LE(sh[i], buf, i * 8 + 4);
    }
  }
}

enum KeccakFamily { keccak, sha3, shake }

class Keccak extends _Keccak implements SerializableHash<KeccakState> {
  static BuBytes keccakF1600(BuBytes src) {
    /// temporary space for permutation (high bits)
    final List<int> sh = List<int>.filled(25, 0);

    /// temporary space for permutation (low bits)
    final List<int> sl = List<int>.filled(25, 0);
    _Keccak._keccakf(sh, sl, src);
    return src;
  }

  // Constructor for Keccak with an optional named parameter digestLength
  Keccak([this.digestLength = 32]) : super(digestLength * 2);

  /// digest length
  final int digestLength;

  /// Resets the hash computation to its initial state.
  ///
  /// This method initializes the hash computation to its initial state, clearing any previously
  /// processed data. After calling this method, you can start a new hash computation.
  @override
  Keccak reset() {
    super.reset();
    return this;
  }

  /// Updates the hash computation with the given data.
  ///
  /// Parameters:
  /// - [data]: Containing the data to be hashed.
  @override
  Keccak update(List<int> data) {
    super.update(data);
    return this;
  }

  /// Finalizes the hash computation and stores the hash state in the provided [dst].
  ///
  /// Parameters:
  ///   - [dst]: In which the hash digest is stored.
  ///
  /// Returns the current instance of the hash algorithm.
  @override
  Keccak finish(List<int> dst) {
    _ensureAlive("Keccak.finish", _cleaned, null);

    if (!_finished) {
      _padAndPermute(0x01);
    } else {
      // Only works for up to blockSize digests,
      // which is the case in our implementation.
      _pos = 0;
    }
    _squeeze(dst);
    return this;
  }

  /// Generates the final hash digest by assembling and returning the hash state in a `List<int>`.
  ///
  @override
  BuBytes digest() {
    final out = BuBytes.fill(digestLength, 0);
    finish(out);
    return out;
  }

  /// Saves the current hash computation state into a serializable state object.
  @override
  KeccakState saveState() {
    _ensureAlive("Keccak.saveState", _cleaned, _finished);
    return KeccakState(
      data: _state.sublist(0, _pos),
      pos: _pos,
      blockSize: blockSize,
      type: KeccakFamily.keccak,
    );
  }

  /// Restores the hash computation state from a previously saved state.
  @override
  Keccak restoreState(KeccakState savedState) {
    _ensureAlive("Keccak.restoreState", _cleaned, null);
    if (savedState.type != KeccakFamily.keccak) {
      throw CoreErrors.cryptoFailed(
        "Keccak.restoreState",
        reason: "Mismatch state type.",
      );
    }
    _blockSize = savedState.blockSize;
    BinaryOps.zero(_state);
    _state.setAll(0, savedState.data);
    _pos = savedState.pos;
    _finished = false;
    return this;
  }

  /// [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(KeccakState savedState) {
    BinaryOps.zero(savedState.data);
  }

  /// Computes the Keccak hash of the provided data.
  static BuBytes hash(List<int> data, [int digestLength = 32]) {
    final h = Keccak(digestLength);
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }

  @override
  int get getBlockSize => blockSize;

  @override
  int get getDigestLength => (200 - blockSize) ~/ 2;
}

/// The `SHA3` class is used to compute hash digests of data, and it allows customization of the
/// digest length
class SHA3 extends _Keccak implements SerializableHash<KeccakState> {
  // Constructor for SHA3 with an optional positional parameter digestLength
  SHA3([int digestLength = 32])
    : getDigestLength = digestLength,
      super(digestLength * 2);

  /// digest length
  @override
  final int getDigestLength;

  /// block size
  @override
  int get getBlockSize => 200;
  SHA3 reset() {
    super.reset();
    return this;
  }

  /// Updates the hash computation with the given data.
  ///
  /// Parameters:
  /// - [data]: Containing the data to be hashed.
  SHA3 update(List<int> data) {
    super.update(data);
    return this;
  }

  /// Finalizes the hash computation and stores the hash state in the provided `List<int>` [dst].
  ///
  /// Parameters:
  ///   - [dst]: In which the hash digest is stored.
  @override
  SHA3 finish(List<int> dst) {
    _ensureAlive("SHA3.finish", _cleaned, null);
    if (!_finished) {
      _padAndPermute(0x06);
    } else {
      // Only works for up to blockSize digests,
      // which is the case in our implementation.
      _pos = 0;
    }
    _squeeze(dst);
    return this;
  }

  /// Generates the final hash digest by assembling and returning the hash state in a `List<int>`.
  @override
  BuBytes digest() {
    final out = BuBytes.fill(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Saves the current hash computation state into a serializable state object.
  @override
  KeccakState saveState() {
    _ensureAlive("SHA3.saveState", _cleaned, _finished);
    return KeccakState(
      data: _state,
      pos: _pos,
      blockSize: _blockSize,
      type: KeccakFamily.sha3,
    );
  }

  /// Restores the hash computation state from a previously saved state.
  ///
  /// Parameters:
  /// - [savedState]: The saved state to restore.
  @override
  SHA3 restoreState(KeccakState savedState) {
    _ensureAlive("SHA3.restoreState", _cleaned, null);
    if (savedState.type != KeccakFamily.sha3) {
      throw CoreErrors.cryptoFailed(
        "SHA3.restoreState",
        reason: "Mismatch state type.",
      );
    }
    _blockSize = savedState.blockSize;
    _state.setAll(0, savedState.data);
    _pos = savedState.pos;
    _finished = false;
    return this;
  }

  /// Clean up and reset the saved state of the hash object to its initial state.
  ///
  /// - [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(KeccakState savedState) {
    BinaryOps.zero(savedState.data);
    savedState.pos = 0;
  }

  /// Computes the SHA3 hash of the provided data.
  static BuBytes hash(List<int> data, [int digestLength = 32]) {
    final h = SHA3(digestLength);
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}

/// The [SHA3224] class represents a specific implementation of the SHA-3 (Secure Hash Algorithm 3) hash function
/// with a digest length of 224 bits (28 bytes).
class SHA3224 extends SHA3 {
  /// Constructor for SHA3224 with a fixed digest length of 224 bits (28 bytes)
  SHA3224() : super(224 ~/ 8);

  /// Computes the SHA3/224 hash of the provided data.
  static BuBytes hash(List<int> data) {
    final h = SHA3224();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}

/// The [SHA3256] class represents a specific implementation of the SHA-3 (Secure Hash Algorithm 3) hash function
/// with a digest length of 256 bits (32 bytes).
class SHA3256 extends SHA3 {
  /// Constructor for SHA3256 with a fixed digest length of 256 bits (32 bytes)
  SHA3256() : super(256 ~/ 8);

  /// Computes the SHA3/256 hash of the provided data.
  static BuBytes hash(List<int> data) {
    final h = SHA3256();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}

/// The [SHA3384] class represents a specific implementation of the SHA-3 (Secure Hash Algorithm 3) hash function
/// with a digest length of 384 bits (48 bytes).
class SHA3384 extends SHA3 {
  /// Constructor for SHA3384 with a fixed digest length of 384 bits (48 bytes)
  SHA3384() : super(384 ~/ 8);

  /// Computes the SHA3/384 hash of the provided data.
  static BuBytes hash(List<int> data) {
    final h = SHA3384();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}

/// The [SHA3512] class represents a specific implementation of the SHA-3 (Secure Hash Algorithm 3) hash function
/// with a digest length of 512 bits (64 bytes).
class SHA3512 extends SHA3 {
  /// Constructor for SHA3512 with a fixed digest length of 512 bits (64 bytes)
  SHA3512() : super(512 ~/ 8);

  /// Computes the SHA3/512 hash of the provided data.
  static BuBytes hash(List<int> data) {
    final h = SHA3512();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}

/// The [SHAKE] class represents the SHAKE (Secure Hash Algorithm KEccak) extendable-output hash function.
class SHAKE extends _Keccak implements SerializableHash<KeccakState> {
  /// The desired output size in bits for the SHAKE digest.
  final int bitSize;

  /// Constructor for SHAKE with a specified bit size
  SHAKE(this.bitSize) : super(bitSize ~/ 8 * 2);

  /// The [stream] method is used for generating a stream of pseudorandom bytes from the SHAKE (Secure Hash Algorithm KEccak) hash function.
  /// Parameters:
  /// - [dst]: To store the generated pseudorandom bytes.
  ///
  /// This method is especially useful for producing variable-length output streams, which is a key feature of SHAKE.
  void stream(List<int> dst) {
    _ensureAlive("SHAKE.stream", _cleaned, null);
    if (!_finished) {
      _padAndPermute(0x1f);
    }
    _squeeze(dst);
  }

  SHAKE reset() {
    super.reset();
    return this;
  }

  /// Updates the hash computation with the given data.
  ///
  /// Parameters:
  /// - [data]: The `List<int>` containing the data to be hashed.
  SHAKE update(List<int> data) {
    super.update(data);
    return this;
  }

  /// Restores the hash computation state from a previously saved state.
  ///
  /// Parameters:
  /// - [savedState]: The saved state to restore.
  @override
  SHAKE restoreState(KeccakState savedState) {
    _ensureAlive("SHAKE.restoreState", _cleaned, null);
    if (savedState.type != KeccakFamily.shake) {
      throw CoreErrors.cryptoFailed(
        "SHAKE.restoreState",
        reason: "Mismatch state type.",
      );
    }

    _blockSize = savedState.blockSize;
    _state.setAll(0, savedState.data);
    _pos = savedState.pos;
    _finished = false;
    return this;
  }

  /// Clean up and reset the saved state of the hash object to its initial state.
  /// - [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(dynamic savedState) {
    BinaryOps.zero(savedState);
  }

  /// Generates the final hash digest by assembling and returning the hash state in a `List<int>`.
  @override
  BuBytes digest([int outlen = 32]) {
    final out = BuBytes.fill(outlen, 0);
    finish(out);
    return out;
  }

  /// Finalizes the hash computation and stores the hash state in the provided [out].
  ///
  /// Parameters:
  ///   - [out]: The `List<int>` in which the hash digest is stored.
  @override
  Hash finish(List<int> out) {
    _ensureAlive("SHAKE.finish", _cleaned, null);
    stream(out);
    return this;
  }

  @override
  int get getBlockSize => bitSize ~/ 8;

  @override
  int get getDigestLength => bitSize ~/ 8; // Default 32

  /// Saves the current hash computation state into a serializable state object.
  @override
  KeccakState saveState() {
    _ensureAlive("SHAKE.saveState", _cleaned, null);
    return KeccakState(
      data: _state,
      pos: _pos,
      blockSize: blockSize,
      type: KeccakFamily.shake,
    );
  }
}

/// [SHAKE128] is an implementation of the SHAKE128 extendable-output function.
///
class SHAKE128 extends SHAKE {
  /// Constructor for SHAKE-128
  SHAKE128() : super(128);
  static BuBytes shake(List<int> data, int outlen) {
    return SHAKE128().update(data).digest(outlen);
  }
}

/// [SHAKE256] is an implementation of the SHAKE256 extendable-output function.
///
class SHAKE256 extends SHAKE {
  /// Constructor for SHAKE-256
  SHAKE256() : super(256);

  static BuBytes shake(List<int> data, int outlen) {
    return SHAKE256().update(data).digest(outlen);
  }
}

/// Serializable snapshot of an in-progress Keccak computation.
class KeccakState extends HashState {
  final KeccakFamily type;
  KeccakState({
    required List<int> data,
    required this.pos,
    required this.type,
    required this.blockSize,
  }) : data = data.clone();
  final List<int> data;
  final int blockSize;
  int pos;
}
