import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/layout/layout.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'addr_key_validator.dart';

class AptosAddrConst {
  static const int specialAddressLastBytesMax = 16;

  /// aptos address bytes length
  static const int addressBytesLength = 32;

  /// The Ed25519 signing scheme flag
  static const int ed25519AddressFlag = 0;

  /// The multi-signature Ed25519 scheme flag
  static const int multiEd25519AddressFlag = 1;

  /// A single key signing scheme flag (likely used for single-key accounts)
  static const int signleKeyAddressFlag = 2;

  /// A multi-key signing scheme flag where multiple different types of keys are involved
  static const int multikeyAddressFlag = 3;

  /// Max number of keys in the multi-signature account
  static const int maximumPublicKeys = 32;

  /// Minimum number of keys required
  static const int minPublicKeys = 2;

  /// Minimum threshold of required signatures
  static const int minthreshold = 1;

  static const int shortAddressLength = 63;

  static const int multikeyMinPublicKey = 1;
  static const int multikeyMaxPublicKey = BinaryOps.mask32;

  static const int multiKeyMaxSignature = 32;

  /// Bcs layout for encdoing multikey address
  static Layout get multiKeyAddressLayout => LayoutConst.struct([
    LayoutConst.bcsVector(
      LayoutConst.bcsLazyEnum([
        LazyVariantModel(
          layout: LayoutConst.bcsBytes,
          property: EllipticCurveTypes.ed25519.name,
          index: 0,
        ),
        LazyVariantModel(
          layout: LayoutConst.bcsBytes,
          property: EllipticCurveTypes.secp256k1.name,
          index: 1,
        ),
      ], property: "pubKey"),
      property: 'publicKeys',
    ),
    LayoutConst.u8(property: "requiredSignature"),
  ]);

  /// Bcs layout for encoding single key address
  static Layout get singleKeyAddressLayout => LayoutConst.bcsLazyEnum([
    LazyVariantModel(
      layout: LayoutConst.bcsBytes,
      property: EllipticCurveTypes.ed25519.name,
      index: 0,
    ),
    LazyVariantModel(
      layout: LayoutConst.bcsBytes,
      property: EllipticCurveTypes.secp256k1.name,
      index: 1,
    ),
  ]);
}

class AptosAddressUtils {
  /// check address bytes and convert special address to 32bytes.
  static List<int> praseAddressBytes(List<int> bytes) {
    final length = bytes.length;
    if (length != AptosAddrConst.addressBytesLength) {
      throw AddressConverterException.addressBytesValidationFailed(
        network: "Aptos",
        details: {
          "expected": AptosAddrConst.addressBytesLength,
          "length": bytes.length,
        },
      );
    }

    return bytes;
  }

  /// convert address string to bytes with padding zero for special addresses.
  static List<int> addressToBytes(String address) {
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
      throw AddressConverterException.addressValidationFailed(
        network: "Aptos",
        details: {"address": address},
      );
    }
    if (bytes.length == 1) {
      final byte = bytes[0];
      if (byte >= AptosAddrConst.specialAddressLastBytesMax) {
        throw AddressConverterException.addressValidationFailed(
          network: "Aptos",
          details: {"address": BytesUtils.toHexString(bytes)},
        );
      }
      bytes = List.filled(AptosAddrConst.addressBytesLength, 0);
      bytes.last = byte;
    }
    return praseAddressBytes(bytes);
  }

  /// convert bytes (ED25519, Secp256k1 or multisig key data) to address with specify scheme
  static List<int> hashKeyBytes({
    required List<int> bytes,
    required int scheme,
  }) {
    bytes = [...bytes, scheme];
    bytes = QuickCrypto.sha3256Hash(bytes);
    return bytes;
  }

  /// encode ED25519 public key to address
  static List<int> encodeEd25519Key(List<int> bytes) {
    try {
      final key = AddrKeyValidator.validateAndGetEd25519Key(
        bytes,
      ).compressed.sublist(1);
      return hashKeyBytes(
        bytes: key,
        scheme: AptosAddrConst.ed25519AddressFlag,
      );
    } catch (_) {
      throw AddressConverterException.addressKeyValidationFailed(
        reason: "Invalid ${EllipticCurveTypes.ed25519.name} public key.",
      );
    }
  }

  /// encode public key to SignleKey address
  static List<int> encodeSingleKey(IPublicKey publicKey) {
    try {
      final pubkeyBytes = switch (publicKey.curve) {
        EllipticCurveTypes.secp256k1 => publicKey.uncompressed,
        EllipticCurveTypes.ed25519 => publicKey.compressed.sublist(1),
        _ =>
          throw AddressConverterException.addressKeyValidationFailed(
            reason: "Unsuported ${publicKey.curve.name} public key.",
          ),
      };
      final structLayout = {publicKey.curve.name: pubkeyBytes};
      final encode = AptosAddrConst.singleKeyAddressLayout.serialize(
        structLayout,
      );
      return hashKeyBytes(
        bytes: encode,
        scheme: AptosAddrConst.signleKeyAddressFlag,
      );
    } on AddressConverterException {
      rethrow;
    } catch (e) {
      throw AddressConverterException.addressBytesValidationFailed(
        details: {"error": e.toString()},
      );
    }
  }

  /// encode Multi ED25519 public keys to MultiEd25519 address
  static List<int> encodeMultiEd25519Key(
    List<Ed25519PublicKey> publicKeys,
    int threshold,
  ) {
    try {
      final keys = publicKeys.toSet();
      if (keys.length != publicKeys.length) {
        throw AddressConverterException.addressKeyValidationFailed(
          reason: "Duplicate public key detected.",
          network: "Aptos",
        );
      }
      if (publicKeys.length < AptosAddrConst.minPublicKeys ||
          publicKeys.length > AptosAddrConst.maximumPublicKeys) {
        throw AddressConverterException.addressKeyValidationFailed(
          network: "Aptos",
          reason:
              "The number of public keys provided is invalid. It must be between ${AptosAddrConst.minPublicKeys} and ${AptosAddrConst.maximumPublicKeys}.",
        );
      }
      if (threshold < AptosAddrConst.minthreshold ||
          threshold > publicKeys.length) {
        throw AddressConverterException.addressKeyValidationFailed(
          network: "Aptos",
          reason:
              "Invalid threshold. The threshold must be between ${AptosAddrConst.minthreshold} and the number of provided public keys (${publicKeys.length}).",
        );
      }
      final keyBytes = [
        ...publicKeys.map((e) => e.compressed.sublist(1)).expand((e) => e),
        threshold,
      ];
      return hashKeyBytes(
        bytes: keyBytes,
        scheme: AptosAddrConst.multiEd25519AddressFlag,
      );
    } on AddressConverterException {
      rethrow;
    } catch (e) {
      throw AddressConverterException.addressKeyValidationFailed(
        network: "Aptos",
        details: {"error": e.toString()},
      );
    }
  }

  /// encode Multi Public keys to MultiKey address
  static List<int> encodeMultiKey(
    List<IPublicKey> publicKeys,
    int requiredSignature,
  ) {
    try {
      final pubkeyLayoutStruct =
          publicKeys.map((e) {
            return switch (e.curve) {
              EllipticCurveTypes.secp256k1 => {e.curve.name: e.uncompressed},
              EllipticCurveTypes.ed25519 => {
                e.curve.name: e.compressed.sublist(1),
              },
              _ =>
                throw AddressConverterException.addressKeyValidationFailed(
                  reason: "Unsupported ${e.curve.name} public key.",
                ),
            };
          }).toList();
      final keys = publicKeys.toSet();
      if (keys.length != publicKeys.length) {
        throw AddressConverterException.addressKeyValidationFailed(
          network: "Aptos",
          reason: "Duplicate public key detected.",
        );
      }
      if (publicKeys.length < AptosAddrConst.multikeyMinPublicKey ||
          publicKeys.length > AptosAddrConst.multikeyMaxPublicKey) {
        throw AddressConverterException.addressKeyValidationFailed(
          network: "Aptos",
          reason:
              "The number of public keys provided is invalid. It must be between ${AptosAddrConst.multikeyMinPublicKey} and ${AptosAddrConst.multikeyMaxPublicKey}.",
        );
      }

      if (requiredSignature < AptosAddrConst.minthreshold ||
          requiredSignature > AptosAddrConst.multiKeyMaxSignature) {
        throw AddressConverterException.addressKeyValidationFailed(
          network: "Aptos",
          reason:
              "Invalid threshold. The threshold must be between ${AptosAddrConst.minthreshold} and ${AptosAddrConst.multiKeyMaxSignature}.",
        );
      }
      if (publicKeys.length < requiredSignature) {
        throw AddressConverterException.addressKeyValidationFailed(
          network: "Aptos",
          reason:
              "The number of public keys must be at least equal to the required signatures.",
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
    } on AddressConverterException {
      rethrow;
    } catch (e) {
      throw AddressConverterException.addressBytesValidationFailed(
        network: "Aptos",
        details: {"error": e.toString()},
      );
    }
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Aptos address.
class AptosAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// This method is used to convert an Aptos blockchain address from its string
  /// representation to its binary format for further processing.
  @override
  List<int> decodeAddr(String addr) {
    return AptosAddressUtils.addressToBytes(addr);
  }
}

class AptosSingleKeyEd25519AddrEncoder implements BlockchainAddressEncoder {
  /// This method is used to create an Aptos `SingleKey` address from `ED25519` public key.
  @override
  String encodeKey(List<int> pubKey) {
    final publicKey = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    final addressBytes = AptosAddressUtils.encodeSingleKey(publicKey);

    /// Concatenate the address prefix and the hash bytes, removing leading zeros
    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.aptos.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }
}

class AptosSingleKeySecp256k1AddrEncoder implements BlockchainAddressEncoder {
  /// This method is used to create an Aptos `SingleKey` address from `Sec256k1` public key.
  @override
  String encodeKey(List<int> pubKey) {
    final publicKey = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final addressBytes = AptosAddressUtils.encodeSingleKey(publicKey);

    /// Concatenate the address prefix and the hash bytes, removing leading zeros
    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.aptos.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Aptos address.
class AptosAddrEncoder implements BlockchainAddressEncoder {
  /// This method is used to create an Aptos `ED25519` address from public key.
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

  /// This method is used to create an Aptos `SingleKey` address from (ED25519, Sec256k1) public key.
  String encodeSingleKey(IPublicKey pubKey) {
    final addressBytes = AptosAddressUtils.encodeSingleKey(pubKey);

    /// Concatenate the address prefix and the hash bytes, removing leading zeros
    return BytesUtils.toHexString(
      addressBytes,
      prefix: AddrKeyValidator.getConfigArg(
        CoinsConf.aptos.params.addrPrefix,
        "addrPrefix",
      ),
    );
  }

  /// This method is used to create an Aptos `MultiEd25519` address from ED25519 public keys.
  String encodeMultiEd25519Key({
    required List<Ed25519PublicKey> publicKeys,
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

  /// This method is used to create an Aptos `MultiKey` address from (ED25519 or Secp256k1) public keys.
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
