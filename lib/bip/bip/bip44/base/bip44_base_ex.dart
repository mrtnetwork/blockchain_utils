import 'package:blockchain_utils/exception/exception.dart';

/// Custom exception for errors related to BIP-44 depth.
///
/// This class, `Bip44DepthError`, represents a custom exception for handling
/// errors related to the BIP-44 hierarchical deterministic wallet structure's
/// depth. It can be thrown to indicate issues with depth levels in BIP-44 paths.
class Bip44DepthError implements BlockchainUtilsException {
  @override
  final String message;

  @override
  final Map<String, dynamic>? details;

  /// Create a `Bip44DepthError` with an optional error message.
  ///
  /// - [message]: An optional error message to provide more context.
  const Bip44DepthError(this.message, {this.details});

  @override
  String toString() {
    return message;
  }
}
