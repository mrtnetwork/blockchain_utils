import 'package:blockchain_utils/exception/exceptions.dart';

/// An exception class for errors related to SS58 address checksum validation.
///
/// The [message] field can contain additional information about the error.
class SS58ChecksumError extends BlockchainUtilsException {
  const SS58ChecksumError(super.message, {super.details});
}
