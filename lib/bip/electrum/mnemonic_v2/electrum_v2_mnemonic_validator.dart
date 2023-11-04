import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_validator.dart';

/// Validator class for Electrum V2 mnemonics.
class ElectrumV2MnemonicValidator extends MnemonicValidator {
  /// Creates a new instance of the Electrum V2 mnemonic validator.
  ///
  /// [v2mnemonicTypes] (Optional) The specific type of Electrum V2 mnemonic to validate.
  /// [language] (Optional) The language to use for validation.
  ElectrumV2MnemonicValidator(
      {ElectrumV2MnemonicTypes? v2mnemonicTypes, ElectrumV2Languages? language})
      : super(ElectrumV2MnemonicDecoder(
            mnemonicType: v2mnemonicTypes, language: language));
}
