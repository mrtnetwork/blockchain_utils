import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/chain/address/neworks/ada/src/ada_address_type.dart';
import 'package:blockchain_utils/chain/address/neworks/ada/src/network.dart';

/// A Cardano pointer address's chain location (slot, tx index, cert index).
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

  /// Decodes a pointer from its variable-length-natural-encoded bytes.
  factory Pointer.fromBytes(List<int> data) {
    final slot = BigintUtils.variableNatDecode(data);
    final txIndex = BigintUtils.variableNatDecode(data.sublist(slot.$2));
    final certIndex = BigintUtils.variableNatDecode(
      data.sublist(slot.$2 + txIndex.$2),
    );
    return Pointer(slot: slot.$1, txIndex: txIndex.$1, certIndex: certIndex.$1);
  }

  /// Encodes this pointer as variable-length naturals.
  BuBytes toBytes() {
    return BuBytes([
      ...BigintUtils.variableNatEncode(slot),
      ...BigintUtils.variableNatEncode(txIndex),
      ...BigintUtils.variableNatEncode(certIndex),
    ]);
  }
}

/// Whether a Cardano stake/payment credential is a key hash or script hash.
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

/// A Cardano stake or payment credential: its type plus hash bytes.
class AdaStakeCredential {
  final AdaStakeCredType type;
  final BuBytes hash;
  AdaStakeCredential._(this.type, List<int> hash)
    : hash = hash.asImmutableBytes;

  factory AdaStakeCredential({
    required List<int> hash,
    required AdaStakeCredType type,
  }) {
    if (hash.length != QuickCrypto.blake2b224DigestSize) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid bytes length.",
        details: {
          "Expected": QuickCrypto.blake2b224DigestSize.toString(),
          "length": hash.length.toString(),
        },
      );
    }
    return AdaStakeCredential._(type, hash);
  }
}

/// Utility class for encoding and decoding Ada Shelley addresses.
class AdaShelleyAddrUtils {
  /// HRP for payment addresses on [network].
  static String getAddressHrp(ADANetwork network) {
    return AddrKeyValidator.getConfigArg(switch (network) {
      ADANetwork.mainnet => CoinsConf.cardanoMainNet.params.addrHrp,
      _ => CoinsConf.cardanoTestNet.params.addrHrp,
    }, "addrHrp");
  }

  /// HRP for reward/staking addresses on [network].
  static String getRewardAddressHrp(ADANetwork network) {
    return AddrKeyValidator.getConfigArg(switch (network) {
      ADANetwork.mainnet => CoinsConf.cardanoMainNet.params.stakingAddrHrp,
      _ => CoinsConf.cardanoTestNet.params.stakingAddrHrp,
    }, "stakingAddrHrp");
  }

  /// Computes the key hash for the given public key bytes.
  /// Key hash is calculated using the Blake2b224 hash function.
  static BuBytes keyHash(List<int> pubKeyBytes) {
    return QuickCrypto.blake2b224Hash(pubKeyBytes);
  }

  /// Builds the 1-byte address header from its type, network tag, and
  /// credential type(s) (see CIP-19).
  static BuBytes encodePrefix(
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

  /// Extracts the network tag (low nibble) from a header byte.
  static int decodeNetworkTag(int header) {
    return header & 0x0F;
  }

  /// Reads the credential type from the given bit of a header byte.
  static AdaStakeCredType decodeCred(int header, int bit) {
    return header & (1 << bit) == 0
        ? AdaStakeCredType.key
        : AdaStakeCredType.script;
  }

  /// Builds a Bech32 address from a credential (+ optional stake
  /// credential or pointer).
  static String encode({
    required AdaStakeCredential credential,
    AdaStakeCredential? stakeCredential,
    Pointer? pointer,
    required ADANetwork network,
    required String hrp,
    required ADAAddressType type,
  }) {
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

  /// Re-encodes raw address bytes as their canonical Bech32 string.
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

/// Decodes an Ada Shelley base (payment) address.
class AdaShelleyAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {ADANetwork network = ADANetwork.mainnet}) {
    final addrDecBytes = Bech32Decoder.decode(
      AdaShelleyAddrUtils.getAddressHrp(network),
      addr,
    );

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      (QuickCrypto.blake2b224DigestSize * 2) + 1,
    );

    // Re-derive the header from the decoded credential bits, then check it
    // matches what's actually in the address.
    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
      ADAAddressType.base,
      network.value,
      AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4),
      stakeType: AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 5),
    );
    return BuBytes(
      AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte),
    );
  }
}

/// Encodes an Ada Shelley base (payment) address.
class AdaShelleyAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes from already-hashed credentials.
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

  @override
  String encodeKey(
    List<int> pubKey, {
    List<int>? pubSkey,
    ADANetwork network = ADANetwork.mainnet,
  }) {
    pubSkey = AddrKeyValidator.getAddrArg<List<int>>(pubSkey, "pubSkey");

    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
    final pubSkeyObj = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubSkey);

    // Hash both the payment and staking (delegation) keys.
    final pubKeyHash = AdaShelleyAddrUtils.keyHash(pubKeyObj);
    final pubSkeyHash = AdaShelleyAddrUtils.keyHash(pubSkeyObj);

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

/// Decodes an Ada Shelley reward (staking) address.
class AdaShelleyStakingAddrDecoder
    implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {ADANetwork network = ADANetwork.mainnet}) {
    final addrDecBytes = Bech32Decoder.decode(
      AdaShelleyAddrUtils.getRewardAddressHrp(network),
      addr,
    );

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.blake2b224DigestSize + 1,
    );

    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
      ADAAddressType.reward,
      network.value,
      AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4),
    );
    return BuBytes(
      AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte),
    );
  }
}

/// Encodes an Ada Shelley reward (staking) address.
class AdaShelleyStakingAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes from an already-hashed credential.
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

  @override
  String encodeKey(
    List<int> pubKey, {
    ADANetwork network = ADANetwork.mainnet,
  }) {
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
    final pubKeyHash = AdaShelleyAddrUtils.keyHash(pubKeyObj);
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

/// Decodes an Ada Shelley enterprise (payment-only, no staking) address.
class AdaShelleyEnterpriseDecoder
    implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {ADANetwork network = ADANetwork.mainnet}) {
    final addrDecBytes = Bech32Decoder.decode(
      AdaShelleyAddrUtils.getAddressHrp(network),
      addr,
    );

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.blake2b224DigestSize + 1,
    );

    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
      ADAAddressType.enterprise,
      network.value,
      AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4),
    );
    return BuBytes(
      AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte),
    );
  }
}

/// Encodes an Ada Shelley enterprise (payment-only) address.
class AdaShelleyEnterpriseAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes from an already-hashed credential.
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

  @override
  String encodeKey(
    List<int> pubKey, {
    ADANetwork network = ADANetwork.mainnet,
  }) {
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
    final pubKeyHash = AdaShelleyAddrUtils.keyHash(pubKeyObj);

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

/// Decodes an Ada Shelley pointer address.
class AdaShelleyPointerDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {ADANetwork network = ADANetwork.mainnet}) {
    final addrDecBytes = Bech32Decoder.decode(
      AdaShelleyAddrUtils.getAddressHrp(network),
      addr,
    );

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.blake2b224DigestSize + 1,
      minLength: QuickCrypto.blake2b224DigestSize + 4,
    );

    // Validate the pointer part parses, without keeping the result.
    Pointer.fromBytes(
      addrDecBytes.sublist(QuickCrypto.blake2b224DigestSize + 1),
    );

    final prefixByte = AdaShelleyAddrUtils.encodePrefix(
      ADAAddressType.pointer,
      network.value,
      AdaShelleyAddrUtils.decodeCred(addrDecBytes[0], 4),
    );
    return BuBytes(
      AddrDecUtils.validateAndRemovePrefixBytes(addrDecBytes, prefixByte),
    );
  }
}

/// Encodes an Ada Shelley pointer address.
class AdaPointerAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes from an already-hashed credential.
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
    final pubKeyObj = AddrKeyValidator.validateAndGetEd25519KeyBytes(pubKey);
    final pubKeyHash = AdaShelleyAddrUtils.keyHash(pubKeyObj);
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
