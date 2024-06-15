import 'package:blockchain_utils/bip/bip/bip32/base/ibip32_mst_key_generator.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_mst_key_generator.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_kholaw_keys.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/hmac/hmac.dart';
import 'package:blockchain_utils/crypto/crypto/pbkdf2/pbkdf2.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// A class that holds constants related to the Cardano Icarus master key generation process.
class CardanoIcarusMasterKeyGeneratorConst {
  /// The password used in the PBKDF2 key derivation process.
  static const String pbkdf2Password = '';

  /// The number of rounds for the PBKDF2 key derivation process.
  static const int pbkdf2Rounds = 4096;

  /// The length of the output bytes from the PBKDF2 key derivation process.
  static const int pbkdf2OutByteLen = 96;
}

/// A class responsible for generating master keys using the Cardano Icarus master key generation process.
class CardanoIcarusMstKeyGenerator implements IBip32MstKeyGenerator {
  /// Generates master keys from the provided seed bytes.
  @override
  Tuple<List<int>, List<int>> generateFromSeed(List<int> seedBytes) {
    if (seedBytes.length < Bip32Slip10MstKeyGeneratorConst.seedMinByteLen) {
      throw ArgumentException('Invalid seed length (${seedBytes.length})');
    }
    List<int> keyBytes = PBKDF2.deriveKey(
        salt: seedBytes,
        mac: () => HMAC(
            () => SHA512(),
            StringUtils.encode(
                CardanoIcarusMasterKeyGeneratorConst.pbkdf2Password)),
        iterations: CardanoIcarusMasterKeyGeneratorConst.pbkdf2Rounds,
        length: CardanoIcarusMasterKeyGeneratorConst.pbkdf2OutByteLen);

    keyBytes = _tweakMasterKeyBits(keyBytes);

    return Tuple(
      keyBytes.sublist(0, Ed25519KholawKeysConst.privKeyByteLen),
      keyBytes.sublist(Ed25519KholawKeysConst.privKeyByteLen),
    );
  }

  /// Tweak the master key bits as part of the derivation process.
  static List<int> _tweakMasterKeyBits(List<int> keyBytes) {
    keyBytes = List<int>.from(keyBytes);
    // Clear the lowest 3 bits of the first byte of kL
    keyBytes[0] = BitUtils.resetBits(keyBytes[0], 0x07);
    // Clear the highest 3 bits of the last byte of kL (standard kholaw only clears the highest one)
    keyBytes[31] = BitUtils.resetBits(keyBytes[31], 0xE0);
    // Set the second-highest bit of the last byte of kL
    keyBytes[31] = BitUtils.setBits(keyBytes[31], 0x40);

    return keyBytes;
  }
}
