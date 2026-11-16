import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';

import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/encoding/bech32/bech32.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Decodes a P2PKH (Pay-to-Public-Key-Hash) Base58 address.
class P2PKHAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(
    String addr, {
    List<int>? netVersion,
    Base58Alphabets alphabet = Base58Alphabets.bitcoin,
  }) {
    final List<int> netVarBytes = AddrKeyValidator.getAddrArg(
      netVersion,
      "netVersion",
    );

    // Decode with the given Base58 alphabet.
    final List<int> addrDecBytes = Base58Decoder.decodeWithChecksum(
      addr,
      alphabet,
    );

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.hash160DigestSize + netVarBytes.length,
    );

    // Strip and validate the network version prefix.
    return BuBytes(
      AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, netVarBytes),
    );
  }
}

/// Encodes a P2PKH (Pay-to-Public-Key-Hash) Base58 address.
class P2PKHAddrEncoder implements BlockchainAddressEncoder {
  /// Validates the pubkey and returns its hash160.
  BuBytes validateAndHashKey(
    List<int> pubKey, {
    CryptoKeyEncoding pubKeyMode = CryptoKeyEncoding.base,
  }) {
    final publicKey = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final BuBytes pubKeyBytes = publicKey.toBytes(mode: pubKeyMode);
    return QuickCrypto.hash160(pubKeyBytes);
  }

  @override
  String encodeKey(
    List<int> pubKey, {
    List<int>? netVersion,
    Base58Alphabets alphabet = Base58Alphabets.bitcoin,
    CryptoKeyEncoding pubKeyMode = CryptoKeyEncoding.base,
  }) {
    final List<int> netVerBytes = AddrKeyValidator.getAddrArg(
      netVersion,
      "netVersion",
    );
    // Address bytes = network version prefix + pubkey hash160.
    return Base58Encoder.encodeWithChecksum([
      ...netVerBytes,
      ...validateAndHashKey(pubKey, pubKeyMode: pubKeyMode),
    ], alphabet);
  }
}

/// Decodes a BCH P2PKH Bech32 (CashAddr) address.
class BchP2PKHAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {List<int>? netVersion, String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );

    final result = BchBech32Decoder.decode(hrp, addr);
    final BuBytes netVerBytesGot = result.$1;
    final BuBytes addrDecBytes = result.$2;

    // Decoded network version must match the one requested.
    if (!BytesUtils.bytesEqual(netVersion, netVerBytesGot)) {
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid address network version.",
      );
    }

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.hash160DigestSize,
    );
    return addrDecBytes;
  }
}

/// Encodes a BCH P2PKH Bech32 (CashAddr) address.
class BchP2PKHAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey, {List<int>? netVersion, String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );

    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final pubkeyHash = QuickCrypto.hash160(
      pubKeyObj.toBytes(mode: CryptoKeyEncoding.base),
    );
    return BchBech32Encoder.encode(hrp, netVersion, pubkeyHash);
  }
}
