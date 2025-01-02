import 'package:blockchain_utils/bech32/segwit_bech32.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'exception/exception.dart';

/// Constants related to P2WPKH (Pay-to-Witness-Public-Key-Hash) addresses.
class P2WPKHAddrConst {
  /// The witness version for P2WPKH addresses.
  /// In the context of Bitcoin and SegWit-based transactions, P2WPKH addresses
  /// typically have a witness version of 0.
  static const int witnessVer = 0;
}

/// Implementation of the [BlockchainAddressDecoder] for Segwit (P2WPKH) addresses.
class P2WPKHAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a P2WPKH address.
  ///
  /// This method decodes a P2WPKH address from the given input string using the Bech32
  /// encoding. It expects an optional map of keyword arguments, with the 'hrp' key
  /// specifying the Human-Readable Part (HRP) of the address. It validates the arguments,
  /// decodes the address, checks the witness version, and returns the decoded address as a `List<int>`.
  ///
  /// Parameters:
  ///   - addr: The Bech32-encoded P2WPKH address to be decoded.
  ///   - kwargs: Optional keyword arguments, with 'hrp' for the Human-Readable Part.
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded P2WPKH address bytes.
  ///
  /// Throws:
  ///   - FormatException if the provided address has an incorrect witness version.
  ///   - ArgumentException if the Bech32 checksum is invalid.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate address arguments and retrieve the Human-Readable Part (HRP)
    AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    final String hrp = kwargs['hrp'];

    /// Decode the Bech32-encoded P2WPKH address, and validate its length.
    final decoded = SegwitBech32Decoder.decode(hrp, addr);
    final witVerGot = decoded.item1;
    final addrDecBytes = decoded.item2;

    /// Check the witness version.
    if (witVerGot != P2WPKHAddrConst.witnessVer) {
      throw AddressConverterException(
          'Invalid witness version (expected ${P2WPKHAddrConst.witnessVer}, got $witVerGot)');
    }

    /// Return the decoded P2WPKH address as a `List<int>`.
    return List<int>.from(addrDecBytes);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Segwit (P2WPKH) addresses.
class P2WPKHAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a P2WPKH address.
  ///
  /// This method encodes a public key as a Pay-to-Witness-Public-Key-Hash (P2WPKH) address
  /// using Bech32 encoding. It expects an optional map of keyword arguments, with the 'hrp'
  /// key specifying the Human-Readable Part (HRP) for the address. It validates the arguments,
  /// processes the public key as a Secp256k1 key, and encodes it as a P2WPKH address.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a P2WPKH address.
  ///   - kwargs: Optional keyword arguments, with 'hrp' for the Human-Readable Part.
  ///
  /// Returns:
  ///   A String representing the P2WPKH address encoded from the provided public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate address arguments and retrieve the Human-Readable Part (HRP).
    AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    final hrp = kwargs['hrp'] as String;

    /// Validate and process the public key as a Secp256k1 key.
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Set the witness version and obtain the public key bytes.
    const witnessVer = P2WPKHAddrConst.witnessVer;
    final pubKeyBytes = pubKeyObj.compressed;

    /// Encode the processed public key as a P2WPKH address using Bech32.
    return SegwitBech32Encoder.encode(
        hrp, witnessVer, QuickCrypto.hash160(pubKeyBytes));
  }
}
