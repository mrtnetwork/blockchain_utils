import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Decodes an Egld (Elrond) address.
class EgldAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    final addrDecBytes = Bech32Decoder.decode(
      AddrKeyValidator.getConfigArg(CoinsConf.elrond.params.addrHrp, "addrHrp"),
      addr,
    );

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      Ed25519KeysConst.pubKeyByteLen,
    );

    return addrDecBytes;
  }
}

/// Encodes an Egld (Elrond) address.
class EgldAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);

    return Bech32Encoder.encode(
      AddrKeyValidator.getConfigArg(CoinsConf.elrond.params.addrHrp, "addrHrp"),
      pubKeyObj,
    );
  }
}
