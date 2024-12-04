import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Constants related to Zilliqa (ZIL) blockchain addresses.
class ZilAddrConst {
  /// The length, in bytes, of a SHA-256 hash used in Zilliqa addresses.
  static const int sha256ByteLen = 20;
}

/// A Zilliqa (ZIL) blockchain address decoder that implements the [BlockchainAddressDecoder] interface.
class ZilAddrDecoder implements BlockchainAddressDecoder {
  /// Decodes a Zilliqa blockchain address from a human-readable representation.
  ///
  /// Given a Zilliqa address string [addr], this method decodes it using the
  /// specified Human Readable Part (HRP) from the Zilliqa configuration. If the
  /// provided address has an invalid bech32 checksum, it raises an [ArgumentException]
  /// with a descriptive error message.
  ///
  /// Parameters:
  /// - [addr]: The Zilliqa address string to decode.
  /// - [kwargs]: An optional map of additional arguments. (Not used in this implementation)
  ///
  /// Returns:
  /// - A [List<int>] representing the decoded Zilliqa address in bytes.
  ///
  /// Throws:
  /// - An [ArgumentException] with an error message if the bech32 checksum is invalid.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Decode the Zilliqa address using the specified Human Readable Part (HRP).
    final addrDecBytes = Bech32Decoder.decode(
      CoinsConf.zilliqa.params.addrHrp!,
      addr,
    );
    return addrDecBytes;
  }
}

/// A Zilliqa blockchain address encoder that implements the [BlockchainAddressEncoder] interface.
class ZilAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a Zilliqa blockchain address from a given public key.
  ///
  /// This method takes a public key in the form of a [List<int>] and generates a Zilliqa
  /// blockchain address by following these steps:
  /// 1. Validate and obtain a secp256k1 key object from the input public key.
  /// 2. Calculate the SHA-256 hash of the compressed public key.
  /// 3. Encode the Zilliqa blockchain address using Bech32 encoding.
  ///
  /// Parameters:
  /// - [pubKey]: The public key to encode as a Zilliqa blockchain address.
  /// - [kwargs]: An optional map of keyword arguments, which is not used in this implementation.
  ///
  /// Returns the Zilliqa blockchain address as a string.
  ///
  /// Throws:
  /// - [ArgumentException] if the public key validation fails or if there is an issue with Bech32 encoding.
  ///
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate the public key and obtain a secp256k1 key object.
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Calculate the SHA-256 hash of the compressed public key.
    final keyHash = QuickCrypto.sha256Hash(pubKeyObj.compressed);

    /// Encode the Zilliqa blockchain address using Bech32 encoding.
    return Bech32Encoder.encode(CoinsConf.zilliqa.params.addrHrp!,
        keyHash.sublist(keyHash.length - ZilAddrConst.sha256ByteLen));
  }
}
