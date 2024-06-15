import 'package:blockchain_utils/exception/exception.dart';

/// An exception representing an error related to mnemonic.
class MnemonicException implements BlockchainUtilsException {
  @override
  final String message;

  @override
  final Map<String, dynamic>? details;

  const MnemonicException(this.message, {this.details});

  @override
  String toString() {
    return message;
  }
}
