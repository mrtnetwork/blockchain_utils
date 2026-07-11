import 'package:blockchain_utils/base32/base32.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/crypto/x_modem_crc/x_modem_crc.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';
import 'exception/exception.dart';
import 'encoder.dart';

/// Enum representing different types of Stellar (XLM) addresses.
enum XlmAddrTypes {
  /// Contract key address type.
  contract(value: 2 << 3, name: "Contract"),

  /// Public key address type. (keyBytes must be a valid Ed25519 public key)
  pubKey(name: "PublicKey", value: 6 << 3),

  /// Private key address type. (keyBytes must be a valid Ed25519 private key)
  privKey(name: "SecretKey", value: 18 << 3),

  /// Muxed
  muxed(value: 12 << 3, name: "Muxed");

  final int value;
  final String name;

  /// Constructor for XlmAddrTypes enum values.
  const XlmAddrTypes({required this.value, required this.name});

  static XlmAddrTypes fromTag(int? tag) {
    return values.firstWhere(
      (e) => e.value == tag,
      orElse:
          () =>
              throw AddressConverterException.addressValidationFailed(
                reason: "Invalid or unsuported xlm address type.",
                details: {
                  "expected": values.map((e) => e.value).join(", "),
                  "got": tag?.toString(),
                },
              ),
    );
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
  static const int pubkeyAddrLength =
      Ed25519KeysConst.pubKeyByteLen +
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
  XlmAddrDecoderResult({
    required this.type,
    required List<int> pubKeyBytes,
    required this.baseAddress,
    required this.accountId,
  }) : pubKeyBytes = pubKeyBytes.asImmutableBytes;
  @override
  String toString() {
    return baseAddress;
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Stellar (XLM) blockchain addresses.
class XlmAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  XlmAddrDecoderResult decode(String addr, {XlmAddrTypes? addrType}) {
    final addrDecBytes = Base32Decoder.decode(addr);

    final payloadBytes =
        AddrDecUtils.splitPartsByChecksum(
          addrDecBytes,
          XlmAddrConst.checksumByteLen,
        ).$1;

    final addrTypeGot = payloadBytes[0];

    final type = XlmAddrTypes.fromTag(addrTypeGot);
    if (addrType != null && addrType != type) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Invalid address type.",
      );
    }
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      type == XlmAddrTypes.muxed
          ? XlmAddrConst.muxedAddrLen
          : XlmAddrConst.pubkeyAddrLength,
    );

    AddrDecUtils.validateChecksum(
      payloadBytes,
      addrDecBytes.sublist(addrDecBytes.length - XlmAddrConst.checksumByteLen),
      _XlmAddrUtils.computeChecksum,
    );
    List<int> pubKeyBytes = payloadBytes.sublist(1);
    BigInt? accountId;
    if (type == XlmAddrTypes.muxed) {
      accountId = BigintUtils.fromBytes(
        pubKeyBytes.sublist(pubKeyBytes.length - XlmAddrConst.muxedIdLength),
      );
      if (accountId > BinaryOps.maxU64 || accountId < BigInt.zero) {
        throw AddressConverterException.addressValidationFailed(
          reason: "Invalid muxed address account id.",
        );
      }
      pubKeyBytes = List<int>.unmodifiable(
        pubKeyBytes.sublist(0, pubKeyBytes.length - XlmAddrConst.muxedIdLength),
      );
      addr = XlmAddrEncoder().encodeKey(pubKeyBytes);
    }
    return XlmAddrDecoderResult(
      type: type,
      pubKeyBytes: pubKeyBytes,
      baseAddress: addr,
      accountId: accountId,
    );
  }

  /// Decode a Stellar (XLM) address and return the public key.
  @override
  List<int> decodeAddr(String addr, {XlmAddrTypes? addrType}) {
    final decodeAddress = decode(addr, addrType: addrType);
    return decodeAddress.pubKeyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Stellar (XLM) blockchain addresses.
class XlmAddrEncoder implements BlockchainAddressEncoder {
  /// Encode a Stellar (XLM) public key as a Stellar address.
  @override
  String encodeKey(
    List<int> pubKey, {
    XlmAddrTypes addrType = XlmAddrTypes.pubKey,
    BigInt? muxedId,
  }) {
    if (pubKey.length ==
        Ed25519KeysConst.pubKeyByteLen + Ed25519KeysConst.pubKeyPrefix.length) {
      pubKey = pubKey.sublist(1);
    }
    AddrDecUtils.validateBytesLength(pubKey, Ed25519KeysConst.pubKeyByteLen);
    if (addrType == XlmAddrTypes.pubKey) {
      AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    } else if (addrType == XlmAddrTypes.privKey) {
      Ed25519PrivateKey.fromBytes(pubKey);
    }

    if (addrType == XlmAddrTypes.muxed) {
      if (muxedId == null ||
          muxedId > BinaryOps.maxU64 ||
          muxedId < BigInt.zero) {
        throw AddressConverterException.missingOrInvalidAddressArguments(
          reason: "muxedId is required for a muxed address.",
        );
      }
      final idBytes = muxedId.toBeBytes(length: XlmAddrConst.muxedIdLength);
      pubKey = [...pubKey, ...idBytes];
    }

    final List<int> payloadBytes = [addrType.value, ...pubKey];

    final List<int> checksumBytes = _XlmAddrUtils.computeChecksum(payloadBytes);
    return Base32Encoder.encodeNoPaddingBytes([
      ...payloadBytes,
      ...checksumBytes,
    ]);
  }
}
