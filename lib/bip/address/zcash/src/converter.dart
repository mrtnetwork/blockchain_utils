import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/address/zcash/src/types.dart';
import 'package:blockchain_utils/bip/address/zcash/src/utils.dart';
import 'package:blockchain_utils/bip/zcash/src/types.dart';

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
      exceptedType: type,
    );
    if (decode == null) {
      throw AddressConverterException.addressValidationFailed();
    }
    return decode;
  }
}

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

class ZcashUnifiedAddrEncoder implements BlockchainAddressEncoder {
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
