import 'package:blockchain_utils/base32/base32.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/crypto/x_modem_crc/x_modem_crc.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';
import 'exception/exception.dart';
import 'encoder.dart';

/// Enum representing different types of Stellar (XLM) addresses.
///
/// This enum defines two address types: "pubKey" and "privKey" with their respective values.
/// - "pubKey" is used for public account keys.
/// - "privKey" is used for private account keys.
///
/// Each enum value corresponds to an integer value, which is a bit shift left operation to calculate the actual value.
/// These values are used to determine the type of Stellar address.
///
/// Example usage:
/// ```
/// final addressType = XlmAddrTypes.pubKey;
/// final addressValue = addressType.value; // Returns 48 (6 << 3)
/// ```
class XlmAddrTypes {
  final int value;
  final String name;

  /// Contract key address type.
  static const XlmAddrTypes contract =
      XlmAddrTypes._(value: 2 << 3, name: "Contract");

  /// Public key address type. (keyBytes must be a valid Ed25519 public key)
  static const XlmAddrTypes pubKey =
      XlmAddrTypes._(name: "PublicKey", value: 6 << 3);

  /// Private key address type. (keyBytes must be a valid Ed25519 private key)
  static const XlmAddrTypes privKey =
      XlmAddrTypes._(name: "SecretKey", value: 18 << 3);

  /// Muxed
  static const XlmAddrTypes muxed =
      XlmAddrTypes._(value: 12 << 3, name: "Muxed");

  static const List<XlmAddrTypes> values = [pubKey, privKey, contract, muxed];

  /// Constructor for XlmAddrTypes enum values.
  const XlmAddrTypes._({required this.value, required this.name});

  static XlmAddrTypes fromTag(int? tag) {
    return values.firstWhere((e) => e.value == tag,
        orElse: () => throw AddressConverterException(
                "Invalid or unsuported xlm address type.",
                details: {
                  "excepted": values.map((e) => e.value).join(", "),
                  "got": tag
                }));
  }

  @override
  String toString() {
    return "XlmAddrTypes.$name";
  }
}

/// Constants related to Stellar (XLM) addresses.
///
/// This class contains constants used for handling Stellar addresses, including the checksum byte length.
class XlmAddrConst {
  /// The length in bytes of the checksum used in Stellar addresses.
  static const int checksumByteLen = 2;
  static const int versionBytesLength = 1;
  static const int muxedAddrLen = pubkeyAddrLength + muxedIdLength;
  static const int pubkeyAddrLength = Ed25519KeysConst.pubKeyByteLen +
      XlmAddrConst.versionBytesLength +
      XlmAddrConst.checksumByteLen;
  static const int muxedIdLength = 8;
}

class _XlmAddrUtils {
  /// Stellar address utility class.

  static List<int> computeChecksum(List<int> payloadBytes) {
    // Compute checksum in Stellar format.
    return XModemCrc.quickDigest(payloadBytes).reversed.toList();
  }
}

class XlmAddrDecoderResult {
  final XlmAddrTypes type;
  final List<int> pubKeyBytes;
  final String baseAddress;
  final BigInt? accountId;
  XlmAddrDecoderResult(
      {required this.type,
      required List<int> pubKeyBytes,
      required this.baseAddress,
      required this.accountId})
      : pubKeyBytes = BytesUtils.toBytes(pubKeyBytes, unmodifiable: true);
  @override
  String toString() {
    return baseAddress;
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Stellar (XLM) blockchain addresses.
class XlmAddrDecoder implements BlockchainAddressDecoder {
  XlmAddrDecoderResult decode(String addr,
      [Map<String, dynamic> kwargs = const {}]) {
    final addrType = AddrKeyValidator.nullOrValidateAddressArgs<XlmAddrTypes>(
        kwargs, "addr_type");
    final addrDecBytes = Base32Decoder.decode(addr);

    final payloadBytes = AddrDecUtils.splitPartsByChecksum(
            addrDecBytes, XlmAddrConst.checksumByteLen)
        .item1;

    final addrTypeGot = payloadBytes[0];

    final type = XlmAddrTypes.fromTag(addrTypeGot);
    if (addrType != null && addrType != type) {
      throw AddressConverterException(
          'Invalid address type (expected ${addrType.value}, got $addrTypeGot)');
    }
    AddrDecUtils.validateBytesLength(
        addrDecBytes,
        type == XlmAddrTypes.muxed
            ? XlmAddrConst.muxedAddrLen
            : XlmAddrConst.pubkeyAddrLength);

    AddrDecUtils.validateChecksum(
        payloadBytes,
        addrDecBytes
            .sublist(addrDecBytes.length - XlmAddrConst.checksumByteLen),
        _XlmAddrUtils.computeChecksum);
    List<int> pubKeyBytes = payloadBytes.sublist(1);
    BigInt? accountId;
    if (type == XlmAddrTypes.muxed) {
      accountId = BigintUtils.fromBytes(
          pubKeyBytes.sublist(pubKeyBytes.length - XlmAddrConst.muxedIdLength));
      if (accountId > maxU64 || accountId < BigInt.zero) {
        throw const AddressConverterException(
            "Invalid muxed address account id.");
      }
      pubKeyBytes = List<int>.unmodifiable(pubKeyBytes.sublist(
          0, pubKeyBytes.length - XlmAddrConst.muxedIdLength));
      addr = XlmAddrEncoder().encodeKey(pubKeyBytes);
    }
    return XlmAddrDecoderResult(
        type: type,
        pubKeyBytes: pubKeyBytes,
        baseAddress: addr,
        accountId: accountId);
  }

  /// Decode a Stellar (XLM) address and return the public key.
  ///
  /// This method decodes a Stellar address and extracts the public key part, returning it as a `List<int>`.
  ///
  /// - [addr]: The Stellar address to decode.
  /// - [kwargs]: A map of optional keyword arguments.
  ///   - [addr_type]: The address type, either XlmAddrTypes.pubKey or XlmAddrTypes.privKey.
  ///
  /// Throws an [AddressConverterException] if the address type is not valid or if there's a validation error.
  ///
  /// Example usage:
  /// ```dart
  /// final decoder = XlmAddrDecoder();
  /// final addr = 'GC2Z66U3A3I5VGM3S5INUT4FVC3VGCUJ7ALDCTF6WLYBMXNO5KNOHWZL';
  /// final publicKey = decoder.decodeAddr(addr, {'addr_type': XlmAddrTypes.pubKey});
  /// ```
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    final decodeAddress = decode(addr, kwargs);
    return decodeAddress.pubKeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Stellar (XLM) blockchain addresses.
class XlmAddrEncoder implements BlockchainAddressEncoder {
  /// Encode a Stellar (XLM) public key as a Stellar address.
  ///
  /// This method encodes a Stellar public key as a Stellar address, which can be used for transactions.
  ///
  /// - [pubKey]: The Stellar public key to encode.
  /// - [kwargs]: A map of optional keyword arguments.
  ///   - [addr_type]: The address type, either XlmAddrTypes.pubKey or XlmAddrTypes.privKey.
  ///
  /// Throws an [AddressConverterException] if the address type is not valid or if there's a validation error.
  ///
  /// Example usage:
  /// ```dart
  /// final encoder = XlmAddrEncoder();
  /// final publicKey = `List<int>`.from([6, ...bytes]); // Replace 'bytes' with the actual public key bytes.
  /// final addr = encoder.encodeKey(publicKey, {'addr_type': XlmAddrTypes.pubKey});
  /// ```
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    if (pubKey.length ==
        Ed25519KeysConst.pubKeyByteLen + Ed25519KeysConst.pubKeyPrefix.length) {
      pubKey = pubKey.sublist(1);
    }
    final addrType = AddrKeyValidator.nullOrValidateAddressArgs<XlmAddrTypes>(
            kwargs, "addr_type") ??
        XlmAddrTypes.pubKey;
    AddrDecUtils.validateBytesLength(pubKey, Ed25519KeysConst.pubKeyByteLen);
    if (addrType == XlmAddrTypes.pubKey) {
      AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    } else if (addrType == XlmAddrTypes.privKey) {
      Ed25519PrivateKey.fromBytes(pubKey);
    }

    if (addrType == XlmAddrTypes.muxed) {
      final BigInt? muxedId = BigintUtils.tryParse(kwargs["account_id"]);
      if (muxedId == null || muxedId > maxU64 || muxedId < BigInt.zero) {
        throw AddressConverterException(
            "Missing or invalid 'account_id'. An accountId is required for a muxed address.",
            details: {"accounts_id": kwargs["account_id"]});
      }
      final idBytes =
          BigintUtils.toBytes(muxedId, length: XlmAddrConst.muxedIdLength);
      pubKey = [...pubKey, ...idBytes];
    }

    final List<int> payloadBytes = List<int>.from([addrType.value, ...pubKey]);

    final List<int> checksumBytes = _XlmAddrUtils.computeChecksum(payloadBytes);
    return Base32Encoder.encodeNoPaddingBytes(
        List<int>.from([...payloadBytes, ...checksumBytes]));
  }
}
