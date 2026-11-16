import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to EOS addresses.
class EosAddrConst {
  /// The length of the checksum in bytes for EOS addresses.
  static const int checksumByteLen = 4;
}

/// Utility methods for EOS addresses.
class _EosAddrUtils {
  static BuBytes computeChecksum(List<int> pubKeyBytes) {
    return QuickCrypto.ripemd160Hash(
      pubKeyBytes,
    ).sublist(0, EosAddrConst.checksumByteLen);
  }
}

/// Decodes an EOS address.
class EosAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    final addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
      addr,
      AddrKeyValidator.getConfigArg(
        CoinsConf.eos.params.addrPrefix,
        "addrPrefix",
      ),
    );

    final addrDecBytes = Base58Decoder.decode(addrNoPrefix);

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      EcdsaKeysConst.pubKeyCompressedByteLen + EosAddrConst.checksumByteLen,
    );

    final parts = AddrDecUtils.splitPartsByChecksum(
      addrDecBytes,
      EosAddrConst.checksumByteLen,
    );

    final pubKeyBytes = parts.$1;
    final checksumBytes = parts.$2;

    AddrDecUtils.validateChecksum(
      pubKeyBytes,
      checksumBytes,
      (pubKeyBytes) => _EosAddrUtils.computeChecksum(pubKeyBytes),
    );

    return BuBytes(pubKeyBytes);
  }
}

/// Encodes an EOS address.
class EosAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    final pubKeyBytes = pubKeyObj.toBytes(mode: CryptoKeyEncoding.base);

    final checksumBytes = _EosAddrUtils.computeChecksum(pubKeyBytes);
    final prefix = AddrKeyValidator.getConfigArg(
      CoinsConf.eos.params.addrPrefix,
      "addrPrefix",
    );

    // Address = prefix + base58(pubkey + checksum).
    return prefix + Base58Encoder.encode(pubKeyBytes + checksumBytes);
  }
}
