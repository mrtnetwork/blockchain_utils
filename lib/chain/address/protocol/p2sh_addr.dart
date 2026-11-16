import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/chain/address/protocol/p2pkh_addr.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/encoding/bech32/bech32.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to P2SH (Pay-to-Script-Hash) addresses.
class P2SHAddrConst {
  /// Witness script prefix: OP_0 (0x00) + push-20-bytes (0x14), used when
  /// wrapping a redeem script's hash160 for P2SH-nested SegWit.
  static const scriptBytes = <int>[0x00, 0x14];
}

/// Utility class for working with P2SH (Pay-to-Script-Hash) addresses and operations.
class _P2SHAddrUtils {
  /// Builds the hash160 of the P2SH-wrapped witness script for [pubKey].
  static List<int> addScriptSig(IPublicKey pubKey) {
    final keyHashBytes = QuickCrypto.hash160(
      pubKey.toBytes(mode: CryptoKeyEncoding.base),
    );
    return QuickCrypto.hash160([...P2SHAddrConst.scriptBytes, ...keyHashBytes]);
  }
}

/// Decodes a P2SH (Pay-to-Script-Hash) address.
class P2SHAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(
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

/// Encodes a P2SH (Pay-to-Script-Hash) address.
class P2SHAddrEncoder implements BlockchainAddressEncoder {
  /// Validates [pubKey] and returns its P2SH-wrapped script hash.
  List<int> validateAndHashKey(List<int> pubKey) {
    final IPublicKey pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(
      pubKey,
    );
    return _P2SHAddrUtils.addScriptSig(pubKeyObj);
  }

  @override
  String encodeKey(List<int> pubKey, {List<int>? netVersion}) {
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );

    return Base58Encoder.encodeWithChecksum([
      ...netVersion,
      ...validateAndHashKey(pubKey),
    ]);
  }
}

/// Decodes a P2SH (Pay-to-Script-Hash) address.
class BchP2SHAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {List<int>? netVersion, String? hrp}) {
    return BchP2PKHAddrDecoder().decodeAddr(
      addr,
      hrp: hrp,
      netVersion: netVersion,
    );
  }
}

/// Encodes a P2SH (Pay-to-Script-Hash) address.
class BchP2SHAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey, {List<int>? netVersion, String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );

    final IPublicKey pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(
      pubKey,
    );
    return BchBech32Encoder.encode(
      hrp,
      netVersion,
      _P2SHAddrUtils.addScriptSig(pubKeyObj),
    );
  }
}
