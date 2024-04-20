import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'decoder.dart';

class _AtomAddressUtils {
  static List<int> hash(List<int> typ, List<int> key) {
    return QuickCrypto.sha256Hash([...QuickCrypto.sha256Hash(typ), ...key]);
  }

  static final List<int> nist566p1KeyType =
      List<int>.unmodifiable("cosmos.crypto.secp256r1.PubKey".codeUnits);
}

/// Implementation of the [BlockchainAddressDecoder] for Atom (ATOM) address.
class AtomAddrDecoder implements BlockchainAddressDecoder {
  /// Decode an address using the Bech32 encoding format with the specified human-readable part (HRP).
  ///
  /// This method takes an encoded address, along with a map of optional keyword arguments,
  /// and decodes it using the Bech32 encoding format. The HRP (human-readable part) is used to
  /// determine the address format.
  ///
  /// - [addr]: The encoded address to decode.
  /// - [kwargs]: Optional keyword arguments, with 'hrp' specifying the human-readable part.
  ///
  /// Returns a List<int> containing the decoded address bytes.
  /// Throws an error if the address format is invalid or if a checksum error occurs.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final String hrp =
        AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    List<int> addrDecBytes = Bech32Decoder.decode(hrp, addr);

    AddrDecUtils.validateBytesLength(
        addrDecBytes, QuickCrypto.hash160DigestSize);
    return addrDecBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Atom (ATOM) address.
class AtomAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as an Atom (ATOM) cryptocurrency address.
  ///
  /// This method takes a public key as input and encodes it as an Atom address
  /// using Bech32 encoding with a specific Human-Readable Part (HRP).
  ///
  /// The `hrp` parameter specifies the Human-Readable Part (HRP) used in the
  /// Bech32 encoding for Atom addresses.
  ///
  /// Returns the Atom address as a string.
  ///
  /// Throws an error if the `hrp` parameter is missing or invalid, or if the
  /// public key cannot be validated.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final String hrp =
        AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    final public = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    return Bech32Encoder.encode(hrp, QuickCrypto.hash160(public.compressed));
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Atom (ATOM) address.
class AtomNist256P1AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as an Atom (ATOM) cryptocurrency address.
  ///
  /// This method takes a public key as input and encodes it as an Atom address
  /// using Bech32 encoding with a specific Human-Readable Part (HRP).
  ///
  /// The `hrp` parameter specifies the Human-Readable Part (HRP) used in the
  /// Bech32 encoding for Atom addresses.
  ///
  /// Returns the Atom address as a string.
  ///
  /// Throws an error if the `hrp` parameter is missing or invalid, or if the
  /// public key cannot be validated.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final String hrp =
        AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    final public = AddrKeyValidator.validateAndGetNist256p1Key(pubKey);
    return Bech32Encoder.encode(
        hrp,
        _AtomAddressUtils.hash(
            _AtomAddressUtils.nist566p1KeyType, public.compressed));
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Atom (ATOM) address.
class AtomNist256P1AddrDecoder implements BlockchainAddressDecoder {
  /// Decode an address using the Bech32 encoding format with the specified human-readable part (HRP).
  ///
  /// This method takes an encoded address, along with a map of optional keyword arguments,
  /// and decodes it using the Bech32 encoding format. The HRP (human-readable part) is used to
  /// determine the address format.
  ///
  /// - [addr]: The encoded address to decode.
  /// - [kwargs]: Optional keyword arguments, with 'hrp' specifying the human-readable part.
  ///
  /// Returns a List<int> containing the decoded address bytes.
  /// Throws an error if the address format is invalid or if a checksum error occurs.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final String hrp =
        AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    List<int> addrDecBytes = Bech32Decoder.decode(hrp, addr);

    AddrDecUtils.validateBytesLength(
        addrDecBytes, QuickCrypto.sha256DigestSize);
    return addrDecBytes;
  }
}
