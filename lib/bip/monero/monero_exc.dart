import 'package:blockchain_utils/exception/exception.dart';

/// An exception class representing an error related to Monero keys.
///
/// This exception class is used to represent errors and exceptions related to Monero keys.
class MoneroKeyError extends BlockchainUtilsException {
  const MoneroKeyError(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}
