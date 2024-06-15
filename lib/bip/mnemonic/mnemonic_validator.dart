import 'package:blockchain_utils/bip/mnemonic/mnemonic_decoder_base.dart';

/// Utility class for validating and checking the validity of mnemonic phrases.
///
/// The `MnemonicValidator` class provides methods to validate and determine the
/// validity of mnemonic phrases using a specified `MnemonicDecoderBase`. It can
/// check whether a given mnemonic phrase is valid and adheres to the expected format.
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
  void validate(String mnemonic) {
    decoder.decode(mnemonic);
  }

  /// Checks if a given [mnemonic] phrase is valid.
  ///
  /// Returns `true` if the mnemonic is valid, `false` otherwise.
  bool isValid(String mnemonic) {
    try {
      validate(mnemonic);
      return true;
    } catch (e) {
      return false;
    }
  }
}
