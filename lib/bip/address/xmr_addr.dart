import 'package:blockchain_utils/base58/base58_xmr.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

import 'exception/exception.dart';
import 'addr_key_validator.dart';

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
              throw AddressConverterException.addressValidationFailed(
                reason: "Invalid monero address prefix.",
                details: {"prefix": prefix?.toString()},
              ),
    );
  }

  static XmrAddressType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(name: "XmrAddressType"),
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

/// Class container for Monero address utility functions.
class _XmrAddrUtils {
  /// Compute checksum in EOS format.
  static List<int> computeChecksum(List<int> payloadBytes) {
    return QuickCrypto.keccack256Hash(
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

    /// Validate checksum
    AddrDecUtils.validateChecksum(payloadBytes, checksumBytes, computeChecksum);

    /// Validate and remove prefix
    final payloadBytesWithoutPrefix = payloadBytes.sublist(
      XmrAddrConst.prefixLength,
    );

    final int netVersion = payloadBytes[0];
    if (netVerBytes != null) {
      if (netVerBytes.length != XmrAddrConst.prefixLength ||
          netVerBytes[0] != netVersion) {
        throw AddressConverterException.addressValidationFailed(
          reason: "Invalid address prefix.",
          details: {
            "expected": netVersion.toString(),
            "network_version": netVersion.toString(),
          },
        );
      }
    }

    final addrType = XmrAddressType.fromPrefix(netVersion);

    List<int>? paymentBytes;
    switch (addrType) {
      case XmrAddressType.integrated:

        /// Validate length with payment ID
        AddrDecUtils.validateBytesLength(
          payloadBytesWithoutPrefix,
          (Ed25519KeysConst.pubKeyByteLen * 2) + XmrAddrConst.paymentIdByteLen,
        );

        /// Check payment ID
        if (paymentIdBytes != null &&
            paymentIdBytes.length != XmrAddrConst.paymentIdByteLen) {
          throw AddressConverterException.addressValidationFailed(
            reason: "Invalid payment id.",
          );
        }

        paymentBytes = payloadBytesWithoutPrefix.sublist(
          payloadBytesWithoutPrefix.length - XmrAddrConst.paymentIdByteLen,
        );

        if (paymentIdBytes != null &&
            !BytesUtils.bytesEqual(paymentIdBytes, paymentBytes)) {
          throw AddressConverterException.addressValidationFailed(
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
          throw AddressConverterException.addressValidationFailed(
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
      throw AddressConverterException.missingOrInvalidAddressArguments(
        reason: "Invalid payment ID length",
      );
    }
    if (netVerBytes.length != XmrAddrConst.prefixLength) {
      throw AddressConverterException.missingOrInvalidAddressArguments(
        reason: "Invalid network version prefix.",
      );
    }
    final type = XmrAddressType.fromPrefix(netVerBytes.first);
    if (type == XmrAddressType.integrated) {
      if (paymentIdBytes == null) {
        throw AddressConverterException.missingOrInvalidAddressArguments(
          reason: "A payment ID is required for an integrated address.",
        );
      }
    } else {
      if (paymentIdBytes != null) {
        throw AddressConverterException.missingOrInvalidAddressArguments(
          reason: "A payment ID is required only for integrated addresses.",
        );
      }
    }
    final pubSpendKeyObj = AddrKeyValidator.validateAndGetEd25519MoneroKey(
      pubSkey,
    );
    final pubViewKeyObj = AddrKeyValidator.validateAndGetEd25519MoneroKey(
      pubVkey,
    );
    final payloadBytes = List<int>.unmodifiable([
      ...netVerBytes,
      ...pubSpendKeyObj.compressed,
      ...pubViewKeyObj.compressed,
      ...paymentIdBytes ?? [],
    ]);
    final checksum = computeChecksum(payloadBytes);

    return Base58XmrEncoder.encode([...payloadBytes, ...checksum]);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Monero (XMR) blockchain addresses.
class XmrAddrDecoder implements BlockchainAddressDecoder<List<int>> {
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

  /// Decodes a Monero (XMR) address.
  @override
  List<int> decodeAddr(String addr, {List<int>? netVersion}) {
    netVersion = AddrKeyValidator.getAddrArg<List<int>>(
      netVersion,
      "netVersion",
    );
    final decodeAddr = decode(addr, netVerBytes: netVersion);
    return decodeAddr.keyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Monero (XMR) blockchain addresses.
class XmrAddrEncoder extends BlockchainAddressEncoder {
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

  /// Encodes a Monero (XMR) public key and view key as an XMR address.
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

/// Implementation of the [BlockchainAddressDecoder] for Monero (XMR) integrated addresses.
class XmrIntegratedAddrDecoder extends BlockchainAddressDecoder {
  /// Decodes a Monero (XMR) integrated address to extract the public key and view key components.
  @override
  List<int> decodeAddr(
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
    return decodeAddr.keyBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Monero (XMR) integrated addresses.
class XmrIntegratedAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a Monero (XMR) public key and view key as an XMR address.
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
