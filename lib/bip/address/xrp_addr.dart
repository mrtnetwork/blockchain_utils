import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'exception/exception.dart';
import 'p2pkh_addr.dart';

/// Constants related to XRP (Ripple) addresses.
class _XRPAddressConst {
  /// The length of the tag included in X-addresses.
  static const int xAddressTagLength = 9;

  /// The prefix for mainnet X-addresses.
  static const List<int> _xAddressPrefixMain = [0x05, 0x44];

  /// The prefix for testnet X-addresses.
  static const List<int> _xAddressPrefixTest = [0x04, 0x93];

  /// The length of the X-address prefix.
  static const int xAddressPrefixLength = 2;
}

class XRPXAddressDecodeResult {
  final List<int> bytes;
  final int? tag;
  final bool isTestnet;
  XRPXAddressDecodeResult(
      {required List<int> bytes, required this.tag, required this.isTestnet})
      : bytes = BytesUtils.toBytes(bytes, unmodifiable: true);
}

class XRPAddressUtils {
  /// Generates an XRP (Ripple) address from the provided address hash.
  ///
  /// This method takes an address hash as input and encodes it into an XRP address
  /// using the Base58Check encoding with the prefix specified in CoinsConf.ripple.params.p2pkhNetVer.
  ///
  /// [addrHash] The address hash used to generate the XRP address.
  /// returns The generated XRP address as a Base58Check encoded string.
  /// throws ArgumentException if the address hash length is not equal to QuickCrypto.hash160DigestSize.
  static String hashToAddress(List<int> addrHash) {
    if (addrHash.length != QuickCrypto.hash160DigestSize) {
      throw AddressConverterException(
          "address hash must be ${QuickCrypto.hash160DigestSize} bytes length but got ${addrHash.length}");
    }

    return Base58Encoder.checkEncode(
        List<int>.from([...CoinsConf.ripple.params.p2pkhNetVer!, ...addrHash]),
        Base58Alphabets.ripple);
  }

  /// Converts a public key represented as a list of bytes into an XRP (Ripple) address.
  ///
  /// This method first computes the RIPEMD-160 hash of the SHA-256 hash of the public key bytes
  /// and then generates an XRP address from the computed hash using the [hashToAddress] method.
  ///
  /// [publicKeyBytes] The public key bytes used to generate the XRP address.
  /// returns The XRP address corresponding to the provided public key bytes.
  static String _toAddress(List<int> publicKeyBytes) {
    final hash160 = QuickCrypto.hash160(publicKeyBytes);

    return hashToAddress(hash160);
  }

  /// Generates an XRP (Ripple) X-address from the provided address hash, X-Address prefix, and optional tag.
  ///
  /// This method constructs an X-Address by combining the address hash, X-Address prefix, and
  /// an optional tag, and then encodes it using the Base58Check encoding with the Ripple alphabet.
  ///
  /// [addrHash] The address hash used to generate the X-Address.
  /// [xAddrPrefix] The prefix for the X-Address, specific to mainnet or testnet.
  /// [tag] An optional tag associated with the X-Address. Must be lower than 2^32 for Ripple X-Addresses.
  /// returns The generated X-Address as a Base58Check encoded string.
  /// throws ArgumentException if the tag is invalid.
  static String hashToXAddress(
      List<int> addrHash, List<int> xAddrPrefix, int? tag) {
    if (tag != null && tag > mask32) {
      throw const AddressConverterException(
          "Invalid tag. Tag should be lower than 2^32 for Ripple X address");
    }
    List<int> addrBytes = [...xAddrPrefix, ...addrHash];
    List<int> tagBytes = writeUint64LE(tag ?? 0);
    addrBytes = [...addrBytes, tag == null ? 0 : 1, ...tagBytes];
    return Base58Encoder.checkEncode(addrBytes, Base58Alphabets.ripple);
  }

  /// Decodes an X-Address and extracts the address hash and, if present, the tag.
  ///
  /// This method decodes the provided X-Address using Base58 decoding and validates the decoded bytes.
  /// It then extracts the address hash and, if present, the tag from the decoded bytes and returns them as a tuple.
  ///
  /// [addr] The X-Address to be decoded.
  /// [prefix] The optional prefix representing the network type (mainnet or testnet).
  /// returns A tuple containing the address hash and an optional tag extracted from the X-Address.
  /// throws ArgumentException if the decoded address has invalid length, prefix mismatch, or an invalid tag.
  static XRPXAddressDecodeResult decodeXAddress(
      String addr, List<int>? prefix) {
    List<int> addrDecBytes =
        Base58Decoder.checkDecode(addr, Base58Alphabets.ripple);

    AddrDecUtils.validateBytesLength(
        addrDecBytes,
        QuickCrypto.hash160DigestSize +
            _XRPAddressConst.xAddressPrefixLength +
            _XRPAddressConst.xAddressTagLength);

    final prefixBytes =
        addrDecBytes.sublist(0, _XRPAddressConst.xAddressPrefixLength);

    if (prefix != null) {
      if (!BytesUtils.bytesEqual(prefix, prefixBytes)) {
        throw AddressConverterException(
            'Invalid prefix (expected $prefix, got $prefixBytes)');
      }
    } else {
      if (!BytesUtils.bytesEqual(
              prefixBytes, _XRPAddressConst._xAddressPrefixMain) &&
          !BytesUtils.bytesEqual(
              prefixBytes, _XRPAddressConst._xAddressPrefixTest)) {
        throw const AddressConverterException(
            'Invalid prefix for mainnet or testnet ripple address');
      }
    }

    final List<int> addrHash = addrDecBytes.sublist(
        prefixBytes.length, QuickCrypto.hash160DigestSize + prefixBytes.length);

    List<int> tagBytes = addrDecBytes
        .sublist(addrDecBytes.length - _XRPAddressConst.xAddressTagLength);
    int tagFlag = tagBytes[0];
    if (tagFlag != 0 && tagFlag != 1) {
      throw AddressConverterException(
          'Invalid tag flag, tag flag should be 0 or 1 but got ${tagBytes[0]}');
    }
    tagBytes = tagBytes.sublist(1);
    if (tagFlag == 0 && !BytesUtils.bytesEqual(tagBytes, List.filled(8, 0))) {
      throw const AddressConverterException(
          "tag bytes must be zero for flag 0");
    }

    int? tag;
    if (tagFlag == 1) {
      tag = readUint32LE(tagBytes);
    }

    return XRPXAddressDecodeResult(
        bytes: addrHash,
        tag: tag,
        isTestnet: BytesUtils.bytesEqual(
            prefixBytes, _XRPAddressConst._xAddressPrefixTest));
  }

  /// Converts a classic XRP address to an X-Address.
  ///
  /// This method decodes the classic XRP address to obtain the address hash and then
  /// calls [hashToXAddress] with the provided X-Address prefix and optional tag to generate the resulting X-Address.
  ///
  /// [addr] The classic XRP address to be converted to an X-Address.
  /// [xAddrPrefix] The prefix for the X-Address, specific to mainnet or testnet.
  /// [tag] An optional tag associated with the X-Address. Must be lower than 2^32 for Ripple X-Addresses.
  /// returns The converted X-Address as a Base58Check encoded string.
  static String classicToXAddress(String addr, List<int> xAddrPrefix,
      {int? tag}) {
    final addrHash = XrpAddrDecoder().decodeAddr(addr);
    return hashToXAddress(addrHash, xAddrPrefix, tag);
  }

  /// Converts an X-Address to a classic XRP address.
  ///
  /// This method decodes the X-Address to obtain the address bytes and then encodes them into a classic XRP address
  /// using the Base58Check encoding with the prefix specified in CoinsConf.ripple.params.p2pkhNetVer.
  ///
  /// [xAddrress] The X-Address to be converted to a classic XRP address.
  /// [xAddrPrefix] The prefix for the X-Address, specific to mainnet or testnet.
  /// returns The converted classic XRP address as a Base58Check encoded string.
  static String xAddressToClassic(String xAddrress, List<int> xAddrPrefix) {
    final decode =
        XrpXAddrDecoder().decodeAddr(xAddrress, {"prefix": xAddrPrefix});

    return Base58Encoder.checkEncode(
        List<int>.from([...CoinsConf.ripple.params.p2pkhNetVer!, ...decode]),
        Base58Alphabets.ripple);
  }

  /// Decodes the given address, whether it is an X-Address or a classic address, and returns the address bytes.
  ///
  /// This method attempts to decode the provided address as a classic XRP address using XrpAddrDecoder.
  /// If decoding as a classic address fails, it attempts to decode the address as an X-Address using decodeXAddress.
  /// Returns the decoded address bytes in both cases.
  ///
  /// [address] The address to be decoded, which can be either an X-Address or a classic address.
  /// [xAddrPrefix] The optional prefix for the X-Address, specific to mainnet or testnet.
  /// returns The decoded address bytes.
  /// throws ArgumentException if the provided address is neither a valid X-Address nor a classic address.
  static List<int> decodeAddress(String address, {List<int>? xAddrPrefix}) {
    try {
      try {
        final decode = XrpAddrDecoder().decodeAddr(address);
        return decode;
      } catch (e) {
        final xAddr = decodeXAddress(address, xAddrPrefix);
        return xAddr.bytes;
      }
    } catch (e) {
      throw const AddressConverterException(
          "invalid ripple X or classic address");
    }
  }

  /// Checks whether the given address is an X-Address.
  ///
  /// This method attempts to decode the provided address as an X-Address using decodeXAddress.
  /// Returns true if the decoding succeeds, indicating that the address is an X-Address; otherwise, returns false.
  ///
  /// [address] The address to be checked.
  /// returns true if the address is an X-Address; false otherwise.
  static bool isXAddress(String? address) {
    try {
      decodeXAddress(address!, null);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks whether the given address is a classic XRP address.
  ///
  /// This method attempts to decode the provided address as a classic XRP address using XrpAddrDecoder.
  /// Returns true if the decoding succeeds, indicating that the address is a classic XRP address; otherwise, returns false.
  ///
  /// [address] The address to be checked.
  /// returns true if the address is a classic XRP address; false otherwise.
  static bool isClassicAddress(String? address) {
    try {
      XrpAddrDecoder().decodeAddr(address!);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ensures that the provided address is a classic XRP address, and if not, converts it to a classic address.
  ///
  /// This method checks if the provided address is a classic XRP address; if it is, the address is returned unchanged.
  /// If the address is an X-Address, it is decoded and converted to a classic address using hashToAddress.
  ///
  /// [address] The address to be checked and ensured as a classic XRP address.
  /// returns The classic XRP address after ensuring it.
  static String ensureClassicAddress(String address) {
    if (isClassicAddress(address)) {
      return address;
    }
    final addrHash = decodeXAddress(address, null).bytes;
    return hashToAddress(addrHash);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for ripple (XRP) blockchain addresses.
class XrpAddrDecoder implements BlockchainAddressDecoder {
  /// Decodes a Ripple (XRP) blockchain address into its byte representation.
  ///
  /// This method takes a Ripple address as a string and optional keyword arguments,
  /// including "net_ver" specifying the network version byte and "base58_alph" specifying
  /// the Base58 alphabet to use for decoding. It delegates the decoding process to the
  /// [P2PKHAddrDecoder] class, providing the necessary parameters. The resulting byte
  /// representation of the address is returned as a [List<int>].
  ///
  /// Parameters:
  /// - [addr]: The Ripple address as a string to decode.
  /// - [kwargs]: Optional keyword arguments, including "net_ver" and "base58_alph" settings.
  ///
  /// Returns:
  /// A [List<int>] representing the byte data of the decoded Ripple address.
  ///
  /// Example usage:
  /// ```dart
  /// final decoder = XrpAddrDecoder();
  /// final rippleAddress = "r9HcFbTdsuGAAQ14xaNk7zPQGqPt6fPqGT";
  /// final decodedBytes = decoder.decodeAddr(rippleAddress);
  /// ```
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Delegate the decoding process to P2PKHAddrDecoder with specific parameters.
    return P2PKHAddrDecoder().decodeAddr(addr, {
      "net_ver": CoinsConf.ripple.params.p2pkhNetVer!,
      "base58_alph": Base58Alphabets.ripple,
    });
  }
}

/// Implementation of the [BlockchainAddressEncoder] for ripple (XRP) blockchain addresses.
class XrpAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a Ripple (XRP) public key as a blockchain address.
  ///
  /// This method takes a public key represented as a [List<int>] and optional keyword arguments,
  /// including "net_ver" specifying the network version byte and "base58_alph" specifying
  /// the Base58 alphabet to use for encoding. It delegates the encoding process to the
  /// [P2PKHAddrEncoder] class, providing the necessary parameters. The resulting Ripple
  /// address is returned as a string.
  ///
  /// Parameters:
  /// - [pubKey]: The public key to encode as a Ripple address.
  /// - [kwargs]: Optional keyword arguments, including "net_ver" and "base58_alph" settings.
  ///
  /// Returns:
  /// A Ripple address string representing the encoded public key.
  ///
  /// Example usage:
  /// ```dart
  /// final encoder = XrpAddrEncoder();
  /// final publicKey = List<int>.from([/* public key bytes */]);
  /// final rippleAddress = encoder.encodeKey(publicKey);
  /// ```
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    var publicType = kwargs["curve_type"] ?? EllipticCurveTypes.secp256k1;
    if (publicType is! EllipticCurveTypes ||
        (publicType != EllipticCurveTypes.secp256k1 &&
            publicType != EllipticCurveTypes.ed25519)) {
      throw const AddressConverterException(
          'Missing required parameters: curve_type, curvetype must be EllipticCurveTypes.secp256k1 or EllipticCurveTypes.ed25519');
    }
    if (publicType == EllipticCurveTypes.secp256k1) {
      return P2PKHAddrEncoder().encodeKey(pubKey, {
        "net_ver": CoinsConf.ripple.params.p2pkhNetVer!,
        "base58_alph": Base58Alphabets.ripple,
      });
    }
    AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    return XRPAddressUtils._toAddress(pubKey);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for ripple (XRP) blockchain addresses.
class XrpXAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes the public key into a Ripple (XRP) X-Address.
  ///
  /// This method encodes the given public key into a Ripple address using the specified network prefix and, optionally, a tag.
  ///
  /// [pubKey] The public key to be encoded.
  /// [kwargs] An optional map of keyword arguments, such as "prefix" for the address prefix and "tag" for an optional tag.
  /// returns The encoded Ripple address as a string.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate network version, Base58 alphabet, and public key mode arguments.
    final prefix =
        AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "prefix");
    int? tag;
    if (kwargs.containsKey("tag")) {
      tag = AddrKeyValidator.validateAddressArgs<int>(kwargs, "tag");
    }

    List<int> pubKeyBytes;

    try {
      /// Validate and process the public key as a Secp256k1 key.
      pubKeyBytes =
          AddrKeyValidator.validateAndGetSecp256k1Key(pubKey).compressed;
    } catch (e) {
      AddrKeyValidator.validateAndGetEd25519Key(pubKey);
      pubKeyBytes = pubKey;
    }

    /// Calculate the hash160 of the public key.
    final hash160 = QuickCrypto.hash160(pubKeyBytes);

    return XRPAddressUtils.hashToXAddress(hash160, prefix, tag);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for decoding Ripple (XRP) blockchain addresses.
class XrpXAddrDecoder implements BlockchainAddressDecoder {
  /// Validates and decodes the given Ripple (XRP) X-address.
  ///
  /// This method decodes the provided Ripple address using the specified network prefix.
  ///
  /// [addr] The Ripple address to be decoded.
  /// [kwargs] An optional map of keyword arguments, such as "prefix" for the address prefix.
  /// returns The decoded address bytes.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final prefix =
        AddrKeyValidator.nullOrValidateAddressArgs<List<int>>(kwargs, "prefix");

    return XRPAddressUtils.decodeXAddress(addr, prefix).bytes;
  }
}
