import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils/chain/address/types/decoder.dart';
import 'package:blockchain_utils/chain/address/types/encoder.dart';
import 'package:blockchain_utils/chain/address/utils/addr_dec_utils.dart';
import 'package:blockchain_utils/chain/address/utils/addr_key_validator.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/encoding/bech32/bech32.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to P2TR (Pay-to-Taproot) addresses.
class P2TRConst {
  /// SegWit witness version used by P2TR (Taproot) addresses.
  static const int witnessVer = 1;

  /// Tapscript leaf version, used when tagged-hashing a script leaf.
  static const int leafVersionTapScript = 0xc0;
}

/// Utility class for working with P2TR (Pay-to-Taproot) addresses and operations.
class P2TRUtils {
  /// BIP-340 tagged hash: SHA256(SHA256(tag) || SHA256(tag) || dataBytes).
  /// [tag] may be a String (hashed first) or already-hashed bytes.
  static List<int> taggedHash(dynamic tag, List<int> dataBytes) {
    // and invalid tag types silently passed through.
    if (tag is! String && tag is! List<int>) {
      throw CoreErrors.missingOrInvalidAddressArguments(
        reason: "Invalid address tag format.",
      );
    }
    final List<int> tagHash =
        tag is String ? QuickCrypto.sha256Hash(StringUtils.encode(tag)) : tag;
    return QuickCrypto.sha256Hash([...tagHash, ...tagHash, ...dataBytes]);
  }

  /// Computes the TapTweak hash for [pubPoint].
  static List<int> hashTapTweak(Secp256k1Point pubPoint) {
    final tapTweakSHA256 = BytesUtils.fromHexString(
      "e80fe1639c9ca050e3af1b39c143c63e429cbceb15d940fbb5c5a1f4af57c5e9",
    );
    return P2TRUtils.taggedHash(tapTweakSHA256, pubPoint.toXOnly());
  }

  /// Recovers the secp256k1 point with even Y for 32-byte big-endian
  /// x-coordinate [xBytes] (as used by BIP-340/Taproot).
  /// Throws [AddressConverterException] if [xBytes] is not a valid
  /// curve x-coordinate (wrong length, out of range, or non-residue).
  static Secp256k1Point liftX(List<int> xBytes) {
    try {
      return Secp256k1AffinePoint.liftX(xBytes).toCurve();
    } catch (_) {
      throw CoreErrors.addressKeyValidationFailed(
        reason: "Invalid public key.",
      );
    }
  }

  static List<int> _tapleafTaggedHash(List<int> script) {
    final scriptBytes = IntUtils.prependVarint(script);

    final part = [P2TRConst.leafVersionTapScript, ...scriptBytes];
    return taggedHash('TapLeaf', part);
  }

  static List<int> _tapBranchTaggedHash(List<int> a, List<int> b) {
    if (BytesUtils.isLessThanBytes(a, b)) {
      return taggedHash("TapBranch", [...a, ...b]);
    }
    return taggedHash("TapBranch", [...b, ...a]);
  }

  static List<int> _getTagHashedMerkleRoot(dynamic args) {
    if (args is List<int>) {
      final tagged = _tapleafTaggedHash(args);
      return tagged;
    }

    args as List;
    if (args.isEmpty) return <int>[];
    if (args.length == 1) {
      return _getTagHashedMerkleRoot(args.first);
    } else if (args.length == 2) {
      final left = _getTagHashedMerkleRoot(args.first);
      final right = _getTagHashedMerkleRoot(args.last);
      final tap = _tapBranchTaggedHash(left, right);
      return tap;
    }
    throw CoreErrors.missingOrInvalidAddressArguments(
      reason: "Invalid address branch.",
    );
  }

  static List<int> calculateTweek(
    Secp256k1Point pubPoint, {
    List<dynamic>? script,
  }) {
    final keyX = pubPoint.toXOnly();
    if (script == null) {
      final tweek = taggedHash("TapTweak", keyX);
      return tweek;
    }
    final merkleRoot = _getTagHashedMerkleRoot(script);
    final tweek = taggedHash("TapTweak", [...keyX, ...merkleRoot]);
    return tweek;
  }

  static Secp256k1Point tweakPublicKey(
    Secp256k1Point pubPoint, {
    List<dynamic>? script,
  }) {
    final h = calculateTweek(pubPoint, script: script);
    final t = Secp256k1Fr.fromBytesUnchecked(h);
    final n = Secp256k1Point.generator_ * t;
    final outPoint = liftX(pubPoint.toXOnly()) + n;

    return outPoint;
  }
}

/// Decodes a Segwit v1 (P2TR) address.
class P2TRAddrDecoder implements BlockchainAddressDecoder<BuBytes> {
  @override
  BuBytes decodeAddr(String addr, {String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");

    final decode = SegwitBech32Decoder.decode(hrp, addr);
    final witVerGot = decode.$1;
    final addrDecBytes = decode.$2;

    AddrDecUtils.validateBytesLength(
      addrDecBytes,
      EcdsaKeysConst.pubKeyCompressedByteLen - 1,
    );

    if (witVerGot != P2TRConst.witnessVer) {
      throw CoreErrors.addressValidationFailed(
        reason: "Invalid address witness version.",
      );
    }

    return addrDecBytes;
  }
}

/// Encodes a Segwit v1 (P2TR) address.
class P2TRAddrEncoder implements BlockchainAddressEncoder {
  @override
  String encodeKey(List<int> pubKey, {String? hrp}) {
    hrp = AddrKeyValidator.getAddrArg<String>(hrp, "hrp");

    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);
    final point = Secp256k1Point.fromBytes(pubKeyObj.toBytes());
    final tweakedPubKey = P2TRUtils.tweakPublicKey(point).toXOnly();
    return SegwitBech32Encoder.encode(hrp, P2TRConst.witnessVer, tweakedPubKey);
  }
}
