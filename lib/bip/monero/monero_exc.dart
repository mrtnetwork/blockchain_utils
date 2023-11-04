/// An exception class representing an error related to Monero keys.
///
/// This exception class is used to represent errors and exceptions related to Monero keys.
class MoneroKeyError implements Exception {
  final String? message;

  /// Constructs a MoneroKeyError with an optional error message.
  ///
  /// [message]: An optional error message describing the key-related issue.
  const MoneroKeyError([this.message]);

  /// Returns a string representation of the exception.
  @override
  String toString() {
    return message ?? super.toString();
  }
}
