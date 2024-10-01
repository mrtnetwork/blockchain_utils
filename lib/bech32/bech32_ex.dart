import 'package:blockchain_utils/exception/exception.dart';

/// An exception class representing errors related to Bech32 checksum validation.
class Bech32ChecksumError extends BlockchainUtilsException {
  /// The error message associated with this checksum error.
  const Bech32ChecksumError(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}
