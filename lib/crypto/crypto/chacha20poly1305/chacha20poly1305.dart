import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/aead/aead.dart';
import 'package:blockchain_utils/crypto/crypto/chacha/chacha.dart';
import 'package:blockchain_utils/crypto/crypto/poly1305/poly1305.dart';
import 'package:blockchain_utils/exception/exception.dart';

const int _nonceLength = 12;
const int _tagLength = 16;
const int _keyLength = 32;

class ChaCha20Poly1305 implements AEAD {
  /// Length of the nonce for ChaCha20-Poly1305 (12 bytes)
  @override
  final int nonceLength = _nonceLength;

  /// Length of the authentication tag
  @override
  final int tagLength = _tagLength;

  /// The encryption key for ChaCha20-Poly1305
  late List<int> _key;

  /// Creates a ChaCha20-Poly1305 instance with the given 32-byte encryption key.
  ChaCha20Poly1305(List<int> key) {
    if (key.length != _keyLength) {
      throw const ArgumentException("ChaCha20Poly1305 needs a 32-byte key");
    }
    _key = BytesUtils.toBytes(key);
  }

  /// Encrypts the provided plaintext data with ChaCha20-Poly1305 encryption.
  ///
  /// This method takes a nonce, plaintext data, and optional associated data and performs
  /// ChaCha20-Poly1305 encryption. It generates an authentication tag, and the encrypted data
  /// is returned in the `List<int>` `dst`. If `dst` is not provided, a new `List<int>` is created
  /// to hold the result.
  ///
  /// Parameters:
  /// - `nonce`: The nonce as a List<int>, with a maximum length of 16 bytes.
  /// - `plaintext`: The plaintext data to be encrypted.
  /// - `associatedData`: Optional associated data that is not encrypted but included in the tag calculation.
  /// - `dst`: An optional destination `List<int>` where the encrypted data and tag will be written.
  ///
  /// Throws:
  /// - `ArgumentException` if the provided nonce length is incorrect or if the destination length is incorrect.
  ///
  /// Returns:
  /// - The `List<int>` containing the encrypted data and authentication tag.
  ///
  /// Note: This method uses ChaCha20-Poly1305 encryption, including nonce handling, authentication tag calculation,
  /// and associated data processing.
  @override
  List<int> encrypt(List<int> nonce, List<int> plaintext,
      {List<int>? associatedData, List<int>? dst}) {
    if (nonce.length > 16) {
      throw const ArgumentException("ChaCha20Poly1305: incorrect nonce length");
    }

    final counter = List<int>.filled(16, 0);

    counter.setRange(counter.length - nonce.length, counter.length,
        BytesUtils.toBytes(nonce));

    final authKey = List<int>.filled(32, 0);
    ChaCha20.stream(_key, counter, authKey, nonceInplaceCounterLength: 4);

    final resultLength = plaintext.length + tagLength;

    List<int> result = dst ?? List<int>.filled(resultLength, 0);
    if (result.length != resultLength) {
      throw const ArgumentException(
          "ChaCha20Poly1305: incorrect destination length");
    }

    ChaCha20.streamXOR(_key, counter, BytesUtils.toBytes(plaintext), result,
        nonceInplaceCounterLength: 4);

    final calculatedTag = List<int>.filled(tagLength, 0);
    final cipherText = result.sublist(0, result.length - tagLength);
    _authenticate(calculatedTag, authKey, cipherText, associatedData);

    result.setRange(result.length - tagLength, result.length, calculatedTag);
    zero(counter);
    return result;
  }

  /// Decrypts the provided sealed data using ChaCha20-Poly1305 decryption.
  ///
  /// This method takes a nonce, sealed data (which includes the ciphertext and authentication tag),
  /// and optional associated data, and attempts to decrypt the sealed data. If the decryption is successful,
  /// the plaintext data is returned in the `List<int>` `dst`. If the decryption fails (e.g., due to an
  /// incorrect tag or nonce), `null` is returned.
  ///
  /// Parameters:
  /// - `nonce`: The nonce as a List<int>, with a maximum length of 16 bytes.
  /// - `sealed`: The sealed data, including the ciphertext and authentication tag.
  /// - `associatedData`: Optional associated data that is not encrypted but used in the tag verification.
  /// - `dst`: An optional destination `List<int>` where the decrypted plaintext will be written.
  ///
  /// Throws:
  /// - `ArgumentException` if the provided nonce length is incorrect or if the destination length is incorrect.
  ///
  /// Returns:
  /// - The `List<int>` containing the decrypted plaintext data, or `null` if decryption fails.
  ///
  /// Note: This method uses ChaCha20-Poly1305 decryption, including nonce handling, tag verification, and
  /// associated data processing. If the authentication tag is incorrect, `null` is returned to indicate
  /// decryption failure.
  @override
  List<int>? decrypt(List<int> nonce, List<int> sealed,
      {List<int>? associatedData, List<int>? dst}) {
    if (nonce.length > 16) {
      throw const ArgumentException("ChaCha20Poly1305: incorrect nonce length");
    }

    if (sealed.length < tagLength) {
      return null;
    }

    final counter = List<int>.filled(16, 0);
    counter.setRange(counter.length - nonce.length, counter.length, nonce);

    final authKey = List<int>.filled(32, 0);
    ChaCha20.stream(_key, counter, authKey, nonceInplaceCounterLength: 4);

    final calculatedTag = List<int>.filled(tagLength, 0);
    _authenticate(calculatedTag, authKey,
        sealed.sublist(0, sealed.length - tagLength), associatedData);

    if (!BytesUtils.bytesEqual(
        calculatedTag, sealed.sublist(sealed.length - tagLength))) {
      return null;
    }

    final resultLength = sealed.length - tagLength;

    List<int> result = dst ?? List<int>.filled(resultLength, 0);
    if (result.length != resultLength) {
      throw const ArgumentException(
          "ChaCha20Poly1305: incorrect destination length");
    }

    ChaCha20.streamXOR(
        _key, counter, sealed.sublist(0, sealed.length - tagLength), result,
        nonceInplaceCounterLength: 4);

    zero(counter);
    return result;
  }

  /// Clears and releases the internal encryption key for ChaCha20-Poly1305 for security and memory management.
  ///
  /// This method securely zeros and releases the internal encryption key used by the ChaCha20-Poly1305
  /// instance to ensure that no sensitive key data is left in memory. It is an essential step for
  /// maintaining the security of the cipher instance after use.
  ///
  /// Returns:
  /// - The same ChaCha20Poly1305 instance after cleaning for method chaining.
  @override
  ChaCha20Poly1305 clean() {
    zero(_key); // Securely zero the encryption key
    return this;
  }

  void _authenticate(List<int> tagOut, List<int> authKey, List<int> ciphertext,
      List<int>? associatedData) {
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
      writeUint64LE(associatedData.length, length);
    }
    h.update(length);

    writeUint64LE(ciphertext.length, length);
    h.update(length);

    final tag = h.digest();
    for (var i = 0; i < tag.length; i++) {
      tagOut[i] = tag[i];
    }

    h.clean();
    zero(tag);
    zero(length);
  }
}
