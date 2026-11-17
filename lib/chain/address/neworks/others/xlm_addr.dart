import 'package:blockchain_utils/encoding/base32/base32.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/crypto/crypto/checksum/x_modem_crc/x_modem_crc.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Enum representing different types of Stellar (XLM) addresses.
enum XlmAddrTypes {
  /// Contract key address type.
  contract(value: 2 << 3, name: "Contract"),

  /// Public key address type. (keyBytes must be a valid Ed25519 public key)
  pubKey(name: "PublicKey", value: 6 << 3),

  /// Private key address type. (keyBytes must be a valid Ed25519 private key)
  privKey(name: "SecretKey", value: 18 << 3),

  /// Muxed (multiplexed Ed25519 account: 32-byte key + 8-byte id).
  muxed(value: 12 << 3, name: "Muxed"),

  /// Muxed contract (CAP-84: 32-byte contract id + 8-byte id).
  muxedContract(value: 22 << 3, name: "MuxedContract");

  final int value;
  final String name;

  const XlmAddrTypes({required this.value, required this.name});

  static XlmAddrTypes fromTag(int? tag) {
    return values.firstWhere(
      (e) => e.value == tag,
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Invalid or unsupported xlm address type.",
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

/// Internal Stellar (XLM) address helpers.
class _XlmAddrUtils {
  static List<int> computeChecksum(List<int> payloadBytes) {
    return XModemCrc.quickDigest(payloadBytes).reversed.toList();
  }
}

class XlmAddrDecoderResult {
  final XlmAddrTypes type;

  /// Key bytes: Ed25519 public key for account types, contract id (hash) for
  /// contract types.
  final List<int> pubKeyBytes;
  final String baseAddress;

  /// Multiplexing id for muxed types (`muxed`, `muxedContract`), null else.
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

/// Decodes a Stellar (XLM) address.
class XlmAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  /// Decodes [addr], returning the full result (type, key, muxed id, etc).
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
      throw CoreErrors.addressValidationFailed(reason: "Invalid address type.");
    }
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      type == XlmAddrTypes.muxed || type == XlmAddrTypes.muxedContract
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
    if (type == XlmAddrTypes.muxed || type == XlmAddrTypes.muxedContract) {
      accountId = BigintUtils.fromBytes(
        pubKeyBytes.sublist(pubKeyBytes.length - XlmAddrConst.muxedIdLength),
      );
      if (accountId > BinaryOps.maxU64 || accountId < BigInt.zero) {
        throw CoreErrors.addressValidationFailed(
          reason: "Invalid muxed address account id.",
        );
      }
      pubKeyBytes = List<int>.unmodifiable(
        pubKeyBytes.sublist(0, pubKeyBytes.length - XlmAddrConst.muxedIdLength),
      );
      addr = XlmAddrEncoder().encodeKey(
        pubKeyBytes,
        addrType:
            type == XlmAddrTypes.muxedContract
                ? XlmAddrTypes.contract
                : XlmAddrTypes.pubKey,
      );
    }
    return XlmAddrDecoderResult(
      type: type,
      pubKeyBytes: pubKeyBytes,
      baseAddress: addr,
      accountId: accountId,
    );
  }

  @override
  BuBytes decodeAddr(String addr, {XlmAddrTypes? addrType}) {
    final decodeAddress = decode(addr, addrType: addrType);
    return BuBytes(decodeAddress.pubKeyBytes);
  }
}

/// Encodes a Stellar (XLM) address.
class XlmAddrEncoder implements BlockchainAddressEncoder {
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
      AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
    } else if (addrType == XlmAddrTypes.privKey) {
      ED25519PrivateKey.fromBytes(pubKey);
    }

    if (addrType == XlmAddrTypes.muxed ||
        addrType == XlmAddrTypes.muxedContract) {
      if (muxedId == null ||
          muxedId > BinaryOps.maxU64 ||
          muxedId < BigInt.zero) {
        throw CoreErrors.missingOrInvalidAddressArguments(
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
