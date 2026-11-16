import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/protocol/ton/mnemonic/ton_entropy_generator.dart';
import 'package:blockchain_utils/protocol/ton/mnemonic/ton_mnemonic_generator.dart';

/// The TonMnemonicValidator class provides methods for validating TON (The Open Network)
/// mnemonic phrases. It ensures the mnemonic meets the required criteria for word count
/// and checks if a passphrase is needed or if it is a basic seed.
class TonMnemonicValidator {
  /// Validates the given mnemonic string, optionally with a password.
  void validate(Mnemonic mnemonic, {String password = ""}) {
    /// Validates the number of words in the mnemonic.
    TonMnemonicGeneratorUtils.validateWordsNum(mnemonic.wordsCount());

    /// Checks if the mnemonic requires a passphrase but one is not provided.
    if (password.isNotEmpty &&
        !TonEntropyGeneratorUtils.isPasswordNeed(mnemonic)) {
      throw CoreErrors.invalidOperationArguments(
        "validate",
        name: "mnemonic",
        reason: "Invalid ton mnemonic.",
      );
    }

    /// Generates entropy from the mnemonic and passphrase, then checks if it is a basic seed.
    if (!TonEntropyGeneratorUtils.isBasicSeed(
      TonEntropyGeneratorUtils.generateEntropy(mnemonic, password: password),
    )) {
      throw CoreErrors.invalidOperationArguments(
        "validate",
        name: "mnemonic",
        reason: "Invalid ton mnemonic.",
      );
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
