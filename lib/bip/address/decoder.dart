/// An abstract class for decoding blockchain addresses.
abstract class BlockchainAddressDecoder<RESULT extends Object> {
  /// Decodes a given blockchain address string.
  RESULT decodeAddr(String addr);
}
