import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Constants related to EOS addresses.
class EosAddrConst {
  /// The length of the checksum in bytes for EOS addresses.
  static const int checksumByteLen = 4;
}

/// Utility methods for EOS addresses.
class _EosAddrUtils {
  /// Computes the checksum for EOS addresses from the given public key bytes.
  ///
  /// [pubKeyBytes]: The public key bytes used to compute the checksum.
  ///
  /// Returns the computed checksum as a `List<int>`.
  static List<int> computeChecksum(List<int> pubKeyBytes) {
    return QuickCrypto.ripemd160Hash(pubKeyBytes)
        .sublist(0, EosAddrConst.checksumByteLen);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for EOS address.
class EosAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the method to decode an EOS address from its string representation.
  ///
  /// [addr]: The EOS address string to be decoded.
  /// [kwargs]: A map of optional keyword arguments.
  ///
  /// This method removes the address prefix, decodes the address bytes, and validates the checksum.
  /// It returns the decoded public key bytes of the EOS address.
  ///
  /// Returns a `List<int>` containing the public key bytes.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Remove the address prefix from the given address
    final addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
        addr, CoinsConf.eos.params.addrPrefix!);

    /// Decode the remaining address bytes
    final addrDecBytes = Base58Decoder.decode(addrNoPrefix);

    /// Validate the length of the decoded address
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      EcdsaKeysConst.pubKeyCompressedByteLen + EosAddrConst.checksumByteLen,
    );

    /// Split the address into its public key bytes and checksum
    final parts = AddrDecUtils.splitPartsByChecksum(
      addrDecBytes,
      EosAddrConst.checksumByteLen,
    );

    final pubKeyBytes = parts.item1;
    final checksumBytes = parts.item2;

    /// Validate the checksum
    AddrDecUtils.validateChecksum(
      pubKeyBytes,
      checksumBytes,
      (pubKeyBytes) => _EosAddrUtils.computeChecksum(pubKeyBytes),
    );

    // Validate public key
    // AddrDecUtils.validatePubKey(pubKeyBytes, Secp256k1PublicKey());

    return pubKeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for EOS address.
class EosAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the method to encode a EOS address from a given public key.
  ///
  /// [pubKey]: The public key to be encoded as an EOS address.
  /// [kwargs]: A map of optional keyword arguments.
  ///
  /// This method takes a public key, computes the address checksum, and encodes it as an EOS address.
  ///
  /// Returns a string containing the EOS address.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate and get the Secp256k1 public key object
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Get the raw compressed public key bytes
    final pubKeyBytes = pubKeyObj.compressed;

    /// Compute the checksum for the address
    final checksumBytes = _EosAddrUtils.computeChecksum(pubKeyBytes);

    /// Combine the address prefix, public key, and checksum to create the EOS address
    return CoinsConf.eos.params.addrPrefix! +
        Base58Encoder.encode(List<int>.from(pubKeyBytes + checksumBytes));
  }
}
