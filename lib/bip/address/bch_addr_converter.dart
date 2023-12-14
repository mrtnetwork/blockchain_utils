import 'package:blockchain_utils/bech32/bch_bech32.dart';

/// Bitcoin Cash address converter class.
/// It allows to convert a Bitcoin Cash address by changing its HRP and net version.
class BchAddrConverter {
  /// Convert a Bitcoin Cash address by changing its HRP and net version.
  static String convert(String address, String hrp, List<int>? netVer) {
    // Decode address
    final decode = BchBech32Decoder.decode(
        address.substring(0, address.indexOf(":")), address);
    final currNetVer = decode.item1;
    final data = decode.item2;
    // Encode again with new HRP and net version
    return BchBech32Encoder.encode(hrp, netVer ?? currNetVer, data);
  }
}
