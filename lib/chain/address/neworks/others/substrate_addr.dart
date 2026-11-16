import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/encoding/ss58/ss58.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Internal Substrate (SS58) address helpers.
class _SubstrateAddrUtils {
  static const int encodeBytesLength = 32;
  static (BuBytes, int) decodeAddr(String addr, int? ss58Format) {
    // Decode from SS58 (SS58Decoder.Decode also validates the length)
    final decodedResult = SS58Decoder.decode(addr);
    final ss58FormatGot = decodedResult.$1;
    final addrDecBytes = decodedResult.$2;
    if (addrDecBytes.length != encodeBytesLength) {
      throw CoreErrors.addressValidationFailed();
    }

    if (ss58Format != null && ss58Format != ss58FormatGot) {
      // is verified inside SS58Decoder.decode).
      throw CoreErrors.missingOrInvalidAddressArguments(
        reason: "Invalid address SS58 format",
      );
    }

    return (addrDecBytes, ss58FormatGot);
  }

  static String encode(List<int> pubKeyBytes, int ss58Format) {
    if (pubKeyBytes.length != encodeBytesLength) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid bytes length.",
      );
    }
    return SS58Encoder.encode(pubKeyBytes, ss58Format);
  }
}

/// Decodes a Substrate Ed25519 address.
class SubstrateEd25519AddrDecoder
    implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {int? ss58Format}) {
    final pubkeyBytes = _SubstrateAddrUtils.decodeAddr(addr, ss58Format).$1;
    AddrKeyValidator.validateAndGetEd25519PubKey(pubkeyBytes);
    return pubkeyBytes;
  }
}

/// Encodes a Substrate Ed25519 address.
class SubstrateEd25519AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes [pubKey] as an SS58 address using [ss58Format].
  @override
  String encodeKey(List<int> pubKey, {int? ss58Format}) {
    ss58Format = AddrKeyValidator.getAddrArg<int>(ss58Format, "ss58Format");
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
    return _SubstrateAddrUtils.encode(pubKeyObj, ss58Format);
  }
}

/// Decodes a Substrate sr25519 address.
class SubstrateSr25519AddrDecoder
    implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {int? ss58Format}) {
    final pubkeyBytes = _SubstrateAddrUtils.decodeAddr(addr, ss58Format).$1;
    AddrKeyValidator.validateAndGetSr25519Key(pubkeyBytes);
    return pubkeyBytes;
  }
}

/// Encodes a Substrate sr25519 address.
class SubstrateSr25519AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes [pubKey] as an SS58 address using [ss58Format].
  @override
  String encodeKey(List<int> pubKey, {int? ss58Format}) {
    ss58Format = AddrKeyValidator.getAddrArg<int>(ss58Format, "ss58Format");

    AddrKeyValidator.validateAndGetSr25519Key(pubKey);
    return _SubstrateAddrUtils.encode(pubKey, ss58Format);
  }
}

/// Decodes a Substrate secp256k1 address.
class SubstrateSecp256k1AddrDecoder
    implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {int? ss58Format}) {
    return _SubstrateAddrUtils.decodeAddr(addr, ss58Format).$1;
  }
}

/// Encodes a Substrate secp256k1 address.
class SubstrateSecp256k1AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes [pubKey] (blake2b-256 hashed) as an SS58 address using [ss58Format].
  @override
  String encodeKey(List<int> pubKey, {int? ss58Format}) {
    ss58Format = AddrKeyValidator.getAddrArg<int>(ss58Format, "ss58Format");
    final key = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    return _SubstrateAddrUtils.encode(
      QuickCrypto.blake2b256Hash(key.toBytes(mode: CryptoKeyEncoding.base)),
      ss58Format,
    );
  }
}

/// Encodes a Substrate address, auto-detecting the key's curve type.
class SubstrateGenericAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey, {int? ss58Format, CryptoKeyType? type}) {
    type = AddrKeyValidator.getAddrArg<CryptoKeyType>(type, "type");
    ss58Format = AddrKeyValidator.getAddrArg<int>(ss58Format, "ss58Format");
    return switch (type) {
      CryptoKeyType.secp256k1 => SubstrateSecp256k1AddrEncoder().encodeKey(
        pubKey,
        ss58Format: ss58Format,
      ),
      CryptoKeyType.sr25519 => SubstrateSr25519AddrEncoder().encodeKey(
        pubKey,
        ss58Format: ss58Format,
      ),
      CryptoKeyType.ed25519 => SubstrateSr25519AddrEncoder().encodeKey(
        pubKey,
        ss58Format: ss58Format,
      ),
      _ =>
        throw CoreErrors.addressKeyValidationFailed(
          reason: "Unsupported public key type.",
        ),
    };
  }
}

/// Decodes any Substrate (SS58) address without checking the key's curve.
class SubstrateGenericAddrDecoder
    implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {int? ss58Format}) {
    return _SubstrateAddrUtils.decodeAddr(addr, ss58Format).$1;
  }

  /// Decodes [addr], also returning its SS58 format byte.
  (List<int>, int) decodeAddWithSS58(String addr, {int? ss58Format}) {
    return _SubstrateAddrUtils.decodeAddr(addr, ss58Format);
  }
}
