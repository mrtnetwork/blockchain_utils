import 'package:blockchain_utils/exception/exception.dart';

/// An exception class for errors related to SS58 address checksum validation.
///
/// The [message] field can contain additional information about the error.
class SS58ChecksumError implements BlockchainUtilsException {
  @override
  final String message;

  @override
  final Map<String, dynamic>? details;

  /// Creates a new [SS58ChecksumError] with an optional [message].
  const SS58ChecksumError(this.message, {this.details});

  @override
  String toString() {
    return message;
  }
}
