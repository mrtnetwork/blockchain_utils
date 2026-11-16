import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/aes.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/padding.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/core/blockcipher.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/cbc/cbc.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/ctr/ctr.dart';
import 'package:blockchain_utils/crypto/crypto/aead/ecb/ecb.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/ff1/src/ff1.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/ff1/src/types.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/stream_cipher/chacha/chacha.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [BlockCipherApi] backed by this package's pure-Dart [AES].
class DartBlockCipherApi implements BlockCipherApi {
  @override
  BlockCipher aes(List<int> key) {
    return AES(key);
  }

  @override
  BlockCipherCbc aesCbc(List<int> aesKey, List<int> iv) {
    return CBC(aes(aesKey), iv);
  }

  @override
  BuAesCtr aesCtr(List<int> key, List<int> counter) {
    return CTR(aes(key), counter);
  }

  @override
  BuAesEcb aesEcb(
    List<int> key, {
    PaddingAlgorithm? padding = PaddingAlgorithm.pkcs7,
  }) {
    return ECB(key, paddingStyle: padding);
  }
}

/// [StreamCipherApi] backed by this package's pure-Dart [ChaCha20].
class DartStreamCipherApi implements StreamCipherApi {
  @override
  BuStreamCipher chacha20(List<int> key) {
    return ChaCha20(key);
  }
}

/// [Ff1Api] backed by this package's pure-Dart [FF1Flexible]/[FF1Binary].
class DartFf1Api implements Ff1Api {
  BlockCipherApi get blockCipherApi => blockchainUtils.api.blockCipher;

  /// FF1 digits are returned as one byte each, so this API can only express
  /// radices that fit in a byte. [FF1Flexible] itself has no such limit —
  /// use it directly for a larger radix.
  static void _checkRadix(int radix, String operation) {
    if (radix < 2 || radix > 256) {
      throw CoreErrors.invalidOperationArguments(
        operation,
        name: "radix",
        reason: "radix must be in 2..256 to be representable as bytes.",
      );
    }
  }

  @override
  BuBytes decrypt({
    required List<int> key,
    required int radix,
    required List<int> ct,
    List<int> tweak = const [],
  }) {
    _checkRadix(radix, "FF1.decrypt");
    final ff1 = FF1Flexible(aes: blockCipherApi.aes(key), radix: radix);
    final dec = ff1.decrypt(FlexibleNumeralString(ct), tweak: tweak);
    return dec.digits.asBytes;
  }

  @override
  BuBytes decryptBinary({
    required List<int> key,
    required List<int> ct,
    List<int> tweak = const [],
  }) {
    final ff1 = FF1Binary(aes: blockCipherApi.aes(key));
    final dec = ff1.decrypt(BinaryNumeralString(ct), tweak: tweak);
    return dec.data;
  }

  @override
  BuBytes encrypt({
    required List<int> key,
    required int radix,
    required List<int> pt,
    List<int> tweak = const [],
  }) {
    _checkRadix(radix, "FF1.encrypt");
    final ff1 = FF1Flexible(aes: blockCipherApi.aes(key), radix: radix);
    final enc = ff1.encrypt(FlexibleNumeralString(pt), tweak: tweak);
    return enc.digits.asBytes;
  }

  @override
  BuBytes encryptBinary({
    required List<int> key,
    required List<int> pt,
    List<int> tweak = const [],
  }) {
    final ff1 = FF1Binary(aes: blockCipherApi.aes(key));
    final enc = ff1.encrypt(BinaryNumeralString(pt), tweak: tweak);
    return enc.data;
  }
}
