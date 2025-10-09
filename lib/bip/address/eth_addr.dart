import 'package:blockchain_utils/bech32/bech32.dart';
import 'package:blockchain_utils/hex/hex.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'addr_key_validator.dart';
import 'encoder.dart';
import 'exception/exception.dart';

/// Constants related to Ethereum addresses.
class EthAddrConst {
  /// The starting byte of an Ethereum address.
  static const int startByte = 24;

  /// The total length of an Ethereum address in hexadecimal characters.
  static const int addrLen = 40;
}

/// Utility class for Ethereum address-related operations.
class EthAddrUtils {
  /// Encodes an Ethereum address with checksum.
  ///
  /// This method takes an Ethereum address as input and calculates its checksum.
  /// The address is converted to lowercase, hashed using the Keccak256 algorithm,
  /// and the resulting hash is used to determine the case of each character in
  /// the address to create a checksum. The final Ethereum address with checksum
  /// is returned as a string.
  ///
  /// Parameters:
  ///   - addr: The Ethereum address to encode with checksum as a string.
  ///
  /// Returns:
  ///   A string representing the Ethereum address with checksum.
  static String _checksumEncode(String addr) {
    final String addrHexDigest = BytesUtils.toHexString(
        QuickCrypto.keccack256Hash(StringUtils.encode(addr.toLowerCase())));
    final List<String> encAddr = addr.split("").asMap().entries.map((entry) {
      final int i = entry.key;
      final String c = entry.value;
      final int charValue = int.parse(addrHexDigest[i], radix: 16);
      return charValue >= 8 ? c.toUpperCase() : c.toLowerCase();
    }).toList();

    return encAddr.join();
  }

  static String toChecksumAddress(String addr) {
    final String wihtoutPrefix = StringUtils.strip0x(addr);
    if (!StringUtils.isHexBytes(wihtoutPrefix)) {
      throw AddressConverterException("Invalid Ethereum address.",
          details: {"address": addr});
    }
    AddrDecUtils.validateLength(wihtoutPrefix, EthAddrConst.addrLen);
    return CoinsConf.ethereum.params.addrPrefix! +
        _checksumEncode(wihtoutPrefix);
  }

  static String addressBytesToChecksumAddress(List<int> bytes) {
    final String addr = BytesUtils.toHexString(bytes);
    return toChecksumAddress(addr);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ethereum addresses.
class EthAddrDecoder implements BlockchainAddressDecoder {
  /// Decodes an Ethereum address from its string representation.
  ///
  /// This method takes a string representing an Ethereum address as input and
  /// decodes it into its byte representation. It also provides an option to
  /// skip checksum validation if specified.
  ///
  /// Parameters:
  ///   - addr: The Ethereum address as a string to be decoded.
  ///   - kwargs: Optional keyword arguments (e.g., skip_chksum_enc) for additional
  ///             configuration.
  ///
  /// Returns:
  ///   A `List<int>` representing the byte-encoded Ethereum address.
  ///
  /// Throws:
  ///   - ArgumentException: If the address is not of the correct length or if checksum
  ///                   validation fails (if not skipped).
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final skipChecksum = kwargs["skip_chksum_enc"] ?? false;

    final String addrNoPrefix = AddrDecUtils.validateAndRemovePrefix(
        addr, CoinsConf.ethereum.params.addrPrefix!);
    AddrDecUtils.validateLength(addrNoPrefix, EthAddrConst.addrLen);
    if (!skipChecksum &&
        addrNoPrefix != EthAddrUtils._checksumEncode(addrNoPrefix)) {
      throw const AddressConverterException("Invalid checksum encoding");
    }
    return BytesUtils.fromHexString(addrNoPrefix);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ethereum addresses.
class EthAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as an Ethereum address.
  ///
  /// This method takes a public key in the form of a `List<int>` and converts it
  /// into an Ethereum address as a string. It includes an option to skip
  /// checksum encoding if specified.
  ///
  /// Parameters:
  ///   - pubKey: The public key in a `List<int>` format to be encoded.
  ///   - kwargs: Optional keyword arguments (e.g., skip_chksum_enc) for additional
  ///             configuration.
  ///
  /// Returns:
  ///   A string representing the Ethereum address.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final IPublicKey pubKeyObj =
        AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final skipChecksum = kwargs["skip_chksum_enc"] ?? false;
    final String kekkakHex = BytesUtils.toHexString(
        QuickCrypto.keccack256Hash(pubKeyObj.uncompressed.sublist(1)));
    final String addr = kekkakHex.substring(EthAddrConst.startByte);
    if (skipChecksum) {
      return addr;
    }
    return CoinsConf.ethereum.params.addrPrefix! +
        EthAddrUtils._checksumEncode(addr);
  }
}

/// Some cosmos-sdk chains integrate EVM modules, which means in the same chain,
/// both bech32 and 0x addresses are supported.
/// Here provides a utility methods to convert between each other.
/// Note: Addresses are convertible if and only if both addresses are derived using the same coin type.
class EthBech32Converter {
  /// Encodes an Ethereum address in Bech32 format.
  /// This method takes a hexadecimal Ethereum address and a prefix,
  /// converts the address to bytes, and then encodes to Bech32-format address.
  ///
  /// Parameters:
  ///   - hexAddress: The hexadecimal representation of the Ethereum address.
  ///   - prefix: The Bech32 prefix to be used for encoding.
  ///
  /// Returns:
  ///   A Bech32-encoded address.
  ///
  /// Throws:
  ///  - AssertionError: If the length of the cleaned hexadecimal address is not equal to the expected Ethereum address length.
  static String ethAddressToBech32(String ethAddress, prefix) {

    final cleanHex = AddrDecUtils.validateAndRemovePrefix(
      ethAddress, CoinsConf.ethereum.params.addrPrefix!
    );
    assert(
      cleanHex.length == EthAddrConst.addrLen,
      "Invalid Ethereum address length: ${cleanHex.length}, expected: ${EthAddrConst.addrLen}"
    );
    final hexAddressBytes = hex.decode(cleanHex);
    return Bech32Encoder.encode(prefix, hexAddressBytes);
  }

  /// Decodes a Bech32-encoded address.
  /// This method takes a Bech32-encoded address
  /// and decodes it to its hexadecimal representation.
  ///
  /// Parameters:
  ///   - bech32Address: The Bech32-encoded Ethereum address.
  ///
  /// Returns:
  ///   A string representing the Ethereum address.
  static String bech32ToEthAddress(String bech32Address, prefix) {
    final decoded = Bech32Decoder.decode(prefix, bech32Address);
    final hexEncoded = hex.encode(decoded);
    assert(
      hexEncoded.length == EthAddrConst.addrLen,
      "Invalid Ethereum address length: ${hexEncoded.length}, expected: ${EthAddrConst.addrLen}"
    );
    return '${CoinsConf.ethereum.params.addrPrefix!}$hexEncoded';
  }
}
