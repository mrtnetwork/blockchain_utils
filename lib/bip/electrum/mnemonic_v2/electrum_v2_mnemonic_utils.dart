import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_validator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_validator.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';

/// Constants related to Electrum V2 mnemonic utilities.
class ElectrumV2MnemonicUtilsConst {
  /// The HMAC key used in Electrum V2 mnemonic operations.
  static const List<int> hmacKey = [
    83,
    101,
    101,
    100,
    32,
    118,
    101,
    114,
    115,
    105,
    111,
    110
  ];
}

/// Utility class for working with Electrum V2 mnemonics.
class ElectrumV2MnemonicUtils {
  /// Checks if a mnemonic is a valid Electrum V2 mnemonic of the specified type.
  ///
  /// [mnemonic] The mnemonic to check.
  /// [mnemonicType] (Optional) The Electrum V2 mnemonic type to check against.
  /// If not provided, any type of Electrum V2 mnemonic will be accepted.
  ///
  /// Returns `true` if the mnemonic is valid for the specified type (or any type),
  /// otherwise returns `false`.
  static bool isValidMnemonic(Mnemonic mnemonic,
      [ElectrumV2MnemonicTypes? mnemonicType]) {
    if (_isBip39OrV1Mnemonic(mnemonic)) {
      return false;
    }
    return (mnemonicType != null
        ? _isType(mnemonic, mnemonicType)
        : _isAnyType(mnemonic));
  }

  /// Checks if the provided mnemonic is a Bip39 or Electrum V1 mnemonic.
  static bool _isBip39OrV1Mnemonic(Mnemonic mnemonic) {
    return Bip39MnemonicValidator().isValid(mnemonic.toStr()) ||
        ElectrumV1MnemonicValidator().isValid(mnemonic.toStr());
  }

  /// Checks if the mnemonic matches any type of Electrum V2 mnemonic.
  static bool _isAnyType(Mnemonic mnemonic) {
    final h = BytesUtils.toHexString(QuickCrypto.hmacSha512Hash(
        ElectrumV2MnemonicUtilsConst.hmacKey,
        StringUtils.encode(mnemonic.toStr())));
    for (var mnemonicType in ElectrumV2MnemonicTypes.values) {
      if (h.startsWith(ElectrumV2MnemonicConst.typeToPrefix[mnemonicType]!)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if the mnemonic matches a specific type of Electrum V2 mnemonic.
  static bool _isType(Mnemonic mnemonic, ElectrumV2MnemonicTypes mnemonicType) {
    final h = BytesUtils.toHexString(QuickCrypto.hmacSha512Hash(
        ElectrumV2MnemonicUtilsConst.hmacKey,
        StringUtils.encode(mnemonic.toStr())));

    return h.startsWith(ElectrumV2MnemonicConst.typeToPrefix[mnemonicType]!);
  }
}
