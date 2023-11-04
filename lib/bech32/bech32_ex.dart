/// An exception class representing errors related to Bech32 checksum validation.
class Bech32ChecksumError implements Exception {
  /// Creates a new instance of [Bech32ChecksumError].
  ///
  /// Parameters:
  /// - message: An optional error message describing the checksum error.
  const Bech32ChecksumError([this.message]);

  /// The error message associated with this checksum error.
  final String? message;

  @override
  String toString() {
    return message ?? super.toString();
  }
}
