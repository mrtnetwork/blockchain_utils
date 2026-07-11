import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
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

  const Pointer({
    required this.slot,
    required this.txIndex,
    required this.certIndex,
  });
  factory Pointer.fromBytes(List<int> data) {
    final slot = BigintUtils.variableNatDecode(data);
    final txIndex = BigintUtils.variableNatDecode(data.sublist(slot.$2));
    final certIndex = BigintUtils.variableNatDecode(
      data.sublist(slot.$2 + txIndex.$2),
    );
    return Pointer(slot: slot.$1, txIndex: txIndex.$1, certIndex: certIndex.$1);
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
    : hash = hash.asImmutableBytes;

  factory AdaStakeCredential({
    required List<int> hash,
    required AdaStakeCredType type,
  }) {
    if (hash.length != QuickCrypto.blake2b224DigestSize) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid bytes length.",
        details: {
          "Excepted": QuickCrypto.blake2b224DigestSize.toString(),
          "length": hash.length.toString(),
        },
      );
    }
    return AdaStakeCredential._(type, hash);
  }
}

/// Utility class for encoding and decoding Ada Shelley addresses.
class AdaShelleyAddrUtils {
  static String getAddressHrp(ADANetwork network) {
    return AddrKeyValidator.getConfigArg(switch (network) {
      ADANetwork.mainnet => CoinsConf.cardanoMainNet.params.addrHrp,
      _ => CoinsConf.cardanoTestNet.params.addrHrp,
    }, "addrHrp");
  }

  static String getRewardAddressHrp(ADANetwork network) {
    return AddrKeyValidator.getConfigArg(switch (network) {
      ADANetwork.mainnet => CoinsConf.cardanoMainNet.params.stakingAddrHrp,
      _ => CoinsConf.cardanoTestNet.params.stakingAddrHrp,
    }, "stakingAddrHrp");
  }

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
  /// - [network]: The network tag representing the network (e.g., mainnet or testnet).
  ///
  /// Returns:
  /// A byte array representing the address prefix.
  static List<int> encodePrefix(
    ADAAddressType hdrType,
    int network,
    AdaStakeCredType credType, {
    AdaStakeCredType? stakeType,
  }) {
    int hdr = (hdrType.header << 4) | credType.value << 4;
    if (hdrType == ADAAddressType.base && stakeType != null) {
      hdr |= stakeType.value << 5;
    }

    hdr += network;
    return hdr.toLeBytes();
  }

  static int decodeNetworkTag(int header) {
    return header & 0x0F;
  }

  static AdaStakeCredType decodeCred(int header, int bit) {
    return header & (1 << bit) == 0
        ? AdaStakeCredType.key
        : AdaStakeCredType.script;
  }

  static String encode({
    required AdaStakeCredential credential,
    AdaStakeCredential? stakeCredential,
    Pointer? pointer,
    required ADANetwork network,
    required String hrp,
    required ADAAddressType type,
  }) {
    /// Encode the address prefix using the header type and network tag.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
      type,
      network.value,
      credential.type,
      stakeType: stakeCredential?.type,
    );

    return Bech32Encoder.encode(hrp, [
      ...prefixByte,
      ...credential.hash,
      ...stakeCredential?.hash ?? <int>[],
      ...pointer?.toBytes() ?? <int>[],
    ]);
  }

  static String encodeBytes(List<int> addrBytes) {
    final int header = addrBytes[0];
    final network = ADANetwork.fromTags(decodeNetworkTag(header)).first;
    final ADAAddressType addressType = ADAAddressType.decodeAddressType(header);
    if (addressType == ADAAddressType.reward) {
      return Bech32Encoder.encode(getRewardAddressHrp(network), addrBytes);
    }
    return Bech32Encoder.encode(getAddressHrp(network), addrBytes);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley address.
class AdaShelleyAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Blockchain address decoder for Ada Shelley addresses.
  /// This decoder is used to decode payment addresses based on the network tag and address format.
  @override
  List<int> decodeAddr(String addr, {ADANetwork network = ADANetwork.mainnet}) {
    // Decode the provided Bech32 address.
    final addrDecBytes = Bech32Decoder.decode(
      AdaShelleyAddrUtils.getAddressHrp(network),
      addr,
    );

    /// Validate the byte length of the decoded address.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      (QuickCrypto.blake2b224DigestSize * 2) + 1,
    );

    /// Encode the address prefix based on the payment header type and network tag.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
      ADAAddressType.base,
      network.value,
      AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4),
      stakeType: AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 5),
    );
    return AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ada Shelley address.
class AdaShelleyAddrEncoder implements BlockchainAddressEncoder {
  String encodeCredential(
    AdaStakeCredential credential, {
    ADANetwork network = ADANetwork.mainnet,
    AdaStakeCredential? pubSkey,
  }) {
    pubSkey = AddrKeyValidator.getAddrArg<AdaStakeCredential>(
      pubSkey,
      "pubSkey",
    );
    return AdaShelleyAddrUtils.encode(
      credential: credential,
      network: network,
      hrp: AdaShelleyAddrUtils.getAddressHrp(network),
      stakeCredential: pubSkey,
      type: ADAAddressType.base,
    );
  }

  /// Blockchain address encoder for Ada Shelley addresses.
  /// This encoder is used to create addresses based on public and private key pairs.
  @override
  String encodeKey(
    List<int> pubKey, {
    List<int>? pubSkey,
    ADANetwork network = ADANetwork.mainnet,
  }) {
    /// Extract the public spending key (pub_skey) from the arguments.
    pubSkey = AddrKeyValidator.getAddrArg<List<int>>(pubSkey, "pubKey");

    /// Validate and retrieve public keys.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    final pubSkeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubSkey);

    // Compute key hashes for public spending and public delegation keys.
    final pubKeyHash = AdaShelleyAddrUtils.keyHash(
      pubKeyObj.compressed.sublist(1),
    );
    final pubSkeyHash = AdaShelleyAddrUtils.keyHash(
      pubSkeyObj.compressed.sublist(1),
    );

    return AdaShelleyAddrUtils.encode(
      credential: AdaStakeCredential(
        hash: pubKeyHash,
        type: AdaStakeCredType.key,
      ),
      network: network,
      hrp: AdaShelleyAddrUtils.getAddressHrp(network),
      stakeCredential: AdaStakeCredential(
        hash: pubSkeyHash,
        type: AdaStakeCredType.key,
      ),
      type: ADAAddressType.base,
    );
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley staking address.
class AdaShelleyStakingAddrDecoder
    implements BlockchainAddressDecoder<List<int>> {
  /// Blockchain address decoder for Ada Shelley staking addresses.
  /// This decoder is used to decode staking addresses based on network tag and address data.
  @override
  List<int> decodeAddr(String addr, {ADANetwork network = ADANetwork.mainnet}) {
    /// Decode the provided address using the staking network tag's address prefix.
    final addrDecBytes = Bech32Decoder.decode(
      AdaShelleyAddrUtils.getRewardAddressHrp(network),
      addr,
    );

    /// Validate the length of the decoded bytes and remove the prefix.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.blake2b224DigestSize + 1,
    );

    /// Encode the address prefix based on the reward header type and network tag.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
      ADAAddressType.reward,
      network.value,
      AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4),
    );

    /// Return the final decoded address by removing the prefix and converting it to bytes.
    return AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Ada Shelley staking address.
class AdaShelleyStakingAddrEncoder implements BlockchainAddressEncoder {
  String encodeCredential(
    AdaStakeCredential credential, {
    ADANetwork network = ADANetwork.mainnet,
  }) {
    return AdaShelleyAddrUtils.encode(
      credential: credential,
      network: network,
      hrp: AdaShelleyAddrUtils.getRewardAddressHrp(network),
      type: ADAAddressType.reward,
    );
  }

  /// Blockchain address encoder for Ada Shelley staking addresses.
  /// This encoder is used to create staking addresses based on the network tag and public key.
  @override
  String encodeKey(
    List<int> pubKey, {
    ADANetwork network = ADANetwork.mainnet,
  }) {
    /// Validate and get the Ed25519 public key object from the provided bytes.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    /// Compute the public key hash based on the compressed key bytes.
    final pubKeyHash = AdaShelleyAddrUtils.keyHash(
      pubKeyObj.compressed.sublist(1),
    );
    return AdaShelleyAddrUtils.encode(
      credential: AdaStakeCredential(
        hash: pubKeyHash,
        type: AdaStakeCredType.key,
      ),
      network: network,
      hrp: AdaShelleyAddrUtils.getRewardAddressHrp(network),
      type: ADAAddressType.reward,
    );
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley address.
class AdaShelleyEnterpriseDecoder
    implements BlockchainAddressDecoder<List<int>> {
  /// Blockchain address decoder for Ada Shelley addresses.
  /// This decoder is used to decode payment addresses based on the network tag and address format.
  @override
  List<int> decodeAddr(String addr, {ADANetwork network = ADANetwork.mainnet}) {
    // Decode the provided Bech32 address.
    final addrDecBytes = Bech32Decoder.decode(
      AdaShelleyAddrUtils.getAddressHrp(network),
      addr,
    );

    /// Validate the byte length of the decoded address.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.blake2b224DigestSize + 1,
    );

    /// Encode the address prefix based on the payment header type and network tag.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
      ADAAddressType.enterprise,
      network.value,
      AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4),
    );
    return AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte);
  }
}

class AdaShelleyEnterpriseAddrEncoder implements BlockchainAddressEncoder {
  String encodeCredential(
    AdaStakeCredential credential, {
    ADANetwork network = ADANetwork.mainnet,
  }) {
    return AdaShelleyAddrUtils.encode(
      credential: credential,
      network: network,
      hrp: AdaShelleyAddrUtils.getAddressHrp(network),
      type: ADAAddressType.enterprise,
    );
  }

  /// Blockchain address encoder for Ada Shelley addresses.
  /// This encoder is used to create addresses based on public and private key pairs.
  @override
  String encodeKey(
    List<int> pubKey, {
    ADANetwork network = ADANetwork.mainnet,
  }) {
    /// Validate and retrieve public keys.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);

    // Compute key hashes for public spending and public delegation keys.
    final pubKeyHash = AdaShelleyAddrUtils.keyHash(
      pubKeyObj.compressed.sublist(1),
    );

    return AdaShelleyAddrUtils.encode(
      credential: AdaStakeCredential(
        hash: pubKeyHash,
        type: AdaStakeCredType.key,
      ),
      network: network,
      hrp: AdaShelleyAddrUtils.getAddressHrp(network),
      type: ADAAddressType.enterprise,
    );
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Ada Shelley address.
class AdaShelleyPointerDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Blockchain address decoder for Ada Shelley addresses.
  /// This decoder is used to decode payment addresses based on the network tag and address format.
  @override
  List<int> decodeAddr(String addr, {ADANetwork network = ADANetwork.mainnet}) {
    // Decode the provided Bech32 address.
    final addrDecBytes = Bech32Decoder.decode(
      AdaShelleyAddrUtils.getAddressHrp(network),
      addr,
    );

    /// Validate the byte length of the decoded address.
    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.blake2b224DigestSize + 1,
      minLength: QuickCrypto.blake2b224DigestSize + 4,
    );

    /// validate pointer data
    Pointer.fromBytes(
      addrDecBytes.sublist(QuickCrypto.blake2b224DigestSize + 1),
    );

    /// Encode the address prefix based on the payment header type and network tag.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
      ADAAddressType.pointer,
      network.value,
      AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4),
    );
    return AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte);
  }
}

class AdaPointerAddrEncoder implements BlockchainAddressEncoder {
  String encodeCredential(
    AdaStakeCredential credential, {
    ADANetwork network = ADANetwork.mainnet,
    Pointer? pointer,
  }) {
    pointer = AddrKeyValidator.getAddrArg<Pointer>(pointer, "pointer");

    return AdaShelleyAddrUtils.encode(
      credential: credential,
      pointer: pointer,
      network: network,
      hrp: AdaShelleyAddrUtils.getAddressHrp(network),
      type: ADAAddressType.pointer,
    );
  }

  @override
  String encodeKey(
    List<int> pubKey, {
    ADANetwork network = ADANetwork.mainnet,
    Pointer? pointer,
  }) {
    // final pointer = AddrKeyValidator.getAddrArg<Pointer>(pointer, "pointer");

    /// Validate and retrieve public keys.
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    // Compute key hashes for public spending and public delegation keys.
    final pubKeyHash = AdaShelleyAddrUtils.keyHash(
      pubKeyObj.compressed.sublist(1),
    );
    return AdaShelleyAddrUtils.encode(
      credential: AdaStakeCredential(
        hash: pubKeyHash,
        type: AdaStakeCredType.key,
      ),
      network: network,
      pointer: AddrKeyValidator.getAddrArg<Pointer>(pointer, "pointer"),
      hrp: AdaShelleyAddrUtils.getAddressHrp(network),
      type: ADAAddressType.pointer,
    );
  }
}
