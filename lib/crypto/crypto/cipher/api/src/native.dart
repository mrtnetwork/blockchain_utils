import 'package:blockchain_utils/crypto/crypto/cipher/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/padding.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [BlockCipherApi] backed by a native (FFI/platform) implementation.
class NativeBlockCipherApi implements BlockCipherApi {
  final BuBlockCipherApi api;
  const NativeBlockCipherApi(this.api);
  @override
  BuBlockCipher aes(List<int> key) {
    return api.aes(key).unwrapOrThrowCryptoError();
  }

  @override
  BuBlockCipherCbc aesCbc(List<int> aesKey, List<int> iv) {
    return api.aesCbc(aesKey, iv).unwrapOrThrowCryptoError();
  }

  @override
  BuAesCtr aesCtr(List<int> key, List<int> counter) {
    return api.aesCtr(key, counter).unwrapOrThrowCryptoError();
  }

  @override
  BuAesEcb aesEcb(
    List<int> key, {
    PaddingAlgorithm? padding = PaddingAlgorithm.pkcs7,
  }) {
    return api
        .aesEcb(
          key,
          padding: padding?.connectorAlgorithm ?? BuPaddingAlgorithm.none,
        )
        .unwrapOrThrowCryptoError();
  }
}

/// [StreamCipherApi] backed by a native (FFI/platform) implementation.
class NativeStreamCipherApi implements StreamCipherApi {
  final BuStreamCipherApi api;
  const NativeStreamCipherApi(this.api);
  @override
  BuStreamCipher chacha20(List<int> key) {
    return api.chacha20(key).unwrapOrThrowCryptoError();
  }
}

/// [Ff1Api] backed by a native (FFI/platform) implementation.
class NativeFf1Api implements Ff1Api {
  NativeFf1Api(this._api);
  final BuFf1Api _api;

  @override
  BuBytes encrypt({
    required List<int> key,
    required int radix,
    required List<int> pt,
    List<int> tweak = const [],
  }) =>
      _api
          .encrypt(key: key, radix: radix, pt: pt, tweak: tweak)
          .unwrapOrThrowCryptoError()
          .asBytes;

  @override
  BuBytes decrypt({
    required List<int> key,
    required int radix,
    required List<int> ct,
    List<int> tweak = const [],
  }) =>
      _api
          .decrypt(key: key, radix: radix, ct: ct, tweak: tweak)
          .unwrapOrThrowCryptoError()
          .asBytes;

  @override
  BuBytes encryptBinary({
    required List<int> key,
    required List<int> pt,
    List<int> tweak = const [],
  }) =>
      _api
          .encryptBinary(key: key, pt: pt, tweak: tweak)
          .unwrapOrThrowCryptoError()
          .asBytes;

  @override
  BuBytes decryptBinary({
    required List<int> key,
    required List<int> ct,
    List<int> tweak = const [],
  }) =>
      _api
          .decryptBinary(key: key, ct: ct, tweak: tweak)
          .unwrapOrThrowCryptoError()
          .asBytes;
}
