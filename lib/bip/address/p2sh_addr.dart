import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bech32/bch_bech32.dart';
import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Constants related to P2SH (Pay-to-Script-Hash) addresses.
class P2SHAddrConst {
  /// The script bytes commonly used in P2SH addresses.
  ///
  /// This represents the standard script for P2SH addresses, consisting of
  /// 0x00 (OP_0) followed by 0x14 bytes (20 bytes), typically corresponding
  /// to the hash of a redeem script.
  static const scriptBytes = <int>[0x00, 0x14];
}

/// Utility class for working with P2SH (Pay-to-Script-Hash) addresses and operations.
class _P2SHAddrUtils {
  /// Create a P2SH script signature from a public key.
  ///
  /// This method takes a public key and generates a P2SH script signature by hashing
  /// the compressed public key bytes along with the standard P2SH script bytes (0x00, 0x14).
  ///
  /// Parameters:
  ///   - pubKey: The public key from which to generate the P2SH script signature.
  ///
  /// Returns:
  ///   A `List<int>` representing the P2SH script signature.
  static List<int> addScriptSig(IPublicKey pubKey) {
    /// Compute the key hash from the compressed public key.
    final keyHashBytes = QuickCrypto.hash160(pubKey.compressed);

    /// Create the P2SH script signature by combining standard script bytes with the key hash.
    final scriptSigBytes =
        List<int>.from([...P2SHAddrConst.scriptBytes, ...keyHashBytes]);

    /// Compute the hash of the script signature.
    return QuickCrypto.hash160(scriptSigBytes);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for P2SH (Pay-to-Script-Hash) addresses.
class P2SHAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a P2SH (Pay-to-Script-Hash) address.
  ///
  /// This method delegates the decoding process to the P2PKHAddrDecoder class, which
  /// specializes in decoding P2SH addresses. It expects the provided address and
  /// an optional map of keyword arguments. The decoded P2SH address is returned as a `List<int>`.
  ///
  /// Parameters:
  ///   - addr: The P2SH address to be decoded.
  ///   - kwargs: Optional keyword arguments for customization (not used in this implementation).
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded P2SH address bytes.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    return P2PKHAddrDecoder().decodeAddr(addr, kwargs);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for P2SH (Pay-to-Script-Hash) addresses.
class P2SHAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a P2SH (Pay-to-Script-Hash) address.
  ///
  /// This method encodes a public key as a P2SH address using Base58 encoding. It expects
  /// an optional map of keyword arguments, with the 'net_ver' key specifying the network
  /// version bytes for the address. It validates the arguments, processes the public key as a
  /// Secp256k1 key, generates a script signature, and combines it with the network version bytes
  /// to create the P2SH address, which is then Base58-encoded.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a P2SH address.
  ///   - kwargs: Optional keyword arguments, with 'net_ver' for the network version bytes.
  ///
  /// Returns:
  ///   A String representing the Base58-encoded P2SH address derived from the provided public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate network version arguments and retrieve the network version bytes.
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, 'net_ver');
    final List<int> netVerBytes = kwargs['net_ver'];

    /// Validate and process the public key as a Secp256k1 key.
    final IPublicKey pubKeyObj =
        AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Generate the script signature from the public key.
    final List<int> scriptSigBytes = _P2SHAddrUtils.addScriptSig(pubKeyObj);

    /// Combine the network version and script signature to form the address bytes.
    final List<int> addressBytes =
        List<int>.filled(netVerBytes.length + scriptSigBytes.length, 0);
    addressBytes.setAll(0, netVerBytes);
    addressBytes.setAll(netVerBytes.length, scriptSigBytes);

    /// Encode the address bytes as a Base58-encoded P2SH address.
    return Base58Encoder.checkEncode(addressBytes);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for P2SH (Pay-to-Script-Hash) addresses.
class BchP2SHAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a P2SH (Pay-to-Script-Hash) address.
  ///
  /// This method decodes a P2SH address from the provided input string using Base58 encoding.
  /// It expects an optional map of keyword arguments with 'hrp' specifying the Human-Readable Part (HRP)
  /// and 'net_ver' for the network version bytes of the address. It validates the arguments and delegates
  /// the decoding process to a specialized P2PKH address decoder (BchP2PKHAddrDecoder).
  ///
  /// Parameters:
  ///   - addr: The P2SH address to be decoded.
  ///   - kwargs: Optional keyword arguments with 'hrp' for HRP and 'net_ver' for network version.
  ///
  /// Returns:
  ///   A `List<int>` containing the decoded P2SH address bytes.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate HRP and network version arguments.
    AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "net_ver");
    final String hrp = kwargs['hrp'];
    final List<int> netVerBytes = kwargs['net_ver'];

    /// Delegate the decoding process to a specialized P2PKH address decoder with HRP and network version.
    return BchP2PKHAddrDecoder()
        .decodeAddr(addr, {'hrp': hrp, 'net_ver': netVerBytes});
  }
}

/// Implementation of the [BlockchainAddressEncoder] for P2SH (Pay-to-Script-Hash) addresses.
class BchP2SHAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a P2SH (Pay-to-Script-Hash) address.
  ///
  /// This method encodes a public key as a P2SH address using Bech32 encoding. It expects
  /// an optional map of keyword arguments with 'hrp' specifying the Human-Readable Part (HRP)
  /// and 'net_ver' for the network version bytes of the address. It validates the arguments,
  /// processes the public key as a Secp256k1 key, generates a script signature, and encodes
  /// it as a P2SH address using Bech32.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a P2SH address.
  ///   - kwargs: Optional keyword arguments with 'hrp' for HRP and 'net_ver' for network version.
  ///
  /// Returns:
  ///   A String representing the Bech32-encoded P2SH address derived from the provided public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate HRP and network version arguments.
    AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "net_ver");
    final String hrp = kwargs['hrp'];
    final List<int> netVerBytes = kwargs['net_ver'];

    /// Validate and process the public key as a Secp256k1 key.
    final IPublicKey pubKeyObj =
        AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Encode the P2SH address using Bech32 encoding.
    return BchBech32Encoder.encode(
        hrp, netVerBytes, _P2SHAddrUtils.addScriptSig(pubKeyObj));
  }
}
