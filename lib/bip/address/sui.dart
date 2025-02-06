import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/layout/layout.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'addr_key_validator.dart';

class SuiPublicKeyAndWeight {
  final IPublicKey publicKey;
  final int weight;
  const SuiPublicKeyAndWeight._(
      {required this.publicKey, required this.weight});
  factory SuiPublicKeyAndWeight(
      {required IPublicKey publicKey, required int weight}) {
    if (weight < 1 || weight >= mask8) {
      throw AddressConverterException(
          "Invalid signer wieght. weight must be between 1 and $mask8 .");
    }
    switch (publicKey.curve) {
      case EllipticCurveTypes.ed25519:
      case EllipticCurveTypes.secp256k1:
      case EllipticCurveTypes.nist256p1:
        break;
      default:
        throw AddressConverterException(
            "Unsupported public key: sui Multikey address can only be generated from secp256k1, ed25519 or nist256p1 public keys.");
    }
    return SuiPublicKeyAndWeight._(publicKey: publicKey, weight: weight);
  }

  List<int> toBytes() {
    final int flag = switch (publicKey.curve) {
      EllipticCurveTypes.ed25519 => SuiAddrConst.ed25519AddressFlag,
      EllipticCurveTypes.secp256k1 => SuiAddrConst.secp256k1AddressFlag,
      _ => SuiAddrConst.secp256r1AddressFlag,
    };
    List<int> publicKeyBytes = publicKey.compressed;
    if (publicKey.curve == EllipticCurveTypes.ed25519) {
      publicKeyBytes = publicKeyBytes.sublist(1);
    }
    return [flag, ...publicKeyBytes, weight];
  }
}

class SuiAddrConst {
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
}

class SuiAddressUtils {
  /// check address bytes and convert special address to 32bytes.
  static List<int> praseAddressBytes(List<int> bytes) {
    if (bytes.length != SuiAddrConst.addressBytesLength) {
      throw AddressConverterException("Invalid sui address bytes length.",
          details: {
            "expected": SuiAddrConst.addressBytesLength,
            "length": bytes.length
          });
    }
    return bytes;
  }

  /// convert address string to bytes without padding special addresses.
  static List<int> addressToBytes(String address) {
    address = StringUtils.strip0x(address);
    List<int>? bytes =
        BytesUtils.tryFromHexString(address, paddingZero: address.length < 2);
    if (bytes?.length != SuiAddrConst.addressBytesLength) {
      throw AddressConverterException("Invalid sui address.",
          details: {"address": address});
    }
    return bytes!;
  }

  /// convert bytes (ED25519, Secp256k1 or multisig key data) to address with specify scheme
  static List<int> hashKeyBytes(
      {required List<int> bytes, required int scheme}) {
    return QuickCrypto.blake2b256Hash([scheme, ...bytes]);
  }

  /// encode ED25519 public key to address
  static List<int> encodeEd25519Key(List<int> bytes) {
    try {
      final key = AddrKeyValidator.validateAndGetEd25519Key(bytes)
          .compressed
          .sublist(1);
      return hashKeyBytes(bytes: key, scheme: SuiAddrConst.ed25519AddressFlag);
    } catch (e) {
      throw AddressConverterException(
          "Failed to generate sui address: Invalid Ed25519 public key provided.");
    }
  }

  /// encode secp256k1 public key to address
  static List<int> encodeSecp256k1(List<int> bytes) {
    try {
      final key = AddrKeyValidator.validateAndGetSecp256k1Key(bytes).compressed;
      return hashKeyBytes(
          bytes: key, scheme: SuiAddrConst.secp256k1AddressFlag);
    } catch (e) {
      throw AddressConverterException(
          "Failed to generate sui address: Invalid secp256k1 public key provided.");
    }
  }

  /// encode secp256r1 public key to address
  static List<int> encodeSecp256r1(List<int> bytes) {
    try {
      final key = AddrKeyValidator.validateAndGetNist256p1Key(bytes).compressed;
      return hashKeyBytes(
          bytes: key, scheme: SuiAddrConst.secp256r1AddressFlag);
    } catch (e) {
      throw AddressConverterException(
          "Failed to generate sui address: Invalid secp256r1 public key provided.");
    }
  }

  /// encode Multi Public keys to MultiKey address
  static List<int> encodeMultiKey(
      List<SuiPublicKeyAndWeight> publicKeys, int threshold) {
    try {
      if (publicKeys.isEmpty) {
        throw AddressConverterException(
            "at least one publickey required for multisig address.");
      }
      final keys = publicKeys.map((e) => e.publicKey).toSet();
      if (keys.length != publicKeys.length) {
        throw AddressConverterException("Duplicate public key detected.");
      }

      if (threshold < 1 || threshold >= mask16) {
        throw AddressConverterException(
            "Invalid threshold. threshold must be between 1 and $mask16 .");
      }
      final sumWeight = publicKeys.fold<int>(0, (p, c) => p + c.weight);
      if (sumWeight < threshold) {
        throw AddressConverterException(
            "Sum of publickey weights must reach the threshold.");
      }
      final encode = publicKeys.map((e) => e.toBytes()).expand((e) => e);
      return hashKeyBytes(bytes: [
        ...LayoutConst.u16().serialize(threshold),
        ...encode,
      ], scheme: SuiAddrConst.multisigAddressFlag);
    } on AddressConverterException {
      rethrow;
    } catch (e) {
      throw AddressConverterException("Invalid sui Multisig address bytes.",
          details: {"error": e.toString()});
    }
  }
}

/// Implementation of the [BlockchainAddressDecoder] for sui address.
class SuiAddrDecoder implements BlockchainAddressDecoder {
  /// This method is used to convert an sui blockchain address from its string
  /// representation to its binary format for further processing.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final addressBytes = SuiAddressUtils.addressToBytes(addr);
    return addressBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for sui address.
class SuiSecp256k1AddrEncoder implements BlockchainAddressEncoder {
  /// encode secp256k1 public key to address
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final addressBytes = SuiAddressUtils.encodeSecp256k1(pubKey);

    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.sui.params.addrPrefix);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for sui address.
class SuiSecp256r1AddrEncoder implements BlockchainAddressEncoder {
  /// encode secp256r1 public key to address
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final addressBytes = SuiAddressUtils.encodeSecp256r1(pubKey);
    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.sui.params.addrPrefix);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for sui address.
class SuiAddrEncoder implements BlockchainAddressEncoder {
  /// This method is used to create an sui `ED25519` address from public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    final addressBytes = SuiAddressUtils.encodeEd25519Key(pubKey);

    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.sui.params.addrPrefix);
  }

  /// encode secp256k1 public key to address
  String encodeSecp256k1Key(List<int> pubKey,
      [Map<String, dynamic> kwargs = const {}]) {
    final addressBytes = SuiAddressUtils.encodeSecp256k1(pubKey);

    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.sui.params.addrPrefix);
  }

  /// encode secp256r1 public key to address
  String encodeSecp256r1Key(List<int> pubKey,
      [Map<String, dynamic> kwargs = const {}]) {
    final addressBytes = SuiAddressUtils.encodeSecp256r1(pubKey);
    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.sui.params.addrPrefix);
  }

  /// encode public keys to multisig address
  String encodeMultisigKey(
      {required List<SuiPublicKeyAndWeight> pubKey, required int threshold}) {
    final addressBytes = SuiAddressUtils.encodeMultiKey(pubKey, threshold);
    return BytesUtils.toHexString(addressBytes,
        prefix: CoinsConf.sui.params.addrPrefix);
  }
}
