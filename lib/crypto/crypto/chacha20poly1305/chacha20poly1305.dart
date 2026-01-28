import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils/crypto/crypto/aead/aead.dart';
import 'package:blockchain_utils/crypto/crypto/chacha/chacha.dart';
import 'package:blockchain_utils/crypto/crypto/poly1305/poly1305.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

class ChaCha20Poly1305 implements AEAD {
  final int _keyLength = 32;

  /// Length of the nonce for ChaCha20-Poly1305 (12 bytes)
  @override
  int get nonceLength => 20;

  /// Length of the authentication tag
  @override
  int get tagLength => 16;

  /// The encryption key for ChaCha20-Poly1305
  late List<int> _key;

  /// Creates a ChaCha20-Poly1305 instance with the given 32-byte encryption key.
  ChaCha20Poly1305(List<int> key) {
    if (key.length != _keyLength) {
      throw ArgumentException.invalidOperationArguments(
        "ChaCha20Poly1305",
        name: "key",
        reason: "Invalid key bytes length.",
        expecteLen: _keyLength,
      );
    }
    _key = key.clone().asBytes;
  }

  /// Encrypts the provided plaintext data with ChaCha20-Poly1305 encryption.
  ///
  /// Parameters:
  /// - [nonce]: The nonce as a `List<int>`, with a maximum length of 16 bytes.
  /// - [plaintext]: The plaintext data to be encrypted.
  /// - [associatedData]: Optional associated data that is not encrypted but included in the tag calculation.
  /// - [dst]: An optional destination `List<int>` where the encrypted data and tag will be written.
  ///
  /// Throws:
  /// - [ArgumentException] if the provided nonce length is incorrect or if the destination length is incorrect.
  @override
  List<int> encrypt(
    List<int> nonce,
    List<int> plaintext, {
    List<int>? associatedData,
    List<int>? dst,
  }) {
    if (nonce.length > 16) {
      throw ArgumentException.invalidOperationArguments(
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

    final authKey = List<int>.filled(32, 0);
    ChaCha20.stream(_key, counter, authKey, nonceInplaceCounterLength: 4);

    final resultLength = plaintext.length + tagLength;

    final List<int> result = dst ?? List<int>.filled(resultLength, 0);
    if (result.length != resultLength) {
      throw ArgumentException.invalidOperationArguments(
        "encrypt",
        name: "dst",
        reason: "Invalid destination bytes length.",
        expecteLen: resultLength,
      );
    }

    ChaCha20.streamXOR(
      _key,
      counter,
      plaintext.asBytes,
      result,
      nonceInplaceCounterLength: 4,
    );

    final calculatedTag = List<int>.filled(tagLength, 0);
    final cipherText = result.sublist(0, result.length - tagLength);
    _authenticate(calculatedTag, authKey, cipherText, associatedData);

    result.setRange(result.length - tagLength, result.length, calculatedTag);
    BinaryOps.zero(counter);
    return result;
  }

  /// Decrypts the provided sealed data using ChaCha20-Poly1305 decryption.
  ///
  /// Parameters:
  /// - [nonce]: The nonce, with a maximum length of 16 bytes.
  /// - [sealed]: The sealed data, including the ciphertext and authentication tag.
  /// - [associatedData]: Optional associated data that is not encrypted but used in the tag verification.
  /// - [dst]: An optional destination  where the decrypted plaintext will be written.
  ///
  /// Throws:
  /// - [ArgumentException] if the provided nonce length is incorrect or if the destination length is incorrect.
  @override
  List<int>? decrypt(
    List<int> nonce,
    List<int> sealed, {
    List<int>? associatedData,
    List<int>? dst,
  }) {
    if (nonce.length > 16) {
      throw ArgumentException.invalidOperationArguments(
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

    final authKey = List<int>.filled(32, 0);
    ChaCha20.stream(_key, counter, authKey, nonceInplaceCounterLength: 4);

    final calculatedTag = List<int>.filled(tagLength, 0);
    _authenticate(
      calculatedTag,
      authKey,
      sealed.sublist(0, sealed.length - tagLength),
      associatedData,
    );

    if (!BytesUtils.bytesEqual(
      calculatedTag,
      sealed.sublist(sealed.length - tagLength),
    )) {
      return null;
    }

    final resultLength = sealed.length - tagLength;

    final List<int> result = dst ?? List<int>.filled(resultLength, 0);
    if (result.length != resultLength) {
      throw ArgumentException.invalidOperationArguments(
        "decrypt",
        name: "dst",
        reason: "Invalid destination bytes length.",
        expecteLen: resultLength,
      );
    }

    ChaCha20.streamXOR(
      _key,
      counter,
      sealed.sublist(0, sealed.length - tagLength),
      result,
      nonceInplaceCounterLength: 4,
    );

    BinaryOps.zero(counter);
    return result;
  }

  /// Clears and releases the internal encryption key for ChaCha20-Poly1305 for security and memory management.
  @override
  ChaCha20Poly1305 clean() {
    BinaryOps.zero(_key); // Securely zero the encryption key
    return this;
  }

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
