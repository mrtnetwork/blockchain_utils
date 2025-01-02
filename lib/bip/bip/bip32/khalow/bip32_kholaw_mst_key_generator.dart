import 'package:blockchain_utils/bip/bip/bip32/base/ibip32_mst_key_generator.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_mst_key_generator.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Constants for generating master keys for Bip32KholawEd25519 keys.
///
/// This class contains constants related to generating master keys for Bip32KholawEd25519 keys,
/// such as the minimum seed byte length and the HMAC key for Ed25519 keys.
class Bip32KholawMstKeyGeneratorConst {
  /// The minimum byte length for the seed when generating a master key.
  static int seedMinByteLen = Bip32Slip10MstKeyGeneratorConst.seedMinByteLen;

  /// The HMAC key for Ed25519 keys used in master key generation.
  static List<int> masterKeyHmacKey =
      Bip32Slip10MstKeyGeneratorConst.hmacKeyEd25519Bytes;
}

class Bip32KholawEd25519MstKeyGenerator implements IBip32MstKeyGenerator {
  /// Generate a master key for Bip32KholawEd25519 keys from a seed.
  ///
  /// This method generates a master key for Bip32KholawEd25519 keys from a given seed.
  ///
  /// Parameters:
  /// - `seedBytes`: The seed data used to generate the master key.
  ///
  /// Returns a tuple of two `List<int>` values:
  /// 1. The master private key bytes.
  /// 2. The chain code bytes associated with the master key.
  ///
  /// Throws an `ArgumentException` if the seed length is less than the required minimum.
  ///
  /// The generation process involves repeated hashing of the seed and HMAC-SHA256 computations.
  ///
  /// This method is used in the context of master key generation for Bip32KholawEd25519 keys.
  ///
  /// Note: The constants for seed minimum length and HMAC key are retrieved from `Bip32KholawMstKeyGeneratorConst`.
  ///
  /// For detailed steps of the generation process, refer to the source code and relevant documentation.
  ///
  /// Returns:
  /// A tuple of two `List<int>` values - the master private key and the chain code.
  @override
  Tuple<List<int>, List<int>> generateFromSeed(List<int> seedBytes) {
    if (seedBytes.length < Bip32KholawMstKeyGeneratorConst.seedMinByteLen) {
      throw const ArgumentException("Invalid seed length");
    }
    final hashDigest = _hashRepeatedly(seedBytes,
        List<int>.from(Bip32KholawMstKeyGeneratorConst.masterKeyHmacKey));
    final tweak = _tweakMasterKeyBits(hashDigest.item1);
    final chainCode = QuickCrypto.hmacsha256Hash(
        List<int>.from(Bip32KholawMstKeyGeneratorConst.masterKeyHmacKey),
        List<int>.from([0x01, ...seedBytes]));

    return Tuple(List<int>.from([...tweak, ...hashDigest.item2]), chainCode);
  }

  /// Repeatedly hashing
  static Tuple<List<int>, List<int>> _hashRepeatedly(
      List<int> dataBytes, List<int> hmacKeyBytes) {
    final halves = QuickCrypto.hmacSha512HashHalves(hmacKeyBytes, dataBytes);

    if ((halves.item1[31] & 0x20) != 0) {
      return _hashRepeatedly(
          List<int>.from([...halves.item1, ...halves.item2]), hmacKeyBytes);
    }

    return halves;
  }

  /// Tweak the bits of the master key bytes for Bip32KholawEd25519.
  ///
  /// This method tweaks the bits of the provided master key bytes according to the
  /// specific requirements for Bip32KholawEd25519 keys.
  ///
  /// Parameters:
  /// - `keyBytes`: The master key bytes to be tweaked.
  ///
  /// Returns:
  /// A `List<int>` with the tweaked master key bits.
  ///
  /// The tweak involves modifying specific bits in the master key bytes:
  /// - Clear the lowest 3 bits of the first byte of kL.
  /// - Clear the highest bit of the last byte of kL.
  /// - Set the second-highest bit of the last byte of kL.
  ///
  /// The purpose of these tweaks is to ensure that the generated master key is
  /// compliant with the requirements for Bip32KholawEd25519 keys.
  ///
  /// This method is used as part of the master key generation process.
  ///
  /// For details on why these specific bits are modified, refer to the source code
  /// and relevant documentation.
  ///
  /// Note: This method is called within the `generateFromSeed` method to prepare
  /// the master key bits.
  static List<int> _tweakMasterKeyBits(List<int> keyBytes) {
    final List<int> keyBytesList = keyBytes.toList();
    // Clear the lowest 3 bits of the first byte of kL
    keyBytesList[0] = keyBytesList[0] & 0xF8;
    // Clear the highest bit of the last byte of kL
    keyBytesList[31] = keyBytesList[31] & 0x7F;
    // Set the second-highest bit of the last byte of kL
    keyBytesList[31] = keyBytesList[31] | 0x40;

    return List<int>.from(keyBytesList);
  }
}
