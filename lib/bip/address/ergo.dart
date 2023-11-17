import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/numbers/int_utils.dart';

/// An enumeration representing different Ergo address types.
enum ErgoAddressTypes {
  /// Pay-to-Public-Key-Hash
  p2pkh(0x01),

  /// Pay-to-Script-Hash
  p2sh(0x02);

  final int value;
  const ErgoAddressTypes(this.value);
}

/// An enumeration representing different Ergo network types.
enum ErgoNetworkTypes {
  mainnet(0x00),
  testnet(0x10);

  final int value;
  const ErgoNetworkTypes(this.value);
}

/// Constants related to Ergo addresses.
class ErgoAddrConst {
  /// Length of the checksum bytes.
  static const int checksumByteLen = 4;
}

/// A utility class for Ergo address-related operations.
class _ErgoAddrUtils {
  /// Computes the checksum for an Ergo address.
  ///
  /// [pubKeyBytes]: The public key bytes to generate the checksum from.
  /// Returns a List<int> representing the computed checksum.
  static List<int> computeChecksum(List<int> pubKeyBytes) {
    final checksum = QuickCrypto.blake2b256Hash(pubKeyBytes);
    return checksum.sublist(0, ErgoAddrConst.checksumByteLen);
  }

  /// Encodes the address prefix for an Ergo address.
  ///
  /// [addrType]: The address type (e.g., p2pkh or p2sh).
  /// [netType]: The network type (e.g., mainnet or testnet).
  /// Returns a List<int> representing the encoded prefix.
  static List<int> encodePrefix(
      ErgoAddressTypes addrType, ErgoNetworkTypes netType) {
    final prefixInt = addrType.value + netType.value;
    final prefix = IntUtils.toBytes(prefixInt,
        length: IntUtils.bitlengthInBytes(prefixInt));
    return prefix;
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ergo address.
class ErgoP2PKHAddrDecoder implements BlockchainAddressDecoder {
  /// Decodes an Ergo address into its respective public key bytes.
  ///
  /// [addr]: The Ergo address to decode.
  /// [kwargs]: Optional parameters.
  ///   - [net_type]: The network type for the Ergo address (mainnet or testnet).
  ///
  /// Returns a List<int> representing the public key bytes decoded from the address.
  /// Throws an ArgumentError if the address type is not of ErgoNetworkTypes.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final netType = kwargs['net_type'] ?? ErgoNetworkTypes.mainnet;

    /// Validate network type
    if (netType is! ErgoNetworkTypes) {
      throw ArgumentError(
          'Address type is not an enumerative of ErgoNetworkTypes');
    }
    final addrDecBytes = Base58Decoder.decode(addr);
    AddrDecUtils.validateBytesLength(
        addrDecBytes,
        EcdsaKeysConst.pubKeyCompressedByteLen +
            ErgoAddrConst.checksumByteLen +
            1);

    final decode = AddrDecUtils.splitPartsByChecksum(
        addrDecBytes, ErgoAddrConst.checksumByteLen);

    /// Extract checksum and public key bytes
    final addrWithPrefix = decode.$1;
    final checksumBytes = decode.$2;

    /// Validate checksum
    AddrDecUtils.validateChecksum(addrWithPrefix, checksumBytes,
        (pubKeyBytes) => _ErgoAddrUtils.computeChecksum(pubKeyBytes));

    /// Extract public key bytes and remove the prefix
    final pubKeyBytes = AddrDecUtils.validateAndRemovePrefixBytes(
        addrWithPrefix,
        _ErgoAddrUtils.encodePrefix(ErgoAddressTypes.p2pkh, netType));

    return pubKeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ergo address.
class ErgoP2PKHAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key into an Ergo address.
  ///
  /// [pubKey]: The public key to encode into an address.
  /// [kwargs]: Optional parameters.
  ///   - [net_type]: The network type for the Ergo address (mainnet or testnet).
  ///
  /// Returns an Ergo address as a string.
  /// Throws an ArgumentError if the address type is not of ErgoNetworkTypes.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final netType = kwargs['net_type'] ?? ErgoNetworkTypes.mainnet;

    /// Validate network type
    if (netType is! ErgoNetworkTypes) {
      throw ArgumentError(
          'Address type is not an enumerative of ErgoNetworkTypes');
    }

    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final pubKeyBytes = pubKeyObj.compressed;

    final prefixByte =
        _ErgoAddrUtils.encodePrefix(ErgoAddressTypes.p2pkh, netType);

    final addrPayloadBytes = List<int>.from([...prefixByte, ...pubKeyBytes]);
    final checksum = _ErgoAddrUtils.computeChecksum(addrPayloadBytes);

    return Base58Encoder.encode(
        List<int>.from([...addrPayloadBytes, ...checksum]));
  }
}
