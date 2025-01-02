import 'dart:typed_data';

import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'exception/exception.dart';

/// An enumeration representing different Ergo address types.
class ErgoAddressTypes {
  /// Pay-to-Public-Key-Hash
  static const ErgoAddressTypes p2pkh = ErgoAddressTypes._(0x01);

  /// Pay-to-Script-Hash
  static const ErgoAddressTypes p2sh = ErgoAddressTypes._(0x02);

  final int value;

  /// Constructor for ErgoAddressTypes.
  const ErgoAddressTypes._(this.value);
}

/// An enumeration representing different Ergo network types.
class ErgoNetworkTypes {
  /// Mainnet network type with a value of 0x00.
  static const ErgoNetworkTypes mainnet = ErgoNetworkTypes._("mainnet", 0x00);

  /// Testnet network type with a value of 0x10.
  static const ErgoNetworkTypes testnet = ErgoNetworkTypes._("testnet", 0x10);

  final String name;
  final int value;

  /// Constructor for ErgoNetworkTypes.
  const ErgoNetworkTypes._(this.name, this.value);

  static const List<ErgoNetworkTypes> values = [mainnet, testnet];
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
  /// Returns a `List` representing the computed checksum.
  static List<int> computeChecksum(List<int> pubKeyBytes) {
    final checksum = QuickCrypto.blake2b256Hash(pubKeyBytes);
    return checksum.sublist(0, ErgoAddrConst.checksumByteLen);
  }

  /// Encodes the address prefix for an Ergo address.
  ///
  /// [addrType]: The address type (e.g., p2pkh or p2sh).
  /// [netType]: The network type (e.g., mainnet or testnet).
  /// Returns a `List` representing the encoded prefix.
  static List<int> encodePrefix(
      ErgoAddressTypes addrType, ErgoNetworkTypes netType) {
    final prefixInt = addrType.value + netType.value;
    final prefix = IntUtils.toBytes(prefixInt,
        length: IntUtils.bitlengthInBytes(prefixInt), byteOrder: Endian.little);
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
  /// Returns a `List` representing the public key bytes decoded from the address.
  /// Throws an ArgumentException if the address type is not of ErgoNetworkTypes.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final netType = kwargs['net_type'] ?? ErgoNetworkTypes.mainnet;

    /// Validate network type
    if (netType is! ErgoNetworkTypes) {
      throw const AddressConverterException(
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
    final addrWithPrefix = decode.item1;
    final checksumBytes = decode.item2;

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
  /// Throws an ArgumentException if the address type is not of ErgoNetworkTypes.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final netType = kwargs['net_type'] ?? ErgoNetworkTypes.mainnet;

    /// Validate network type
    if (netType is! ErgoNetworkTypes) {
      throw const AddressConverterException(
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
