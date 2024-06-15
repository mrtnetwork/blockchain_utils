import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bech32/bch_bech32.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'decoder.dart';
import 'exception/exception.dart';

/// Enumeration representing different modes for public keys used in P2PKH addresses.
///
/// This enum defines different modes for public keys that can be used in P2PKH (Pay-to-Public-Key-Hash)
/// addresses. These modes may include compressed and uncompressed public keys, among others.
enum PubKeyModes {
  compressed,
  uncompressed,
}

/// Implementation of the [BlockchainAddressDecoder] for P2PKH (Pay-to-Public-Key-Hash) addresses.
class P2PKHAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a P2PKH (Pay-to-Public-Key-Hash) address.
  ///
  /// This method decodes a P2PKH address from the provided input string using Base58 encoding.
  /// It expects an optional map of keyword arguments with 'net_ver' specifying the network version bytes,
  /// and 'base58_alph' for the Base58 alphabet. It validates the arguments, decodes the address,
  /// checks its length and network version, and returns the decoded P2PKH address as a List<int>.
  ///
  /// Parameters:
  ///   - addr: The P2PKH address to be decoded.
  ///   - kwargs: Optional keyword arguments with 'net_ver' for the network version and 'base58_alph' for Base58 alphabet.
  ///
  /// Returns:
  ///   A List<int> containing the decoded P2PKH address bytes.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate network version and Base58 alphabet arguments.
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "net_ver");
    List<int> netVarBytes = kwargs["net_ver"];

    final Base58Alphabets alphabet =
        kwargs["base58_alph"] ?? Base58Alphabets.bitcoin;

    /// Decode the address using the specified Base58 alphabet.
    List<int> addrDecBytes = Base58Decoder.checkDecode(addr, alphabet);

    /// Validate the length of the decoded address and its network version.
    AddrDecUtils.validateBytesLength(
        addrDecBytes, QuickCrypto.hash160DigestSize + netVarBytes.length);

    /// Remove and validate the network version prefix bytes.
    return List<int>.from(
        AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, netVarBytes));
  }
}

/// Implementation of the [BlockchainAddressEncoder] for P2PKH (Pay-to-Public-Key-Hash) addresses.
class P2PKHAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a P2PKH (Pay-to-Public-Key-Hash) address.
  ///
  /// This method encodes a public key as a P2PKH address using Base58 encoding. It expects
  /// an optional map of keyword arguments with 'net_ver' specifying the network version bytes,
  /// 'base58_alph' for the Base58 alphabet, and 'pub_key_mode' for the public key mode.
  /// It validates the arguments, processes the public key as a Secp256k1 key, determines the
  /// public key mode (compressed or uncompressed), generates a hash160 of the public key,
  /// and encodes it as a P2PKH address using Base58.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a P2PKH address.
  ///   - kwargs: Optional keyword arguments with 'net_ver' for the network version, 'base58_alph' for Base58 alphabet,
  ///     and 'pub_key_mode' for the public key mode.
  ///
  /// Returns:
  ///   A String representing the Base58-encoded P2PKH address derived from the provided public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate network version, Base58 alphabet, and public key mode arguments.
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "net_ver");
    final List<int> netVerBytes = kwargs["net_ver"];
    final alphabet = kwargs["base58_alph"] ?? Base58Alphabets.bitcoin;
    if (alphabet is! Base58Alphabets) {
      throw const AddressConverterException("invalid base58 alphabet");
    }
    final pubKeyModes = kwargs["pub_key_mode"] ?? PubKeyModes.compressed;
    if (pubKeyModes is! PubKeyModes) {
      throw const AddressConverterException("invalid pub key mode");
    }

    /// Validate and process the public key as a Secp256k1 key.
    final publicKey = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Determine the public key bytes based on the selected mode.
    final List<int> pubKeyBytes = pubKeyModes == PubKeyModes.compressed
        ? publicKey.compressed
        : publicKey.uncompressed;

    /// Calculate the hash160 of the public key.
    final hash160 = QuickCrypto.hash160(pubKeyBytes);

    /// Combine the network version and hash160 to form the address bytes.
    return Base58Encoder.checkEncode(
        List<int>.from([...netVerBytes, ...hash160]), alphabet);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for P2PKH (Pay-to-Public-Key-Hash) addresses.
class BchP2PKHAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a P2PKH (Pay-to-Public-Key-Hash) address using bch Bech32 encoding.
  ///
  /// This method decodes a P2PKH address from the provided input string using Bech32 encoding.
  /// It expects an optional map of keyword arguments with 'net_ver' specifying the network version bytes
  /// and 'hrp' for the Human-Readable Part (HRP). It validates the arguments, decodes the Bech32 address,
  /// checks its network version, length, and checksum, and returns the decoded P2PKH address as a List<int>.
  ///
  /// Parameters:
  ///   - addr: The Bech32-encoded P2PKH address to be decoded.
  ///   - kwargs: Optional keyword arguments with 'net_ver' for the network version and 'hrp' for HRP.
  ///
  /// Returns:
  ///   A List<int> containing the decoded P2PKH address bytes.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate network version and HRP arguments.
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "net_ver");
    AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    final String hrp = kwargs["hrp"];
    final List<int> netVerBytes = kwargs["net_ver"];

    /// Decode the Bech32 address and retrieve network version and decoded bytes.
    final result = BchBech32Decoder.decode(hrp, addr);
    List<int> netVerBytesGot = result.item1;
    List<int> addrDecBytes = result.item2;

    /// Validate that the decoded network version matches the expected network version.
    if (!BytesUtils.bytesEqual(netVerBytes, netVerBytesGot)) {
      throw const AddressConverterException("Invalid net version");
    }

    /// Validate the length of the decoded address.
    AddrDecUtils.validateBytesLength(
        addrDecBytes, QuickCrypto.hash160DigestSize);
    return addrDecBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for P2PKH (Pay-to-Public-Key-Hash) addresses.
class BchP2PKHAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a P2PKH (Pay-to-Public-Key-Hash) address using bch Bech32 encoding.
  ///
  /// This method encodes a public key as a P2PKH address using Bech32 encoding. It expects an optional map of keyword
  /// arguments with 'net_ver' specifying the network version bytes and 'hrp' for the Human-Readable Part (HRP).
  /// It validates the arguments, processes the public key as a Secp256k1 key, generates a hash160 of the compressed
  /// public key, and encodes it as a P2PKH address using Bech32.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a P2PKH address.
  ///   - kwargs: Optional keyword arguments with 'net_ver' for the network version and 'hrp' for HRP.
  ///
  /// Returns:
  ///   A String representing the Bech32-encoded P2PKH address derived from the provided public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate network version and HRP arguments.
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "net_ver");
    AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    String hrp = kwargs['hrp'];
    List<int> netVerBytes = kwargs['net_ver'];

    /// Validate and process the public key as a Secp256k1 key.
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    // Generate the hash160 of the compressed public key.
    final pubkeyHash = QuickCrypto.hash160(pubKeyObj.compressed);

    /// Encode the P2PKH address using Bech32 encoding.
    return BchBech32Encoder.encode(
      hrp,
      netVerBytes,
      pubkeyHash,
    );
  }
}
