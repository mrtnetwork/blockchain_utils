import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/encoding/base58/src/base58_base.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

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
  static List<int> computeChecksum(List<int> pubKeyBytes) {
    final checksum = QuickCrypto.blake2b256Hash(pubKeyBytes);
    return checksum.sublist(0, ErgoAddrConst.checksumByteLen);
  }

  /// Encodes the address prefix for an Ergo address.
  static List<int> encodePrefix(
    ErgoAddressTypes addrType,
    ErgoNetworkTypes netType,
  ) {
    final prefixInt = addrType.value + netType.value;
    return prefixInt.toLeBytes();
  }
}

/// Decodes an Ergo P2PKH address.
class ErgoP2PKHAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(
    String addr, {
    ErgoNetworkTypes netType = ErgoNetworkTypes.mainnet,
  }) {
    final addrDecBytes = Base58Decoder.decode(addr);
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      EcdsaKeysConst.pubKeyCompressedByteLen +
          ErgoAddrConst.checksumByteLen +
          1,
    );

    final decode = AddrDecUtils.splitPartsByChecksum(
      addrDecBytes,
      ErgoAddrConst.checksumByteLen,
    );

    final addrWithPrefix = decode.$1;
    final checksumBytes = decode.$2;

    AddrDecUtils.validateChecksum(
      addrWithPrefix,
      checksumBytes,
      (pubKeyBytes) => _ErgoAddrUtils.computeChecksum(pubKeyBytes),
    );

    final pubKeyBytes = AddrDecUtils.validateAndRemovePrefixBytes(
      addrWithPrefix,
      _ErgoAddrUtils.encodePrefix(ErgoAddressTypes.p2pkh, netType),
    );

    return BuBytes(pubKeyBytes);
  }
}

/// Encodes an Ergo P2PKH address.
class ErgoP2PKHAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(
    List<int> pubKey, {
    ErgoNetworkTypes netType = ErgoNetworkTypes.mainnet,
  }) {
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final pubKeyBytes = pubKeyObj.toBytes(mode: CryptoKeyEncoding.base);

    final prefixByte = _ErgoAddrUtils.encodePrefix(
      ErgoAddressTypes.p2pkh,
      netType,
    );

    final addrPayloadBytes = [...prefixByte, ...pubKeyBytes];
    final checksum = _ErgoAddrUtils.computeChecksum(addrPayloadBytes);

    return Base58Encoder.encode([...addrPayloadBytes, ...checksum]);
  }
}
