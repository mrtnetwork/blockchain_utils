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
class P2WPKHAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a P2WPKH address.
  @override
  List<int> decodeAddr(String addr, {String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");

    /// Decode the Bech32-encoded P2WPKH address, and validate its length.
    final decoded = SegwitBech32Decoder.decode(hrp, addr);
    final witVerGot = decoded.$1;
    final addrDecBytes = decoded.$2;

    /// Check the witness version.
    if (witVerGot != P2WPKHAddrConst.witnessVer) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Invalid address checksum",
      );
    }

    /// Return the decoded P2WPKH address as a `List<int>`.
    return addrDecBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Segwit (P2WPKH) addresses.
class P2WPKHAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a P2WPKH address.
  @override
  String encodeKey(List<int> pubKey, {String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");

    /// Validate and process the public key as a Secp256k1 key.
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Set the witness version and obtain the public key bytes.
    const witnessVer = P2WPKHAddrConst.witnessVer;
    final pubKeyBytes = pubKeyObj.compressed;

    /// Encode the processed public key as a P2WPKH address using Bech32.
    return SegwitBech32Encoder.encode(
      hrp,
      witnessVer,
      QuickCrypto.hash160(pubKeyBytes),
    );
  }
}
