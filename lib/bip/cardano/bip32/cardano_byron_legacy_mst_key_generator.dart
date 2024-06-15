import 'package:blockchain_utils/bip/bip/bip32/base/ibip32_mst_key_generator.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/cbor/types/bytes.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// A class that holds constants related to the Cardano Byron legacy master key generation process.
class CardanoByronLegacyMstKeyGeneratorConst {
  /// The HMAC message format used in the generation of master keys.
  static const String hmacMessageFormat = "Root Seed Chain ";

  /// The length of the seed in bytes.
  static const int seedByteLen = 32;
}

/// A class responsible for generating master keys for Cardano Byron legacy accounts.
class CardanoByronLegacyMstKeyGenerator extends IBip32MstKeyGenerator {
  /// Generates master keys from the provided seed bytes.
  @override
  Tuple<List<int>, List<int>> generateFromSeed(List<int> seedBytes) {
    if (seedBytes.length !=
        CardanoByronLegacyMstKeyGeneratorConst.seedByteLen) {
      throw ArgumentException('Invalid seed length (${seedBytes.length})');
    }
    return _hashRepeatedly(CborBytesValue(seedBytes).encode(), 1);
  }

  /// Recursively hashes and tweaks the provided data bytes to derive master keys.
  Tuple<List<int>, List<int>> _hashRepeatedly(List<int> dataBytes, int itrNum) {
    final halves = QuickCrypto.hmacSha512HashHalves(
        dataBytes,
        List<int>.from([
          ...(CardanoByronLegacyMstKeyGeneratorConst.hmacMessageFormat +
                  itrNum.toString())
              .codeUnits,
        ]));
    List<int> keyBytes =
        _tweakMasterKeyBits(QuickCrypto.sha512Hash(halves.item1));
    if (BitUtils.areBitsSet(keyBytes[31], 0x20)) {
      return _hashRepeatedly(dataBytes, itrNum + 1);
    }
    return Tuple(keyBytes, halves.item2);
  }

  /// Tweaks the master key bits as part of the derivation process.
  static List<int> _tweakMasterKeyBits(List<int> keyBytes) {
    keyBytes = List<int>.from(keyBytes);
    // Clear the lowest 3 bits of the first byte of kL
    keyBytes[0] = BitUtils.resetBits(keyBytes[0], 0x07);
    // Clear the highest bit of the last byte of kL
    keyBytes[31] = BitUtils.resetBits(keyBytes[31], 0x80);
    // Set the second-highest bit of the last byte of kL
    keyBytes[31] = BitUtils.setBits(keyBytes[31], 0x40);
    return keyBytes;
  }
}
