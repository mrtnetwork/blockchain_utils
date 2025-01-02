/// An abstract class for decoding blockchain addresses.
abstract class BlockchainAddressDecoder {
  /// Decodes a given blockchain address string.
  ///
  /// This method takes an address string and optional keyword arguments (kwargs)
  /// and decodes it into a List representing the decoded address.
  ///
  /// - [addr]: The blockchain address string to be decoded.
  /// - [kwargs]: Optional keyword arguments that can be used for configuration.
  ///
  /// Returns a List containing the decoded blockchain address.
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]);
}
