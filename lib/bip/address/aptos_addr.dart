import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'addr_key_validator.dart';

/// Constants related to Aptos blockchain addresses.
class AptosAddrConst {
  /// The suffix byte used for single signature addresses.
  static final singleSigSuffixByte = List<int>.from([0x00]);
}

/// Implementation of the [BlockchainAddressDecoder] for Aptos address.
class AptosAddrDecoder implements BlockchainAddressDecoder {
  /// Decode an Aptos blockchain address from its string representation.
  ///
  /// This method decodes the provided `addr` string by removing the prefix,
  /// ensuring the address length is valid, and parsing the hexadecimal string
  /// to obtain the address bytes.
  ///
  /// Parameters:
  /// - `addr`: The Aptos blockchain address in string format.
  /// - `kwargs` (optional): Additional arguments, though none are used in this method.
  ///
  /// Returns:
  /// - A List<int> containing the decoded address bytes.
  ///
  /// Throws:
  /// - ArgumentException if the provided string is not a valid hex encoding.
  ///
  /// This method is used to convert an Aptos blockchain address from its string
  /// representation to its binary format for further processing.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    String addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
      addr,
      CoinsConf.aptos.params.addrPrefix!,
    );
    addrNoPrefix = addrNoPrefix.padLeft(QuickCrypto.sha3256DigestSize * 2, "0");
    AddrDecUtils.validateLength(
        addrNoPrefix, QuickCrypto.sha3256DigestSize * 2);

    return BytesUtils.fromHexString(addrNoPrefix);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Aptos address.
class AptosAddrEncoder implements BlockchainAddressEncoder {
  /// Encode an Aptos blockchain address from a public key.
  ///
  /// This method encodes an Aptos blockchain address from the provided `pubKey`
  /// by performing the following steps:
  /// 1. Validate the public key and extract its raw compressed bytes.
  /// 2. Prepare the payload by appending a single-sig suffix byte.
  /// 3. Compute the SHA-3-256 hash of the payload.
  /// 4. Concatenate the address prefix and the hash bytes.
  /// 5. Remove leading zeros from the resulting hex-encoded address.
  ///
  /// Parameters:
  /// - `pubKey`: The public key for which to generate the address.
  /// - `kwargs` (optional): Additional arguments, though none are used in this method.
  ///
  /// Returns:
  /// - A hex-encoded string representing the generated Aptos blockchain address.
  ///
  /// This method is used to create an Aptos blockchain address from a public key.
  /// The resulting address is a hexadecimal string without leading zeros.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final pubKeyBytes = pubKey;
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKeyBytes);

    /// Prepare the payload by appending a single-sig suffix byte
    final payloadBytes = List<int>.from([
      ...List<int>.from(pubKeyObj.compressed.sublist(1)),
      ...AptosAddrConst.singleSigSuffixByte
    ]);

    /// Compute the SHA-3-256 hash of the payload
    final keyHashBytes = QuickCrypto.sha3256Hash(payloadBytes);

    /// Concatenate the address prefix and the hash bytes, removing leading zeros
    return CoinsConf.aptos.params.addrPrefix! +
        BytesUtils.toHexString(keyHashBytes).replaceFirst(RegExp('^0+'), '');
  }
}
