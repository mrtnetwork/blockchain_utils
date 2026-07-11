import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v1/electrum_v1_mnemonic_decoder.dart';
import 'package:blockchain_utils/bip/mnemonic/src/mnemonic_validator.dart';

/// A class for validating Electrum V1 mnemonics, extending the MnemonicValidator class.
class ElectrumV1MnemonicValidator extends MnemonicValidator {
  /// Constructs an ElectrumV1MnemonicValidator with an optional language specification.
  ///
  /// [language]: The language to use for mnemonic decoding (default: English).
  ///
  ElectrumV1MnemonicValidator([
    ElectrumV1Languages? language = ElectrumV1Languages.english,
  ]) : super(ElectrumV1MnemonicDecoder(language));
}
