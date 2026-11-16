import 'package:blockchain_utils/protocol/bip/bip/bip39/bip39_mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip39/bip39_mnemonic_decoder.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic_validator.dart';

/// Validates BIP39 mnemonics based on a specified language.
class Bip39MnemonicValidator extends MnemonicValidator<Bip39MnemonicDecoder> {
  /// Creates a new instance of the Bip39MnemonicValidator.
  ///
  /// The [language] parameter specifies the language used for the word list.
  Bip39MnemonicValidator([Bip39Languages? language])
    : super(Bip39MnemonicDecoder(language));

  bool validateWords(String mnemonic) {
    final mn = Mnemonic.fromString(mnemonic);
    try {
      final language = decoder.findLanguage(mn).$1;
      decoder.mnemonicToBinaryStr(mn, language);
      return true;
    } catch (e) {
      return false;
    } finally {
      mn.dispose();
    }
  }
}
