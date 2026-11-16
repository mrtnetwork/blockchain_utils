import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/chain/address/neworks/others/atom_addr.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Internal Avalanche address helpers.
class _AvaxAddrUtils {
  /// Strips [prefix] then decodes the remaining Bech32 [hrp] address.
  static BuBytes decodeAddr(String addr, String prefix, String hrp) {
    final addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(addr, prefix);
    return AtomAddrDecoder().decodeAddr(addrNoPrefix, hrp: hrp);
  }
}

/// Decodes an Avalanche P-Chain address.
class AvaxPChainAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    return _AvaxAddrUtils.decodeAddr(
      addr,
      AddrKeyValidator.getConfigArg(
        CoinsConf.avaxPChain.params.addrPrefix,
        "addrPrefix",
      ),
      AddrKeyValidator.getConfigArg(
        CoinsConf.avaxPChain.params.addrHrp,
        "addrHrp",
      ),
    );
  }
}

/// Encodes an Avalanche P-Chain address.
class AvaxPChainAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final String prefix = AddrKeyValidator.getConfigArg(
      CoinsConf.avaxPChain.params.addrPrefix,
      "addrPrefix",
    );
    return prefix +
        AtomAddrEncoder().encodeKey(
          pubKey,
          hrp: AddrKeyValidator.getConfigArg(
            CoinsConf.avaxPChain.params.addrHrp,
            "addrHrp",
          ),
          type: CryptoKeyType.secp256k1,
        );
  }
}

/// Decodes an Avalanche X-Chain address.
class AvaxXChainAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    return _AvaxAddrUtils.decodeAddr(
      addr,
      AddrKeyValidator.getConfigArg(
        CoinsConf.avaxXChain.params.addrPrefix,
        "addrPrefix",
      ),
      AddrKeyValidator.getConfigArg(
        CoinsConf.avaxXChain.params.addrHrp,
        "addrHrp",
      ),
    );
  }
}

/// Encodes an Avalanche X-Chain address.
class AvaxXChainAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final String prefix = AddrKeyValidator.getConfigArg(
      CoinsConf.avaxXChain.params.addrPrefix,
      "addrPrefix",
    );
    return prefix +
        AtomAddrEncoder().encodeKey(
          pubKey,
          hrp: AddrKeyValidator.getConfigArg(
            CoinsConf.avaxXChain.params.addrHrp,
            "addrHrp",
          ),
          type: CryptoKeyType.secp256k1,
        );
  }
}
