import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/neworks/others/eth_addr.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Decodes an INJ (Injective Protocol) address.
class InjAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    final addrDecBytes = Bech32Decoder.decode(
      AddrKeyValidator.getConfigArg(
        CoinsConf.injective.params.addrHrp,
        "addrHrp",
      ),
      addr,
    );

    AddrDecUtils.validateBytesLength(addrDecBytes, EthAddrConst.addrLen ~/ 2);
    return addrDecBytes;
  }
}

/// Encodes an INJ (Injective Protocol) address.
class InjAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    // INJ addresses reuse Ethereum's key derivation, re-encoded as Bech32.
    final ethAddr = EthAddrEncoder().encodeKey(pubKey);
    return Bech32Encoder.encode(
      AddrKeyValidator.getConfigArg(
        CoinsConf.injective.params.addrHrp,
        "addrHrp",
      ),
      BytesUtils.fromHexString(ethAddr),
    );
  }
}
