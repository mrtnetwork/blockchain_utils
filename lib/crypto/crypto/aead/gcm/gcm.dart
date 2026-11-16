import 'dart:math' as math;

import 'package:blockchain_utils/crypto/crypto/aead/core/aead.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/core/blockcipher.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/ctr/ctr.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Galois/Counter Mode (GCM): authenticated encryption built from a
/// 16-byte-block cipher run in CTR mode, with a GHASH-based tag.
class GCM implements AEAD {
  @override
  final int nonceLength = 12;
  @override
  final int tagLength = 16;

  SecretBytes _sKey = SecretBytes.zero(0);
  late BlockCipher _cipher;

  /// Creates a GCM instance over [cipher] (must have a 16-byte block size).
  GCM(BlockCipher cipher) {
    if (cipher.blockSize != 16) {
      throw CoreErrors.invalidOperationArguments(
        "GCM",
        name: "cipher",
        reason: "GCM supports only 16-byte block cipher.",
      );
    }
    _cipher = cipher;
    _sKey.zero();
    _sKey = SecretBytes.take(
      _cipher.encryptBlock(List<int>.filled(_cipher.blockSize, 0)),
    );
  }

  /// Encrypts [plaintext] with the given 12-byte [nonce], authenticating
  /// [associatedData] too. Returns ciphertext || 16-byte tag.
  @override
  BuBytes encrypt(
    List<int> nonce,
    List<int> plaintext, {
    List<int>? associatedData,
    List<int>? dst,
  }) {
    if (nonce.length != nonceLength) {
      throw CoreErrors.invalidOperationArguments(
        "encrypt",
        name: "nonce",
        reason: "Incorrect nonce length.",
      );
    }

    final blockSize = _cipher.blockSize;

    final resultLength = plaintext.length + tagLength;
    final BuBytes result = BuBytes.unsafeMutable(
      dst ?? List<int>.filled(resultLength, 0),
    );
    if (result.length != resultLength) {
      throw CoreErrors.invalidOperationArguments(
        "encrypt",
        name: "dst",
        reason: "Incorrect destination length.",
      );
    }

    final counter = List<int>.filled(blockSize, 0);
    counter.setAll(0, nonce);

    counter[blockSize - 1] = 1;

    final tagMask = List<int>.filled(blockSize, 0);
    _cipher.encryptBlock(counter, tagMask);

    counter[blockSize - 1] = 2;

    final ctr = CTR(_cipher, counter);
    ctr.process(plaintext, result);
    ctr.clean();
    final calculatedTag = List<int>.filled(tagLength, 0);
    final cipherText = result.sublist(0, result.length - tagLength);

    _authenticate(calculatedTag, tagMask, cipherText, associatedData);
    result.setRange(result.length - tagLength, result.length, calculatedTag);
    BinaryOps.zero(counter);
    BinaryOps.zero(tagMask);
    return result;
  }

  /// Decrypts [sealed] (ciphertext || tag) with the given 12-byte [nonce]
  /// and [associatedData]. Returns null if authentication fails.
  ///
  /// The tag comparison is constant-time.
  @override
  BuBytes? decrypt(
    List<int> nonce,
    List<int> sealed, {
    List<int>? associatedData,
    List<int>? dst,
  }) {
    if (nonce.length != nonceLength) {
      throw CoreErrors.invalidOperationArguments(
        "decrypt",
        name: "nonce",
        reason: "Incorrect nonce length.",
      );
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
    _authenticate(
      calculatedTag,
      tagMask,
      sealed.sublist(0, sealed.length - tagLength),
      associatedData,
    );

    if (!BytesUtils.bytesEqualConst(
      calculatedTag,
      sealed.sublist(sealed.length - tagLength),
    )) {
      return null;
    }

    final resultLength = sealed.length - tagLength;
    final BuBytes result = BuBytes.unsafeMutable(
      dst ?? List<int>.filled(resultLength, 0),
    );
    if (result.length != resultLength) {
      throw CoreErrors.invalidOperationArguments(
        "decrypt",
        name: "dst",
        reason: "Incorrect destination length.",
      );
    }
    final ctr = CTR(_cipher, counter);
    ctr.process(sealed.sublist(0, sealed.length - tagLength), result);
    ctr.clean();

    BinaryOps.zero(counter);
    BinaryOps.zero(tagMask);
    return result;
  }

  /// Zeroes the GHASH subkey.
  @override
  GCM clean() {
    _sKey.zero();
    return this;
  }

  /// Computes the GHASH-based authentication tag over [associatedData]
  /// and [ciphertext], XORed with [tagMask], writing it to [tagOut].
  void _authenticate(
    List<int> tagOut,
    List<int> tagMask,
    List<int> ciphertext, [
    List<int>? associatedData,
  ]) {
    _sKey.useValue((subKey) {
      final blockSize = _cipher.blockSize;
      if (associatedData != null) {
        for (int i = 0; i < associatedData.length; i += blockSize) {
          final slice = associatedData.sublist(
            i,
            math.min(i + blockSize, associatedData.length),
          );
          _addmul(tagOut, slice, subKey);
        }
      }

      for (int i = 0; i < ciphertext.length; i += blockSize) {
        final slice = ciphertext.sublist(
          i,
          math.min(i + blockSize, ciphertext.length),
        );
        _addmul(tagOut, slice, subKey);
      }

      final lengthsBlock = List<int>.filled(blockSize, 0);
      if (associatedData != null) {
        _writeBitLength(associatedData.length, lengthsBlock, 0);
      }
      _writeBitLength(ciphertext.length, lengthsBlock, 8);
      _addmul(tagOut, lengthsBlock, subKey);

      for (var i = 0; i < tagMask.length; i++) {
        tagOut[i] ^= tagMask[i];
      }

      BinaryOps.zero(lengthsBlock);
    });
  }

  /// Writes `byteLength * 8` as a big-endian 64-bit integer at `dst[offset...]`.
  void _writeBitLength(int byteLength, List<int> dst, [int offset = 0]) {
    final hi = (byteLength ~/ 0x20000000);
    final lo = byteLength << 3;
    BinaryOps.writeUint32BE(hi, dst, offset + 0);
    BinaryOps.writeUint32BE(lo, dst, offset + 4);
  }

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
      v3 = ((v2 << 31) & BinaryOps.mask32) | ((v3 >> 1) & BinaryOps.mask32);
      v2 = ((v1 << 31) & BinaryOps.mask32) | ((v2 >> 1) & BinaryOps.mask32);
      v1 = ((v0 << 31) & BinaryOps.mask32) | ((v1 >> 1) & BinaryOps.mask32);
      v0 = ((v0 >> 1) & BinaryOps.mask32) ^ (0xe1000000 & mask);
    }
    BinaryOps.writeUint32BE(z0, a, 0);
    BinaryOps.writeUint32BE(z1, a, 4);
    BinaryOps.writeUint32BE(z2, a, 8);
    BinaryOps.writeUint32BE(z3, a, 12);
  }
}
