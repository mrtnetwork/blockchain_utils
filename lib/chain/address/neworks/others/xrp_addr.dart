import 'package:blockchain_utils/chain/address/protocol/p2pkh_addr.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to XRP (Ripple) addresses.
class _XRPAddressConst {
  /// The length of the tag included in X-addresses.
  static const int xAddressTagLength = 9;

  /// The length of the X-address prefix.
  static const int xAddressPrefixLength = 2;
  static const int classAddressMaxLength = 35;

  static const Map<ChainType, List<int>> prefixes = {
    ChainType.testnet: [0x04, 0x93],
    ChainType.mainnet: [0x05, 0x44],
  };
}

enum XRPAddressType {
  classic(0),
  xAddress(1);

  final int value;
  const XRPAddressType(this.value);
  static XRPAddressType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse:
          () => throw CoreErrors.addressValidationFailed(
            reason: "Invalid XRP address type.",
            details: {"got": value?.toString()},
          ),
    );
  }

  bool get isXAddress => this == xAddress;
}

class XRPAddressDecodeResult {
  final BuBytes hash;
  final int? tag;
  final ChainType? chainType;
  final String classicAddress;
  factory XRPAddressDecodeResult.classic({
    required List<int> hash,
    required String address,
  }) {
    return XRPAddressDecodeResult._(bytes: hash, classicAddress: address);
  }
  factory XRPAddressDecodeResult.x({
    required List<int> hash,
    required ChainType chainType,
    required String classicAddress,
    int? tag,
  }) {
    return XRPAddressDecodeResult._(
      bytes: hash,
      chainType: chainType,
      classicAddress: classicAddress,

      tag: tag,
    );
  }
  XRPAddressDecodeResult._({
    required List<int> bytes,
    required this.classicAddress,
    this.tag,
    this.chainType,
  }) : hash =
           (bytes.length == QuickCrypto.hash160DigestSize
                   ? bytes
                   : throw CoreErrors.addressBytesValidationFailed(
                     reason: "Invalid hash bytes length.",
                     details: {
                       "expected": QuickCrypto.hash160DigestSize.toString(),
                       "got": bytes.length.toString(),
                     },
                   ))
               .asImmutableBytes;

  XRPAddressType get type =>
      chainType != null ? XRPAddressType.xAddress : XRPAddressType.classic;
}

class XRPXAddressEncodeResult {
  final BuBytes hash;
  final int? tag;
  final ChainType chainType;
  final String xAddress;
  final String classicAddress;
  XRPXAddressEncodeResult({
    required List<int> hash,
    this.tag,
    required this.chainType,
    required this.xAddress,
    required this.classicAddress,
  }) : hash = hash.asImmutableBytes;
}

class XRPAddressUtils {
  /// Generates an XRP (Ripple) address from the provided address hash.
  static String hashToAddress(List<int> addrHash) {
    if (addrHash.length != QuickCrypto.hash160DigestSize) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid address bytes.",
      );
    }

    return Base58Encoder.encodeWithChecksum([
      ...AddrKeyValidator.getConfigArg<List<int>>(
        CoinsConf.ripple.params.p2pkhNetVer,
        "p2pkhNetVer",
      ),
      ...addrHash,
    ], Base58Alphabets.ripple);
  }

  /// Generates an XRP (Ripple) X-address from the provided address hash, X-Address prefix, and optional tag.
  static String hashToXAddress(
    List<int> addrHash,
    ChainType chainType,
    int? tag,
  ) {
    if (addrHash.length != QuickCrypto.hash160DigestSize) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid address bytes.",
      );
    }

    if (tag != null && tag > BinaryOps.mask32) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Invalid address tag.",
      );
    }
    final xAddrPrefix = _XRPAddressConst.prefixes[chainType]!;
    List<int> addrBytes = [...xAddrPrefix, ...addrHash];
    final List<int> tagBytes = BinaryOps.writeUint64LE(tag ?? 0);
    addrBytes = [...addrBytes, tag == null ? 0 : 1, ...tagBytes];
    return Base58Encoder.encodeWithChecksum(addrBytes, Base58Alphabets.ripple);
  }

  /// Decodes an X-Address and extracts the address hash and, if present, the tag.
  static XRPAddressDecodeResult decodeXAddress(String addr) {
    final List<int> addrDecBytes = Base58Decoder.decodeWithChecksum(
      addr,
      Base58Alphabets.ripple,
    );

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      QuickCrypto.hash160DigestSize +
          _XRPAddressConst.xAddressPrefixLength +
          _XRPAddressConst.xAddressTagLength,
    );

    final prefixBytes = addrDecBytes.sublist(
      0,
      _XRPAddressConst.xAddressPrefixLength,
    );
    final prefix = _XRPAddressConst.prefixes.entries.firstWhere(
      (e) => BytesUtils.bytesEqual(e.value, prefixBytes),
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Invalid address prefix bytes.",
              ),
    );

    final List<int> addrHash = addrDecBytes.sublist(
      prefixBytes.length,
      QuickCrypto.hash160DigestSize + prefixBytes.length,
    );

    List<int> tagBytes = addrDecBytes.sublist(
      addrDecBytes.length - _XRPAddressConst.xAddressTagLength,
    );
    final int tagFlag = tagBytes[0];
    if (tagFlag != 0 && tagFlag != 1) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address tag.",
      );
    }
    tagBytes = tagBytes.sublist(1);
    if (tagFlag == 0 && !BytesUtils.bytesEqual(tagBytes, List.filled(8, 0))) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address tag.",
      );
    }

    int? tag;
    if (tagFlag == 1) {
      tag = BinaryOps.readUint32LE(tagBytes);
    }

    return XRPAddressDecodeResult.x(
      hash: addrHash,
      tag: tag,
      chainType: prefix.key,
      classicAddress: hashToAddress(addrHash),
    );
  }

  /// Converts a classic XRP address to an X-Address.
  static String classicToXAddress(
    String addr,
    ChainType chainType, {
    int? tag,
  }) {
    final addrHash = XrpAddrDecoder().decodeAddr(addr);
    return hashToXAddress(addrHash, chainType, tag);
  }

  /// Converts an X-Address to a classic XRP address.
  static String xAddressToClassic(String xAddrress, {ChainType? chainType}) {
    final decode = XrpXAddrDecoder().decodeAddr(
      xAddrress,
      chainType: chainType,
    );
    return hashToAddress(decode);
  }

  /// Decodes the given address, whether it is an X-Address or a classic address, and returns the address bytes.
  ///
  /// Throws [BuError] if the address is neither a valid
  /// classic nor a valid X-Address (or the chain type does not match).
  static XRPAddressDecodeResult decodeAddress(
    String address, {
    ChainType? chainType,
  }) {
    BuError? classicError;
    try {
      if (address.length <= _XRPAddressConst.classAddressMaxLength) {
        final decode = XrpAddrDecoder().decodeAddr(address);
        return XRPAddressDecodeResult.classic(hash: decode, address: address);
      }
    } on BuError catch (e) {
      classicError = e;
    }
    try {
      final decode = decodeXAddress(address);
      if (chainType == null || chainType == decode.chainType) {
        return decode;
      }
    } on BuError catch (e) {
      throw CoreErrors.addressValidationFailed(
        reason: classicError?.message ?? e.message,
        details: {...?classicError?.details, ...?e.details},
      );
    }
    throw CoreErrors.addressValidationFailed(
      reason:
          classicError?.message ?? "Address is neither classic nor X-Address.",
      details: classicError?.details,
    );
  }

  /// Checks whether the given address is an X-Address.
  static bool isXAddress(String? address) {
    if (address == null ||
        address.length <= _XRPAddressConst.classAddressMaxLength) {
      return false;
    }
    try {
      decodeXAddress(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks whether the given address is a classic XRP address.
  static bool isClassicAddress(String? address) {
    if (address == null ||
        address.length > _XRPAddressConst.classAddressMaxLength) {
      return false;
    }
    try {
      XrpAddrDecoder().decodeAddr(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ensures that the provided address is a classic XRP address, and if not, converts it to a classic address.
  static String ensureClassicAddress(String address) {
    if (isClassicAddress(address)) {
      return address;
    }
    final addrHash = decodeXAddress(address).hash;
    return hashToAddress(addrHash);
  }

  static BuBytes keyToHash(List<int> publicKey, {CryptoKeyType? type}) {
    List<int> pubkeyBytes = switch (type) {
      CryptoKeyType.secp256k1 => AddrKeyValidator.validateAndGetSecp256k1Key(
        publicKey,
      ).toBytes(mode: CryptoKeyEncoding.base),
      CryptoKeyType.ed25519 => [
        ...Ed25519KeysConst.xrpPubKeyPrefix,
        ...AddrKeyValidator.validateAndGetEd25519KeyBytes(publicKey),
      ],
      null => (() {
        try {
          return AddrKeyValidator.validateAndGetSecp256k1Key(
            publicKey,
          ).toBytes(mode: CryptoKeyEncoding.base);
        } catch (e) {
          return [
            ...Ed25519KeysConst.xrpPubKeyPrefix,
            ...AddrKeyValidator.validateAndGetEd25519KeyBytes(publicKey),
          ];
        }
      }()),
      _ =>
        throw CoreErrors.addressBytesValidationFailed(
          reason: "Unsupported ${type.name} public key",
        ),
    };
    return QuickCrypto.hash160(pubkeyBytes).asImmutableBytes;
  }
}

/// Decodes a classic Ripple (XRP) address.
class XrpAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr) {
    return P2PKHAddrDecoder().decodeAddr(
      addr,
      netVersion: AddrKeyValidator.getConfigArg(
        CoinsConf.ripple.params.p2pkhNetVer,
        "p2pkhNetVer",
      ),
      alphabet: Base58Alphabets.ripple,
    );
  }
}

/// Encodes a classic Ripple (XRP) address.
class XrpAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes an already-hashed address.
  String encodeHash(List<int> bytes) {
    AddrDecUtils.validateBytesLength(bytes, QuickCrypto.hash160DigestSize);
    return XRPAddressUtils.hashToAddress(bytes);
  }

  @override
  String encodeKey(List<int> pubKey, {CryptoKeyType? pubKeyType}) {
    final hash160 = XRPAddressUtils.keyToHash(pubKey, type: pubKeyType);
    return XRPAddressUtils.hashToAddress(hash160);
  }
}

/// Encodes a Ripple (XRP) X-Address.
class XrpXAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes an already-hashed address.
  String encodeHash(
    List<int> bytes, {
    int? tag,
    ChainType chainType = ChainType.mainnet,
  }) {
    AddrDecUtils.validateBytesLength(bytes, QuickCrypto.hash160DigestSize);
    return XRPAddressUtils.hashToXAddress(bytes, chainType, tag);
  }

  XRPXAddressEncodeResult encodeKeyWithClassicAddress(
    List<int> pubKey, {
    int? tag,
    ChainType chainType = ChainType.mainnet,
    CryptoKeyType? pubKeyType,
  }) {
    final hash160 = XRPAddressUtils.keyToHash(pubKey, type: pubKeyType);
    return XRPXAddressEncodeResult(
      hash: hash160,
      chainType: chainType,
      xAddress: XRPAddressUtils.hashToXAddress(hash160, chainType, tag),
      classicAddress: XRPAddressUtils.hashToAddress(hash160),
    );
  }

  @override
  String encodeKey(
    List<int> pubKey, {
    int? tag,
    ChainType chainType = ChainType.mainnet,
    CryptoKeyType? pubKeyType,
  }) {
    final hash160 = XRPAddressUtils.keyToHash(pubKey, type: pubKeyType);
    return XRPAddressUtils.hashToXAddress(hash160, chainType, tag);
  }
}

/// Decodes a Ripple (XRP) X-Address.
class XrpXAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {ChainType? chainType}) {
    final decode = XRPAddressUtils.decodeXAddress(addr);
    if (chainType != null && decode.chainType != chainType) {
      throw CoreErrors.addressValidationFailed(
        reason: "Mismatch chain type.",
      );
    }
    return decode.hash;
  }
}
