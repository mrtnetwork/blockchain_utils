/// An abstract class for encoding blockchain addresses.
///
/// This abstract class defines a common interface for encoding blockchain addresses.
/// Subclasses of this class will implement specific encoding algorithms for different
/// blockchain networks.
abstract class BlockchainAddressEncoder {
  /// Encodes a public key into a blockchain address.
  ///
  /// This method takes a public key in the form of a List and optional keyword
  /// arguments (kwargs) for additional configuration if required. It encodes the
  /// public key into a blockchain-specific address.
  ///
  /// - [pubKey]: The public key to be encoded as a blockchain address.
  /// - [kwargs]: Optional keyword arguments for encoder-specific options.
  ///
  /// Returns the blockchain address string representing the encoded public key.
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]);
}
