import 'package:blockchain_utils/exception/exceptions.dart';

/// An exception representing an error related to mnemonic.
class MnemonicException extends BlockchainUtilsException {
  const MnemonicException(super.message, {super.details});
  static const MnemonicException invalidChecksum = MnemonicException(
    "Invalid mnemonic checksum.",
  );
}
