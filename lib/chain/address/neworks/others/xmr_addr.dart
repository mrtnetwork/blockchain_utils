import 'package:blockchain_utils/encoding/base58/src/base58_xmr.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to Monero (XMR) addresses.
class XmrAddrConst {
  /// The length of the checksum bytes used in XMR addresses.
  static const int checksumByteLen = 4;

  /// The length of payment ID bytes used in XMR addresses.
  static const int paymentIdByteLen = 8;

  static const int prefixLength = 1;
}

enum XmrAddressType {
  primaryAddress(name: "Primary", prefixes: [0x12, 0x18, 0x35], value: 0),
  integrated(name: "Integrated", prefixes: [0x19, 0x36, 0x13], value: 1),
  subaddress(name: "Subaddress", prefixes: [0x24, 0x3F, 0x2A], value: 2);

  final int value;
  final String name;
  final List<int> prefixes;
  const XmrAddressType({
    required this.name,
    required this.prefixes,
    required this.value,
  });
  static XmrAddressType fromPrefix(int? prefix) {
    return values.firstWhere(
      (e) => e.prefixes.contains(prefix),
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Invalid monero address prefix.",
                details: {"prefix": prefix?.toString()},
              ),
    );
  }

  static XmrAddressType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse:
          () => throw CoreErrors.addressValidationFailed(
            reason: "Invalid monero address type.",
            details: {"got": value?.toString()},
          ),
    );
  }

  @override
  String toString() {
    return "XmrAddressType.$name";
  }
}

class XmrAddressDecodeResult {
  final List<int> publicViewKey;
  final List<int> publicSpendKey;
  final List<int>? paymentId;
  final int netVersion;
  final XmrAddressType type;
  XmrAddressDecodeResult({
    required List<int> publicViewKey,
    required List<int> publicSpendKey,
    List<int>? paymentId,
    required this.netVersion,
    required this.type,
  }) : publicViewKey = publicViewKey.asImmutableBytes,
       publicSpendKey = publicSpendKey.asImmutableBytes,
       paymentId = paymentId?.asImmutableBytes;
  List<int> get keyBytes => [...publicSpendKey, ...publicViewKey];
}

/// Internal Monero (XMR) address helpers.
class _XmrAddrUtils {
  static List<int> computeChecksum(List<int> payloadBytes) {
    return QuickCrypto.keccak256Hash(
      payloadBytes,
    ).sublist(0, XmrAddrConst.checksumByteLen);
  }

  static XmrAddressDecodeResult decodeAddress(
    String addr, {
    List<int>? netVerBytes,
    List<int>? paymentIdBytes,
  }) {
    final addrDecBytes = Base58XmrDecoder.decode(addr);
    final parts = AddrDecUtils.splitPartsByChecksum(
      addrDecBytes,
      XmrAddrConst.checksumByteLen,
    );
    final payloadBytes = parts.$1;
    final checksumBytes = parts.$2;

    AddrDecUtils.validateChecksum(payloadBytes, checksumBytes, computeChecksum);
    final payloadBytesWithoutPrefix = payloadBytes.sublist(
      XmrAddrConst.prefixLength,
    );

    final int netVersion = payloadBytes[0];
    if (netVerBytes != null) {
      if (netVerBytes.length != XmrAddrConst.prefixLength ||
          netVerBytes[0] != netVersion) {
        throw CoreErrors.addressValidationFailed(
          reason: "Invalid address prefix.",
          details: {
            "expected": netVerBytes.toString(),
            "network_version": netVersion.toString(),
          },
        );
      }
    }

    final addrType = XmrAddressType.fromPrefix(netVersion);

    List<int>? paymentBytes;
    switch (addrType) {
      case XmrAddressType.integrated:
        AddrDecUtils.validateBytesLength(
          payloadBytesWithoutPrefix,
          (Ed25519KeysConst.pubKeyByteLen * 2) + XmrAddrConst.paymentIdByteLen,
        );

        if (paymentIdBytes != null &&
            paymentIdBytes.length != XmrAddrConst.paymentIdByteLen) {
          throw CoreErrors.addressValidationFailed(
            reason: "Invalid payment id.",
          );
        }

        paymentBytes = payloadBytesWithoutPrefix.sublist(
          payloadBytesWithoutPrefix.length - XmrAddrConst.paymentIdByteLen,
        );

        if (paymentIdBytes != null &&
            !BytesUtils.bytesEqual(paymentIdBytes, paymentBytes)) {
          throw CoreErrors.addressValidationFailed(
            reason: "Invalid payment id.",
            details: {
              "expected": BytesUtils.toHexString(paymentIdBytes),
              "payment_id": BytesUtils.toHexString(paymentBytes),
            },
          );
        }
        break;
      default:
        AddrDecUtils.validateBytesLength(
          payloadBytesWithoutPrefix,
          Ed25519KeysConst.pubKeyByteLen * 2,
        );
        if (paymentIdBytes != null) {
          throw CoreErrors.addressValidationFailed(
            reason: "Invalid address type.",
            details: {
              "expected": XmrAddressType.integrated.toString(),
              "type": addrType.toString(),
            },
          );
        }
        break;
    }

    final pubSpendKeyBytes = payloadBytesWithoutPrefix.sublist(
      0,
      Ed25519KeysConst.pubKeyByteLen,
    );
    final pubViewKeyBytes = payloadBytesWithoutPrefix.sublist(
      Ed25519KeysConst.pubKeyByteLen,
      Ed25519KeysConst.pubKeyByteLen * 2,
    );
    return XmrAddressDecodeResult(
      publicViewKey: pubViewKeyBytes,
      publicSpendKey: pubSpendKeyBytes,
      netVersion: netVersion,
      type: addrType,
      paymentId: paymentBytes,
    );
  }

  static String encodeKey(
    List<int> pubSkey,
    List<int> pubVkey,
    List<int> netVerBytes, {
    List<int>? paymentIdBytes,
  }) {
    if (paymentIdBytes != null &&
        paymentIdBytes.length != XmrAddrConst.paymentIdByteLen) {
      throw CoreErrors.missingOrInvalidAddressArguments(
        reason: "Invalid payment ID length",
      );
    }
    if (netVerBytes.length != XmrAddrConst.prefixLength) {
      throw CoreErrors.missingOrInvalidAddressArguments(
        reason: "Invalid network version prefix.",
      );
    }
    final type = XmrAddressType.fromPrefix(netVerBytes.first);
    if (type == XmrAddressType.integrated) {
      if (paymentIdBytes == null) {
        throw CoreErrors.missingOrInvalidAddressArguments(
          reason: "A payment ID is required for an integrated address.",
        );
      }
    } else {
      if (paymentIdBytes != null) {
        throw CoreErrors.missingOrInvalidAddressArguments(
          reason: "A payment ID is required only for integrated addresses.",
        );
      }
    }
    final pubSpendKeyObj = AddrKeyValidator.validateAndGetEd25519MoneroKeyBytes(
      pubSkey,
    );
    final pubViewKeyObj = AddrKeyValidator.validateAndGetEd25519MoneroKeyBytes(
      pubVkey,
    );
    final payloadBytes = List<int>.unmodifiable([
      ...netVerBytes,
      ...pubSpendKeyObj,
      ...pubViewKeyObj,
      ...paymentIdBytes ?? [],
    ]);
    final checksum = computeChecksum(payloadBytes);

    return Base58XmrEncoder.encode([...payloadBytes, ...checksum]);
  }
}

/// Decodes a Monero (XMR) address.
class XmrAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  /// Decodes [addr], returning the full result (keys, type, payment id).
  XmrAddressDecodeResult decode(
    String addr, {
    List<int>? netVerBytes,
    List<int>? paymentId,
  }) {
    return _XmrAddrUtils.decodeAddress(
      addr,
      netVerBytes: netVerBytes,
      paymentIdBytes: paymentId,
    );
  }

  @override
  BuBytes decodeAddr(String addr, {List<int>? netVersion}) {
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );
    final decodeAddr = decode(addr, netVerBytes: netVersion);
    return BuBytes(decodeAddr.keyBytes);
  }
}

/// Encodes a Monero (XMR) address.
class XmrAddrEncoder extends BlockchainAddressEncoder {
  /// Encodes from an already-validated spend key + view key.
  String encode({
    required List<int> pubSpendKey,
    required List<int> pubViewKey,
    required List<int> netVarBytes,
    List<int>? paymentId,
  }) {
    return _XmrAddrUtils.encodeKey(
      pubSpendKey,
      pubViewKey,
      netVarBytes,
      paymentIdBytes: paymentId,
    );
  }

  @override
  String encodeKey(
    List<int> pubKey, {
    List<int>? netVersion,
    List<int>? pubVKey,
  }) {
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );
    pubVKey = AddrKeyValidator.getAddrArg<List<int>>(pubVKey, "pub_vkey");
    return encode(
      pubSpendKey: pubKey,
      pubViewKey: pubVKey,
      netVarBytes: netVersion,
    );
  }
}

/// Decodes a Monero (XMR) integrated address.
class XmrIntegratedAddrDecoder extends BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(
    String addr, {
    List<int>? netVersion,
    List<int>? paymentId,
  }) {
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );
    paymentId = AddrKeyValidator.getAddrArg<List<int>>(paymentId, "paymentId");
    final decodeAddr = XmrAddrDecoder().decode(
      addr,
      netVerBytes: netVersion,
      paymentId: paymentId,
    );
    return BuBytes(decodeAddr.keyBytes);
  }
}

/// Encodes a Monero (XMR) integrated address.
class XmrIntegratedAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(
    List<int> pubKey, {
    List<int>? netVersion,
    List<int>? paymentId,
    List<int>? pubVKey,
  }) {
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );
    paymentId = AddrKeyValidator.getAddrArg<List<int>>(paymentId, "paymentId");
    pubVKey = AddrKeyValidator.getAddrArg<List<int>>(pubVKey, "pubVKey");
    return XmrAddrEncoder().encode(
      pubSpendKey: pubKey,
      pubViewKey: pubVKey,
      netVarBytes: netVersion,
      paymentId: paymentId,
    );
  }
}
