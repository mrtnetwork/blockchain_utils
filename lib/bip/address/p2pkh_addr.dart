import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bech32/bch_bech32.dart';
import 'package:blockchain_utils/bip/bip/types/types.dart';

import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'decoder.dart';
import 'exception/exception.dart';

/// Implementation of the [BlockchainAddressDecoder] for P2PKH (Pay-to-Public-Key-Hash) addresses.
class P2PKHAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a P2PKH (Pay-to-Public-Key-Hash) address.
  @override
  List<int> decodeAddr(
    String addr, {
    List<int>? netVersion,
    Base58Alphabets alphabet = Base58Alphabets.bitcoin,
  }) {
    final List<int> netVarBytes = AddrKeyValidator.getAddrArg(
      netVersion,
      "netVersion",
    );

    /// Decode the address using the specified Base58 alphabet.
    final List<int> addrDecBytes = Base58Decoder.checkDecode(addr, alphabet);

    /// Validate the length of the decoded address and its network version.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.hash160DigestSize + netVarBytes.length,
    );

    /// Remove and validate the network version prefix bytes.
    return AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, netVarBytes);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for P2PKH (Pay-to-Public-Key-Hash) addresses.
class P2PKHAddrEncoder implements BlockchainAddressEncoder {
  List<int> validateAndHashKey(
    List<int> pubKey, {
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
  }) {
    /// Validate and process the public key as a Secp256k1 key.
    final publicKey = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Determine the public key bytes based on the selected mode.
    final List<int> pubKeyBytes =
        pubKeyMode == PubKeyModes.compressed
            ? publicKey.compressed
            : publicKey.uncompressed;

    /// Calculate the hash160 of the public key.
    final hash160 = QuickCrypto.hash160(pubKeyBytes);

    /// Combine the network version and hash160 to form the address bytes.
    return hash160;
  }

  /// Overrides the base class method to encode a public key as a P2PKH (Pay-to-Public-Key-Hash) address.
  @override
  String encodeKey(
    List<int> pubKey, {
    List<int>? netVersion,
    Base58Alphabets alphabet = Base58Alphabets.bitcoin,
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
  }) {
    final List<int> netVerBytes = AddrKeyValidator.getAddrArg(
      netVersion,
      "netVersion",
    );
    return Base58Encoder.checkEncode([
      ...netVerBytes,
      ...validateAndHashKey(pubKey, pubKeyMode: pubKeyMode),
    ], alphabet);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for P2PKH (Pay-to-Public-Key-Hash) addresses.
class BchP2PKHAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a P2PKH (Pay-to-Public-Key-Hash) address using bch Bech32 encoding.
  @override
  List<int> decodeAddr(String addr, {List<int>? netVersion, String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );

    /// Decode the Bech32 address and retrieve network version and decoded bytes.
    final result = BchBech32Decoder.decode(hrp, addr);
    final List<int> netVerBytesGot = result.$1;
    final List<int> addrDecBytes = result.$2;

    /// Validate that the decoded network version matches the expected network version.
    if (!BytesUtils.bytesEqual(netVersion, netVerBytesGot)) {
      throw AddressConverterException.addressKeyValidationFailed(
        reason: "Invalid address checksum.",
      );
    }

    /// Validate the length of the decoded address.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.hash160DigestSize,
    );
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
  String encodeKey(List<int> pubKey, {List<int>? netVersion, String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );

    /// Validate and process the public key as a Secp256k1 key.
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    // Generate the hash160 of the compressed public key.
    final pubkeyHash = QuickCrypto.hash160(pubKeyObj.compressed);

    /// Encode the P2PKH address using Bech32 encoding.
    return BchBech32Encoder.encode(hrp, netVersion, pubkeyHash);
  }
}
