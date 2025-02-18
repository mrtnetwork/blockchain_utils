import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/layout/layout.dart';
import 'package:blockchain_utils/utils/utils.dart';

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
  static const int multikeyMaxPublicKey = mask32;

  static const int multiKeyMaxSignature = 32;

  /// Bcs layout for encdoing multikey address
  static final multiKeyAddressLayout = LayoutConst.struct([
    LayoutConst.bcsVector(
        LayoutConst.bcsLazyEnum([
          LazyVariantModel(
              layout: LayoutConst.bcsBytes,
              property: EllipticCurveTypes.ed25519.name,
              index: 0),
          LazyVariantModel(
              layout: LayoutConst.bcsBytes,
              property: EllipticCurveTypes.secp256k1.name,
              index: 1)
        ], property: "pubKey"),
        property: 'publicKeys'),
    LayoutConst.u8(property: "requiredSignature")
  ]);

  /// Bcs layout for encoding single key address
  static final singleKeyAddressLayout = LayoutConst.bcsLazyEnum([
    LazyVariantModel(
        layout: LayoutConst.bcsBytes,
        property: EllipticCurveTypes.ed25519.name,
        index: 0),
    LazyVariantModel(
        layout: LayoutConst.bcsBytes,
        property: EllipticCurveTypes.secp256k1.name,
        index: 1)
  ]);
}

class AptosAddressUtils {
  /// check address bytes and convert special address to 32bytes.
  static List<int> praseAddressBytes(List<int> bytes) {
    final length = bytes.length;
    if (length != AptosAddrConst.addressBytesLength) {
      throw AddressConverterException("Invalid aptos address bytes length.",
          details: {
            "expected": AptosAddrConst.addressBytesLength,
            "length": bytes.length
          });
    }

    return bytes;
  }

  /// convert address string to bytes with padding zero for special addresses.
  static List<int> addressToBytes(String address) {
    address = StringUtils.strip0x(address);
    List<int>? bytes = BytesUtils.tryFromHexString(address,
        paddingZero: address.length == 1 ||
            address.length == AptosAddrConst.shortAddressLength);
    if (bytes == null ||
        (bytes.length != AptosAddrConst.addressBytesLength &&
            bytes.length != 1)) {
      throw AddressConverterException("Invalid aptos address.",
          details: {"address": address});
    }
    if (bytes.length == 1) {
      final byte = bytes[0];
      if (byte >= AptosAddrConst.specialAddressLastBytesMax) {
        throw AddressConverterException("Invalid special address.",
            details: {"address": BytesUtils.toHexString(bytes)});
      }
      bytes = List.filled(AptosAddrConst.addressBytesLength, 0);
      bytes.last = byte;
    }
    return praseAddressBytes(bytes);
  }

  /// convert bytes (ED25519, Secp256k1 or multisig key data) to address with specify scheme
  static List<int> hashKeyBytes(
      {required List<int> bytes, required int scheme}) {
    bytes = [...bytes, scheme];
    bytes = QuickCrypto.sha3256Hash(bytes);
    return bytes;
  }

  /// encode ED25519 public key to address
  static List<int> encodeEd25519Key(List<int> bytes) {
    try {
      final key = AddrKeyValidator.validateAndGetEd25519Key(bytes)
          .compressed
          .sublist(1);
      return hashKeyBytes(
          bytes: key, scheme: AptosAddrConst.ed25519AddressFlag);
    } catch (e) {
      throw AddressConverterException(
          "Failed to generate Aptos address: Invalid Ed25519 public key provided.");
    }
  }

  /// encode public key to SignleKey address
  static List<int> encodeSingleKey(IPublicKey publicKey) {
    try {
      final pubkeyBytes = switch (publicKey.curve) {
        EllipticCurveTypes.secp256k1 => publicKey.uncompressed,
        EllipticCurveTypes.ed25519 => publicKey.compressed.sublist(1),
        _ => throw AddressConverterException(
            "Unsupported public key: Aptos SingleKey can only be generated from secp256k1 or ed25519 public keys.")
      };
      final structLayout = {publicKey.curve.name: pubkeyBytes};
      final encode =
          AptosAddrConst.singleKeyAddressLayout.serialize(structLayout);
      return hashKeyBytes(
          bytes: encode, scheme: AptosAddrConst.signleKeyAddressFlag);
    } on AddressConverterException {
      rethrow;
    } catch (e) {
      throw AddressConverterException("Invalid aptos MultiKey address bytes.",
          details: {"error": e.toString()});
    }
  }

  /// encode Multi ED25519 public keys to MultiEd25519 address
  static List<int> encodeMultiEd25519Key(
      List<Ed25519PublicKey> publicKeys, int threshold) {
    try {
      final keys = publicKeys.toSet();
      if (keys.length != publicKeys.length) {
        throw AddressConverterException("Duplicate public key detected.");
      }
      if (publicKeys.length < AptosAddrConst.minPublicKeys ||
          publicKeys.length > AptosAddrConst.maximumPublicKeys) {
        throw AddressConverterException(
            "The number of public keys provided is invalid. It must be between ${AptosAddrConst.minPublicKeys} and ${AptosAddrConst.maximumPublicKeys}.");
      }
      if (threshold < AptosAddrConst.minthreshold ||
          threshold > publicKeys.length) {
        throw AddressConverterException(
            "Invalid threshold. The threshold must be between ${AptosAddrConst.minthreshold} and the number of provided public keys (${publicKeys.length}).");
      }
      final keyBytes = [
        ...publicKeys.map((e) => e.compressed.sublist(1)).expand((e) => e),
        threshold
      ];
      return hashKeyBytes(
          bytes: keyBytes, scheme: AptosAddrConst.multiEd25519AddressFlag);
    } on AddressConverterException {
      rethrow;
    } catch (e) {
      throw AddressConverterException(
          "Invalid aptos MultiEd25519 address bytes.",
          details: {"error": e.toString()});
    }
  }

  /// encode Multi Public keys to MultiKey address
  static List<int> encodeMultiKey(
      List<IPublicKey> publicKeys, int requiredSignature) {
    try {
      final pubkeyLayoutStruct = publicKeys.map((e) {
        return switch (e.curve) {
          EllipticCurveTypes.secp256k1 => {e.curve.name: e.uncompressed},
          EllipticCurveTypes.ed25519 => {e.curve.name: e.compressed.sublist(1)},
          _ => throw AddressConverterException(
              "Unsupported public key: Aptos Multikey address can only be generated from secp256k1 or ed25519 public keys.")
        };
      }).toList();
      final keys = publicKeys.toSet();
      if (keys.length != publicKeys.length) {
        throw AddressConverterException("Duplicate public key detected.");
      }
      if (publicKeys.length < AptosAddrConst.multikeyMinPublicKey ||
          publicKeys.length > AptosAddrConst.multikeyMaxPublicKey) {
        throw AddressConverterException(
            "The number of public keys provided is invalid. It must be between ${AptosAddrConst.multikeyMinPublicKey} and ${AptosAddrConst.multikeyMaxPublicKey}.");
      }

      if (requiredSignature < AptosAddrConst.minthreshold ||
          requiredSignature > AptosAddrConst.multiKeyMaxSignature) {
        throw AddressConverterException(
            "Invalid threshold. The threshold must be between ${AptosAddrConst.minthreshold} and ${AptosAddrConst.multiKeyMaxSignature}.");
      }
      if (publicKeys.length < requiredSignature) {
        throw AddressConverterException(
            "The number of public keys must be at least equal to the required signatures.");
      }
      final layoutStruct = {
        "requiredSignature": requiredSignature,
        "publicKeys": pubkeyLayoutStruct
      };
      final encode =
          AptosAddrConst.multiKeyAddressLayout.serialize(layoutStruct);
      return hashKeyBytes(
          bytes: encode, scheme: AptosAddrConst.multikeyAddressFlag);
    } on AddressConverterException {
      rethrow;
    } catch (e) {
      throw AddressConverterException("Invalid aptos MultiKey address bytes.",
          details: {"error": e.toString()});
    }
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Aptos address.
class AptosAddrDecoder implements BlockchainAddressDecoder {
  /// This method is used to convert an Aptos blockchain address from its string
  /// representation to its binary format for further processing.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    return AptosAddressUtils.addressToBytes(addr);
  }
}

class AptosSingleKeyEd25519AddrEncoder implements BlockchainAddressEncoder {
  /// This method is used to create an Aptos `SingleKey` address from `ED25519` public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final publicKey = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    final addressBytes = AptosAddressUtils.encodeSingleKey(publicKey);

    /// Concatenate the address prefix and the hash bytes, removing leading zeros
    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.aptos.params.addrPrefix);
  }
}

class AptosSingleKeySecp256k1AddrEncoder implements BlockchainAddressEncoder {
  /// This method is used to create an Aptos `SingleKey` address from `Sec256k1` public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final publicKey = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final addressBytes = AptosAddressUtils.encodeSingleKey(publicKey);

    /// Concatenate the address prefix and the hash bytes, removing leading zeros
    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.aptos.params.addrPrefix);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Aptos address.
class AptosAddrEncoder implements BlockchainAddressEncoder {
  /// This method is used to create an Aptos `ED25519` address from public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final addressBytes = AptosAddressUtils.encodeEd25519Key(pubKey);

    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.aptos.params.addrPrefix);
  }

  /// This method is used to create an Aptos `SingleKey` address from (ED25519, Sec256k1) public key.
  String encodeSingleKey(IPublicKey pubKey) {
    final addressBytes = AptosAddressUtils.encodeSingleKey(pubKey);

    /// Concatenate the address prefix and the hash bytes, removing leading zeros
    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.aptos.params.addrPrefix);
  }

  /// This method is used to create an Aptos `MultiEd25519` address from ED25519 public keys.
  String encodeMultiEd25519Key(
      {required List<Ed25519PublicKey> publicKeys, required int threshold}) {
    final addressBytes =
        AptosAddressUtils.encodeMultiEd25519Key(publicKeys, threshold);
    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.aptos.params.addrPrefix);
  }

  /// This method is used to create an Aptos `MultiKey` address from (ED25519 or Secp256k1) public keys.
  String encodeMultiKey(
      {required List<IPublicKey> publicKeys, required int requiredSignature}) {
    final addressBytes =
        AptosAddressUtils.encodeMultiKey(publicKeys, requiredSignature);
    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.aptos.params.addrPrefix);
  }
}
