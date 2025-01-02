import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

class ChaCha20 {
  static void _quarterround(List<int> output, int a, int b, int c, int d) {
    output[d] = rotl32(output[d] ^ (output[a] += output[b]), 16);
    output[b] = rotl32(output[b] ^ (output[c] += output[d]), 12);
    output[d] = rotl32(output[d] ^ (output[a] += output[b]), 8);
    output[b] = rotl32(output[b] ^ (output[c] += output[d]), 7);

    // Ensure all values are within UINT32 range
    output[a] &= mask32;
    output[b] &= mask32;
    output[c] &= mask32;
    output[d] &= mask32;
  }

  static const _rounds = 20;
  static void _core(List<int> out, List<int> input, List<int> key) {
    const j0 = 0x61707865;
    const j1 = 0x3320646E;
    const j2 = 0x79622D32;
    const j3 = 0x6B206574;
    final mix = List<int>.filled(16, 0);

    final j4 = (key[3] << 24) | (key[2] << 16) | (key[1] << 8) | key[0];
    final j5 = (key[7] << 24) | (key[6] << 16) | (key[5] << 8) | key[4];
    final j6 = (key[11] << 24) | (key[10] << 16) | (key[9] << 8) | key[8];
    final j7 = (key[15] << 24) | (key[14] << 16) | (key[13] << 8) | key[12];
    final j8 = (key[19] << 24) | (key[18] << 16) | (key[17] << 8) | key[16];
    final j9 = (key[23] << 24) | (key[22] << 16) | (key[21] << 8) | key[20];
    final j10 = (key[27] << 24) | (key[26] << 16) | (key[25] << 8) | key[24];
    final j11 = (key[31] << 24) | (key[30] << 16) | (key[29] << 8) | key[28];

    final j12 =
        (input[3] << 24) | (input[2] << 16) | (input[1] << 8) | input[0];
    final j13 =
        (input[7] << 24) | (input[6] << 16) | (input[5] << 8) | input[4];
    final j14 =
        (input[11] << 24) | (input[10] << 16) | (input[9] << 8) | input[8];
    final j15 =
        (input[15] << 24) | (input[14] << 16) | (input[13] << 8) | input[12];

    mix[0] = j0;
    mix[1] = j1;
    mix[2] = j2;
    mix[3] = j3;
    mix[4] = j4;
    mix[5] = j5;
    mix[6] = j6;
    mix[7] = j7;
    mix[8] = j8;
    mix[9] = j9;
    mix[10] = j10;
    mix[11] = j11;
    mix[12] = j12;
    mix[13] = j13;
    mix[14] = j14;
    mix[15] = j15;

    for (int i = 0; i < _rounds; i += 2) {
      _quarterround(mix, 0, 4, 8, 12);
      _quarterround(mix, 1, 5, 9, 13);
      _quarterround(mix, 2, 6, 10, 14);
      _quarterround(mix, 3, 7, 11, 15);
      _quarterround(mix, 0, 5, 10, 15);
      _quarterround(mix, 1, 6, 11, 12);
      _quarterround(mix, 2, 7, 8, 13);
      _quarterround(mix, 3, 4, 9, 14);
    }
    writeUint32LE(mix[0] + j0 & mask32, out, 0);
    writeUint32LE(mix[1] + j1 & mask32, out, 4);
    writeUint32LE(mix[2] + j2 & mask32, out, 8);
    writeUint32LE(mix[3] + j3 & mask32, out, 12);
    writeUint32LE(mix[4] + j4 & mask32, out, 16);
    writeUint32LE(mix[5] + j5 & mask32, out, 20);
    writeUint32LE(mix[6] + j6 & mask32, out, 24);
    writeUint32LE(mix[7] + j7 & mask32, out, 28);
    writeUint32LE(mix[8] + j8 & mask32, out, 32);
    writeUint32LE(mix[9] + j9 & mask32, out, 36);
    writeUint32LE(mix[10] + j10 & mask32, out, 40);
    writeUint32LE(mix[11] + j11 & mask32, out, 44);
    writeUint32LE(mix[12] + j12 & mask32, out, 48);
    writeUint32LE(mix[13] + j13 & mask32, out, 52);
    writeUint32LE(mix[14] + j14 & mask32, out, 56);
    writeUint32LE(mix[15] + j15 & mask32, out, 60);
  }

  static void _incrementCounter(List<int> counter, int pos, int len) {
    int carry = 1;
    while (len > 0) {
      carry += (counter[pos] & 0xFF);
      counter[pos] = carry & 0xFF;
      carry >>= 8;
      pos++;
      len--;
    }
    if (carry > 0) {
      throw const MessageException("ChaCha: counter overflow");
    }
  }

  /// Encrypts or decrypts data by XORing it with the output of the ChaCha stream cipher.
  ///
  /// This function takes a key, nonce, source data (`src`), and destination data (`dst`) and encrypts
  /// or decrypts the source data by XORing it with the output of the ChaCha stream cipher. The nonce can
  /// be used with or without an inplace counter, depending on the value of `nonceInplaceCounterLength`.
  ///
  /// Parameters:
  /// - `key`: The 256-bit (32-byte) encryption key as a `List<int>`.
  /// - `nonce`: The nonce data, which must be either 8, 12, or 16 bytes in length depending on the
  ///   value of `nonceInplaceCounterLength`.
  /// - `src`: The source data to be encrypted or decrypted.
  /// - `dst`: The destination data where the result will be written.
  /// - `nonceInplaceCounterLength`: An optional parameter to specify the length of the nonce inplace counter
  ///   (0 for no counter, 16 bytes if a counter is included in the nonce).
  ///
  /// Throws:
  /// - `ArgumentException` if the key size is not 32 bytes, if the destination is shorter than the source, or if
  ///   the nonce length is invalid.
  ///
  /// Returns:
  /// - The `dst` `List<int>` containing the result of the XOR operation.
  ///
  /// Note: This function securely zeros temporary data to protect sensitive information.
  static List<int> streamXOR(
      List<int> key, List<int> nonce, List<int> src, List<int> dst,
      {int nonceInplaceCounterLength = 0}) {
    // We only support 256-bit keys.
    if (key.length != 32) {
      throw const ArgumentException("ChaCha: key size must be 32 bytes");
    }

    if (dst.length < src.length) {
      throw const ArgumentException(
          "ChaCha: destination is shorter than source");
    }

    List<int> nc;
    int counterLength;

    if (nonceInplaceCounterLength == 0) {
      if (nonce.length != 8 && nonce.length != 12) {
        throw const ArgumentException("ChaCha nonce must be 8 or 12 bytes");
      }
      nc = List<int>.filled(16, 0);
      counterLength = nc.length - nonce.length;
      nc.setAll(counterLength, nonce);
    } else {
      if (nonce.length != 16) {
        throw const ArgumentException(
            "ChaCha nonce with counter must be 16 bytes");
      }
      nc = nonce;
      counterLength = nonceInplaceCounterLength;
    }

    final block = List<int>.filled(64, 0);

    for (int i = 0; i < src.length; i += 64) {
      _core(block, nc, key);

      for (int j = i; j < i + 64 && j < src.length; j++) {
        dst[j] = (src[j] & mask8) ^ block[j - i];
      }

      _incrementCounter(nc, 0, counterLength);
    }

    zero(block);

    if (nonceInplaceCounterLength == 0) {
      zero(nc);
    }

    return dst;
  }

  /// Generates a stream of pseudo-random bytes using the ChaCha stream cipher.
  ///
  /// This function generates a stream of pseudo-random bytes by encrypting a nonce and key with the
  /// ChaCha stream cipher algorithm. The generated stream is then XORed with the `dst` data, resulting
  /// in the encrypted output. It also provides the option to incorporate a nonce inplace counter.
  ///
  /// Parameters:
  /// - `key`: The encryption key as a `List<int>`.
  /// - `nonce`: A unique nonce as a `List<int>`.
  /// - `dst`: The destination `List<int>` where the generated stream will be XORed.
  /// - `nonceInplaceCounterLength`: An optional parameter to specify the length of the nonce inplace counter
  ///   (default is 0, meaning no nonce inplace counter).
  ///
  /// Returns:
  /// - The `dst` `List<int>` containing the encrypted data.
  ///
  /// Note: This function securely zeros the `dst` data before writing the generated stream and should
  /// be used for generating secure random data.
  static List<int> stream(List<int> key, List<int> nonce, List<int> dst,
      {int nonceInplaceCounterLength = 0}) {
    zero(dst);
    return streamXOR(key, nonce, dst, dst,
        nonceInplaceCounterLength: nonceInplaceCounterLength);
  }
}
