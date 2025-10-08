import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic.dart';
import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_validator.dart';

/// A class for validating Monero mnemonics.
///
/// This class extends `MnemonicValidator` and is specialized for validating Monero mnemonics.
/// It uses a `MoneroMnemonicDecoder` for decoding and validating Monero mnemonics.
///
/// [language]: The Monero language used for validation. Defaults to null, allowing the decoder
/// to use the default language.
class MoneroMnemonicValidator extends MnemonicValidator {
  /// Constructs a MoneroMnemonicValidator with an optional language parameter.
  ///
  /// [language]: The Monero language used for validation. Defaults to null.
  MoneroMnemonicValidator([MoneroLanguages? language])
      : super(MoneroMnemonicDecoder(language));
}
