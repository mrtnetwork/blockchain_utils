import 'package:blockchain_utils/exception/exception.dart';

/// Custom exception for errors related to BIP-44 depth.
///
/// This class, `Bip44DepthError`, represents a custom exception for handling
/// errors related to the BIP-44 hierarchical deterministic wallet structure's
/// depth. It can be thrown to indicate issues with depth levels in BIP-44 paths.
class Bip44DepthError extends BlockchainUtilsException {
  const Bip44DepthError(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}
