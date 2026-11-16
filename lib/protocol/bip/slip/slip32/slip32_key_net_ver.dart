/// A class that represents network versions for SLIP-32 extended keys.
class Slip32KeyNetVersions {
  /// Public key network version
  final String pubNetVar;

  /// Private key network version
  final String privNetVar;

  /// Constructor to create Slip32KeyNetVersions.
  ///
  /// Initializes the network versions for public and private keys.
  const Slip32KeyNetVersions({
    required this.pubNetVar,
    required this.privNetVar,
  });

  /// Get the public key network version.
  String get public => pubNetVar;

  /// Get the private key network version.
  String get private => privNetVar;
}
