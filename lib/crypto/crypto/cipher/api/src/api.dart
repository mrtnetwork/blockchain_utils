import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/aead/chacha20poly1305/chacha20poly1305.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/aes.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/padding.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constructs AES block ciphers and their modes (CBC, CTR, ECB).
abstract interface class BlockCipherApi {
  /// Creates AES with 16, 24 or 32-byte [key]. Throws on invalid key length.
  BuBlockCipher aes(List<int> key);

  /// Creates CBC mode with 16, 24 or 32-byte [aesKey] and 16-byte [iv]. Throws on invalid lengths.
  BuBlockCipherCbc aesCbc(List<int> aesKey, List<int> iv);

  /// Creates ECB mode with 16, 24 or 32-byte [key] and [padding] (PKCS7 default, null requires block-aligned input). Throws on invalid key length.
  BuAesEcb aesEcb(
    List<int> key, {
    PaddingAlgorithm? padding = PaddingAlgorithm.pkcs7,
  });

  /// Creates CTR mode with 16, 24 or 32-byte [key] and 16-byte [counter]. Throws on invalid lengths.
  BuAesCtr aesCtr(List<int> key, List<int> counter);
}

/// Constructs stream ciphers (ChaCha20).
abstract interface class StreamCipherApi {
  /// Creates ChaCha20 with 32-byte [key]. Throws on invalid key length.
  BuStreamCipher chacha20(List<int> key);
}

/// [StreamCipherApi] wrapper that validates key length before delegating.
class ValidatedStreamCipherApi implements StreamCipherApi {
  final StreamCipherApi _inner;
  const ValidatedStreamCipherApi(this._inner);

  @override
  BuStreamCipher chacha20(List<int> key) {
    ApiValidate.length(
      key,
      ChaCha20Poly1305.keyLength,
      operation: "chacha20",
      name: "key",
    );
    return _inner.chacha20(key);
  }
}

/// FF1 format-preserving encryption (NIST SP 800-38G).
abstract interface class Ff1Api {
  /// Encrypts digit bytes [pt] (each < [radix]) with 16, 24 or 32-byte [key], [radix] 2..65536 (Dart backend 2..256) and [tweak]. Returns same-length ciphertext. Throws on bad key/radix or empty pt.
  BuBytes encrypt({
    required List<int> key,
    required int radix,
    required List<int> pt,
    List<int> tweak = const [],
  });

  /// Decrypts digit bytes [ct] (each < [radix]) with 16, 24 or 32-byte [key], [radix] 2..65536 (Dart backend 2..256) and [tweak]. Returns same-length plaintext. Throws on bad key/radix or empty ct.
  BuBytes decrypt({
    required List<int> key,
    required int radix,
    required List<int> ct,
    List<int> tweak = const [],
  });

  /// Encrypts raw bytes [pt] (binary radix-2 FF1) with 16, 24 or 32-byte [key] and [tweak]. Returns same-length ciphertext. Throws on bad key or empty pt.
  BuBytes encryptBinary({
    required List<int> key,
    required List<int> pt,
    List<int> tweak = const [],
  });

  /// Decrypts raw bytes [ct] (binary radix-2 FF1) with 16, 24 or 32-byte [key] and [tweak]. Returns same-length plaintext. Throws on bad key or empty ct.
  BuBytes decryptBinary({
    required List<int> key,
    required List<int> ct,
    List<int> tweak = const [],
  });
}

/// [BlockCipherApi] wrapper that validates key/IV lengths before delegating.
class ValidatedBlockCipherApi implements BlockCipherApi {
  final BlockCipherApi _inner;
  const ValidatedBlockCipherApi(this._inner);
  @override
  BuBlockCipher aes(List<int> key) {
    ApiValidate.oneOfLengths(
      key,
      AES.allowedKeysLength,
      operation: "aes",
      name: "key",
    );
    return _inner.aes(key);
  }

  @override
  BuBlockCipherCbc aesCbc(List<int> aesKey, List<int> iv) {
    ApiValidate.oneOfLengths(
      aesKey,
      AES.allowedKeysLength,
      operation: "aesCbc",
      name: "aesKey",
    );
    ApiValidate.length(iv, 16, operation: "aesCbc", name: "iv");
    return _inner.aesCbc(aesKey, iv);
  }

  @override
  BuAesCtr aesCtr(List<int> key, List<int> counter) {
    ApiValidate.oneOfLengths(
      key,
      AES.allowedKeysLength,
      operation: "aesCtr",
      name: "key",
    );
    ApiValidate.length(counter, 16, operation: "aesCtr", name: "counter");
    return _inner.aesCtr(key, counter);
  }

  @override
  BuAesEcb aesEcb(
    List<int> key, {
    PaddingAlgorithm? padding = PaddingAlgorithm.pkcs7,
  }) {
    ApiValidate.oneOfLengths(
      key,
      AES.allowedKeysLength,
      operation: "aesEcb",
      name: "key",
    );
    return _inner.aesEcb(key, padding: padding);
  }
}

/// [Ff1Api] wrapper that validates arguments before delegating.
class ValidatedFf1Api implements Ff1Api {
  ValidatedFf1Api(this.inner);
  final Ff1Api inner;
  static const _tag = 'FF1';

  void _key(List<int> key) {
    ApiValidate.oneOfLengths(
      key,
      const [16, 24, 32],
      operation: _tag,
      name: 'key',
    );
  }

  void _radix(int radix) {
    if (radix < 2 || radix > 65536) {
      throw CoreErrors.invalidOperationArguments(
        _tag,
        name: 'radix',
        reason: 'radix must be in 2..65536',
      );
    }
  }

  @override
  BuBytes encrypt({
    required List<int> key,
    required int radix,
    required List<int> pt,
    List<int> tweak = const [],
  }) {
    _key(key);
    _radix(radix);
    ApiValidate.nonEmpty(pt, operation: '$_tag.encrypt', name: 'pt');
    return inner.encrypt(key: key, radix: radix, pt: pt, tweak: tweak);
  }

  @override
  BuBytes decrypt({
    required List<int> key,
    required int radix,
    required List<int> ct,
    List<int> tweak = const [],
  }) {
    _key(key);
    _radix(radix);
    ApiValidate.nonEmpty(ct, operation: '$_tag.decrypt', name: 'ct');
    return inner.decrypt(key: key, radix: radix, ct: ct, tweak: tweak);
  }

  @override
  BuBytes encryptBinary({
    required List<int> key,
    required List<int> pt,
    List<int> tweak = const [],
  }) {
    _key(key);
    ApiValidate.nonEmpty(pt, operation: '$_tag.encryptBinary', name: 'pt');
    return inner.encryptBinary(key: key, pt: pt, tweak: tweak);
  }

  @override
  BuBytes decryptBinary({
    required List<int> key,
    required List<int> ct,
    List<int> tweak = const [],
  }) {
    _key(key);
    ApiValidate.nonEmpty(ct, operation: '$_tag.decryptBinary', name: 'ct');
    return inner.decryptBinary(key: key, ct: ct, tweak: tweak);
  }
}
