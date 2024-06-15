import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/aead/aead.dart';
import 'package:blockchain_utils/crypto/crypto/blockcipher/blockcipher.dart';
import 'package:blockchain_utils/crypto/crypto/ctr/ctr.dart';
import 'package:blockchain_utils/exception/exception.dart';

import 'dart:math' as math;

/// Galois/Counter Mode (GCM) implementation for authenticated encryption with associated data (AEAD).
///
/// This class implements the GCM mode, which provides authenticated encryption with associated data (AEAD)
/// using a block cipher with a 16-byte block size.
class GCM implements AEAD {
  @override
  final int nonceLength = 12;
  @override
  final int tagLength = 16;

  late List<int> _subkey;
  late BlockCipher _cipher;

  /// Creates a GCM instance with the specified block cipher.
  ///
  /// Parameters:
  /// - `cipher`: The block cipher with a 16-byte block size to be used for GCM encryption and decryption.
  ///
  /// Throws:
  /// - `ArgumentException` if the provided block cipher does not have a 16-byte block size.
  GCM(BlockCipher cipher) {
    if (cipher.blockSize != 16) {
      throw const ArgumentException("GCM supports only 16-byte block cipher");
    }
    _cipher = cipher;

    _subkey = List<int>.filled(_cipher.blockSize, 0);
    _cipher.encryptBlock(List<int>.filled(_cipher.blockSize, 0), _subkey);
  }

  /// Encrypts data using the Galois/Counter Mode (GCM) with associated data (AEAD).
  ///
  /// This method encrypts data using the GCM mode, providing authenticated encryption with associated data (AEAD).
  /// It uses a nonce and associated data for encryption, and generates an authentication tag to ensure data integrity.
  ///
  /// Parameters:
  /// - `nonce`: The nonce value used for encryption, must have a length equal to the GCM nonce length (12 bytes).
  /// - `plaintext`: The data to be encrypted.
  /// - `associatedData`: (Optional) Additional data that is authenticated but not encrypted.
  /// - `dst`: (Optional) The destination for the encrypted data and authentication tag. If not provided, a new `List<int>` is created.
  ///
  /// Returns:
  /// - The encrypted data with the appended authentication tag.
  ///
  /// Throws:
  /// - `ArgumentException` if the provided nonce has an incorrect length or if the destination size is incorrect.
  ///
  /// Note: This method performs GCM encryption by combining nonce, plaintext, and optional associated data,
  /// and generating an authentication tag for data integrity verification.
  @override
  List<int> encrypt(List<int> nonce, List<int> plaintext,
      {List<int>? associatedData, List<int>? dst}) {
    if (nonce.length != nonceLength) {
      throw const ArgumentException("GCM: incorrect nonce length");
    }

    final blockSize = _cipher.blockSize;

    final resultLength = plaintext.length + tagLength;
    List<int> result = dst ?? List<int>.filled(resultLength, 0);
    if (result.length != resultLength) {
      throw const ArgumentException("GCM: incorrect destination length");
    }

    final counter = List<int>.filled(blockSize, 0);
    counter.setAll(0, nonce);

    counter[blockSize - 1] = 1;

    final tagMask = List<int>.filled(blockSize, 0);
    _cipher.encryptBlock(counter, tagMask);

    counter[blockSize - 1] = 2;

    final ctr = CTR(_cipher, counter);
    ctr.streamXOR(plaintext, result);
    ctr.clean();
    final calculatedTag = List<int>.filled(tagLength, 0);
    final cipherText = result.sublist(0, result.length - tagLength);

    _authenticate(calculatedTag, tagMask, cipherText, associatedData);
    result.setRange(result.length - tagLength, result.length, calculatedTag);
    zero(counter);
    zero(tagMask);
    return result;
  }

  /// Decrypts sealed data using the Galois/Counter Mode (GCM) with associated data (AEAD).
  ///
  /// This method decrypts sealed data using the GCM mode, ensuring data integrity and authenticity with the associated data.
  ///
  /// Parameters:
  /// - `nonce`: The nonce value used during encryption, must have a length equal to the GCM nonce length (12 bytes).
  /// - `sealed`: The sealed data that includes the ciphertext and authentication tag.
  /// - `associatedData`: (Optional) Additional data that was authenticated during encryption but not encrypted.
  /// - `dst`: (Optional) The destination for the decrypted data. If not provided, a new `List<int>` is created.
  ///
  /// Returns:
  /// - The decrypted data if authentication succeeds; otherwise, returns null if authentication fails.
  ///
  /// Throws:
  /// - `ArgumentException` if the provided nonce has an incorrect length, if the destination size is incorrect, or if the authentication tag verification fails.
  ///
  /// Note: This method performs GCM decryption, verifying the authentication tag and ensuring the data's integrity and authenticity.
  @override
  List<int>? decrypt(List<int> nonce, List<int> sealed,
      {List<int>? associatedData, List<int>? dst}) {
    if (nonce.length != nonceLength) {
      throw const ArgumentException("GCM: incorrect nonce length");
    }

    if (sealed.length < tagLength) {
      return null;
    }

    final blockSize = _cipher.blockSize;

    final counter = List<int>.filled(blockSize, 0);
    counter.setAll(0, nonce);

    counter[blockSize - 1] = 1;

    final tagMask = List<int>.filled(blockSize, 0);
    _cipher.encryptBlock(counter, tagMask);

    counter[blockSize - 1] = 2;

    final calculatedTag = List<int>.filled(tagLength, 0);
    _authenticate(calculatedTag, tagMask,
        sealed.sublist(0, sealed.length - tagLength), associatedData);

    if (!BytesUtils.bytesEqual(
        calculatedTag, sealed.sublist(sealed.length - tagLength))) {
      return null;
    }

    final resultLength = sealed.length - tagLength;
    List<int> result = dst ?? List<int>.filled(resultLength, 0);
    if (result.length != resultLength) {
      throw const ArgumentException("GCM: incorrect destination length");
    }
    final ctr = CTR(_cipher, counter);
    ctr.streamXOR(sealed.sublist(0, sealed.length - tagLength), result);
    ctr.clean();

    zero(counter);
    zero(tagMask);
    return result;
  }

  /// Cleans up resources used by the Galois/Counter Mode (GCM) instance.
  ///
  /// This method clears sensitive data and resources, such as the subkey used for encryption and decryption.
  ///
  /// Returns:
  /// - A reference to the cleaned GCM instance.
  ///
  /// Note: Cleaning the GCM instance is important for security to prevent potential data leaks.
  @override
  GCM clean() {
    zero(_subkey);
    return this;
  }

  _authenticate(List<int> tagOut, List<int> tagMask, List<int> ciphertext,
      [List<int>? associatedData]) {
    final blockSize = _cipher.blockSize;
    if (associatedData != null) {
      for (int i = 0; i < associatedData.length; i += blockSize) {
        final slice = associatedData.sublist(
            i, math.min(i + blockSize, associatedData.length));
        _addmul(tagOut, slice, _subkey);
      }
    }

    for (int i = 0; i < ciphertext.length; i += blockSize) {
      final slice =
          ciphertext.sublist(i, math.min(i + blockSize, ciphertext.length));
      _addmul(tagOut, slice, _subkey);
    }

    final lengthsBlock = List<int>.filled(blockSize, 0);
    if (associatedData != null) {
      _writeBitLength(associatedData.length, lengthsBlock, 0);
    }
    _writeBitLength(ciphertext.length, lengthsBlock, 8);
    _addmul(tagOut, lengthsBlock, _subkey);

    for (var i = 0; i < tagMask.length; i++) {
      tagOut[i] ^= tagMask[i];
    }

    zero(lengthsBlock);
  }

  void _writeBitLength(int byteLength, List<int> dst, [int offset = 0]) {
    final hi = (byteLength ~/ 0x20000000);
    final lo = byteLength << 3;
    writeUint32BE(hi, dst, offset + 0);
    writeUint32BE(lo, dst, offset + 4);
  }

// Add and multiply in GF(2^128)
//
// a = (a + x) * y in the finite field
//
// a is 16 bytes
// y is 16 bytes
// x is 0-16 bytes, if x.length <= 16; x is implicitly 0-padded
//
// Masking idea from Mike Belopuhov's implementation,
// that credits John-Mark Gurney for the idea.
// http://cvsweb.openbsd.org/cgi-bin/cvsweb/src/sys/crypto/gmac.c
//
// Addition with implicit padding before multiplication
// is due to Daniel J. Bernstein's implementation in SUPERCOP.
  void _addmul(List<int> a, List<int> x, List<int> y) {
    for (int i = 0; i < x.length; i++) {
      a[i] ^= x[i];
    }

    int v0 = (y[3] | y[2] << 8 | y[1] << 16 | y[0] << 24);
    int v1 = (y[7] | y[6] << 8 | y[5] << 16 | y[4] << 24);
    int v2 = (y[11] | y[10] << 8 | y[9] << 16 | y[8] << 24);
    int v3 = (y[15] | y[14] << 8 | y[13] << 16 | y[12] << 24);
    int z0 = 0, z1 = 0, z2 = 0, z3 = 0;

    for (var i = 0; i < 128; i++) {
      int mask = ~((((-(a[i >> 3] & (1 << (~i & 7)))) >> 31) & 1) - 1);
      z0 ^= v0 & mask;
      z1 ^= v1 & mask;
      z2 ^= v2 & mask;
      z3 ^= v3 & mask;

      mask = ~((v3 & 1) - 1);
      v3 = ((v2 << 31) & mask32) | ((v3 >> 1) & mask32);
      v2 = ((v1 << 31) & mask32) | ((v2 >> 1) & mask32);
      v1 = ((v0 << 31) & mask32) | ((v1 >> 1) & mask32);
      v0 = ((v0 >> 1) & mask32) ^ (0xe1000000 & mask);
    }
    writeUint32BE(z0, a, 0);
    writeUint32BE(z1, a, 4);
    writeUint32BE(z2, a, 8);
    writeUint32BE(z3, a, 12);
  }
}
