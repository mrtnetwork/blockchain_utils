import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/ss58/ss58_base.dart';
import 'exception/exception.dart';

/// Utility class for decoding and working with Substrate addresses.
class _SubstrateAddrUtils {
  static const int encodeBytesLength = 32;
  static (List<int>, int) decodeAddr(String addr, int? ss58Format) {
    // Decode from SS58 (SS58Decoder.Decode also validates the length)
    final decodedResult = SS58Decoder.decode(addr);
    final ss58FormatGot = decodedResult.$1;
    final addrDecBytes = decodedResult.$2;
    if (addrDecBytes.length != encodeBytesLength) {
      throw AddressConverterException.addressValidationFailed();
    }

    if (ss58Format != null && ss58Format != ss58FormatGot) {
      throw AddressConverterException.missingOrInvalidAddressArguments(
        reason: "Invalid address checksum",
      );
    }

    return (addrDecBytes, ss58FormatGot);
  }

  static String encode(List<int> pubKeyBytes, int ss58Format) {
    if (pubKeyBytes.length != encodeBytesLength) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid bytes length.",
      );
    }
    return SS58Encoder.encode(pubKeyBytes, ss58Format);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Substrate addresses.
class SubstrateEd25519AddrDecoder
    implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a Substrate address.
  ///
  /// This method decodes a Substrate address from the given input string. It expects a
  /// map of optional keyword arguments, with the 'ss58_format' key specifying the expected
  /// SS58 format for the address. It validates the arguments, decodes the address, and returns
  /// the decoded address as a `List<int>`.
  ///
  /// Parameters:
  ///   - addr: The address to be decoded.
  ///   - kwargs: Optional keyword arguments (e.g., 'ss58_format') for customization.
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded address bytes.
  ///
  /// Throws:
  ///   - FormatException if the provided address is not in the expected SS58 format.
  @override
  List<int> decodeAddr(String addr, {int? ss58Format}) {
    final pubkeyBytes = _SubstrateAddrUtils.decodeAddr(addr, ss58Format).$1;
    AddrKeyValidator.validateAndGetEd25519Key(pubkeyBytes);
    return pubkeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Substrate addresses.
class SubstrateEd25519AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key into a Substrate address.
  ///
  /// This method takes a public key as a `List<int>` and an optional map of keyword
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
  String encodeKey(List<int> pubKey, {int? ss58Format}) {
    ss58Format = AddrKeyValidator.getAddrArg<int>(ss58Format, "ss58Format");
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    return _SubstrateAddrUtils.encode(
      pubKeyObj.compressed.sublist(1),
      ss58Format,
    );
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Substrate addresses.
class SubstrateSr25519AddrDecoder
    implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a Substrate address.
  ///
  /// This method decodes a Substrate address from the given input string. It expects a
  /// map of optional keyword arguments, with the 'ss58_format' key specifying the expected
  /// SS58 format for the address. It validates the arguments, decodes the address, and returns
  /// the decoded address as a `List<int>`.
  ///
  /// Parameters:
  ///   - addr: The address to be decoded.
  ///   - kwargs: Optional keyword arguments (e.g., 'ss58_format') for customization.
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded address bytes.
  ///
  /// Throws:
  ///   - FormatException if the provided address is not in the expected SS58 format.
  @override
  List<int> decodeAddr(String addr, {int? ss58Format}) {
    final pubkeyBytes = _SubstrateAddrUtils.decodeAddr(addr, ss58Format).$1;
    AddrKeyValidator.validateAndGetSr25519Key(pubkeyBytes);
    return pubkeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Substrate addresses.
class SubstrateSr25519AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key into a Substrate address.
  ///
  /// This method takes a public key as a `List<int>` and an optional map of keyword
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
  String encodeKey(List<int> pubKey, {int? ss58Format}) {
    ss58Format = AddrKeyValidator.getAddrArg<int>(ss58Format, "ss58Format");

    AddrKeyValidator.validateAndGetSr25519Key(pubKey);
    return _SubstrateAddrUtils.encode(pubKey, ss58Format);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Substrate addresses.
class SubstrateSecp256k1AddrDecoder
    implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a Substrate address.
  ///
  /// This method decodes a Substrate address from the given input string. It expects a
  /// map of optional keyword arguments, with the 'ss58_format' key specifying the expected
  /// SS58 format for the address. It validates the arguments, decodes the address, and returns
  /// the decoded address as a `List<int>`.
  ///
  /// Parameters:
  ///   - addr: The address to be decoded.
  ///   - kwargs: Optional keyword arguments (e.g., 'ss58_format') for customization.
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded address bytes.
  ///
  /// Throws:
  ///   - FormatException if the provided address is not in the expected SS58 format.
  @override
  List<int> decodeAddr(String addr, {int? ss58Format}) {
    return _SubstrateAddrUtils.decodeAddr(addr, ss58Format).$1;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Substrate addresses.
class SubstrateSecp256k1AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key into a Substrate address.
  ///
  /// This method takes a public key as a `List<int>` and an optional map of keyword
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
  String encodeKey(List<int> pubKey, {int? ss58Format}) {
    ss58Format = AddrKeyValidator.getAddrArg<int>(ss58Format, "ss58Format");
    final key = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    return _SubstrateAddrUtils.encode(
      QuickCrypto.blake2b256Hash(key.compressed),
      ss58Format,
    );
  }
}

class SubstrateGenericAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey, {int? ss58Format}) {
    ss58Format = AddrKeyValidator.getAddrArg<int>(ss58Format, "ss58Format");
    try {
      if (AddrKeyValidator.hasValidPubkeyBytes(
        pubKey,
        EllipticCurveTypes.secp256k1,
      )) {
        return SubstrateSecp256k1AddrEncoder().encodeKey(
          pubKey,
          ss58Format: ss58Format,
        );
      } else if (!AddrKeyValidator.hasValidPubkeyBytes(
        pubKey,
        EllipticCurveTypes.sr25519,
      )) {
        return SubstrateEd25519AddrEncoder().encodeKey(
          pubKey,
          ss58Format: ss58Format,
        );
      }
      return SubstrateSr25519AddrEncoder().encodeKey(
        pubKey,
        ss58Format: ss58Format,
      );
    } catch (e) {
      throw AddressConverterException.addressKeyValidationFailed(
        reason: "Unsupported public key.",
      );
    }
  }
}

class SubstrateGenericAddrDecoder
    implements BlockchainAddressDecoder<List<int>> {
  @override
  List<int> decodeAddr(String addr, {int? ss58Format}) {
    return _SubstrateAddrUtils.decodeAddr(addr, ss58Format).$1;
  }

  (List<int>, int) decodeAddWithSS58(String addr, {int? ss58Format}) {
    return _SubstrateAddrUtils.decodeAddr(addr, ss58Format);
  }
}
