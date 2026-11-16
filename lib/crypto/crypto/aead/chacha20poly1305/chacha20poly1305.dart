import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils/crypto/crypto/aead/core/aead.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/stream_cipher/chacha/chacha.dart';
import 'package:blockchain_utils/crypto/crypto/aead/chacha20poly1305/poly1305.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// ChaCha20-Poly1305 (RFC 8439) AEAD cipher.
class ChaCha20Poly1305 implements AEAD {
  static const int keyLength = 32;

  /// Length of the nonce for ChaCha20-Poly1305 (12 bytes)
  @override
  int get nonceLength => 12;

  /// Length of the authentication tag
  @override
  int get tagLength => 16;

  /// The encryption key for ChaCha20-Poly1305
  late final ChaCha20 chacha;

  /// Creates a ChaCha20-Poly1305 instance with the given 32-byte encryption key.
  ChaCha20Poly1305(List<int> key) {
    if (key.length != keyLength) {
      throw CoreErrors.invalidOperationArguments(
        "ChaCha20Poly1305",
        name: "key",
        reason: "Invalid key bytes length.",
      );
    }
    chacha = ChaCha20(key);
  }

  /// Encrypts [plaintext] with [nonce] (up to 16 bytes, left-zero-padded;
  /// 12 bytes per RFC 8439), authenticating [associatedData] too. Returns
  /// ciphertext || 16-byte tag.
  ///
  /// The one-time Poly1305 key and the counter are wiped before returning,
  /// including on failure.
  @override
  BuBytes encrypt(
    List<int> nonce,
    List<int> plaintext, {
    List<int>? associatedData,
    List<int>? dst,
  }) {
    if (nonce.length > 16) {
      throw CoreErrors.invalidOperationArguments(
        "encrypt",
        name: "nonce",
        reason: "Invalid nonce bytes length.",
      );
    }

    final counter = List<int>.filled(16, 0);

    counter.setRange(
      counter.length - nonce.length,
      counter.length,
      nonce.asBytes,
    );

    final authKey = BuBytes.fill(32, 0);
    try {
      chacha.stream(counter, authKey, nonceInplaceCounterLength: 4);
      final resultLength = plaintext.length + tagLength;
      final BuBytes result = BuBytes.unsafeMutable(
        dst ?? List<int>.filled(resultLength, 0),
      );
      if (result.length != resultLength) {
        throw CoreErrors.invalidOperationArguments(
          "encrypt",
          name: "dst",
          reason: "Invalid destination bytes length.",
        );
      }

      chacha.process(
        plaintext,
        nonce: counter,
        dst: result,
        nonceInplaceCounterLength: 4,
      );

      final calculatedTag = List<int>.filled(tagLength, 0);
      final cipherText = result.sublist(0, result.length - tagLength);
      _authenticate(calculatedTag, authKey, cipherText, associatedData);
      result.setRange(result.length - tagLength, result.length, calculatedTag);
      BinaryOps.zero(calculatedTag);
      return result;
    } finally {
      BinaryOps.zero(counter);
      authKey.forceZero();
    }
  }

  /// Decrypts [sealed] (ciphertext || tag) with [nonce] and
  /// [associatedData]. Returns null if authentication fails.
  ///
  /// The tag comparison is constant-time; the one-time Poly1305 key and
  /// the counter are wiped before returning, including on failure.
  @override
  BuBytes? decrypt(
    List<int> nonce,
    List<int> sealed, {
    List<int>? associatedData,
    List<int>? dst,
  }) {
    if (nonce.length > 16) {
      throw CoreErrors.invalidOperationArguments(
        "decrypt",
        name: "nonce",
        reason: "Invalid nonce bytes length.",
      );
    }

    if (sealed.length < tagLength) {
      return null;
    }

    final counter = List<int>.filled(16, 0);
    counter.setRange(counter.length - nonce.length, counter.length, nonce);

    final authKey = BuBytes.fill(32, 0);
    final calculatedTag = List<int>.filled(tagLength, 0);
    try {
      chacha.stream(counter, authKey, nonceInplaceCounterLength: 4);
      _authenticate(
        calculatedTag,
        authKey,
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
          reason: "Invalid destination bytes length.",
        );
      }

      chacha.process(
        sealed.sublist(0, sealed.length - tagLength),
        nonce: counter,
        dst: result,
        nonceInplaceCounterLength: 4,
      );

      return result;
    } finally {
      BinaryOps.zero(counter);
      authKey.forceZero();
      BinaryOps.zero(calculatedTag);
    }
  }

  /// Securely zeroes the encryption key.
  @override
  ChaCha20Poly1305 clean() {
    chacha.clean();
    return this;
  }

  /// Computes the Poly1305 tag over [associatedData] and [ciphertext]
  /// (each padded to a 16-byte boundary, per RFC 8439), writing it to [tagOut].
  void _authenticate(
    List<int> tagOut,
    List<int> authKey,
    List<int> ciphertext,
    List<int>? associatedData,
  ) {
    final h = Poly1305(authKey);

    if (associatedData != null) {
      h.update(associatedData);
      if (associatedData.length % 16 > 0) {
        h.update(List<int>.filled(16 - (associatedData.length % 16), 0));
      }
    }

    h.update(ciphertext);
    if (ciphertext.length % 16 > 0) {
      h.update(List<int>.filled(16 - (ciphertext.length % 16), 0));
    }

    final length = List<int>.filled(8, 0);
    if (associatedData != null) {
      BinaryOps.writeUint64LE(associatedData.length, length);
    }
    h.update(length);

    BinaryOps.writeUint64LE(ciphertext.length, length);
    h.update(length);

    final tag = h.digest();
    for (var i = 0; i < tag.length; i++) {
      tagOut[i] = tag[i];
    }

    h.clean();
    BinaryOps.zero(tag);
    BinaryOps.zero(length);
  }
}
