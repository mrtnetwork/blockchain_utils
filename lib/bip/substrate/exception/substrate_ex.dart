import 'package:blockchain_utils/exception/exception.dart';

/// An exception class representing an error related to Substrate keys.
class SubstrateKeyError extends BlockchainUtilsException {
  const SubstrateKeyError(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}

/// An exception class representing an error related to Substrate paths.
class SubstratePathError extends BlockchainUtilsException {
  const SubstratePathError(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}
