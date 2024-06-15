import 'dart:typed_data';
import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'ada_addres_type.dart';
import 'network.dart';

class Pointer {
  final BigInt slot;
  final BigInt txIndex;
  final BigInt certIndex;
  @override
  String toString() {
    return "Pointer{slot: $slot, txIndex: $txIndex, certIndex: $certIndex}";
  }

  const Pointer(
      {required this.slot, required this.txIndex, required this.certIndex});
  factory Pointer.fromBytes(List<int> data) {
    final slot = BigintUtils.variableNatDecode(data);
    final txIndex = BigintUtils.variableNatDecode(data.sublist(slot.item2));
    final certIndex =
        BigintUtils.variableNatDecode(data.sublist(slot.item2 + txIndex.item2));
    return Pointer(
        slot: slot.item1, txIndex: txIndex.item1, certIndex: certIndex.item1);
  }

  List<int> toBytes() {
    return [
      ...BigintUtils.variableNatEncode(slot),
      ...BigintUtils.variableNatEncode(txIndex),
      ...BigintUtils.variableNatEncode(certIndex),
    ];
  }
}

class AdaStakeCredType {
  final String name;
  final int value;
  const AdaStakeCredType._(this.name, this.value);
  static const AdaStakeCredType key = AdaStakeCredType._("Key", 0x00);
  static const AdaStakeCredType script = AdaStakeCredType._("Script", 0x01);

  @override
  String toString() {
    return "AdaStakeCredType.$name";
  }
}

class AdaStakeCredential {
  final AdaStakeCredType type;
  final List<int> hash;
  AdaStakeCredential._(this.type, List<int> hash)
      : hash = BytesUtils.toBytes(hash, unmodifiable: true);

  factory AdaStakeCredential(
      {required List<int> hash, required AdaStakeCredType type}) {
    if (hash.length != QuickCrypto.blake2b224DigestSize) {
      throw AddressConverterException("Invalid credential hash length. ",
          details: {
            "Excepted": QuickCrypto.blake2b224DigestSize,
            "length": hash.length
          });
    }
    return AdaStakeCredential._(type, hash);
  }
}

/// Constants related to Ada Shelley addresses, including address human-readable prefixes.
class AdaShelleyAddrConst {
  /// Maps Ada Shelley network tags to their corresponding address human-readable prefixes.
  static final Map<ADANetwork, String> networkTagToAddrHrp = {
    ADANetwork.mainnet: CoinsConf.cardanoMainNet.params.addrHrp!,
    ADANetwork.testnet: CoinsConf.cardanoTestNet.params.addrHrp!,
    ADANetwork.testnetPreprod: CoinsConf.cardanoTestNet.params.addrHrp!,
    ADANetwork.testnetPreview: CoinsConf.cardanoTestNet.params.addrHrp!,
  };

  /// Maps Ada Shelley network tags to their corresponding staking (reward) address human-readable prefixes.
  static final Map<ADANetwork, String> networkTagToRewardAddrHrp = {
    ADANetwork.mainnet: CoinsConf.cardanoMainNet.params.stakingAddrHrp!,
    ADANetwork.testnet: CoinsConf.cardanoTestNet.params.stakingAddrHrp!,
    ADANetwork.testnetPreprod: CoinsConf.cardanoTestNet.params.stakingAddrHrp!,
    ADANetwork.testnetPreview: CoinsConf.cardanoTestNet.params.stakingAddrHrp!,
  };
}

/// Utility class for encoding and decoding Ada Shelley addresses.
class AdaShelleyAddrUtils {
  /// Computes the key hash for the given public key bytes.
  /// Key hash is calculated using the Blake2b224 hash function.
  static List<int> keyHash(List<int> pubKeyBytes) {
    return QuickCrypto.blake2b224Hash(pubKeyBytes);
  }

  /// Encodes the address prefix based on the header type and network tag.
  /// The prefix is a combination of the header type and network tag.
  ///
  /// Parameters:
  /// - [hdrType]: The header type used for encoding (e.g., payment or reward).
  /// - [netTag]: The network tag representing the network (e.g., mainnet or testnet).
  ///
  /// Returns:
  /// A byte array representing the address prefix.
  static List<int> encodePrefix(
      ADAAddressType hdrType, int netTag, AdaStakeCredType credType,
      {AdaStakeCredType? stakeType}) {
    int hdr = (hdrType.header << 4) | credType.value << 4;
    if (hdrType == ADAAddressType.base && stakeType != null) {
      hdr |= stakeType.value << 5;
    }

    hdr += netTag;
    return IntUtils.toBytes(hdr,
        length: IntUtils.bitlengthInBytes(hdr), byteOrder: Endian.little);
  }

  static int decodeNetworkTag(int header) {
    return header & 0x0F;
  }

  static AdaStakeCredType decodeCred(int header, int bit) {
    return header & (1 << bit) == 0
        ? AdaStakeCredType.key
        : AdaStakeCredType.script;
  }

  static String encode(
      {required AdaStakeCredential credential,
      AdaStakeCredential? stakeCredential,
      Pointer? pointer,
      required ADANetwork netTag,
      required String hrp,
      required ADAAddressType type}) {
    /// Encode the address prefix using the header type and network tag.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
        type, netTag.value, credential.type,
        stakeType: stakeCredential?.type);

    return Bech32Encoder.encode(
        hrp,
        List<int>.from([
          ...prefixByte,
          ...credential.hash,
          ...stakeCredential?.hash ?? <int>[],
          ...pointer?.toBytes() ?? <int>[]
        ]));
  }

  static String encodeBytes(List<int> addrBytes) {
    int header = addrBytes[0];
    final netTag = ADANetwork.fromTag(decodeNetworkTag(header));
    ADAAddressType addressType = ADAAddressType.decodeAddressType(header);
    if (addressType == ADAAddressType.reward) {
      return Bech32Encoder.encode(
          AdaShelleyAddrConst.networkTagToRewardAddrHrp[netTag]!, addrBytes);
    }
    return Bech32Encoder.encode(
        AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!, addrBytes);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley address.
class AdaShelleyAddrDecoder implements BlockchainAddressDecoder {
  /// Blockchain address decoder for Ada Shelley addresses.
  /// This decoder is used to decode payment addresses based on the network tag and address format.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }

    // Decode the provided Bech32 address.
    final addrDecBytes = Bech32Decoder.decode(
        AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!, addr);

    /// Validate the byte length of the decoded address.
    AddrDecUtils.validateBytesLength(
        addrDecBytes, (QuickCrypto.blake2b224DigestSize * 2) + 1);

    /// Encode the address prefix based on the payment header type and network tag.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(ADAAddressType.base,
        netTag.value, AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4),
        stakeType: AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 5));
    return AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ada Shelley address.
class AdaShelleyAddrEncoder implements BlockchainAddressEncoder {
  String encodeCredential(AdaStakeCredential credential,
      [Map<String, dynamic> kwargs = const {}]) {
    final AdaStakeCredential pubSkey =
        AddrKeyValidator.validateAddressArgs<AdaStakeCredential>(
            kwargs, "pub_skey");

    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }
    return AdaShelleyAddrUtils.encode(
        credential: credential,
        netTag: netTag,
        hrp: AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!,
        stakeCredential: pubSkey,
        type: ADAAddressType.base);
  }

  /// Blockchain address encoder for Ada Shelley addresses.
  /// This encoder is used to create addresses based on public and private key pairs.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate the provided address arguments.
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "pub_skey");

    /// Extract the public spending key (pub_skey) from the arguments.
    final List<int> pubSkey = kwargs["pub_skey"];

    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }

    /// Validate and retrieve public keys.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    final pubSkeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubSkey);

    // Compute key hashes for public spending and public delegation keys.
    final pubKeyHash =
        AdaShelleyAddrUtils.keyHash(pubKeyObj.compressed.sublist(1));
    final pubSkeyHash =
        AdaShelleyAddrUtils.keyHash(pubSkeyObj.compressed.sublist(1));

    return AdaShelleyAddrUtils.encode(
        credential:
            AdaStakeCredential(hash: pubKeyHash, type: AdaStakeCredType.key),
        netTag: netTag,
        hrp: AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!,
        stakeCredential:
            AdaStakeCredential(hash: pubSkeyHash, type: AdaStakeCredType.key),
        type: ADAAddressType.base);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley staking address.
class AdaShelleyStakingAddrDecoder implements BlockchainAddressDecoder {
  /// Blockchain address decoder for Ada Shelley staking addresses.
  /// This decoder is used to decode staking addresses based on network tag and address data.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }

    /// Decode the provided address using the staking network tag's address prefix.
    final addrDecBytes = Bech32Decoder.decode(
        AdaShelleyAddrConst.networkTagToRewardAddrHrp[netTag]!, addr);

    /// Validate the length of the decoded bytes and remove the prefix.
    AddrDecUtils.validateBytesLength(
        addrDecBytes, QuickCrypto.blake2b224DigestSize + 1);

    /// Encode the address prefix based on the reward header type and network tag.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(ADAAddressType.reward,
        netTag.value, AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4));

    /// Return the final decoded address by removing the prefix and converting it to bytes.
    return AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ada Shelley staking address.
class AdaShelleyStakingAddrEncoder implements BlockchainAddressEncoder {
  String encodeCredential(AdaStakeCredential credential,
      [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }
    return AdaShelleyAddrUtils.encode(
        credential: credential,
        netTag: netTag,
        hrp: AdaShelleyAddrConst.networkTagToRewardAddrHrp[netTag]!,
        type: ADAAddressType.reward);
  }

  /// Blockchain address encoder for Ada Shelley staking addresses.
  /// This encoder is used to create staking addresses based on the network tag and public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }

    /// Validate and get the Ed25519 public key object from the provided bytes.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Compute the public key hash based on the compressed key bytes.
    final pubKeyHash =
        AdaShelleyAddrUtils.keyHash(pubKeyObj.compressed.sublist(1));
    return AdaShelleyAddrUtils.encode(
        credential:
            AdaStakeCredential(hash: pubKeyHash, type: AdaStakeCredType.key),
        netTag: netTag,
        hrp: AdaShelleyAddrConst.networkTagToRewardAddrHrp[netTag]!,
        type: ADAAddressType.reward);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley address.
class AdaShelleyEnterpriseDecoder implements BlockchainAddressDecoder {
  /// Blockchain address decoder for Ada Shelley addresses.
  /// This decoder is used to decode payment addresses based on the network tag and address format.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }

    // Decode the provided Bech32 address.
    final addrDecBytes = Bech32Decoder.decode(
        AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!, addr);

    /// Validate the byte length of the decoded address.
    AddrDecUtils.validateBytesLength(
        addrDecBytes, QuickCrypto.blake2b224DigestSize + 1);

    /// Encode the address prefix based on the payment header type and network tag.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
        ADAAddressType.enterprise,
        netTag.value,
        AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4));
    return AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte);
  }
}

class AdaShelleyEnterpriseAddrEncoder implements BlockchainAddressEncoder {
  String encodeCredential(AdaStakeCredential credential,
      [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }

    return AdaShelleyAddrUtils.encode(
        credential: credential,
        netTag: netTag,
        hrp: AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!,
        type: ADAAddressType.enterprise);
  }

  /// Blockchain address encoder for Ada Shelley addresses.
  /// This encoder is used to create addresses based on public and private key pairs.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }

    /// Validate and retrieve public keys.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    // Compute key hashes for public spending and public delegation keys.
    final pubKeyHash =
        AdaShelleyAddrUtils.keyHash(pubKeyObj.compressed.sublist(1));

    return AdaShelleyAddrUtils.encode(
        credential:
            AdaStakeCredential(hash: pubKeyHash, type: AdaStakeCredType.key),
        netTag: netTag,
        hrp: AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!,
        type: ADAAddressType.enterprise);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley address.
class AdaShelleyPointerDecoder implements BlockchainAddressDecoder {
  /// Blockchain address decoder for Ada Shelley addresses.
  /// This decoder is used to decode payment addresses based on the network tag and address format.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }

    // Decode the provided Bech32 address.
    final addrDecBytes = Bech32Decoder.decode(
        AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!, addr);

    /// Validate the byte length of the decoded address.
    AddrDecUtils.validateBytesLength(
        addrDecBytes, QuickCrypto.blake2b224DigestSize + 1,
        minLength: QuickCrypto.blake2b224DigestSize + 4);

    /// validate pointer data
    Pointer.fromBytes(
        addrDecBytes.sublist(QuickCrypto.blake2b224DigestSize + 1));

    /// Encode the address prefix based on the payment header type and network tag.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(ADAAddressType.pointer,
        netTag.value, AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4));
    return AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte);
  }
}

class AdaPointerAddrEncoder implements BlockchainAddressEncoder {
  String encodeCredential(AdaStakeCredential credential,
      [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }

    final pointer = kwargs["pointer"];
    if (pointer is! Pointer) {
      throw const AddressConverterException(
          'The provided value for "Pointer" is not of type Pointer.');
    }
    return AdaShelleyAddrUtils.encode(
        credential: credential,
        pointer: pointer,
        netTag: netTag,
        hrp: AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!,
        type: ADAAddressType.pointer);
  }

  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? ADANetwork.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! ADANetwork) {
      throw const AddressConverterException(
          'Address type is not an enumerative of ADANetwork');
    }

    final pointer = kwargs["pointer"];
    if (pointer is! Pointer) {
      throw const AddressConverterException(
          'The provided value for "Pointer" is not of type Pointer.');
    }

    /// Validate and retrieve public keys.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    // Compute key hashes for public spending and public delegation keys.
    final pubKeyHash =
        AdaShelleyAddrUtils.keyHash(pubKeyObj.compressed.sublist(1));
    return AdaShelleyAddrUtils.encode(
        credential:
            AdaStakeCredential(hash: pubKeyHash, type: AdaStakeCredType.key),
        netTag: netTag,
        pointer: pointer,
        hrp: AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!,
        type: ADAAddressType.pointer);
  }
}
