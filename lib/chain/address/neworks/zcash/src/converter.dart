import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/chain/address/neworks/zcash/src/types.dart';
import 'package:blockchain_utils/chain/address/neworks/zcash/src/utils.dart';
import 'package:blockchain_utils/protocol/zcash/src/types.dart';

/// Decodes a Zcash address (transparent, shielded, or unified).
class ZcashAddrDecoder
    implements BlockchainAddressDecoder<ZcashDecodedAddressResult> {
  @override
  ZcashDecodedAddressResult decodeAddr(
    String addr, {
    ZcashNetwork? network,
    ZcashAddressType? type,
  }) {
    final decode = ZcashAddressUtils.parseAddress(
      addr,
      expectedNetwork: network,
      expectedType: type,
    );
    if (decode == null) {
      throw CoreErrors.addressValidationFailed();
    }
    return decode;
  }
}

/// Encodes a Zcash transparent or shielded address.
class ZcashAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(
    List<int> keyBytes, {
    ZcashNetwork? network,
    ZcashAddressType? addrType,
  }) {
    network ??= ZcashNetwork.mainnet;
    addrType ??= AddrKeyValidator.getAddrArg<ZcashAddressType>(
      addrType,
      "addrType",
    );
    return ZcashAddressUtils.encodeAddress(
      bytes: keyBytes,
      type: addrType,
      network: network,
    );
  }
}

/// Encodes a Zcash unified address.
class ZcashUnifiedAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a unified address directly from its receivers.
  String encodeUnifiedReceivers(
    List<ZUnifiedReceiver> receivers, {
    ZcashNetwork? network,
  }) {
    network ??= ZcashNetwork.mainnet;
    return ZcashAddressUtils.encodeAddress(
      bytes: const [],
      type: ZcashAddressType.unified,
      network: network,
      receivers: receivers,
    );
  }

  @override
  String encodeKey(List<int> keyBytes, {ZcashNetwork? network}) {
    network ??= ZcashNetwork.mainnet;
    return ZcashAddressUtils.encodeAddress(
      bytes: keyBytes,
      type: ZcashAddressType.unified,
      network: network,
    );
  }
}
