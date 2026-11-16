
/// An abstract class for decoding blockchain addresses.
///
/// Implementations must throw [AddressConverterException] when the
/// input address string is malformed or fails validation.
abstract class BlockchainAddressDecoder<RESULT extends Object> {
  /// Decodes a given blockchain address string.
  ///
  /// Throws [AddressConverterException] on invalid input.
  RESULT decodeAddr(String addr);
}
