
/// An abstract class for encoding blockchain addresses.
///
/// Implementations must throw [AddressConverterException] when the
/// input key/address bytes or conversion arguments are invalid.
abstract class BlockchainAddressEncoder {
  /// Encodes a public key or address bytes into a blockchain address.
  ///
  /// Throws [AddressConverterException] on invalid input.
  String encodeKey(List<int> keyBytes);
}
