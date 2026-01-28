import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/eth_addr.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

class TrxAddressUtils {
  static const List<int> prefix = [0x41];
  static String fromHexBytes(List<int> bytes) {
    final validateBytes = AddrDecUtils.validateAndRemovePrefixBytes(
      bytes,
      prefix,
    );
    AddrDecUtils.validateBytesLength(validateBytes, EthAddrConst.addrLen ~/ 2);
    return Base58Encoder.checkEncode([...prefix, ...validateBytes]);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for TRON (TRX) blockchain addresses.
class TrxAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decodes a Tron address from its encoded representation.
  @override
  List<int> decodeAddr(String addr) {
    final List<int> addrDec = Base58Decoder.checkDecode(addr);
    final tronPrefix = BytesUtils.fromHexString(
      AddrKeyValidator.getConfigArg(
        CoinsConf.tron.params.addrPrefix,
        "addrPrefix",
      ),
    );
    AddrDecUtils.validateBytesLength(
      addrDec,
      (EthAddrConst.addrLen ~/ 2) + tronPrefix.length,
    );
    final addrNoPrefix = AddrDecUtils.validateAndRemovePrefixBytes(
      addrDec,
      tronPrefix,
    );

    return EthAddrDecoder().decodeAddr(
      AddrKeyValidator.getConfigArg(
            CoinsConf.ethereum.params.addrPrefix,
            "addrPrefix",
          ) +
          BytesUtils.toHexString(addrNoPrefix),
      skipChecksum: true,
    );
  }
}

/// Implementation of the [BlockchainAddressEncoder] for TRON (TRX) blockchain addresses.
class TrxAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as a Tron address.
  @override
  String encodeKey(List<int> pubKey) {
    final String ethAddr = EthAddrEncoder().encodeKey(pubKey).substring(2);
    return Base58Encoder.checkEncode([
      ...BytesUtils.fromHexString(
        AddrKeyValidator.getConfigArg(
          CoinsConf.tron.params.addrPrefix,
          "addrPrefix",
        ),
      ),
      ...BytesUtils.fromHexString(ethAddr),
    ]);
  }
}
