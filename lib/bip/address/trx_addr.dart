import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/eth_addr.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/utils/utils.dart';

class TrxAddressUtils {
  static const List<int> prefix = [0x41];
  static String fromHexBytes(List<int> bytes) {
    final validateBytes =
        AddrDecUtils.validateAndRemovePrefixBytes(bytes, prefix);
    AddrDecUtils.validateBytesLength(validateBytes, EthAddrConst.addrLen ~/ 2);
    return Base58Encoder.checkEncode(
        List<int>.from([...prefix, ...validateBytes]));
  }
}

/// Implementation of the [BlockchainAddressDecoder] for TRON (TRX) blockchain addresses.
class TrxAddrDecoder implements BlockchainAddressDecoder {
  /// Decodes a Tron address from its encoded representation.
  ///
  /// The `addr` parameter is the encoded Tron address to be decoded.
  /// The optional `kwargs` parameter allows for additional configuration.
  /// Returns the decoded address as a `List<int>`.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final List<int> addrDec = Base58Decoder.checkDecode(addr);
    final tronPrefix =
        BytesUtils.fromHexString(CoinsConf.tron.params.addrPrefix!);
    AddrDecUtils.validateBytesLength(
        addrDec, (EthAddrConst.addrLen ~/ 2) + tronPrefix.length);
    final addrNoPrefix =
        AddrDecUtils.validateAndRemovePrefixBytes(addrDec, tronPrefix);

    return EthAddrDecoder().decodeAddr(
        CoinsConf.ethereum.params.addrPrefix! +
            BytesUtils.toHexString(addrNoPrefix),
        {
          "skip_chksum_enc": true,
        });
  }
}

/// Implementation of the [BlockchainAddressEncoder] for TRON (TRX) blockchain addresses.
class TrxAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as a Tron address.
  ///
  /// This method takes a public key and encodes it as a Tron address by first
  /// converting it to an Ethereum address and then prefixing it with the Tron
  /// address prefix. The resulting address is encoded using the Base58 encoding.
  ///
  /// Parameters:
  /// - pubKey: The public key to be encoded.
  /// - kwargs: Optional arguments, if needed.
  ///
  /// Returns:
  /// A Tron address encoded as a Base58 string.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final String ethAddr = EthAddrEncoder().encodeKey(pubKey).substring(2);
    return Base58Encoder.checkEncode(List<int>.from([
      ...BytesUtils.fromHexString(CoinsConf.tron.params.addrPrefix!),
      ...BytesUtils.fromHexString(ethAddr)
    ]));
  }
}
