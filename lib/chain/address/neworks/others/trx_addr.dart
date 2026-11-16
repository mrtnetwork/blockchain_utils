import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/neworks/others/eth_addr.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Internal TRON (TRX) address helpers.
class TrxAddressUtils {
  static const List<int> prefix = [0x41];

  /// Converts raw address bytes (with the 0x41 prefix) to a Base58 address.
  static String fromHexBytes(List<int> bytes) {
    final validateBytes = AddrDecUtils.validateAndRemovePrefixBytes(
      bytes,
      prefix,
    );
    AddrDecUtils.validateBytesLength(validateBytes, EthAddrConst.addrLen ~/ 2);
    return Base58Encoder.encodeWithChecksum([...prefix, ...validateBytes]);
  }
}

/// Decodes a TRON (TRX) address.
class TrxAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    final List<int> addrDec = Base58Decoder.decodeWithChecksum(addr);
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

/// Encodes a TRON (TRX) address.
class TrxAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final String ethAddr = EthAddrEncoder().encodeKey(pubKey).substring(2);
    return Base58Encoder.encodeWithChecksum([
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
