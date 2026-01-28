import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/eth_addr.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

/// Implementation of the [BlockchainAddressDecoder] for INJ (Injective Protocol) addresses.
class InjAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode an INJ (Injective Protocol) address.
  @override
  List<int> decodeAddr(String addr) {
    /// Decode the Bech32-encoded address using the INJ address human-readable part (hrp).
    final addrDecBytes = Bech32Decoder.decode(
      AddrKeyValidator.getConfigArg(
        CoinsConf.injective.params.addrHrp,
        "addrHrp",
      ),
      addr,
    );

    /// Validate the length of the decoded address.
    AddrDecUtils.validateBytesLength(addrDecBytes, EthAddrConst.addrLen ~/ 2);
    return addrDecBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for INJ (Injective Protocol) addresses.
class InjAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as an INJ (Injective Protocol) address.
  @override
  String encodeKey(List<int> pubKey) {
    /// Encode the public key as an Ethereum (ETH) address.
    final ethAddr = EthAddrEncoder().encodeKey(pubKey);

    /// Encode the ETH address using the INJ address human-readable part (hrp).
    return Bech32Encoder.encode(
      AddrKeyValidator.getConfigArg(
        CoinsConf.injective.params.addrHrp,
        "addrHrp",
      ),
      BytesUtils.fromHexString(ethAddr),
    );
  }
}
