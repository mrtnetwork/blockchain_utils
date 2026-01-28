import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

/// Defines constants related to ICON (ICX) addresses.
class IcxAddrConst {
  /// The length in bytes of the key hash portion of an ICON address.
  static const int keyHashByteLen = 20;
}

/// Implementation of the [BlockchainAddressDecoder] for ICON (ICX) addresses.
class IcxAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode an ICON (ICX) address.
  @override
  List<int> decodeAddr(String addr) {
    /// Remove the ICON address prefix.
    final String addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
      addr,
      AddrKeyValidator.getConfigArg(
        CoinsConf.icon.params.addrPrefix,
        "addrPrefix",
      ),
    );

    /// Convert the remaining string to a `List<int>` and validate its length.
    final List<int> pubKeyHashBytes = BytesUtils.fromHexString(addrNoPrefix);
    AddrDecUtils.validateBytesLength(
      pubKeyHashBytes,
      IcxAddrConst.keyHashByteLen,
    );

    return pubKeyHashBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for ICON (ICX) addresses.
class IcxAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as an ICON (ICX) address.
  @override
  String encodeKey(List<int> pubKey) {
    /// Validate and transform the public key into a 32-byte hash.
    final IPublicKey pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(
      pubKey,
    );
    List<int> pubKeyHashBytes = QuickCrypto.sha3256Hash(
      pubKeyObj.uncompressed.sublist(1),
    );

    /// Truncate the hash to the required ICON address length.
    pubKeyHashBytes = pubKeyHashBytes.sublist(
      pubKeyHashBytes.length - IcxAddrConst.keyHashByteLen,
    );

    /// Add the ICON address prefix to the hash.
    return AddrKeyValidator.getConfigArg(
          CoinsConf.icon.params.addrPrefix,
          "addrPrefix",
        ) +
        BytesUtils.toHexString(pubKeyHashBytes);
  }
}
