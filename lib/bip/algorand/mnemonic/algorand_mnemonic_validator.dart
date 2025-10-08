import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic.dart';
import 'package:blockchain_utils/bip/algorand/mnemonic/algorand_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_validator.dart';

/// A validator for Algorand mnemonic phrases.
class AlgorandMnemonicValidator extends MnemonicValidator {
  /// The [AlgorandMnemonicValidator] class is used to validate Algorand
  /// mnemonic phrases. It utilizes the [AlgorandMnemonicDecoder] to decode the
  /// mnemonic and verify its integrity.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final validator = AlgorandMnemonicValidator(AlgorandLanguages.english);
  /// final isValid = validator.isValidMnemonic("your mnemonic phrase here");
  /// ```
  ///
  /// The [isValid] method can be used to check the validity of a given
  /// mnemonic phrase.
  AlgorandMnemonicValidator(
      [AlgorandLanguages? language = AlgorandLanguages.english])
      : super(AlgorandMnemonicDecoder(language));
}
