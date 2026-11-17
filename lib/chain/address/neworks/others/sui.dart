import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/protocol/bip/bip.dart';
import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A public key + its signature weight, for Sui multisig addresses.
class SuiPublicKeyAndWeight {
  final IPublicKey publicKey;
  final int weight;
  const SuiPublicKeyAndWeight._({
    required this.publicKey,
    required this.weight,
  });
  factory SuiPublicKeyAndWeight({
    required IPublicKey publicKey,
    required int weight,
  }) {
    if (weight < 1 || weight > BinaryOps.mask8) {
      throw CoreErrors.addressKeyValidationFailed(
        reason:
            "Invalid signer weight. weight must be between 1 and ${BinaryOps.mask8}.",
      );
    }
    switch (publicKey.type) {
      case CryptoKeyType.ed25519:
      case CryptoKeyType.secp256k1:
      case CryptoKeyType.nist256p1:
      case CryptoKeyType.nist256p1Hybrid:
        break;
      default:
        throw CoreErrors.addressBytesValidationFailed(
          reason: "Unsupported ${publicKey.type.name} public key",
        );
    }
    return SuiPublicKeyAndWeight._(publicKey: publicKey, weight: weight);
  }

  /// Encodes as [scheme flag, compressed pubkey bytes, weight].
  List<int> toBytes() {
    final int flag = switch (publicKey.type) {
      CryptoKeyType.ed25519 => SuiAddrConst.ed25519AddressFlag,
      CryptoKeyType.secp256k1 => SuiAddrConst.secp256k1AddressFlag,
      _ => SuiAddrConst.secp256r1AddressFlag,
    };
    List<int> publicKeyBytes = publicKey.toBytes(mode: CryptoKeyEncoding.base);

    return [flag, ...publicKeyBytes, weight];
  }
}

/// Sui address constants.
class SuiAddrConst {
  /// Special addresses must have their last byte below this value.
  static const int specialAddressLastBytesMax = 16;

  /// sui address bytes length
  static const int addressBytesLength = 32;

  /// The Ed25519 signing scheme flag
  static const int ed25519AddressFlag = 0;

  /// The secp256k1 scheme flag
  static const int secp256k1AddressFlag = 1;

  /// The secp256r1 scheme flag
  static const int secp256r1AddressFlag = 2;

  /// A multi-key signing scheme flag where multiple different types of keys are involved
  static const int multisigAddressFlag = 3;

  static const int multisigAccountMaxThreshold = BinaryOps.mask16;
  static const int multisigAccountMinThreshold = 1;
  static const int multisigAccountMaxPublicKey = 10;
  static const int multisigAccountPublicKeyMaxWeight = 255;
  static const int multisigAccountPublicKeyMinWeight = 1;
}

/// Internal Sui address helpers.
class SuiAddressUtils {
  /// Validates address bytes are the expected length.
  static List<int> parseAddressBytes(List<int> bytes) {
    if (bytes.length != SuiAddrConst.addressBytesLength) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid bytes length.",
        details: {
          "expected": SuiAddrConst.addressBytesLength.toString(),
          "length": bytes.length.toString(),
        },
      );
    }
    return bytes;
  }

  /// Parses an address string to bytes (no special-address padding).
  static BuBytes addressToBytes(String address) {
    address = StringUtils.strip0x(address);
    BuBytes? bytes = BytesUtils.tryFromHexString(
      address,
      paddingZero: address.length < 2,
    );
    if (bytes?.length != SuiAddrConst.addressBytesLength) {
      throw CoreErrors.addressValidationFailed(details: {"address": address});
    }
    return bytes!;
  }

  /// Hashes key bytes with a scheme byte to derive an address.
  static BuBytes hashKeyBytes({required List<int> bytes, required int scheme}) {
    return QuickCrypto.blake2b256Hash([scheme, ...bytes]);
  }

  /// Encodes an Ed25519 public key to a Sui address.
  static List<int> encodeEd25519Key(List<int> bytes) {
    try {
      final key = AddrKeyValidator.validateAndGetEd25519KeyBytes(bytes);
      return hashKeyBytes(bytes: key, scheme: SuiAddrConst.ed25519AddressFlag);
    } catch (e) {
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid ${CryptoKeyType.ed25519.name} public key.",
      );
    }
  }

  /// Encodes a secp256k1 public key to a Sui address.
  static List<int> encodeSecp256k1(List<int> bytes) {
    try {
      final key = AddrKeyValidator.validateAndGetSecp256k1Key(
        bytes,
      ).toBytes(mode: CryptoKeyEncoding.base);
      return hashKeyBytes(
        bytes: key,
        scheme: SuiAddrConst.secp256k1AddressFlag,
      );
    } catch (e) {
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid ${CryptoKeyType.secp256k1.name} public key.",
      );
    }
  }

  /// Encodes a secp256r1 public key to a Sui address.
  static List<int> encodeSecp256r1(List<int> bytes) {
    try {
      final key = AddrKeyValidator.validateAndGetNist256p1Key(
        bytes,
      ).toBytes(mode: CryptoKeyEncoding.base);
      return hashKeyBytes(
        bytes: key,
        scheme: SuiAddrConst.secp256r1AddressFlag,
      );
    } catch (e) {
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid ${CryptoKeyType.nist256p1.name} public key.",
      );
    }
  }

  /// Encodes public keys + threshold to a Sui multisig address.
  static List<int> encodeMultiKey(
    List<SuiPublicKeyAndWeight> publicKeys,
    int threshold,
  ) {
    try {
      if (publicKeys.isEmpty) {
        throw CoreErrors.addressKeyValidationFailed(
          reason: "At least one publickey required for multisig address.",
        );
      }
      final keys = publicKeys.map((e) => e.publicKey).toSet();
      if (keys.length != publicKeys.length) {
        throw CoreErrors.addressKeyValidationFailed(
          reason: "Duplicate public key detected.",
        );
      }
      if (keys.length > SuiAddrConst.multisigAccountMaxPublicKey) {
        throw CoreErrors.addressKeyValidationFailed(
          reason:
              "Exceeded the maximum allowed public keys for a multisig account.",
          details: {
            "maximum": SuiAddrConst.multisigAccountMaxPublicKey.toString(),
            "length": publicKeys.length.toString(),
          },
        );
      }

      if (threshold < SuiAddrConst.multisigAccountMinThreshold ||
          threshold > SuiAddrConst.multisigAccountMaxThreshold) {
        // (Dart's `$name` interpolation doesn't follow property access);
        // needed `${...}` braces to actually show the numeric limit.
        throw CoreErrors.addressKeyValidationFailed(
          reason:
              "Invalid threshold. threshold must be between 1 and "
              "${SuiAddrConst.multisigAccountMaxThreshold}.",
        );
      }
      final sumWeight = publicKeys.fold<int>(0, (p, c) => p + c.weight);
      if (sumWeight < threshold) {
        throw CoreErrors.addressKeyValidationFailed(
          reason: "Sum of publickey weights must reach the threshold.",
        );
      }
      final encode = publicKeys.map((e) => e.toBytes()).expand((e) => e);
      return hashKeyBytes(
        bytes: [...LayoutConst.u16().serialize(threshold), ...encode],
        scheme: SuiAddrConst.multisigAddressFlag,
      );
    } on BuError {
      rethrow;
    } catch (e) {
      throw CoreErrors.addressKeyValidationFailed(
        details: {"error": e.toString()},
      );
    }
  }
}

/// Decodes a Sui address.
class SuiAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    final addressBytes = SuiAddressUtils.addressToBytes(addr);
    return addressBytes;
  }
}

/// Encodes a Sui secp256k1 address.
class SuiSecp256k1AddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final addressBytes = SuiAddressUtils.encodeSecp256k1(pubKey);

    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.sui.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }
}

/// Encodes a Sui secp256r1 address.
class SuiSecp256r1AddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final addressBytes = SuiAddressUtils.encodeSecp256r1(pubKey);
    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.sui.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }
}

/// Encodes a Sui Ed25519 address (with secp256k1/secp256r1/multisig helpers).
class SuiAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final addressBytes = SuiAddressUtils.encodeEd25519Key(pubKey);

    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.sui.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }

  /// Encodes a secp256k1 public key to a Sui address.
  String encodeSecp256k1Key(List<int> pubKey) {
    final addressBytes = SuiAddressUtils.encodeSecp256k1(pubKey);

    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.sui.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }

  /// Encodes a secp256r1 public key to a Sui address.
  String encodeSecp256r1Key(List<int> pubKey) {
    final addressBytes = SuiAddressUtils.encodeSecp256r1(pubKey);
    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.sui.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }

  /// Encodes public keys + threshold to a Sui multisig address.
  String encodeMultisigKey({
    required List<SuiPublicKeyAndWeight> pubKey,
    required int threshold,
  }) {
    final addressBytes = SuiAddressUtils.encodeMultiKey(pubKey, threshold);
    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.sui.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }
}
