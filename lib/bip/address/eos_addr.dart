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
  static List<int> computeChecksum(List<int> pubKeyBytes) {
    return QuickCrypto.ripemd160Hash(
      pubKeyBytes,
    ).sublist(0, EosAddrConst.checksumByteLen);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for EOS address.
class EosAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the method to decode an EOS address from its string representation.
  @override
  List<int> decodeAddr(String addr) {
    /// Remove the address prefix from the given address
    final addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
      addr,
      AddrKeyValidator.getConfigArg(
        CoinsConf.eos.params.addrPrefix,
        "addrPrefix",
      ),
    );

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

    final pubKeyBytes = parts.$1;
    final checksumBytes = parts.$2;

    /// Validate the checksum
    AddrDecUtils.validateChecksum(
      pubKeyBytes,
      checksumBytes,
      (pubKeyBytes) => _EosAddrUtils.computeChecksum(pubKeyBytes),
    );

    return pubKeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for EOS address.
class EosAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the method to encode a EOS address from a given public key.
  @override
  String encodeKey(List<int> pubKey) {
    /// Validate and get the Secp256k1 public key object
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Get the raw compressed public key bytes
    final pubKeyBytes = pubKeyObj.compressed;

    /// Compute the checksum for the address
    final checksumBytes = _EosAddrUtils.computeChecksum(pubKeyBytes);
    final prefix = AddrKeyValidator.getConfigArg(
      CoinsConf.eos.params.addrPrefix,
      "addrPrefix",
    );

    /// Combine the address prefix, public key, and checksum to create the EOS address
    return prefix + Base58Encoder.encode(pubKeyBytes + checksumBytes);
  }
}
