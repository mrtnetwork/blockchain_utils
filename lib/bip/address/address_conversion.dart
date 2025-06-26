import 'package:blockchain_utils/bech32/bech32.dart';
import 'package:blockchain_utils/hex/hex.dart';

/// Some cosmos-sdk chains integrate EVM modules, which means in the same chain,
/// both bech32 and 0x addresses are supported.
/// Here provides a utility methods to convert between each other.
/// Note: Addresses are convertible if and only if both addresses are derived using the same coin type.
class AddressConversion {
  static String hexToBech32(String hexAddress, prefix) {
    final cleanHex = hexAddress.startsWith('0x')
        ? hexAddress.substring(2)
        : hexAddress;
    final hexAddressBytes = hex.decode(cleanHex);
    return Bech32Encoder.encode(prefix, hexAddressBytes);
  }

  static String bech32ToHex(String bech32Address, prefix) {
    final decoded = Bech32Decoder.decode(prefix, bech32Address);
    return '0x${hex.encode(decoded)}';
  }
}
