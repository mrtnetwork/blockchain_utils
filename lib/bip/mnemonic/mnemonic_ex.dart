import 'package:blockchain_utils/exception/exception.dart';

/// An exception representing an error related to mnemonic.
class MnemonicException extends BlockchainUtilsException {
  const MnemonicException(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}
