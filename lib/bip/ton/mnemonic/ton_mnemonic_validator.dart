import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_ex.dart';
import 'ton_entropy_generator.dart';
import 'ton_mnemonic_generator.dart';

/// The TomMnemonicValidator class provides methods for validating TON (The Open Network)
/// mnemonic phrases. It ensures the mnemonic meets the required criteria for word count
/// and checks if a passphrase is needed or if it is a basic seed.
class TomMnemonicValidator {
  /// Validates the given mnemonic string, optionally with a password.
  void validate(Mnemonic mnemonic, {String password = ""}) {
    /// Validates the number of words in the mnemonic.
    TonMnemonicGeneratorUtils.validateWordsNum(mnemonic.wordsCount());

    /// Checks if the mnemonic requires a passphrase but one is not provided.
    if (password.isNotEmpty &&
        !TonEntropyGeneratorUtils.isPasswordNeed(mnemonic)) {
      throw const MnemonicException("Invalid Ton mnemonic. is Basic seed.");
    }

    /// Generates entropy from the mnemonic and passphrase, then checks if it is a basic seed.
    if (!TonEntropyGeneratorUtils.isBasicSeed(
        TonEntropyGeneratorUtils.generateEnteropy(mnemonic,
            password: password))) {
      throw const MnemonicException("Invalid Ton mnemonic.");
    }
  }

  /// Determines if the given mnemonic string is valid, optionally with a passphrase.
  bool isValid(Mnemonic mnemonic, {String password = ""}) {
    try {
      validate(mnemonic, password: password);
      return true;
    } catch (e) {
      return false;
    }
  }
}
