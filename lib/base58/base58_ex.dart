import 'package:blockchain_utils/exception/exception.dart';

/// An exception class representing an error related to Base58 checksum validation.
class Base58ChecksumError extends BlockchainUtilsException {
  /// Constructor for creating a Base58ChecksumError with an optional error message.
  const Base58ChecksumError(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}
