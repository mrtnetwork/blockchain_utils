import 'package:blockchain_utils/exception/exception.dart';

/// An exception class representing an error related to Substrate keys.
class SubstrateKeyError implements BlockchainUtilsException {
  /// The error message associated with this exception.
  @override
  final String message;

  @override
  final Map<String, dynamic>? details;

  /// Creates a new instance of [SubstrateKeyError] with an optional [message].
  const SubstrateKeyError(this.message, {this.details});

  @override
  String toString() {
    return message;
  }
}

/// An exception class representing an error related to Substrate paths.
class SubstratePathError implements BlockchainUtilsException {
  /// The error message associated with this exception.
  @override
  final String message;

  @override
  final Map<String, dynamic>? details;

  /// Creates a new instance of [SubstratePathError] with an optional [message].
  const SubstratePathError(this.message, {this.details});

  @override
  String toString() {
    return message;
  }
}
