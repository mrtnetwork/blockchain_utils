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
  static List<int> addScriptSig(IPublicKey pubKey) {
    /// Compute the key hash from the compressed public key.
    final keyHashBytes = QuickCrypto.hash160(pubKey.compressed);

    /// Compute the hash of the script signature.
    return QuickCrypto.hash160([...P2SHAddrConst.scriptBytes, ...keyHashBytes]);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for P2SH (Pay-to-Script-Hash) addresses.
class P2SHAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a P2SH (Pay-to-Script-Hash) address.
  @override
  List<int> decodeAddr(
    String addr, {
    List<int>? netVersion,
    Base58Alphabets alphabet = Base58Alphabets.bitcoin,
  }) {
    return P2PKHAddrDecoder().decodeAddr(
      addr,
      netVersion: netVersion,
      alphabet: alphabet,
    );
  }
}

/// Implementation of the [BlockchainAddressEncoder] for P2SH (Pay-to-Script-Hash) addresses.
class P2SHAddrEncoder implements BlockchainAddressEncoder {
  List<int> validateAndHashKey(List<int> pubKey) {
    /// Validate and process the public key as a Secp256k1 key.
    final IPublicKey pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(
      pubKey,
    );

    /// Generate the script signature from the public key.
    return _P2SHAddrUtils.addScriptSig(pubKeyObj);
  }

  /// Overrides the base class method to encode a public key as a P2SH (Pay-to-Script-Hash) address.
  @override
  String encodeKey(List<int> pubKey, {List<int>? netVersion}) {
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );

    /// Encode the address bytes as a Base58-encoded P2SH address.
    return Base58Encoder.checkEncode([
      ...netVersion,
      ...validateAndHashKey(pubKey),
    ]);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for P2SH (Pay-to-Script-Hash) addresses.
class BchP2SHAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Overrides the base class method to decode a P2SH (Pay-to-Script-Hash) address.
  @override
  List<int> decodeAddr(String addr, {List<int>? netVersion, String? hrp}) {
    /// Delegate the decoding process to a specialized P2PKH address decoder with HRP and network version.
    return BchP2PKHAddrDecoder().decodeAddr(
      addr,
      hrp: hrp,
      netVersion: netVersion,
    );
  }
}

/// Implementation of the [BlockchainAddressEncoder] for P2SH (Pay-to-Script-Hash) addresses.
class BchP2SHAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a P2SH (Pay-to-Script-Hash) address.
  @override
  String encodeKey(List<int> pubKey, {List<int>? netVersion, String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );

    /// Validate and process the public key as a Secp256k1 key.
    final IPublicKey pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(
      pubKey,
    );

    /// Encode the P2SH address using Bech32 encoding.
    return BchBech32Encoder.encode(
      hrp,
      netVersion,
      _P2SHAddrUtils.addScriptSig(pubKeyObj),
    );
  }
}
