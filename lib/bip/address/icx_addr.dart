import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Defines constants related to ICON (ICX) addresses.
class IcxAddrConst {
  /// The length in bytes of the key hash portion of an ICON address.
  static const int keyHashByteLen = 20;
}

/// Implementation of the [BlockchainAddressDecoder] for ICON (ICX) addresses.
class IcxAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode an ICON (ICX) address.
  ///
  /// This method decodes an ICON address from the provided input string. It expects an optional map of
  /// keyword arguments for custom ICON address parameters. The method performs the following steps:
  /// 1. Removes the ICON address prefix.
  /// 2. Validates the length of the decoded public key hash.
  /// 3. Returns the decoded public key hash as a `List<int>`.
  ///
  /// Parameters:
  ///   - addr: The ICON address to be decoded as a string.
  ///   - kwargs: Optional keyword arguments for custom ICON address parameters (not used in this implementation).
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded public key hash of the ICON address.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Remove the ICON address prefix.
    final String addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
      addr,
      CoinsConf.icon.params.addrPrefix!,
    );

    /// Convert the remaining string to a `List<int>` and validate its length.
    final List<int> pubKeyHashBytes = BytesUtils.fromHexString(addrNoPrefix);
    AddrDecUtils.validateBytesLength(
        pubKeyHashBytes, IcxAddrConst.keyHashByteLen);

    return pubKeyHashBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for ICON (ICX) addresses.
class IcxAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as an ICON (ICX) address.
  ///
  /// This method encodes a public key as an ICON address. It expects the public key as a `List<int>`
  /// and returns the ICON address as a string. The encoding process involves:
  /// 1. Validating and transforming the public key into a 32-byte hash.
  /// 2. Truncating the hash to the required ICON address length.
  /// 3. Adding the ICON address prefix to the hash.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as an ICON address in the form of a `List<int>`.
  ///   - kwargs: Optional keyword arguments (not used in this implementation).
  ///
  /// Returns:
  ///   A string representing the ICON (ICX) address corresponding to the provided public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate and transform the public key into a 32-byte hash.
    final IPublicKey pubKeyObj =
        AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    List<int> pubKeyHashBytes =
        QuickCrypto.sha3256Hash(pubKeyObj.uncompressed.sublist(1));

    /// Truncate the hash to the required ICON address length.
    pubKeyHashBytes = pubKeyHashBytes
        .sublist(pubKeyHashBytes.length - IcxAddrConst.keyHashByteLen);

    /// Add the ICON address prefix to the hash.
    return CoinsConf.icon.params.addrPrefix! +
        BytesUtils.toHexString(pubKeyHashBytes);
  }
}
