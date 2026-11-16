import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to Zilliqa (ZIL) blockchain addresses.
class ZilAddrConst {
  /// The length, in bytes, of a SHA-256 hash used in Zilliqa addresses.
  static const int sha256ByteLen = 20;
}

/// Decodes a Zilliqa (ZIL) address.
class ZilAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    final addrDecBytes = Bech32Decoder.decode(
      AddrKeyValidator.getConfigArg(
        CoinsConf.zilliqa.params.addrHrp,
        "addrHrp",
      ),
      addr,
    );
    AddrDecUtils.validateBytesLength(addrDecBytes, ZilAddrConst.sha256ByteLen);
    return addrDecBytes;
  }
}

/// Encodes a Zilliqa (ZIL) address.
class ZilAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final keyHash = QuickCrypto.sha256Hash(
      pubKeyObj.toBytes(mode: CryptoKeyEncoding.base),
    );
    return Bech32Encoder.encode(
      AddrKeyValidator.getConfigArg(
        CoinsConf.zilliqa.params.addrHrp,
        "addrHrp",
      ),
      keyHash.sublist(keyHash.length - ZilAddrConst.sha256ByteLen),
    );
  }
}
