import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bech32/bech32_ex.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/numbers/int_utils.dart';

/// An enumeration of Ada Shelley address network tags.
enum AdaShelleyAddrNetworkTags {
  /// Mainnet network tag with a value of 1.
  mainnet(1),

  /// Testnet network tag with a value of 0.
  testnet(0);

  final int value;

  /// Constants representing header types for Ada Shelley addresses.
  const AdaShelleyAddrNetworkTags(this.value);
}

class AdaShelleyAddrHeaderTypes {
  /// Header type for payment addresses.
  static const int payment = 0x00;

  /// Header type for reward addresses.
  static const int reward = 0x0E;
}

/// Constants related to Ada Shelley addresses, including address human-readable prefixes.
class AdaShelleyAddrConst {
  /// Maps Ada Shelley network tags to their corresponding address human-readable prefixes.
  static final Map<AdaShelleyAddrNetworkTags, String> networkTagToAddrHrp = {
    AdaShelleyAddrNetworkTags.mainnet: CoinsConf.cardanoMainNet.params.addrHrp!,
    AdaShelleyAddrNetworkTags.testnet: CoinsConf.cardanoTestNet.params.addrHrp!,
  };

  /// Maps Ada Shelley network tags to their corresponding staking (reward) address human-readable prefixes.
  static final Map<AdaShelleyAddrNetworkTags, String>
      networkTagToRewardAddrHrp = {
    AdaShelleyAddrNetworkTags.mainnet:
        CoinsConf.cardanoMainNet.params.stakingAddrHrp!,
    AdaShelleyAddrNetworkTags.testnet:
        CoinsConf.cardanoTestNet.params.stakingAddrHrp!,
  };
}

/// Utility class for encoding and decoding Ada Shelley addresses.
class _AdaShelleyAddrUtils {
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
  static List<int> encodePrefix(int hdrType, int netTag) {
    final hdr = (hdrType << 4) + netTag;
    return IntUtils.toBytes(hdr, length: IntUtils.bitlengthInBytes(hdr));
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley address.
class AdaShelleyAddrDecoder implements BlockchainAddressDecoder {
  /// Blockchain address decoder for Ada Shelley addresses.
  /// This decoder is used to decode payment addresses based on the network tag and address format.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? AdaShelleyAddrNetworkTags.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! AdaShelleyAddrNetworkTags) {
      throw ArgumentError(
          'Address type is not an enumerative of AdaShelleyAddrNetworkTags');
    }

    // Decode the provided Bech32 address.
    try {
      final addrDecBytes = Bech32Decoder.decode(
          AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!, addr);

      /// Validate the byte length of the decoded address.
      AddrDecUtils.validateBytesLength(
          addrDecBytes, (QuickCrypto.blake2b224DigestSize * 2) + 1);

      /// Encode the address prefix based on the payment header type and network tag.
      final prefixByte = _AdaShelleyAddrUtils.encodePrefix(
          AdaShelleyAddrHeaderTypes.payment, netTag.value);
      return AddrDecUtils.validateAndRemovePrefixBytes(
          addrDecBytes, prefixByte);
    } on Bech32ChecksumError catch (e) {
      throw ArgumentError('Invalid bech32 checksum $e');
    }
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ada Shelley address.
class AdaShelleyAddrEncoder implements BlockchainAddressEncoder {
  /// Blockchain address encoder for Ada Shelley addresses.
  /// This encoder is used to create addresses based on public and private key pairs.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate the provided address arguments.
    AddrKeyValidator.validateAddressArgs<List<int>>(kwargs, "pub_skey");

    /// Extract the public spending key (pub_skey) from the arguments.
    final List<int> pubSkey = kwargs["pub_skey"];

    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? AdaShelleyAddrNetworkTags.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! AdaShelleyAddrNetworkTags) {
      throw ArgumentError(
          'Address type is not an enumerative of AdaShelleyAddrNetworkTags');
    }

    /// Validate and retrieve public keys.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    final pubSkeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubSkey);

    // Compute key hashes for public spending and public delegation keys.
    final pubKeyHash =
        _AdaShelleyAddrUtils.keyHash(pubKeyObj.compressed.sublist(1));
    final pubSkeyHash =
        _AdaShelleyAddrUtils.keyHash(pubSkeyObj.compressed.sublist(1));

    /// Encode the address prefix using the header type and network tag.
    final prefixByte = _AdaShelleyAddrUtils.encodePrefix(
        AdaShelleyAddrHeaderTypes.payment, netTag.value);

    /// Create the final address by combining prefix, public key hashes, and spending key hash.
    return Bech32Encoder.encode(
        AdaShelleyAddrConst.networkTagToAddrHrp[netTag]!,
        List<int>.from([...prefixByte, ...pubKeyHash, ...pubSkeyHash]));
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley staking address.
class AdaShelleyStakingAddrDecoder implements BlockchainAddressDecoder {
  /// Blockchain address decoder for Ada Shelley staking addresses.
  /// This decoder is used to decode staking addresses based on network tag and address data.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? AdaShelleyAddrNetworkTags.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! AdaShelleyAddrNetworkTags) {
      throw ArgumentError(
          'Address type is not an enumerative of AdaShelleyAddrNetworkTags');
    }

    try {
      /// Decode the provided address using the staking network tag's address prefix.
      final addrDecBytes = Bech32Decoder.decode(
          AdaShelleyAddrConst.networkTagToRewardAddrHrp[netTag]!, addr);

      /// Validate the length of the decoded bytes and remove the prefix.
      AddrDecUtils.validateBytesLength(
          addrDecBytes, QuickCrypto.blake2b224DigestSize + 1);

      /// Encode the address prefix based on the reward header type and network tag.
      final prefixByte = _AdaShelleyAddrUtils.encodePrefix(
          AdaShelleyAddrHeaderTypes.reward, netTag.value);

      /// Return the final decoded address by removing the prefix and converting it to bytes.
      return AddrDecUtils.validateAndRemovePrefixBytes(
          addrDecBytes, prefixByte);
    } on Bech32ChecksumError catch (e) {
      throw ArgumentError('Invalid bech32 checksum $e');
    }
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ada Shelley staking address.
class AdaShelleyStakingAddrEncoder implements BlockchainAddressEncoder {
  /// Blockchain address encoder for Ada Shelley staking addresses.
  /// This encoder is used to create staking addresses based on the network tag and public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Determine the network tag, defaulting to mainnet if not specified.
    final netTag = kwargs["net_tag"] ?? AdaShelleyAddrNetworkTags.mainnet;

    /// Check if the provided network tag is a valid enum value.
    if (netTag is! AdaShelleyAddrNetworkTags) {
      throw ArgumentError(
          'Address type is not an enumerative of AdaShelleyAddrNetworkTags');
    }

    /// Validate and get the Ed25519 public key object from the provided bytes.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Compute the public key hash based on the compressed key bytes.
    final pubKeyHash =
        _AdaShelleyAddrUtils.keyHash(pubKeyObj.compressed.sublist(1));

    /// Encode the address prefix based on the reward header type and network tag.
    final firstByte = _AdaShelleyAddrUtils.encodePrefix(
        AdaShelleyAddrHeaderTypes.reward, netTag.value);

    /// Generate the staking address using Bech32 encoding with the appropriate HRP.
    return Bech32Encoder.encode(
        AdaShelleyAddrConst.networkTagToRewardAddrHrp[netTag]!,
        List<int>.from([...firstByte, ...pubKeyHash]));
  }
}
