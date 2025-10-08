import 'package:blockchain_utils/exception/exceptions.dart';

/// An exception class representing an error related to Monero keys.
///
/// This exception class is used to represent errors and exceptions related to Monero keys.
class MoneroKeyError extends BlockchainUtilsException {
  const MoneroKeyError(super.message, {super.details});
}
