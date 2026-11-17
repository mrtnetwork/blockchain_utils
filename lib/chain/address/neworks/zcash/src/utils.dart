import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/neworks/zcash/src/types.dart';
import 'package:blockchain_utils/protocol/zip32/conf/zcash.dart';
import 'package:blockchain_utils/protocol/zip32/conf/config.dart';
import 'package:blockchain_utils/protocol/zcash/src/encoding/encoding.dart';
import 'package:blockchain_utils/protocol/zcash/src/types.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Internal Zcash address parsing/encoding helpers.
class ZcashAddressUtils {
  /// Matches a Base58 address prefix to its network + address type.
  static (ZIP32CoinConfig, ZcashAddressType)? _findNetworkAndTypeFromB58Prefix(
    List<int> prefix,
    ZcashConf config,
  ) {
    ZIP32CoinConfig? network = config.findFromP2shPrefix(prefix);
    if (network != null) {
      return (network, ZcashAddressType.p2sh);
    }
    network = config.findFromP2pkhPrefix(prefix);
    if (network != null) {
      return (network, ZcashAddressType.p2pkh);
    }
    network = config.findFromSproutPrefix(prefix);
    if (network != null) {
      return (network, ZcashAddressType.sprout);
    }
    return null;
  }

  /// Tries each Zcash address format in turn until one matches.
  static ZcashDecodedAddressResult? _parseAddress(
    String address, {
    ZcashAddressType? expectedType,
  }) {
    final configs = ZcashConf();
    if (expectedType == null || expectedType == ZcashAddressType.unified) {
      final unified = ZcashEncodingUtils.decodeUnifiedObject(
        address: address,
        mode: UnifiedReceiverMode.address,
      );
      if (unified != null) {
        final network = configs.findFromUnifiedAddressHrp(unified.$3)?.network;
        if (network == null) return null;
        return ZcashDecodedAddressResult(
          network: network,
          unifiedReceiver: unified.$1,
          addressBytes: unified.$2,
          type: ZcashAddressType.unified,
        );
      }
    }

    if (expectedType == null ||
        expectedType == ZcashAddressType.tex ||
        expectedType == ZcashAddressType.sapling) {
      (List<int>, String)? b32;
      // Harmless here (the branch returns before falling through), but
      // confusing and easy to break on a future edit.
      if (expectedType != ZcashAddressType.tex) {
        b32 = ZcashEncodingUtils.tryDecodeBech32(
          bech32: address,
          encoding: Bech32Encodings.bech32,
        );
        if (b32 != null) {
          final network = configs.findFromSaplingPaymentAddressHrp(b32.$2);
          if (network != null) {
            return ZcashDecodedAddressResult(
              network: network.network,
              addressBytes: b32.$1,
              type: ZcashAddressType.sapling,
            );
          }
        }
      }
      if (expectedType != ZcashAddressType.sapling) {
        b32 = ZcashEncodingUtils.tryDecodeBech32(
          bech32: address,
          encoding: Bech32Encodings.bech32m,
        );
        if (b32 != null) {
          final network = configs.findFromTexHrp(b32.$2);
          if (network != null) {
            return ZcashDecodedAddressResult(
              network: network.network,
              addressBytes: b32.$1,
              type: ZcashAddressType.tex,
            );
          }
        }
      }
    }
    if (expectedType == null ||
        expectedType == ZcashAddressType.sprout ||
        expectedType == ZcashAddressType.p2pkh ||
        expectedType == ZcashAddressType.p2sh) {
      final b58 = ZcashEncodingUtils.tryDecodeBase58WithCheck(address, 2);
      if (b58 != null) {
        final network = _findNetworkAndTypeFromB58Prefix(b58.$1, configs);
        if (network == null) return null;
        return ZcashDecodedAddressResult(
          network: network.$1.network,
          addressBytes: b58.$2,
          type: network.$2,
        );
      }
    }

    return null;
  }

  /// Decodes a Zcash address, validating against [expectedNetwork]/
  /// [expectedType] if given.
  static ZcashDecodedAddressResult? parseAddress(
    String address, {
    ZcashNetwork? expectedNetwork,
    ZcashAddressType? expectedType,
  }) {
    final decode = _parseAddress(address, expectedType: expectedType);
    if (decode == null) return null;
    _validate(
      network: decode.network,
      type: decode.type,
      expectedType: expectedType,
      expectedNetwork: expectedNetwork,
    );
    return decode;
  }

  /// Checks decoded network/type against the expected ones, if given.
  static void _validate({
    required ZcashNetwork network,
    required ZcashAddressType type,
    ZcashNetwork? expectedNetwork,
    ZcashAddressType? expectedType,
  }) {
    if (expectedNetwork != null && expectedNetwork != network) {
      throw CoreErrors.addressValidationFailed(
        reason: "Mismatch address network.",
        details: {'network': network.name, 'expected': expectedNetwork.name},
      );
    }
    if (expectedType != null && expectedType != type) {
      throw CoreErrors.addressValidationFailed(
        reason: "Mismatch address type.",
        details: {'type': type.name, 'expected': expectedType.name},
      );
    }
  }

  /// Encodes [bytes] as a Zcash address of the given [type]/[network].
  static String encodeAddress({
    required List<int> bytes,
    required ZcashAddressType type,
    required ZcashNetwork network,
    List<ZUnifiedReceiver>? receivers,
  }) {
    final config = ZcashConf().fromNetwork(network);
    try {
      switch (type) {
        case ZcashAddressType.p2sh:
          return encodeBase58Addresses(
            bytes: bytes,
            prefix: config.b58ScriptAddressPrefix,
            type: type,
          );
        case ZcashAddressType.p2pkh:
          return encodeBase58Addresses(
            bytes: bytes,
            prefix: config.b58PubkeyAddressPrefix,
            type: type,
          );
        case ZcashAddressType.sprout:
          return encodeBase58Addresses(
            bytes: bytes,
            prefix: config.b58SproutAddressPrefix,
            type: type,
          );
        case ZcashAddressType.tex:
          return encodeBech32Address(
            bytes: bytes,
            hrp: config.hrpTexAddress,
            type: type,
          );
        case ZcashAddressType.sapling:
          return encodeBech32Address(
            bytes: bytes,
            hrp: config.hrpSaplingPaymentAddress,
            type: type,
          );
        case ZcashAddressType.unified:
          return ZcashEncodingUtils.encodeUnifiedObject(
            addressBytes: bytes,
            hrp: config.hrpUnifiedAddress,
            receivers: receivers,
            mode: UnifiedReceiverMode.address,
          );
      }
    } on BuError catch (e) {
      if (e.type == DefaultErrorType.invalidAddress) rethrow;
      if (e.type == DefaultErrorType.invalidKeyData) {
        throw CoreErrors.addressValidationFailed(details: e.details);
      }
      throw CoreErrors.addressValidationFailed(reason: e.toString());
    } catch (e) {
      throw CoreErrors.addressValidationFailed(reason: e.toString());
    }
  }

  /// Encodes a Base58Check address (p2pkh/p2sh/sprout).
  static String encodeBase58Addresses({
    required List<int> bytes,
    required List<int> prefix,
    required ZcashAddressType type,
  }) {
    if (prefix.length != 2 || bytes.length != type.lengthInBytes) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid address bytes length.",
      );
    }
    return ZcashEncodingUtils.encodeBase58WithCheck(
      bytes: bytes,
      prefix: prefix,
    );
  }

  /// Encodes a Bech32/Bech32m address (sapling/tex).
  static String encodeBech32Address({
    required List<int> bytes,
    required String hrp,
    required ZcashAddressType type,
  }) {
    if (bytes.length != type.lengthInBytes) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid address bytes length.",
      );
    }
    return ZcashEncodingUtils.encodeBech32Address(
      bytes: bytes,
      hrp: hrp,
      encoding:
          type == ZcashAddressType.tex
              ? Bech32Encodings.bech32m
              : Bech32Encodings.bech32,
    );
  }
}
