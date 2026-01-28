import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/address/zcash/src/types.dart';
import 'package:blockchain_utils/bip/address/zcash/src/utils.dart';
import 'package:blockchain_utils/bip/zcash/src/types.dart';

class ZCashAddrDecoder
    implements BlockchainAddressDecoder<ZCashDecodedAddressResult> {
  @override
  ZCashDecodedAddressResult decodeAddr(
    String addr, {
    ZcashNetwork? network,
    ZCashAddressType? type,
  }) {
    final decode = ZCashAddressUtils.parseAddress(
      addr,
      expectedNetwork: network,
      exceptedType: type,
    );
    if (decode == null) {
      throw AddressConverterException.addressValidationFailed();
    }
    return decode;
  }
}

class ZCashAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(
    List<int> keyBytes, {
    ZcashNetwork? network,
    ZCashAddressType? addrType,
  }) {
    network ??= ZcashNetwork.mainnet;
    addrType ??= AddrKeyValidator.getAddrArg<ZCashAddressType>(
      addrType,
      "addrType",
    );
    return ZCashAddressUtils.encodeAddress(
      bytes: keyBytes,
      type: addrType,
      network: network,
    );
  }
}

class ZCashUnifiedAddrEncoder implements BlockchainAddressEncoder {
  String encodeUnifiedReceivers(
    List<ZUnifiedReceiver> receivers, {
    ZcashNetwork? network,
  }) {
    network ??= ZcashNetwork.mainnet;
    return ZCashAddressUtils.encodeAddress(
      bytes: const [],
      type: ZCashAddressType.unified,
      network: network,
      receivers: receivers,
    );
  }

  @override
  String encodeKey(List<int> keyBytes, {ZcashNetwork? network}) {
    network ??= ZcashNetwork.mainnet;
    return ZCashAddressUtils.encodeAddress(
      bytes: keyBytes,
      type: ZCashAddressType.unified,
      network: network,
    );
  }
}
