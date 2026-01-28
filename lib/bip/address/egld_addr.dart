import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'encoder.dart';

/// Implementation of the [BlockchainAddressDecoder] for Egld (Elrond) address.
class EgldAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the method to decode an Egld (Elrond) address from the provided string [addr].
  @override
  List<int> decodeAddr(String addr) {
    /// Decode the Bech32 address with the specified Human-Readable Part (HRP)
    final addrDecBytes = Bech32Decoder.decode(
      AddrKeyValidator.getConfigArg(CoinsConf.elrond.params.addrHrp, "addrHrp"),
      addr,
    );

    /// Validate the length of the decoded address
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      Ed25519KeysConst.pubKeyByteLen,
    );

    return addrDecBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Egld (Elrond) address.
class EgldAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the method to encode an Egld (Elrond) address based on the provided [pubKey].
  @override
  String encodeKey(List<int> pubKey) {
    /// Validate and retrieve the Ed25519 public key
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Encode the Egld address using the provided HRP and the raw compressed public key
    return Bech32Encoder.encode(
      AddrKeyValidator.getConfigArg(CoinsConf.elrond.params.addrHrp, "addrHrp"),
      pubKeyObj.compressed.sublist(1),
    );
  }
}
