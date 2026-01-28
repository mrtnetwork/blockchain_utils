import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'addr_dec_utils.dart';

/// Enum defining address prefixes for Tezos (XTZ) blockchain addresses.
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
  static const List<XtzAddrPrefixes> values = [tz1, tz2, tz3];
}

/// Implementation of the [BlockchainAddressDecoder] for Tezos (XTZ) blockchain addresses.
class XtzAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decodes a Tezos (XTZ) blockchain address from its string representation to its byte data.
  @override
  List<int> decodeAddr(String addr, {XtzAddrPrefixes? addressPrefix}) {
    /// Validate and retrieve the address prefix from the keyword arguments.
    addressPrefix = AddrKeyValidator.getAddrArg<XtzAddrPrefixes>(
      addressPrefix,
      "addressPrefix",
    );

    /// Decode the base58 address into bytes.
    final addrDecBytes = Base58Decoder.checkDecode(addr);

    /// Validate the length of the decoded address and remove the prefix bytes.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      addressPrefix.value.length + 20,
    );
    final blakeBytes = AddrDecUtils.validateAndRemovePrefixBytes(
      addrDecBytes,
      addressPrefix.value,
    );

    return blakeBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Tezos (XTZ) blockchain addresses.
class XtzAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as a Tezos (XTZ) blockchain address using the specified prefix.
  @override
  String encodeKey(List<int> pubKey, {XtzAddrPrefixes? addressPrefix}) {
    addressPrefix = AddrKeyValidator.getAddrArg<XtzAddrPrefixes>(
      addressPrefix,
      "addressPrefix",
    );

    /// Validate the provided public key.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Derive the address by hashing and prepending the prefix.
    final blakeBytes = QuickCrypto.blake2b160Hash(
      pubKeyObj.compressed.sublist(1),
    );

    /// Encode the address using base58 and the specified prefix.
    return Base58Encoder.checkEncode([...addressPrefix.value, ...blakeBytes]);
  }
}
