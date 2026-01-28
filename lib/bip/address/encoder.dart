/// An abstract class for encoding blockchain addresses.
abstract class BlockchainAddressEncoder {
  /// Encodes a public key or address bytes into a blockchain address.
  String encodeKey(List<int> keyBytes);
}
