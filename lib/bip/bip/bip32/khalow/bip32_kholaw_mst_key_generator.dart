import 'package:blockchain_utils/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_mst_key_generator.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

class Bip32KholawEd25519MstKeyGenerator implements IBip32MstKeyGenerator {
  /// The minimum byte length for the seed when generating a master key.
  final int seedMinByteLen = Bip32Slip10MstKeyGeneratorConst.seedMinByteLen;

  /// The HMAC key for Ed25519 keys used in master key generation.
  final List<int> masterKeyHmacKey =
      Bip32Slip10MstKeyGeneratorConst.hmacKeyEd25519Bytes;

  /// Generate a master key for Bip32KholawEd25519 keys from a seed.
  @override
  Bip32MasterKey generateFromSeed(List<int> seedBytes) {
    if (seedBytes.length < seedMinByteLen) {
      throw ArgumentException.invalidOperationArguments(
        "generateFromSeed",
        name: "seedBytes",
        reason: "Invalid seed length.",
      );
    }
    final hashDigest = _hashRepeatedly(seedBytes, masterKeyHmacKey);
    final tweak = _tweakMasterKeyBits(hashDigest.$1);
    final chainCode = QuickCrypto.hmacsha256Hash(masterKeyHmacKey, [
      0x01,
      ...seedBytes,
    ]);
    return Bip32MasterKey(
      chainCode: Bip32ChainCode(chainCode),
      key: [...tweak, ...hashDigest.$2],
    );
  }

  /// Repeatedly hashing
  static (List<int>, List<int>) _hashRepeatedly(
    List<int> dataBytes,
    List<int> hmacKeyBytes,
  ) {
    final halves = QuickCrypto.hmacSha512HashHalves(hmacKeyBytes, dataBytes);

    if ((halves.$1[31] & 0x20) != 0) {
      return _hashRepeatedly([...halves.$1, ...halves.$2], hmacKeyBytes);
    }

    return halves;
  }

  /// Tweak the bits of the master key bytes for Bip32KholawEd25519.
  static List<int> _tweakMasterKeyBits(List<int> keyBytes) {
    final List<int> keyBytesList = keyBytes.toList();
    // Clear the lowest 3 bits of the first byte of kL
    keyBytesList[0] = keyBytesList[0] & 0xF8;
    // Clear the highest bit of the last byte of kL
    keyBytesList[31] = keyBytesList[31] & 0x7F;
    // Set the second-highest bit of the last byte of kL
    keyBytesList[31] = keyBytesList[31] | 0x40;

    return keyBytesList;
  }
}
