import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic_decoder_base.dart';

/// Utility class for validating and checking the validity of mnemonic phrases.
class MnemonicValidator<T extends MnemonicDecoderBase> {
  final T decoder;

  /// Creates a new instance of the MnemonicValidator with the provided [decoder].
  ///
  /// The [decoder] is responsible for decoding and verifying the correctness
  /// of the mnemonic phrase.
  MnemonicValidator(this.decoder);

  /// Validates a given [mnemonic] phrase using the associated decoder.
  ///
  /// Throws an exception if the mnemonic phrase is invalid or cannot be decoded.
  void validate(Mnemonic mnemonic) {
    final decode = decoder.decode(mnemonic);
    decode.zero();
  }

  /// Checks if a given [mnemonic] phrase is valid.
  bool isValid(Mnemonic mnemonic) {
    try {
      validate(mnemonic);
      return true;
    } catch (e) {
      return false;
    }
  }
}
