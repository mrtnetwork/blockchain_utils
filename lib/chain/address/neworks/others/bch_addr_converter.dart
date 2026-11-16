import 'package:blockchain_utils/encoding/bech32/bech32.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

/// Converts a Bitcoin Cash address to a new HRP and/or network version.
class BchAddrConverter {
  /// Re-encodes [address] with [hrp] and [netVer] (defaults to its current
  /// network version if not given).
  static String convert(String address, String hrp, List<int>? netVer) {
    final sepIndex = address.indexOf(":");
    if (sepIndex == -1) {
      throw CoreErrors.addressValidationFailed(
        network: "BitcoinCash",
        reason: "Missing HRP separator ':' in address.",
      );
    }
    final decode = BchBech32Decoder.decode(
      address.substring(0, sepIndex),
      address,
    );
    final currNetVer = decode.$1;
    final data = decode.$2;
    return BchBech32Encoder.encode(hrp, netVer ?? currNetVer, data);
  }
}
