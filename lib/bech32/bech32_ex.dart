import 'package:blockchain_utils/exception/exception.dart';

/// An exception class representing errors related to Bech32 checksum validation.
class Bech32ChecksumError implements BlockchainUtilsException {
  /// The error message associated with this checksum error.
  @override
  final String message;
  @override
  final Map<String, dynamic>? details;

  /// Creates a new instance of [Bech32ChecksumError].
  ///
  /// Parameters:
  /// - message: An optional error message describing the checksum error.
  const Bech32ChecksumError(this.message, {this.details});

  @override
  String toString() {
    return message;
  }
}
