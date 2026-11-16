import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/protocol/bip/bip.dart';
import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Aptos address constants.
class AptosAddrConst {
  /// Special addresses must have their last byte below this value.
  static const int specialAddressLastBytesMax = 16;

  /// Address length in bytes.
  static const int addressBytesLength = 32;

  /// Ed25519 scheme flag.
  static const int ed25519AddressFlag = 0;

  /// MultiEd25519 scheme flag.
  static const int multiEd25519AddressFlag = 1;

  /// SingleKey scheme flag.
  static const int singleKeyAddressFlag = 2;

  /// MultiKey scheme flag.
  static const int multikeyAddressFlag = 3;

  /// Max keys allowed in a multi-signature account.
  static const int maximumPublicKeys = 32;

  /// Min keys required.
  static const int minPublicKeys = 2;

  /// Min required-signature threshold.
  static const int minThreshold = 1;

  static const int shortAddressLength = 63;

  static const int multikeyMinPublicKey = 1;
  static const int multikeyMaxPublicKey = BinaryOps.mask32;

  static const int multiKeyMaxSignature = 32;

  /// BCS layout for encoding a MultiKey address.
  static Layout get multiKeyAddressLayout => LayoutConst.struct([
    LayoutConst.bcsVector(
      LayoutConst.bcsLazyEnum([
        LazyVariantModel(
          layout: LayoutConst.bcsBytes,
          property: CryptoKeyType.ed25519.name,
          index: 0,
        ),
        LazyVariantModel(
          layout: LayoutConst.bcsBytes,
          property: CryptoKeyType.secp256k1.name,
          index: 1,
        ),
      ], property: "pubKey"),
      property: 'publicKeys',
    ),
    LayoutConst.u8(property: "requiredSignature"),
  ]);

  /// BCS layout for encoding a SingleKey address.
  static Layout get singleKeyAddressLayout => LayoutConst.bcsLazyEnum([
    LazyVariantModel(
      layout: LayoutConst.bcsBytes,
      property: CryptoKeyType.ed25519.name,
      index: 0,
    ),
    LazyVariantModel(
      layout: LayoutConst.bcsBytes,
      property: CryptoKeyType.secp256k1.name,
      index: 1,
    ),
  ]);
}

class AptosAddressUtils {
  /// Validates address bytes are the expected length.
  static List<int> praseAddressBytes(List<int> bytes) {
    final length = bytes.length;
    if (length != AptosAddrConst.addressBytesLength) {
      throw CoreErrors.addressBytesValidationFailed(
        network: "Aptos",
        details: {
          "expected": AptosAddrConst.addressBytesLength.toString(),
          "length": bytes.length.toString(),
        },
      );
    }

    return bytes;
  }

  /// Parses an address string, zero-padding special short addresses.
  static BuBytes addressToBytes(String address) {
    address = StringUtils.strip0x(address);
    List<int>? bytes = BytesUtils.tryFromHexString(
      address,
      paddingZero:
          address.length == 1 ||
          address.length == AptosAddrConst.shortAddressLength,
    );
    if (bytes == null ||
        (bytes.length != AptosAddrConst.addressBytesLength &&
            bytes.length != 1)) {
      throw CoreErrors.addressValidationFailed(
        network: "Aptos",
        details: {"address": address},
      );
    }
    if (bytes.length == 1) {
      final byte = bytes[0];
      if (byte >= AptosAddrConst.specialAddressLastBytesMax) {
        throw CoreErrors.addressValidationFailed(
          network: "Aptos",
          details: {"address": BytesUtils.toHexString(bytes)},
        );
      }
      bytes = List.filled(AptosAddrConst.addressBytesLength, 0);
      bytes.last = byte;
    }
    return BuBytes(praseAddressBytes(bytes));
  }

  /// Hashes key bytes with a scheme byte to derive an address.
  static BuBytes hashKeyBytes({required List<int> bytes, required int scheme}) {
    return QuickCrypto.sha3256Hash([...bytes, scheme]);
  }

  /// Encodes an Ed25519 public key to address bytes.
  static List<int> encodeEd25519Key(List<int> bytes) {
    try {
      final key = AddrKeyValidator.validateAndGetEd25519KeyBytes(bytes);
      return hashKeyBytes(
        bytes: key,
        scheme: AptosAddrConst.ed25519AddressFlag,
      );
    } catch (_) {
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid ${CryptoKeyType.ed25519.name} public key.",
      );
    }
  }

  /// Encodes a public key to a SingleKey address.
  static List<int> encodeSingleKey(IPublicKey publicKey) {
    try {
      final pubkeyBytes = switch (publicKey.type) {
        CryptoKeyType.secp256k1 => publicKey.toBytes(
          mode: CryptoKeyEncoding.uncompressed,
        ),
        CryptoKeyType.ed25519 => publicKey.toBytes(),
        _ =>
          throw CoreErrors.addressKeyValidationFailed(
            reason: "Unsupported ${publicKey.type.name} public key.",
          ),
      };
      final structLayout = {publicKey.type.name: pubkeyBytes};
      final encode = AptosAddrConst.singleKeyAddressLayout.serialize(
        structLayout,
      );
      return hashKeyBytes(
        bytes: encode,
        scheme: AptosAddrConst.singleKeyAddressFlag,
      );
    } on BuError {
      rethrow;
    } catch (e) {
      throw CoreErrors.addressBytesValidationFailed(
        details: {"error": e.toString()},
      );
    }
  }

  static bool isValidMultiEd25519KeyConfig(int keyLength, int threshold) {
    if (keyLength < AptosAddrConst.minPublicKeys ||
        keyLength > AptosAddrConst.maximumPublicKeys) {
      return false;
    }
    if (threshold < AptosAddrConst.minThreshold || threshold > keyLength) {
      return false;
    }
    return true;
  }

  static bool isValidMultiKeyConfig(int keyLength, int threshold) {
    if (keyLength < AptosAddrConst.multikeyMinPublicKey ||
        keyLength > AptosAddrConst.multikeyMaxPublicKey) {
      return false;
    }

    if (threshold < AptosAddrConst.minThreshold ||
        threshold > AptosAddrConst.multiKeyMaxSignature) {
      return false;
    }
    if (keyLength < threshold) {
      return false;
    }
    return true;
  }

  /// Encodes Ed25519 public keys to a MultiEd25519 address.
  static List<int> encodeMultiEd25519Key(
    List<ED25519PublicKey> publicKeys,
    int threshold,
  ) {
    try {
      final keys = publicKeys.toSet();
      if (keys.length != publicKeys.length) {
        throw CoreErrors.addressKeyValidationFailed(
          reason: "Duplicate public key detected.",
          network: "Aptos",
        );
      }
      if (!isValidMultiEd25519KeyConfig(keys.length, threshold)) {
        throw CoreErrors.addressKeyValidationFailed(
          network: "Aptos",
          reason: "Invalid key length/threshod config.",
        );
      }

      final keyBytes = [
        ...publicKeys.map((e) => e.toBytes()).expand((e) => e),
        threshold,
      ];
      return hashKeyBytes(
        bytes: keyBytes,
        scheme: AptosAddrConst.multiEd25519AddressFlag,
      );
    } on BuError {
      rethrow;
    } catch (e) {
      throw CoreErrors.addressKeyValidationFailed(
        network: "Aptos",
        details: {"error": e.toString()},
      );
    }
  }

  /// Encodes public keys to a MultiKey address.
  static List<int> encodeMultiKey(
    List<IPublicKey> publicKeys,
    int requiredSignature,
  ) {
    try {
      final pubkeyLayoutStruct =
          publicKeys.map((e) {
            return switch (e.type) {
              CryptoKeyType.secp256k1 => {
                e.type.name: e.toBytes(mode: CryptoKeyEncoding.uncompressed),
              },
              CryptoKeyType.ed25519 => {e.type.name: e.toBytes()},
              _ =>
                throw CoreErrors.addressKeyValidationFailed(
                  reason: "Unsupported ${e.type.name} public key.",
                ),
            };
          }).toList();
      final keys = publicKeys.toSet();
      if (keys.length != publicKeys.length) {
        throw CoreErrors.addressKeyValidationFailed(
          network: "Aptos",
          reason: "Duplicate public key detected.",
        );
      }
      if (!isValidMultiKeyConfig(publicKeys.length, requiredSignature)) {
        throw CoreErrors.addressKeyValidationFailed(
          network: "Aptos",
          reason: "Invalid key length/threshod config.",
        );
      }

      final layoutStruct = {
        "requiredSignature": requiredSignature,
        "publicKeys": pubkeyLayoutStruct,
      };
      final encode = AptosAddrConst.multiKeyAddressLayout.serialize(
        layoutStruct,
      );
      return hashKeyBytes(
        bytes: encode,
        scheme: AptosAddrConst.multikeyAddressFlag,
      );
    } on BuError {
      rethrow;
    } catch (e) {
      throw CoreErrors.addressBytesValidationFailed(
        network: "Aptos",
        details: {"error": e.toString()},
      );
    }
  }
}

/// Decodes an Aptos address.
class AptosAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  /// Returns the decoded address bytes.
  @override
  BuBytes decodeAddr(String addr) {
    return AptosAddressUtils.addressToBytes(addr);
  }
}

/// Encodes an Aptos SingleKey address from an Ed25519 public key.
class AptosSingleKeyEd25519AddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final publicKey = AddrKeyValidator.validateAndGetEd25519PubKey(pubKey);
    final addressBytes = AptosAddressUtils.encodeSingleKey(publicKey);

    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.aptos.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }
}

/// Encodes an Aptos SingleKey address from a Secp256k1 public key.
class AptosSingleKeySecp256k1AddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey) {
    final publicKey = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final addressBytes = AptosAddressUtils.encodeSingleKey(publicKey);

    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.aptos.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }
}

/// Encodes an Aptos Ed25519 address.
class AptosAddrEncoder implements BlockchainAddressEncoder {
  /// Returns the encoded Ed25519 address.
  @override
  String encodeKey(List<int> pubKey) {
    final addressBytes = AptosAddressUtils.encodeEd25519Key(pubKey);

    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.aptos.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }

  /// Returns the encoded SingleKey address.
  String encodeSingleKey(IPublicKey pubKey) {
    final addressBytes = AptosAddressUtils.encodeSingleKey(pubKey);

    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.aptos.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }

  /// Returns the encoded MultiEd25519 address.
  String encodeMultiEd25519Key({
    required List<ED25519PublicKey> publicKeys,
    required int threshold,
  }) {
    final addressBytes = AptosAddressUtils.encodeMultiEd25519Key(
      publicKeys,
      threshold,
    );
    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.aptos.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }

  /// Returns the encoded MultiKey address.
  String encodeMultiKey({
    required List<IPublicKey> publicKeys,
    required int requiredSignature,
  }) {
    final addressBytes = AptosAddressUtils.encodeMultiKey(
      publicKeys,
      requiredSignature,
    );
    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.aptos.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }
}
