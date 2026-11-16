import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Salsa20 stream cipher (Bernstein, Salsa20/20) with [HSalsa20] and
/// XSalsa20 keystream derivation.
///
/// Nonce layouts (all little-endian):
/// - Original Salsa20: 32-byte key, 8-byte nonce, 64-bit block counter.
/// - HSalsa20: 32-byte key, 16-byte nonce, no counter. Outputs the 32-byte
///   subkey; there is no feed-forward addition.
/// - XSalsa20: 32-byte key, 24-byte nonce. `subkey = HSalsa20(key,
///   nonce[0:16])`, then Salsa20 with `subkey` and `nonce[16:24]`.
class Salsa20 implements BuStreamCipher {
  /// Required key length in bytes.
  static const int keyLength = 32;

  /// Original Salsa20 nonce length in bytes.
  static const int nonceLength = 8;

  /// Extended (XSalsa20) nonce length in bytes.
  static const int xsalsaNonceLength = 24;

  /// Length of one Salsa20 keystream block in bytes.
  static const int blockLength = 64;

  static const int _sigma0 = 0x61707865;
  static const int _sigma1 = 0x3320646e;
  static const int _sigma2 = 0x79622d32;
  static const int _sigma3 = 0x6b206574;

  late final BuBytes _key;

  /// Creates a Salsa20 instance with the given 32-byte [key].
  Salsa20(List<int> key) {
    if (key.length != keyLength) {
      throw CoreErrors.invalidOperationArguments(
        "Salsa20",
        name: "key",
        reason: "Invalid key bytes length.",
      );
    }
    _key = BuBytes(key);
  }

  static int _rotl(int v, int shift) => BinaryOps.rotl32(v, shift);

  /// One Salsa20 double round (column round + row round) in place.
  static void _doubleRound(List<int> x) {
    // Column rounds.
    x[4] ^= _rotl(BinaryOps.add32(x[0], x[12]), 7);
    x[8] ^= _rotl(BinaryOps.add32(x[4], x[0]), 9);
    x[12] ^= _rotl(BinaryOps.add32(x[8], x[4]), 13);
    x[0] ^= _rotl(BinaryOps.add32(x[12], x[8]), 18);
    x[9] ^= _rotl(BinaryOps.add32(x[5], x[1]), 7);
    x[13] ^= _rotl(BinaryOps.add32(x[9], x[5]), 9);
    x[1] ^= _rotl(BinaryOps.add32(x[13], x[9]), 13);
    x[5] ^= _rotl(BinaryOps.add32(x[1], x[13]), 18);
    x[14] ^= _rotl(BinaryOps.add32(x[10], x[6]), 7);
    x[2] ^= _rotl(BinaryOps.add32(x[14], x[10]), 9);
    x[6] ^= _rotl(BinaryOps.add32(x[2], x[14]), 13);
    x[10] ^= _rotl(BinaryOps.add32(x[6], x[2]), 18);
    x[3] ^= _rotl(BinaryOps.add32(x[15], x[11]), 7);
    x[7] ^= _rotl(BinaryOps.add32(x[3], x[15]), 9);
    x[11] ^= _rotl(BinaryOps.add32(x[7], x[3]), 13);
    x[15] ^= _rotl(BinaryOps.add32(x[11], x[7]), 18);
    // Row rounds.
    x[1] ^= _rotl(BinaryOps.add32(x[0], x[3]), 7);
    x[2] ^= _rotl(BinaryOps.add32(x[1], x[0]), 9);
    x[3] ^= _rotl(BinaryOps.add32(x[2], x[1]), 13);
    x[0] ^= _rotl(BinaryOps.add32(x[3], x[2]), 18);
    x[6] ^= _rotl(BinaryOps.add32(x[5], x[4]), 7);
    x[7] ^= _rotl(BinaryOps.add32(x[6], x[5]), 9);
    x[4] ^= _rotl(BinaryOps.add32(x[7], x[6]), 13);
    x[5] ^= _rotl(BinaryOps.add32(x[4], x[7]), 18);
    x[11] ^= _rotl(BinaryOps.add32(x[10], x[9]), 7);
    x[8] ^= _rotl(BinaryOps.add32(x[11], x[10]), 9);
    x[9] ^= _rotl(BinaryOps.add32(x[8], x[11]), 13);
    x[10] ^= _rotl(BinaryOps.add32(x[9], x[8]), 18);
    x[12] ^= _rotl(BinaryOps.add32(x[15], x[14]), 7);
    x[13] ^= _rotl(BinaryOps.add32(x[12], x[15]), 9);
    x[14] ^= _rotl(BinaryOps.add32(x[13], x[12]), 13);
    x[15] ^= _rotl(BinaryOps.add32(x[14], x[13]), 18);
    for (int i = 0; i < 16; i++) {
      x[i] &= BinaryOps.mask32;
    }
  }

  static void _ensureKey(List<int> key) {
    if (key.length != keyLength) {
      throw CoreErrors.invalidOperationArguments(
        "Salsa20",
        name: "key",
        reason: "Invalid key bytes length.",
      );
    }
  }

  /// HSalsa20: derives a 32-byte subkey from [key] and a 16-byte [nonce].
  ///
  /// Output words are `x[0], x[5], x[10], x[15], x[6], x[7], x[8], x[9]`
  /// serialized little-endian, with no feed-forward addition.
  static BuBytes hsalsa20(List<int> key, List<int> nonce) {
    _ensureKey(key);
    if (nonce.length != 16) {
      throw CoreErrors.invalidOperationArguments(
        "hsalsa20",
        name: "nonce",
        reason: "Invalid nonce bytes length.",
      );
    }
    final x = List<int>.filled(16, 0);
    x[0] = _sigma0;
    x[1] = BinaryOps.readUint32LE(key, 0);
    x[2] = BinaryOps.readUint32LE(key, 4);
    x[3] = BinaryOps.readUint32LE(key, 8);
    x[4] = BinaryOps.readUint32LE(key, 12);
    x[5] = _sigma1;
    x[6] = BinaryOps.readUint32LE(nonce, 0);
    x[7] = BinaryOps.readUint32LE(nonce, 4);
    x[8] = BinaryOps.readUint32LE(nonce, 8);
    x[9] = BinaryOps.readUint32LE(nonce, 12);
    x[10] = _sigma2;
    x[11] = BinaryOps.readUint32LE(key, 16);
    x[12] = BinaryOps.readUint32LE(key, 20);
    x[13] = BinaryOps.readUint32LE(key, 24);
    x[14] = BinaryOps.readUint32LE(key, 28);
    x[15] = _sigma3;
    for (int i = 0; i < 10; i++) {
      _doubleRound(x);
    }
    final out = BuBytes.fill(32, 0);
    BinaryOps.writeUint32LE(x[0], out, 0);
    BinaryOps.writeUint32LE(x[5], out, 4);
    BinaryOps.writeUint32LE(x[10], out, 8);
    BinaryOps.writeUint32LE(x[15], out, 12);
    BinaryOps.writeUint32LE(x[6], out, 16);
    BinaryOps.writeUint32LE(x[7], out, 20);
    BinaryOps.writeUint32LE(x[8], out, 24);
    BinaryOps.writeUint32LE(x[9], out, 28);
    BinaryOps.zero(x);
    return out;
  }

  /// Computes one 64-byte Salsa20 block for [key], 8-byte [nonce] and a
  /// 64-bit block [counter], writing the result into [out] at [outOffset].
  static void salsa20Block(
    List<int> out,
    List<int> key,
    List<int> nonce,
    int counter, [
    int outOffset = 0,
  ]) {
    _ensureKey(key);
    if (nonce.length != nonceLength) {
      throw CoreErrors.invalidOperationArguments(
        "salsa20Block",
        name: "nonce",
        reason: "Invalid nonce bytes length.",
      );
    }
    final state = List<int>.filled(16, 0);
    state[0] = _sigma0;
    state[1] = BinaryOps.readUint32LE(key, 0);
    state[2] = BinaryOps.readUint32LE(key, 4);
    state[3] = BinaryOps.readUint32LE(key, 8);
    state[4] = BinaryOps.readUint32LE(key, 12);
    state[5] = _sigma1;
    state[6] = BinaryOps.readUint32LE(nonce, 0);
    state[7] = BinaryOps.readUint32LE(nonce, 4);
    state[8] = counter & BinaryOps.mask32;
    state[9] = (counter >> 32) & BinaryOps.mask32;
    state[10] = _sigma2;
    state[11] = BinaryOps.readUint32LE(key, 16);
    state[12] = BinaryOps.readUint32LE(key, 20);
    state[13] = BinaryOps.readUint32LE(key, 24);
    state[14] = BinaryOps.readUint32LE(key, 28);
    state[15] = _sigma3;
    final x = List<int>.from(state);
    for (int i = 0; i < 10; i++) {
      _doubleRound(x);
    }
    for (int i = 0; i < 16; i++) {
      BinaryOps.writeUint32LE(
        BinaryOps.add32(x[i], state[i]),
        out,
        outOffset + i * 4,
      );
    }
    BinaryOps.zero(state);
    BinaryOps.zero(x);
  }

  /// Generates [length] bytes of XSalsa20 keystream for [key] and a 24-byte
  /// [nonce], starting at block [initialCounter].
  static BuBytes xsalsa20Stream(
    List<int> key,
    List<int> nonce,
    int length, {
    int initialCounter = 0,
  }) {
    _ensureKey(key);
    if (nonce.length != xsalsaNonceLength) {
      throw CoreErrors.invalidOperationArguments(
        "xsalsa20Stream",
        name: "nonce",
        reason: "Invalid nonce bytes length.",
      );
    }
    if (length < 0) {
      throw CoreErrors.invalidOperationArguments(
        "xsalsa20Stream",
        name: "length",
        reason: "Invalid stream bytes length.",
      );
    }
    final subkey = hsalsa20(key, nonce.sublist(0, 16));
    final nonce8 = nonce.sublist(16, 24);
    try {
      final out = BuBytes.fill(length, 0);
      final block = List<int>.filled(blockLength, 0);
      int offset = 0;
      int counter = initialCounter;
      while (offset < length) {
        salsa20Block(block, subkey, nonce8, counter);
        counter++;
        final take =
            (length - offset) < blockLength ? (length - offset) : blockLength;
        out.setRange(offset, offset + take, block.sublist(0, take));
        offset += take;
        if (counter < 0) {
          throw CoreErrors.invalidOperationArguments(
            "xsalsa20Stream",
            name: "length",
            reason: "Keystream counter overflow.",
          );
        }
      }
      BinaryOps.zero(block);
      return out;
    } finally {
      subkey.forceZero();
      BinaryOps.zero(nonce8);
    }
  }

  /// Encrypts/decrypts [data] with the 8-byte [nonce] (Salsa20 is symmetric).
  ///
  /// [seekBytes] skips that many keystream bytes before XORing, mirroring
  /// [ChaCha20.process] semantics.
  @override
  BuBytes process(
    List<int> data, {
    required List<int> nonce,
    int nonceInplaceCounterLength = 0,
    int seekBytes = 0,
    List<int>? dst,
  }) {
    if (nonceInplaceCounterLength != 0) {
      throw CoreErrors.invalidOperationArguments(
        "process",
        name: "nonceInplaceCounterLength",
        reason: "Salsa20 only supports an 8-byte nonce.",
      );
    }
    if (nonce.length != nonceLength) {
      throw CoreErrors.invalidOperationArguments(
        "process",
        name: "nonce",
        reason: "Invalid nonce bytes length.",
      );
    }
    if (seekBytes < 0) {
      throw CoreErrors.invalidOperationArguments(
        "process",
        name: "seekBytes",
        reason: "Invalid seek bytes.",
      );
    }
    final out = BuBytes.unsafeMutable(dst ?? List<int>.filled(data.length, 0));
    if (out.length != data.length) {
      throw CoreErrors.invalidOperationArguments(
        "process",
        name: "dst",
        reason: "Invalid destination bytes length.",
      );
    }
    final block = List<int>.filled(blockLength, 0);
    int counter = seekBytes ~/ blockLength;
    int offset = seekBytes % blockLength;
    int srcOffset = 0;
    if (offset != 0 && srcOffset < data.length) {
      salsa20Block(block, _key, nonce, counter);
      counter++;
      for (int j = offset; j < blockLength && srcOffset < data.length; j++) {
        out[srcOffset] =
            (data[srcOffset] & BinaryOps.mask8) ^ (block[j] & BinaryOps.mask8);
        srcOffset++;
      }
    }
    while (srcOffset < data.length) {
      salsa20Block(block, _key, nonce, counter);
      counter++;
      for (int j = 0; j < blockLength && srcOffset < data.length; j++) {
        out[srcOffset] =
            (data[srcOffset] & BinaryOps.mask8) ^ (block[j] & BinaryOps.mask8);
        srcOffset++;
      }
    }
    BinaryOps.zero(block);
    return out;
  }

  @override
  void clean() {
    _key.forceZero();
  }
}
