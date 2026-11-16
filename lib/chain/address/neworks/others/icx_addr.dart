import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Defines constants related to ICON (ICX) addresses.
class IcxAddrConst {
  /// The length in bytes of the key hash portion of an ICON address.
  static const int keyHashByteLen = 20;
}

/// Decodes an ICON (ICX) address.
class IcxAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    final String addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
      addr,
      AddrKeyValidator.getConfigArg(
        CoinsConf.icon.params.addrPrefix,
        "addrPrefix",
      ),
    );

    final BuBytes pubKeyHashBytes = BytesUtils.fromHexString(addrNoPrefix);
    AddrDecUtils.validateBytesLength(
      pubKeyHashBytes,
      IcxAddrConst.keyHashByteLen,
    );

    return pubKeyHashBytes;
  }
}

/// Encodes an ICON (ICX) address.
class IcxAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final IPublicKey pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(
      pubKey,
    );
    // SHA3-256 of the uncompressed pubkey (minus its 0x04 tag byte).
    List<int> pubKeyHashBytes = QuickCrypto.sha3256Hash(
      pubKeyObj.toBytes(mode: CryptoKeyEncoding.uncompressed).sublist(1),
    );

    // Keep only the last 20 bytes of the hash.
    pubKeyHashBytes = pubKeyHashBytes.sublist(
      pubKeyHashBytes.length - IcxAddrConst.keyHashByteLen,
    );

    return AddrKeyValidator.getConfigArg(
          CoinsConf.icon.params.addrPrefix,
          "addrPrefix",
        ) +
        BytesUtils.toHexString(pubKeyHashBytes);
  }
}
