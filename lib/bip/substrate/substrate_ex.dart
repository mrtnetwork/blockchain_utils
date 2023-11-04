/// An exception class representing an error related to Substrate keys.
class SubstrateKeyError implements Exception {
  /// The error message associated with this exception.
  final String? message;

  /// Creates a new instance of [SubstrateKeyError] with an optional [message].
  const SubstrateKeyError([this.message]);

  @override
  String toString() {
    return message ?? super.toString();
  }
}

/// An exception class representing an error related to Substrate paths.
class SubstratePathError implements Exception {
  /// The error message associated with this exception.
  final String? message;

  /// Creates a new instance of [SubstratePathError] with an optional [message].
  const SubstratePathError([this.message]);

  @override
  String toString() {
    return message ?? super.toString();
  }
}
