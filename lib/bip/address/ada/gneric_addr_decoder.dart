import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/ada/ada_byron_addr.dart';
import 'package:blockchain_utils/bip/address/ada/ada_shelley_addr.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'ada_addres_type.dart';
import 'network.dart';

class AdaGenericAddrDecoderResult {
  AdaGenericAddrDecoderResult._(
      {required this.type,
      required this.baseHashBytes,
      required this.network,
      required List<int> addressBytes,
      List<int>? prefixBytes,
      this.stakeHashBytes,
      this.pointer,
      this.byronAddrPayload})
      : addressBytes = BytesUtils.toBytes(addressBytes, unmodifiable: true),
        prefixBytes = BytesUtils.tryToBytes(prefixBytes, unmodifiable: true);
  final ADAAddressType type;
  final List<int> addressBytes;
  final AdaStakeCredential? baseHashBytes;
  final List<int>? prefixBytes;
  final AdaStakeCredential? stakeHashBytes;
  final Pointer? pointer;
  final ADAByronAddr? byronAddrPayload;
  final ADANetwork network;
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley address.
class AdaGenericAddrDecoder {
  AdaGenericAddrDecoderResult decode(String addr,
      [Map<String, dynamic> kwargs = const {}]) {
    final netTag = kwargs["net_tag"];

    if (netTag != null) {
      if (netTag is! ADANetwork) {
        throw const AddressConverterException(
            'Address type is not an enumerative of ADANetwork');
      }
    }
    Tuple<String, List<int>> addrDecBytes;
    bool checkedByron = false;
    ADANetwork? network;
    try {
      // Decode the provided Bech32 address.
      addrDecBytes = Bech32Decoder.decodeWithoutHRP(addr);
    } catch (e) {
      final base58Decode = Base58Decoder.decode(addr);
      final byron = ADAByronAddr.deserialize(base58Decode);
      network = ADANetwork.fromProtocolMagic(byron.payload.attrs.networkMagic);
      addrDecBytes = Tuple(
          AdaShelleyAddrConst.networkTagToAddrHrp[network]!, base58Decode);
      checkedByron = true;
    }

    final List<int> addressBytes = addrDecBytes.item2;
    if (addressBytes.length < QuickCrypto.blake2b224DigestSize + 1) {
      throw const AddressConverterException("Invalid address length.");
    }
    final int header = addressBytes[0];
    final int networkTag = AdaShelleyAddrUtils.decodeNetworkTag(header);
    final ADAAddressType addressType = ADAAddressType.decodeAddressType(header);

    if (network == null) {
      if (addressType == ADAAddressType.byron) {
        final byron = ADAByronAddr.deserialize(addressBytes);
        network =
            ADANetwork.fromProtocolMagic(byron.payload.attrs.networkMagic);
      } else {
        network = ADANetwork.fromTag(networkTag);
      }
    }
    String? hrp = AdaShelleyAddrConst.networkTagToAddrHrp[network];

    switch (addressType) {
      case ADAAddressType.base:
        AddrDecUtils.validateBytesLength(
            addressBytes, (QuickCrypto.blake2b224DigestSize * 2) + 1);
        break;
      case ADAAddressType.reward:
        AddrDecUtils.validateBytesLength(
            addressBytes, QuickCrypto.blake2b224DigestSize + 1);
        hrp = AdaShelleyAddrConst.networkTagToRewardAddrHrp[network];
        break;
      case ADAAddressType.enterprise:
        AddrDecUtils.validateBytesLength(
            addressBytes, QuickCrypto.blake2b224DigestSize + 1);
        break;
      case ADAAddressType.pointer:
        AddrDecUtils.validateBytesLength(
            addressBytes, QuickCrypto.blake2b224DigestSize + 1 + 3,
            minLength: QuickCrypto.blake2b224DigestSize + 1 + 3);
        break;
      case ADAAddressType.byron:
        if (!checkedByron) {
          ADAByronAddr.deserialize(addressBytes);
        }

        break;
      default:
        throw AddressConverterException("Invalid address prefix $addressType");
    }
    if (hrp == null || addrDecBytes.item1 != hrp) {
      throw AddressConverterException("Invalid address hrp ${hrp ?? ''}");
    }

    if (addressType == ADAAddressType.byron) {
      return AdaGenericAddrDecoderResult._(
          type: addressType,
          baseHashBytes: null,
          network: network,
          addressBytes: addressBytes,
          byronAddrPayload: ADAByronAddr.deserialize(addressBytes));
    }

    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
      addressType,
      networkTag,
      AdaShelleyAddrUtils.decodeCred(header, 4),
      stakeType: AdaShelleyAddrUtils.decodeCred(header, 5),
    );
    return AdaGenericAddrDecoderResult._(
      type: addressType,
      addressBytes: addressBytes,
      network: network,
      baseHashBytes: AdaStakeCredential(
          hash: addressBytes.sublist(prefixByte.length,
              prefixByte.length + QuickCrypto.blake2b224DigestSize),
          type: AdaShelleyAddrUtils.decodeCred(header, 4)),
      prefixBytes: prefixByte,
      stakeHashBytes: addressType == ADAAddressType.base
          ? AdaStakeCredential(
              hash: addressBytes.sublist(
                  prefixByte.length + QuickCrypto.blake2b224DigestSize),
              type: AdaShelleyAddrUtils.decodeCred(header, 5))
          : null,
      pointer: addressType == ADAAddressType.pointer
          ? Pointer.fromBytes(addressBytes
              .sublist(prefixByte.length + QuickCrypto.blake2b224DigestSize))
          : null,
    );
  }
}
