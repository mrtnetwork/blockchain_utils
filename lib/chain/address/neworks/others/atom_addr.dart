import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';

import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';

/// Internal Cosmos (ATOM) address helpers.
class AtomAddressUtils {
  /// SHA-256(SHA-256(typ) + key), the generic Cosmos address hash.
  static BuBytes hash(List<int> typ, List<int> key) {
    return QuickCrypto.sha256Hash([...QuickCrypto.sha256Hash(typ), ...key]);
  }

  /// Derives an address from a secp256r1 (nist256p1) public key.
  static BuBytes secp256r1PubKeyToAddress(List<int> pubkeyBytes) {
    final type = StringUtils.encode("cosmos.crypto.secp256r1.PubKey");
    final pubkey = AddrKeyValidator.validateAndGetNist256p1Key(pubkeyBytes);
    return hash(type, pubkey.toBytes());
  }

  /// Derives an address from an Ed25519 public key.
  static BuBytes ed25519PubkeyToAddress(List<int> pubkeyBytes) {
    final pubkey = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubkeyBytes);
    return QuickCrypto.sha256Hash(pubkey).sublist(0, 20);
  }

  /// Derives an Ethermint-style address from a secp256k1 public key.
  static BuBytes ethSecp256k1PubKeyToAddress(List<int> pubkeyBytes) {
    final pubkey = AddrKeyValidator.validateAndGetSecp256k1Key(pubkeyBytes);
    return QuickCrypto.keccak256Hash(
      pubkey.toBytes(mode: CryptoKeyEncoding.uncompressed).sublist(1),
    ).sublist(12);
  }

  /// Derives an address from a secp256k1 public key.
  static BuBytes secp256k1PubKeyToAddress(List<int> pubkeyBytes) {
    final pubkey = AddrKeyValidator.validateAndGetSecp256k1Key(pubkeyBytes);
    return QuickCrypto.hash160(pubkey.toBytes());
  }

  /// Derives a module account address from a module name and derivation
  /// keys (e.g. `address.Module(dao.ModuleName, newDAO.ID)`).
  static BuBytes module(
    String moduleName, {
    List<List<int>> derivationKeys = const [],
  }) {
    List<int> keyBytes = StringUtils.encode(moduleName);
    if (derivationKeys.isEmpty) {
      return QuickCrypto.sha256Hash(keyBytes).sublist(0, 20);
    }
    keyBytes = [...keyBytes, 0];
    List<int> addr = AtomAddressUtils.hash(StringUtils.encode("module"), [
      ...keyBytes,
      ...derivationKeys[0],
    ]);
    for (int i = 1; i < derivationKeys.length; i++) {
      addr = AtomAddressUtils.hash(addr, derivationKeys[i]);
    }
    return BuBytes(addr);
  }

  /// Validates decoded address bytes are a supported digest length.
  static void validateAddressBytes(List<int> addrBytes) {
    if (addrBytes.length != QuickCrypto.hash160DigestSize &&
        addrBytes.length != QuickCrypto.sha256DigestSize) {
      throw CoreErrors.addressBytesValidationFailed(
        details: {
          "length": addrBytes.length.toString(),
          "Expected":
              "${QuickCrypto.hash160DigestSize} or ${QuickCrypto.sha256DigestSize}",
        },
      );
    }
  }

  /// Encodes address bytes as Bech32 with the given HRP.
  static String encodeAddressBytes({
    required List<int> addressBytes,
    required String hrp,
  }) {
    validateAddressBytes(addressBytes);
    return Bech32Encoder.encode(hrp, addressBytes);
  }

  /// Decodes a Bech32 address, optionally checking its HRP.
  static AtomAddressDecodeResult decode(String address, {String? hrp}) {
    try {
      final decode = Bech32Decoder.decodeWithoutHRP(address);
      if (hrp != null && hrp != decode.$1) {
        throw CoreErrors.addressValidationFailed(
          reason: "Invalid hrp.",
          details: {"hrp": decode.$1, "expected": hrp},
        );
      }
      final addressBytes = decode.$2;
      validateAddressBytes(addressBytes);
      return AtomAddressDecodeResult(hrp: decode.$1, bytes: addressBytes);
    } on BuError {
      rethrow;
    } catch (e) {
      throw CoreErrors.addressValidationFailed(
        details: {"address": address, "error": e.toString()},
      );
    }
  }
}

/// Result of decoding a Cosmos address: HRP plus raw bytes.
class AtomAddressDecodeResult {
  final String hrp;
  final BuBytes bytes;
  AtomAddressDecodeResult({required this.hrp, required List<int> bytes})
    : bytes = bytes.asImmutableBytes;
}

/// Decodes a Cosmos (ATOM) Bech32 address.
class AtomAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {String? hrp}) {
    final decode = AtomAddressUtils.decode(addr, hrp: hrp);
    return decode.bytes;
  }
}

/// Encodes a Cosmos (ATOM) address from a public key.
class AtomAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(
    List<int> pubKey, {
    String? hrp,
    CryptoKeyType type = CryptoKeyType.secp256k1,
  }) {
    return Bech32Encoder.encode(
      AddrKeyValidator.getAddrArg<String>(hrp, "hrp"),
      switch (type) {
        CryptoKeyType.secp256k1 => AtomAddressUtils.secp256k1PubKeyToAddress(
          pubKey,
        ),
        CryptoKeyType.nist256p1 => AtomAddressUtils.secp256r1PubKeyToAddress(
          pubKey,
        ),
        CryptoKeyType.ed25519 => AtomAddressUtils.ed25519PubkeyToAddress(
          pubKey,
        ),
        _ =>
          throw CoreErrors.addressKeyValidationFailed(
            reason: "Unsupported public key type",
            details: {"type": type.name},
          ),
      },
    );
  }
}

/// Encodes a Cosmos Ethermint-style address from a secp256k1 public key.
class AtomEthSecp256k1AddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey, {String? hrp}) {
    return Bech32Encoder.encode(
      AddrKeyValidator.getAddrArg<String>(hrp, "hrp"),
      AtomAddressUtils.ethSecp256k1PubKeyToAddress(pubKey),
    );
  }
}

/// Decodes a Cosmos Ethermint-style Bech32 address.
class AtomEthSecp256k1AddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {String? hrp}) {
    final BuBytes addrDecBytes = Bech32Decoder.decode(
      AddrKeyValidator.getAddrArg<String>(hrp, "hrp"),
      addr,
    );

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.hash160DigestSize,
    );
    return addrDecBytes;
  }
}
