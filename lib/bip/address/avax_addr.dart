import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';

import 'addr_dec_utils.dart';
import 'atom_addr.dart';

/// A utility class providing methods for decoding Avax (Avalanche) addresses.
class _AvaxAddrUtils {
  /// Decodes an Avax address with the specified [prefix] and Human-Readable Part (HRP).
  static List<int> decodeAddr(String addr, String prefix, String hrp) {
    final addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(addr, prefix);
    return AtomAddrDecoder().decodeAddr(addrNoPrefix, hrp: hrp);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Avax P-Chain address.
class AvaxPChainAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the address decoding method for Avax P-Chain addresses.
  @override
  List<int> decodeAddr(String addr) {
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

/// Implementation of the [BlockchainAddressEncoder] for Avax P-Chain address.
class AvaxPChainAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the address encoding method for Avax P-Chain addresses.
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
        );
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Avax X-Chain address.
class AvaxXChainAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the address decoding method for Avax X-Chain addresses.
  @override
  List<int> decodeAddr(String addr) {
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

/// Implementation of the [BlockchainAddressEncoder] for Avax X-Chain address.
class AvaxXChainAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the address encoding method for Avax X-Chain addresses.
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
        );
  }
}
