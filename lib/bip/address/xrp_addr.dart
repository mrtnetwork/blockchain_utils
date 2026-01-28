import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'exception/exception.dart';
import 'p2pkh_addr.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

/// Constants related to XRP (Ripple) addresses.
class _XRPAddressConst {
  /// The length of the tag included in X-addresses.
  static const int xAddressTagLength = 9;

  /// The prefix for mainnet X-addresses.
  static const List<int> _xAddressPrefixMain = [0x05, 0x44];

  /// The prefix for testnet X-addresses.
  static const List<int> _xAddressPrefixTest = [0x04, 0x93];

  /// The length of the X-address prefix.
  static const int xAddressPrefixLength = 2;
}

class XRPXAddressDecodeResult {
  final List<int> bytes;
  final int? tag;
  final bool isTestnet;
  XRPXAddressDecodeResult({
    required List<int> bytes,
    required this.tag,
    required this.isTestnet,
  }) : bytes = bytes.asImmutableBytes;
}

class XRPAddressUtils {
  /// Generates an XRP (Ripple) address from the provided address hash.
  static String hashToAddress(List<int> addrHash) {
    if (addrHash.length != QuickCrypto.hash160DigestSize) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid address bytes.",
      );
    }

    return Base58Encoder.checkEncode([
      ...AddrKeyValidator.getConfigArg<List<int>>(
        CoinsConf.ripple.params.p2pkhNetVer,
        "p2pkhNetVer",
      ),
      ...addrHash,
    ], Base58Alphabets.ripple);
  }

  /// Converts a public key represented as a list of bytes into an XRP (Ripple) address.
  static String _toAddress(List<int> publicKeyBytes) {
    final hash160 = QuickCrypto.hash160(publicKeyBytes);

    return hashToAddress(hash160);
  }

  /// Generates an XRP (Ripple) X-address from the provided address hash, X-Address prefix, and optional tag.
  static String hashToXAddress(
    List<int> addrHash,
    List<int> xAddrPrefix,
    int? tag,
  ) {
    if (tag != null && tag > BinaryOps.mask32) {
      throw AddressConverterException.addressBytesValidationFailed(
        reason: "Invalid address tag.",
      );
    }
    List<int> addrBytes = [...xAddrPrefix, ...addrHash];
    final List<int> tagBytes = BinaryOps.writeUint64LE(tag ?? 0);
    addrBytes = [...addrBytes, tag == null ? 0 : 1, ...tagBytes];
    return Base58Encoder.checkEncode(addrBytes, Base58Alphabets.ripple);
  }

  /// Decodes an X-Address and extracts the address hash and, if present, the tag.
  static XRPXAddressDecodeResult decodeXAddress(
    String addr,
    List<int>? prefix,
  ) {
    final List<int> addrDecBytes = Base58Decoder.checkDecode(
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

    if (prefix != null) {
      if (!BytesUtils.bytesEqual(prefix, prefixBytes)) {
        throw AddressConverterException.addressValidationFailed(
          reason: "Invalid address checksum.",
        );
      }
    } else {
      if (!BytesUtils.bytesEqual(
            prefixBytes,
            _XRPAddressConst._xAddressPrefixMain,
          ) &&
          !BytesUtils.bytesEqual(
            prefixBytes,
            _XRPAddressConst._xAddressPrefixTest,
          )) {
        throw AddressConverterException.addressValidationFailed(
          reason: "Invalid address prefix.",
        );
      }
    }

    final List<int> addrHash = addrDecBytes.sublist(
      prefixBytes.length,
      QuickCrypto.hash160DigestSize + prefixBytes.length,
    );

    List<int> tagBytes = addrDecBytes.sublist(
      addrDecBytes.length - _XRPAddressConst.xAddressTagLength,
    );
    final int tagFlag = tagBytes[0];
    if (tagFlag != 0 && tagFlag != 1) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Invalid address tag.",
      );
    }
    tagBytes = tagBytes.sublist(1);
    if (tagFlag == 0 && !BytesUtils.bytesEqual(tagBytes, List.filled(8, 0))) {
      throw AddressConverterException.addressValidationFailed(
        reason: "Invalid address tag.",
      );
    }

    int? tag;
    if (tagFlag == 1) {
      tag = BinaryOps.readUint32LE(tagBytes);
    }

    return XRPXAddressDecodeResult(
      bytes: addrHash,
      tag: tag,
      isTestnet: BytesUtils.bytesEqual(
        prefixBytes,
        _XRPAddressConst._xAddressPrefixTest,
      ),
    );
  }

  /// Converts a classic XRP address to an X-Address.
  static String classicToXAddress(
    String addr,
    List<int> xAddrPrefix, {
    int? tag,
  }) {
    final addrHash = XrpAddrDecoder().decodeAddr(addr);
    return hashToXAddress(addrHash, xAddrPrefix, tag);
  }

  /// Converts an X-Address to a classic XRP address.
  static String xAddressToClassic(String xAddrress, List<int> xAddrPrefix) {
    final decode = XrpXAddrDecoder().decodeAddr(
      xAddrress,
      addrPrefix: xAddrPrefix,
    );

    return Base58Encoder.checkEncode([
      ...AddrKeyValidator.getConfigArg<List<int>>(
        CoinsConf.ripple.params.p2pkhNetVer,
        "p2pkhNetVer",
      ),
      ...decode,
    ], Base58Alphabets.ripple);
  }

  /// Decodes the given address, whether it is an X-Address or a classic address, and returns the address bytes.
  static List<int> decodeAddress(String address, {List<int>? xAddrPrefix}) {
    try {
      try {
        final decode = XrpAddrDecoder().decodeAddr(address);
        return decode;
      } catch (e) {
        final xAddr = decodeXAddress(address, xAddrPrefix);
        return xAddr.bytes;
      }
    } catch (e) {
      throw AddressConverterException.addressValidationFailed();
    }
  }

  /// Checks whether the given address is an X-Address.
  static bool isXAddress(String? address) {
    try {
      decodeXAddress(address!, null);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks whether the given address is a classic XRP address.
  static bool isClassicAddress(String? address) {
    try {
      XrpAddrDecoder().decodeAddr(address!);
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
    final addrHash = decodeXAddress(address, null).bytes;
    return hashToAddress(addrHash);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for ripple (XRP) blockchain addresses.
class XrpAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Decodes a Ripple (XRP) blockchain address into its byte representation.
  @override
  List<int> decodeAddr(String addr) {
    /// Delegate the decoding process to P2PKHAddrDecoder with specific parameters.
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

/// Implementation of the [BlockchainAddressEncoder] for ripple (XRP) blockchain addresses.
class XrpAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes a Ripple (XRP) public key as a blockchain address.
  @override
  String encodeKey(
    List<int> pubKey, {
    EllipticCurveTypes pubKeyType = EllipticCurveTypes.secp256k1,
  }) {
    if ((pubKeyType != EllipticCurveTypes.secp256k1 &&
        pubKeyType != EllipticCurveTypes.ed25519)) {
      throw AddressConverterException.addressKeyValidationFailed(
        reason: "Unsupported ${pubKeyType.name} public key.",
      );
    }
    if (pubKeyType == EllipticCurveTypes.secp256k1) {
      return P2PKHAddrEncoder().encodeKey(
        pubKey,
        alphabet: Base58Alphabets.ripple,
        netVersion: AddrKeyValidator.getConfigArg<List<int>>(
          CoinsConf.ripple.params.p2pkhNetVer,
          "p2pkhNetVer",
        ),
      );
    }
    AddrKeyValidator.validateAndGetEd25519Key(pubKey);
    return XRPAddressUtils._toAddress(pubKey);
  }
}

/// Implementation of the [BlockchainAddressEncoder] for ripple (XRP) blockchain addresses.
class XrpXAddrEncoder implements BlockchainAddressEncoder {
  /// Encodes the public key into a Ripple (XRP) X-Address.
  @override
  String encodeKey(List<int> pubKey, {List<int>? addrPrefix, int? tag}) {
    addrPrefix = AddrKeyValidator.getAddrArg<List<int>>(
      addrPrefix,
      "addrPrefix",
    );

    List<int> pubKeyBytes;

    try {
      /// Validate and process the public key as a Secp256k1 key.
      pubKeyBytes =
          AddrKeyValidator.validateAndGetSecp256k1Key(pubKey).compressed;
    } catch (e) {
      AddrKeyValidator.validateAndGetEd25519Key(pubKey);
      pubKeyBytes = pubKey;
    }

    /// Calculate the hash160 of the public key.
    final hash160 = QuickCrypto.hash160(pubKeyBytes);

    return XRPAddressUtils.hashToXAddress(hash160, addrPrefix, tag);
  }
}

/// Implementation of the [BlockchainAddressDecoder] for decoding Ripple (XRP) blockchain addresses.
class XrpXAddrDecoder implements BlockchainAddressDecoder<List<int>> {
  /// Validates and decodes the given Ripple (XRP) X-address.
  @override
  List<int> decodeAddr(String addr, {List<int>? addrPrefix}) {
    addrPrefix = AddrKeyValidator.getAddrArg<List<int>>(
      addrPrefix,
      "addrPrefix",
    );
    return XRPAddressUtils.decodeXAddress(addr, addrPrefix).bytes;
  }
}
