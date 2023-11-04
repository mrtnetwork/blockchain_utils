import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic_validator.dart';

/// Validates BIP39 mnemonics based on a specified language.
///
/// The `Bip39MnemonicValidator` class is responsible for validating BIP39 mnemonics
/// by using the `Bip39MnemonicDecoder` for decoding and checking the correctness of
/// the mnemonic phrase. It ensures that the provided mnemonic follows the specified
/// language's word list and can be successfully decoded.
/// The [isValid] method can be used to check the validity of a given
/// mnemonic phrase.
class Bip39MnemonicValidator extends MnemonicValidator {
  /// Creates a new instance of the Bip39MnemonicValidator.
  ///
  /// The [language] parameter specifies the language used for the word list.
  Bip39MnemonicValidator([Bip39Languages? language])
      : super(Bip39MnemonicDecoder(language));
}
