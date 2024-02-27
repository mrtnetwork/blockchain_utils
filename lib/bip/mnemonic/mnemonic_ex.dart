import 'package:blockchain_utils/exception/exception.dart';

/// An exception representing an error related to the checksum validation of a mnemonic phrase.
///
/// This exception is thrown when the checksum of a mnemonic phrase is found to be invalid
/// during mnemonic validation or when attempting to derive a key from the mnemonic phrase.
class MnemonicChecksumError implements BlockchainUtilsException {
  const MnemonicChecksumError(this.message);

  @override
  final String message;

  @override
  String toString() {
    return message;
  }
}
