import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'decoder.dart';
import 'exception/exception.dart';

class AtomAddressUtils {
  static List<int> hash(List<int> typ, List<int> key) {
    return QuickCrypto.sha256Hash([...QuickCrypto.sha256Hash(typ), ...key]);
  }

  static List<int> get nist566p1KeyType =>
      "cosmos.crypto.secp256r1.PubKey".codeUnits;

  static List<int> secp256r1PubKeyToAddress(List<int> pubkeyBytes) {
    final pubkey = AddrKeyValidator.validateAndGetNist256p1Key(pubkeyBytes);
    return hash(nist566p1KeyType, pubkey.compressed);
  }

  static List<int> ed25519PubkeyToAddress(List<int> pubkeyBytes) {
    final pubkey = AddrKeyValidator.validateAndGetEd25519Key(pubkeyBytes);
    return QuickCrypto.sha256Hash(pubkey.compressed).sublist(0, 20);
  }

  static List<int> ethSecp256k1PubKeyToAddress(List<int> pubkeyBytes) {
    final pubkey = AddrKeyValidator.validateAndGetSecp256k1Key(pubkeyBytes);
    return QuickCrypto.keccack256Hash(
      pubkey.uncompressed.sublist(1),
    ).sublist(12);
  }

  static List<int> secp256k1PubKeyToAddress(List<int> pubkeyBytes) {
    final pubkey = AddrKeyValidator.validateAndGetSecp256k1Key(pubkeyBytes);
    return QuickCrypto.hash160(pubkey.compressed);
  }

  /// Module is a specialized version of a composed address for modules. Each module account
  /// is constructed from a module name and a sequence of derivation keys (at least one
  /// derivation key must be provided). The derivation keys must be unique
  /// in the module scope, and is usually constructed from some object id. Example, let's
  /// a x/dao module, and a new DAO object, it's address would be:
  ///
  ///	address.Module(dao.ModuleName, newDAO.ID)
  static List<int> module(
    String moduleName, {
    List<List<int>> derivationKeys = const [],
  }) {
    List<int> keyBytes = StringUtils.encode(moduleName);
    if (derivationKeys.isEmpty) {
      return QuickCrypto.sha256Hash(keyBytes).sublist(0, 20);
    }
    keyBytes = [...keyBytes, 0];
    List<int> addr = AtomAddressUtils.hash("module".codeUnits, [
      ...keyBytes,
      ...derivationKeys[0],
    ]);
    for (int i = 1; i < derivationKeys.length; i++) {
      addr = AtomAddressUtils.hash(addr, derivationKeys[i]);
    }
    return addr;
  }

  static void validateAddressBytes(List<int> addrBytes) {
    if (addrBytes.length != QuickCrypto.hash160DigestSize &&
        addrBytes.length != QuickCrypto.sha256DigestSize) {
      throw AddressConverterException.addressBytesValidationFailed(
        details: {
          "length": addrBytes.length.toString(),
          "Excepted":
              "${QuickCrypto.hash160DigestSize} or ${QuickCrypto.sha256DigestSize}",
        },
      );
    }
  }

  static String encodeAddressBytes({
    required List<int> addressBytes,
    required String hrp,
  }) {
    validateAddressBytes(addressBytes);
    return Bech32Encoder.encode(hrp, addressBytes);
  }

  static AtomAddressDecodeResult decode(String address, {String? hrp}) {
    try {
      final decode = Bech32Decoder.decodeWithoutHRP(address);
      if (hrp != null && hrp != decode.$1) {
        throw AddressConverterException.addressValidationFailed(
          reason: "Invalid hrp.",
          details: {"hrp": decode.$1, "excepted": hrp},
        );
      }
      final addressBytes = decode.$2;
      validateAddressBytes(addressBytes);
      return AtomAddressDecodeResult(hrp: decode.$1, bytes: addressBytes);
    } on AddressConverterException {
      rethrow;
    } catch (e) {
      throw AddressConverterException.addressValidationFailed(
        details: {"address": address, "error": e.toString()},
      );
    }
  }
}

class AtomAddressDecodeResult {
  final String hrp;
  final List<int> bytes;
  AtomAddressDecodeResult({required this.hrp, required List<int> bytes})
    : bytes = bytes.immutable;
}

/// Implementation of the [BlockchainAddressDecoder] for Atom (ATOM) address.
class AtomAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decode an address using the Bech32 encoding format with the specified human-readable part (HRP).
  @override
  List<int> decodeAddr(String addr, {String? hrp}) {
    final List<int> addrDecBytes = Bech32Decoder.decode(
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

/// Implementation of the [BlockchainAddressDecoder] for Atom (ATOM) address.
class AtomEthSecp256k1AddrDecoder
    implements BlockchainAddressDecoder<List<int>> {
  /// Decode an address using the Bech32 encoding format with the specified human-readable part (HRP).
  @override
  List<int> decodeAddr(String addr, {String? hrp}) {
    final List<int> addrDecBytes = Bech32Decoder.decode(
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

/// Implementation of the [BlockchainAddressEncoder] for Atom (ATOM) address.
class AtomAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as an Atom (ATOM) cryptocurrency address.
  @override
  String encodeKey(List<int> pubKey, {String? hrp}) {
    return Bech32Encoder.encode(
      AddrKeyValidator.getAddrArg<String>(hrp, "hrp"),
      AtomAddressUtils.secp256k1PubKeyToAddress(pubKey),
    );
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Atom (ATOM) address.
class AtomEthSecp256k1AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as an Atom (ATOM) cryptocurrency address.
  @override
  String encodeKey(List<int> pubKey, {String? hrp}) {
    return Bech32Encoder.encode(
      AddrKeyValidator.getAddrArg<String>(hrp, "hrp"),
      AtomAddressUtils.ethSecp256k1PubKeyToAddress(pubKey),
    );
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Atom (ATOM) address.
class AtomNist256P1AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as an Atom (ATOM) cryptocurrency address.
  @override
  String encodeKey(List<int> pubKey, {String? hrp}) {
    return Bech32Encoder.encode(
      AddrKeyValidator.getAddrArg<String>(hrp, "hrp"),
      AtomAddressUtils.secp256r1PubKeyToAddress(pubKey),
    );
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Atom (ATOM) address.
class AtomNist256P1AddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decode an address using the Bech32 encoding format with the specified human-readable part (HRP).
  @override
  List<int> decodeAddr(String addr, {String? hrp}) {
    final List<int> addrDecBytes = Bech32Decoder.decode(
      AddrKeyValidator.getAddrArg<String>(hrp, "hrp"),
      addr,
    );

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.sha256DigestSize,
    );
    return addrDecBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Atom (ATOM) address.
class AtomEd25519AddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a public key as an Atom (ATOM) cryptocurrency address.
  @override
  String encodeKey(List<int> pubKey, {String? hrp}) {
    return Bech32Encoder.encode(
      AddrKeyValidator.getAddrArg<String>(hrp, "hrp"),
      AtomAddressUtils.ed25519PubkeyToAddress(pubKey),
    );
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Atom (ATOM) address.
class AtomEd25519AddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decode an address using the Bech32 encoding format with the specified human-readable part (HRP).
  @override
  List<int> decodeAddr(String addr, {String? hrp}) {
    final List<int> addrDecBytes = Bech32Decoder.decode(
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
