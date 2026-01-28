import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/address/zcash/src/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/zcash.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/config.dart';
import 'package:blockchain_utils/bip/zcash/src/encoding/encoding.dart';
import 'package:blockchain_utils/bip/zcash/src/exception.dart';
import 'package:blockchain_utils/bip/zcash/src/types.dart';

class ZCashAddressUtils {
  static (ZIP32CoinConfig, ZCashAddressType)? _findNetworkAndTypeFromB58Prefix(
    List<int> prefix,
    ZcashConf config,
  ) {
    ZIP32CoinConfig? network = config.findFromP2shPrefix(prefix);
    if (network != null) {
      return (network, ZCashAddressType.p2sh);
    }
    network = config.findFromP2pkhPrefix(prefix);
    if (network != null) {
      return (network, ZCashAddressType.p2pkh);
    }
    network = config.findFromSproutPrefix(prefix);
    if (network != null) {
      return (network, ZCashAddressType.sprout);
    }
    return null;
  }

  static ZCashDecodedAddressResult? _parseAddress(
    String address, {
    ZCashAddressType? exceptedType,
  }) {
    final configs = ZcashConf();
    if (exceptedType == null || exceptedType == ZCashAddressType.unified) {
      final unified = ZCashEncodingUtils.decodeUnifiedObject(
        address: address,
        mode: UnifiedReceiverMode.address,
      );
      if (unified != null) {
        final network = configs.findFromUnifiedAddressHrp(unified.$3)?.network;
        if (network == null) return null;
        return ZCashDecodedAddressResult(
          network: network,
          unifiedReceiver: unified.$1,
          addressBytes: unified.$2,
          type: ZCashAddressType.unified,
        );
      }
    }

    if (exceptedType == null ||
        exceptedType == ZCashAddressType.tex ||
        exceptedType == ZCashAddressType.sapling) {
      (List<int>, String)? b32;
      if (exceptedType != ZCashAddressType.tex) {
        (List<int>, String)? b32 = ZCashEncodingUtils.tryDecodeBech32(
          bech32: address,
          encoding: Bech32Encodings.bech32,
        );
        if (b32 != null) {
          final network = configs.findFromSaplingPaymentAddressHrp(b32.$2);
          if (network != null) {
            return ZCashDecodedAddressResult(
              network: network.network,
              addressBytes: b32.$1,
              type: ZCashAddressType.sapling,
            );
          }
        }
      }
      if (exceptedType != ZCashAddressType.sapling) {
        b32 = ZCashEncodingUtils.tryDecodeBech32(
          bech32: address,
          encoding: Bech32Encodings.bech32m,
        );
        if (b32 != null) {
          final network = configs.findFromTexHrp(b32.$2);
          if (network != null) {
            return ZCashDecodedAddressResult(
              network: network.network,
              addressBytes: b32.$1,
              type: ZCashAddressType.tex,
            );
          }
        }
      }
    }
    if (exceptedType == null ||
        exceptedType == ZCashAddressType.sprout ||
        exceptedType == ZCashAddressType.p2pkh ||
        exceptedType == ZCashAddressType.p2sh) {
      final b58 = ZCashEncodingUtils.tryDecodeBase58WithCheck(address, 2);
      if (b58 != null) {
        final network = _findNetworkAndTypeFromB58Prefix(b58.$1, configs);
        if (network == null) return null;
        return ZCashDecodedAddressResult(
          network: network.$1.network,
          addressBytes: b58.$2,
          type: network.$2,
        );
      }
    }

    return null;
  }

  static ZCashDecodedAddressResult? parseAddress(
    String address, {
    ZcashNetwork? expectedNetwork,
    ZCashAddressType? exceptedType,
  }) {
    final decode = _parseAddress(address, exceptedType: exceptedType);
    if (decode == null) return null;
    _validate(
      network: decode.network,
      type: decode.type,
      exceptedType: exceptedType,
      expectedNetwork: expectedNetwork,
    );
    return decode;
  }

  static void _validate({
    required ZcashNetwork network,
    required ZCashAddressType type,
    ZcashNetwork? expectedNetwork,
    ZCashAddressType? exceptedType,
  }) {
    if (expectedNetwork != null && expectedNetwork != network) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Mismatch address network.",
        details: {'network': network.name, 'expected': expectedNetwork.name},
      );
    }
    if (exceptedType != null && exceptedType != type) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Mismatch address type.",
        details: {'type': type.name, 'expected': exceptedType.name},
      );
    }
  }

  static String encodeAddress({
    required List<int> bytes,
    required ZCashAddressType type,
    required ZcashNetwork network,
    List<ZUnifiedReceiver>? receivers,
  }) {
    final config = ZcashConf().fromNetwork(network);
    try {
      switch (type) {
        case ZCashAddressType.p2sh:
          return encodeBase58Addresses(
            bytes: bytes,
            prefix: config.b58ScriptAddressPrefix,
            type: type,
          );
        case ZCashAddressType.p2pkh:
          return encodeBase58Addresses(
            bytes: bytes,
            prefix: config.b58PubkeyAddressPrefix,
            type: type,
          );
        case ZCashAddressType.sprout:
          return encodeBase58Addresses(
            bytes: bytes,
            prefix: config.b58SproutAddressPrefix,
            type: type,
          );
        case ZCashAddressType.tex:
          return encodeBech32Address(
            bytes: bytes,
            hrp: config.hrpTexAddress,
            type: type,
          );
        case ZCashAddressType.sapling:
          return encodeBech32Address(
            bytes: bytes,
            hrp: config.hrpSaplingPaymentAddress,
            type: type,
          );
        case ZCashAddressType.unified:
          return ZCashEncodingUtils.encodeUnifiedObject(
            addressBytes: bytes,
            hrp: config.hrpUnifiedAddress,
            receivers: receivers,
            mode: UnifiedReceiverMode.address,
          );
      }
    } on AddressConverterException {
      rethrow;
    } on ZCashKeyEncodingError catch (e) {
      throw AddressConverterException.addressValidationFailed(
        details: e.details,
      );
    } catch (e) {
      throw AddressConverterException.addressValidationFailed(
        reason: e.toString(),
      );
    }
  }

  static String encodeBase58Addresses({
    required List<int> bytes,
    required List<int> prefix,
    required ZCashAddressType type,
  }) {
    assert(
      [
        ZCashAddressType.p2pkh,
        ZCashAddressType.p2sh,
        ZCashAddressType.sprout,
      ].contains(type),
    );
    assert(prefix.length == 2);
    if (prefix.length != 2 || bytes.length != type.lengthInBytes) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid address bytes length.",
      );
    }
    return ZCashEncodingUtils.encodeBase58WithCheck(
      bytes: bytes,
      prefix: prefix,
    );
  }

  static String encodeBech32Address({
    required List<int> bytes,
    required String hrp,
    required ZCashAddressType type,
  }) {
    assert([ZCashAddressType.sapling, ZCashAddressType.tex].contains(type));
    if (bytes.length != type.lengthInBytes) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid address bytes length.",
      );
    }
    return ZCashEncodingUtils.encodeBech32Address(
      bytes: bytes,
      hrp: hrp,
      encoding:
          type == ZCashAddressType.tex
              ? Bech32Encodings.bech32m
              : Bech32Encodings.bech32,
    );
  }
}
