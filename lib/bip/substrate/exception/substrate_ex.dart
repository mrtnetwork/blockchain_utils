import 'package:blockchain_utils/exception/exceptions.dart';

/// An exception class representing an error related to Substrate keys.
class SubstrateKeyError extends BlockchainUtilsException {
  const SubstrateKeyError(super.message, {super.details});
}

/// An exception class representing an error related to Substrate paths.
class SubstratePathError extends BlockchainUtilsException {
  const SubstratePathError(super.message, {super.details});
}
