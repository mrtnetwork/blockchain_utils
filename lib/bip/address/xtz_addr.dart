import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'addr_dec_utils.dart';

/// Enum defining address prefixes for Tezos (XTZ) blockchain addresses.
///
/// This enum specifies the address prefixes for Tezos blockchain addresses, which
/// differentiate between various address types (e.g., tz1, tz2, tz3).
///
/// Each enum value corresponds to a specific address prefix and consists of a list
/// of integers representing the prefix bytes. The enum also provides a static method,
/// `fromName`, to retrieve the enum value corresponding to a given name.
///
/// Example usage:
/// ```
/// final prefix = XtzAddrPrefixes.tz1;
/// final prefixBytes = prefix.value;
/// final prefixName = prefix.name;
/// ```
class XtzAddrPrefixes {
  /// Address prefix for tz1 addresses.
  static const XtzAddrPrefixes tz1 = XtzAddrPrefixes._([0x06, 0xa1, 0x9f]);

  /// Address prefix for tz2 addresses.
  static const XtzAddrPrefixes tz2 = XtzAddrPrefixes._([0x06, 0xa1, 0xa1]);

  /// Address prefix for tz3 addresses.
  static const XtzAddrPrefixes tz3 = XtzAddrPrefixes._([0x06, 0xa1, 0xa4]);

  /// The bytes that make up the address prefix.
  final List<int> value;

  /// Constructor to create an enum value with the specified prefix bytes.
  const XtzAddrPrefixes._(this.value);

  // Enum values as a list for iteration
  static const List<XtzAddrPrefixes> values = [
    tz1,
    tz2,
    tz3,
  ];

  // Enum value accessor by index
  static XtzAddrPrefixes getByIndex(int index) {
    if (index >= 0 && index < values.length) {
      return values[index];
    }
    throw MessageException('Index out of bounds', details: {"index": index});
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Tezos (XTZ) blockchain addresses.
class XtzAddrDecoder implements BlockchainAddressDecoder {
  /// Decodes a Tezos (XTZ) blockchain address from its string representation to its byte data.
  ///
  /// This method takes an encoded Tezos address string and optional keyword arguments, including
  /// the "prefix" specifying the address prefix to use for decoding. It validates and decodes the
  /// given address, removing the specified prefix and returning the decoded byte data.
  ///
  /// Throws an exception if the address is not in the expected format or if the prefix is invalid.
  ///
  /// Parameters:
  /// - [addr]: The encoded Tezos address as a string.
  /// - [kwargs]: Optional keyword arguments, including "prefix" to specify the address prefix.
  ///
  /// Returns:
  /// A [List<int>] containing the decoded byte data of the Tezos address.
  ///
  /// Example usage:
  /// ```dart
  /// final decoder = XtzAddrDecoder();
  /// final encodedAddress = "tz1abc123...";
  /// final decodedAddress = decoder.decodeAddr(encodedAddress, {"prefix": XtzAddrPrefixes.tz1});
  /// ```
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate and retrieve the address prefix from the keyword arguments.
    AddrKeyValidator.validateAddressArgs<XtzAddrPrefixes>(kwargs, "prefix");
    final XtzAddrPrefixes prefix = kwargs["prefix"];

    /// Decode the base58 address into bytes.
    final addrDecBytes = Base58Decoder.checkDecode(addr);

    /// Validate the length of the decoded address and remove the prefix bytes.
    AddrDecUtils.validateBytesLength(addrDecBytes, prefix.value.length + 20);
    final blakeBytes =
        AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefix.value);

    return List<int>.from(blakeBytes);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Tezos (XTZ) blockchain addresses.
class XtzAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as a Tezos (XTZ) blockchain address using the specified prefix.
  ///
  /// This method takes a public key in the form of a [List<int>] and optional keyword arguments,
  /// including the "prefix" specifying the address prefix to use for encoding. It first validates
  /// the public key, then derives the address by hashing and prepending the prefix. The resulting
  /// address is returned as a string.
  ///
  /// Throws an exception if the public key is not in the expected format or if the prefix is invalid.
  ///
  /// Parameters:
  /// - [pubKey]: The public key as a [List<int>] to encode.
  /// - [kwargs]: Optional keyword arguments, including "prefix" to specify the address prefix.
  ///
  /// Returns:
  /// A string representing the encoded Tezos address.
  ///
  /// Example usage:
  /// ```dart
  /// final encoder = XtzAddrEncoder();
  /// final publicKey = List<int>.from([0x03, 0x7f, 0x12, ...]);
  /// final address = encoder.encodeKey(publicKey, {"prefix": XtzAddrPrefixes.tz1});
  /// ```
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate and retrieve the address prefix from the keyword arguments.
    AddrKeyValidator.validateAddressArgs<XtzAddrPrefixes>(kwargs, "prefix");

    final XtzAddrPrefixes prefix = kwargs["prefix"];

    /// Validate the provided public key.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Derive the address by hashing and prepending the prefix.
    final blakeBytes =
        QuickCrypto.blake2b160Hash(pubKeyObj.compressed.sublist(1));

    /// Encode the address using base58 and the specified prefix.
    return Base58Encoder.checkEncode(
        List<int>.from([...prefix.value, ...blakeBytes]));
  }
}
