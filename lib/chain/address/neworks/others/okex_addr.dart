import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/neworks/others/eth_addr.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Decodes an OKExChain address.
class OkexAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    try {
      final List<int> addrDecBytes = Bech32Decoder.decode(
        AddrKeyValidator.getConfigArg(
          CoinsConf.okexChain.params.addrHrp,
          "addrHrp",
        ),
        addr,
      );

      // OKExChain reuses Ethereum's address format under the hood.
      return EthAddrDecoder().decodeAddr(
        AddrKeyValidator.getConfigArg(
              CoinsConf.ethereum.params.addrPrefix,
              "addrPrefix",
            ) +
            BytesUtils.toHexString(addrDecBytes),
        skipChecksum: true,
      );
    } catch (e) {
      throw CoreErrors.addressValidationFailed(
        details: {"error": e.toString()},
      );
    }
  }
}

/// Encodes an OKExChain address.
class OkexAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final String ethAddr = StringUtils.strip0x(
      EthAddrEncoder().encodeKey(pubKey),
    );

    return Bech32Encoder.encode(
      AddrKeyValidator.getConfigArg(
        CoinsConf.okexChain.params.addrHrp,
        "addrHrp",
      ),
      BytesUtils.fromHexString(ethAddr),
    );
  }
}
