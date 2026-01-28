import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/eth_addr.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'exception/exception.dart';

/// Implementation of the [BlockchainAddressDecoder] for OKExChain addresses.
class OkexAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode an OKExChain address.
  @override
  List<int> decodeAddr(String addr) {
    try {
      /// Decode the OKExChain address using the OKExChain configuration's HRP.
      final List<int> addrDecBytes = Bech32Decoder.decode(
        AddrKeyValidator.getConfigArg(
          CoinsConf.okexChain.params.addrHrp,
          "addrHrp",
        ),
        addr,
      );

      /// Decode the address again as an Ethereum address with a custom prefix.
      return EthAddrDecoder().decodeAddr(
        AddrKeyValidator.getConfigArg(
              CoinsConf.ethereum.params.addrPrefix,
              "addrPrefix",
            ) +
            BytesUtils.toHexString(addrDecBytes),
        skipChecksum: true,
      );
    } catch (e) {
      throw AddressConverterException.addressValidationFailed(
        details: {"error": e.toString()},
      );
    }
  }
}

/// Implementation of the [BlockchainAddressEncoder] for OKExChain addresses.
class OkexAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as an OKExChain address using Bech32 encoding.
  @override
  String encodeKey(List<int> pubKey) {
    /// Encode the Ethereum address without the '0x' prefix.
    final String ethAddr = StringUtils.strip0x(
      EthAddrEncoder().encodeKey(pubKey),
    );

    /// Encode the Ethereum address as an OKExChain address using Bech32 encoding.
    return Bech32Encoder.encode(
      AddrKeyValidator.getConfigArg(
        CoinsConf.okexChain.params.addrHrp,
        "addrHrp",
      ),
      BytesUtils.fromHexString(ethAddr),
    );
  }
}
