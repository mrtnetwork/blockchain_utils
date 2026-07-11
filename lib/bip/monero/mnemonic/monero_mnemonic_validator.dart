import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_validator.dart';

/// A class for validating Monero mnemonics.
class MoneroMnemonicValidator extends MnemonicValidator {
  /// Constructs a MoneroMnemonicValidator with an optional language parameter.
  ///
  /// -[language]: The Monero language used for validation. Defaults to null.
  ///
  MoneroMnemonicValidator([MoneroLanguages? language])
    : super(MoneroMnemonicDecoder(language));
}
