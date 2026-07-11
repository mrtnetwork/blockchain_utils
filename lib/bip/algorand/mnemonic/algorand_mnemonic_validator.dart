import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_validator.dart';

/// A validator for Algorand mnemonic phrases.
class AlgorandMnemonicValidator extends MnemonicValidator {
  /// The [AlgorandMnemonicValidator] class is used to validate Algorand
  AlgorandMnemonicValidator([
    AlgorandLanguages? language = AlgorandLanguages.english,
  ]) : super(AlgorandMnemonicDecoder(language));
}
