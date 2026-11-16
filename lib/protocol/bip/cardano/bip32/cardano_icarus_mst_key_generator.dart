import 'package:blockchain_utils/protocol/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_mst_key_generator.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/bit_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

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
  Bip32MasterKey generateFromSeed(List<int> seedBytes) {
    if (seedBytes.length < Bip32Slip10MstKeyGeneratorConst.seedMinByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "generateFromSeed",
        name: "seedBytes",
        reason: "Invalid seed bytes length.",
      );
    }
    List<int> keyBytes = QuickCrypto.pbkdf2Sha512DeriveKey(
      password: StringUtils.encode(
        CardanoIcarusMasterKeyGeneratorConst.pbkdf2Password,
      ),
      salt: seedBytes,
      iterations: CardanoIcarusMasterKeyGeneratorConst.pbkdf2Rounds,
      dklen: CardanoIcarusMasterKeyGeneratorConst.pbkdf2OutByteLen,
    );

    keyBytes = _tweakMasterKeyBits(keyBytes);

    return Bip32MasterKey(
      key: keyBytes.sublist(0, Ed25519KeysConst.kholawPrivKeyLen),
      chainCode: Bip32ChainCode(
        keyBytes.sublist(Ed25519KeysConst.kholawPrivKeyLen),
      ),
    );
  }

  /// Tweak the master key bits as part of the derivation process.
  static List<int> _tweakMasterKeyBits(List<int> keyBytes) {
    keyBytes = keyBytes.clone();
    // Clear the lowest 3 bits of the first byte of kL
    keyBytes[0] = BitUtils.resetBits(keyBytes[0], 0x07);
    // Clear the highest 3 bits of the last byte of kL (standard kholaw only clears the highest one)
    keyBytes[31] = BitUtils.resetBits(keyBytes[31], 0xE0);
    // Set the second-highest bit of the last byte of kL
    keyBytes[31] = BitUtils.setBits(keyBytes[31], 0x40);

    return keyBytes;
  }
}
