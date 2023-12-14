import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Utility class for decoding and working with Substrate addresses.
class _SubstrateAddrUtils {
  static List<int> decodeAddr(
      String addr, int ss58Format, IPublicKey? pubKeyCls) {
    // Decode from SS58 (SS58Decoder.Decode also validates the length)
    final decodedResult = SS58Decoder.decode(addr);
    final ss58FormatGot = decodedResult.item1;
    final addrDecBytes = decodedResult.item2;

    if (ss58Format != ss58FormatGot) {
      throw ArgumentException(
          "Invalid SS58 format (expected $ss58Format, got $ss58FormatGot)");
    }

    // Validate public key
    // AddrDecUtils.validatePubKey(addrDecBytes, pubKeyCls);

    return addrDecBytes;
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Substrate addresses.
class SubstrateEd25519AddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a Substrate address.
  ///
  /// This method decodes a Substrate address from the given input string. It expects a
  /// map of optional keyword arguments, with the 'ss58_format' key specifying the expected
  /// SS58 format for the address. It validates the arguments, decodes the address, and returns
  /// the decoded address as a List<int>.
  ///
  /// Parameters:
  ///   - addr: The address to be decoded.
  ///   - kwargs: Optional keyword arguments (e.g., 'ss58_format') for customization.
  ///
  /// Returns:
  ///   A List<int> containing the decoded address bytes.
  ///
  /// Throws:
  ///   - FormatException if the provided address is not in the expected SS58 format.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    AddrKeyValidator.validateAddressArgs<int>(kwargs, "ss58_format");
    final int ss58Format = kwargs["ss58_format"];
    return _SubstrateAddrUtils.decodeAddr(addr, ss58Format, null);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Substrate addresses.
class SubstrateEd25519AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key into a Substrate address.
  ///
  /// This method takes a public key as a List<int> and an optional map of keyword
  /// arguments, with the 'ss58_format' key specifying the desired SS58 format for
  /// the address. It validates the arguments, encodes the public key, and returns
  /// the resulting Substrate address as a String.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a Substrate address.
  ///   - kwargs: Optional keyword arguments (e.g., 'ss58_format') for customization.
  ///
  /// Returns:
  ///   A String representing the Substrate address encoded from the provided public key.
  ///
  /// Throws:
  ///   - FormatException if the provided SS58 format is invalid or if the public key
  ///     is not a valid Ed25519 key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    AddrKeyValidator.validateAddressArgs<int>(kwargs, "ss58_format");
    final int ss58Format = kwargs["ss58_format"];
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    return SS58Encoder.encode(pubKeyObj.compressed.sublist(1), ss58Format);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Substrate addresses.
class SubstrateSr25519AddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a Substrate address.
  ///
  /// This method decodes a Substrate address from the given input string. It expects a
  /// map of optional keyword arguments, with the 'ss58_format' key specifying the expected
  /// SS58 format for the address. It validates the arguments, decodes the address, and returns
  /// the decoded address as a List<int>.
  ///
  /// Parameters:
  ///   - addr: The address to be decoded.
  ///   - kwargs: Optional keyword arguments (e.g., 'ss58_format') for customization.
  ///
  /// Returns:
  ///   A List<int> containing the decoded address bytes.
  ///
  /// Throws:
  ///   - FormatException if the provided address is not in the expected SS58 format.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    AddrKeyValidator.validateAddressArgs<int>(kwargs, "ss58_format");
    final int ss58Format = kwargs["ss58_format"];
    return _SubstrateAddrUtils.decodeAddr(addr, ss58Format, null);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Substrate addresses.
class SubstrateSr25519AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key into a Substrate address.
  ///
  /// This method takes a public key as a List<int> and an optional map of keyword
  /// arguments, with the 'ss58_format' key specifying the desired SS58 format for
  /// the address. It validates the arguments, encodes the public key, and returns
  /// the resulting Substrate address as a String.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a Substrate address.
  ///   - kwargs: Optional keyword arguments (e.g., 'ss58_format') for customization.
  ///
  /// Returns:
  ///   A String representing the Substrate address encoded from the provided public key.
  ///
  /// Throws:
  ///   - FormatException if the provided SS58 format is invalid or if the public key
  ///     is not a valid sr25519 key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    AddrKeyValidator.validateAddressArgs<int>(kwargs, "ss58_format");
    final int ss58Format = kwargs["ss58_format"];
    List<int> pubBytes = pubKey;
    try {
      AddrKeyValidator.validateAndGetSr25519Key(pubBytes);
    } catch (e) {
      final pub = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
      pubBytes = pub.compressed.sublist(1);
    }
    return SS58Encoder.encode(pubBytes, ss58Format);
  }
}
