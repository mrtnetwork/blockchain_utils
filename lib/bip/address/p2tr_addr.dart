import 'package:blockchain_utils/bech32/segwit_bech32.dart';
import 'package:blockchain_utils/compare/compare.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/numbers/bigint_utils.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/numbers/int_utils.dart';
import '../../string/string.dart';

/// Constants related to P2TR (Pay-to-Taproot) addresses.
class P2TRConst {
  /// The SHA-256 digest of the TapTweak value.
  ///
  /// This value is used in the construction of P2TR addresses.
  static final List<int> tapTweakSHA256 = BytesUtils.fromHexString(
    "e80fe1639c9ca050e3af1b39c143c63e429cbceb15d940fbb5c5a1f4af57c5e9",
  );

  /// The witness version for P2TR addresses.
  ///
  /// In the context of SegWit-based transactions and P2TR addresses, the witness version
  /// is typically set to 1.
  static const int witnessVer = 1;
  static const int leafVersionTapScript = 0xc0;
}

/// Utility class for working with P2TR (Pay-to-Taproot) addresses and operations.
class P2TRUtils {
  /// Compute a tagged hash for P2TR operations.
  ///
  /// This method takes a tag and data bytes, validates the tag type, and computes
  /// a tagged hash by applying SHA-256 on the tag and data concatenated twice.
  ///
  /// Parameters:
  ///   - tag: The tag for the hash (either bytes or a string).
  ///   - dataBytes: The data bytes to be hashed.
  ///
  /// Returns:
  ///   A List<int> representing the tagged hash.
  ///
  /// Throws:
  ///   - ArgumentException if the tag is not a string or bytes.
  static List<int> taggedHash(dynamic tag, List<int> dataBytes) {
    if (tag! is String && tag! is List<int>) {
      throw ArgumentException("tag must be bytes or string");
    }
    List<int> tagHash =
        tag is String ? QuickCrypto.sha256Hash(StringUtils.encode(tag)) : tag;
    return QuickCrypto.sha256Hash(
        List<int>.from([...tagHash, ...tagHash, ...dataBytes]));
  }

  /// Compute the TapTweak hash for a P2TR address.
  ///
  /// This method computes the TapTweak hash by using the taggedHash method.
  ///
  /// Parameters:
  ///   - pubKey: The public key for which to compute the TapTweak.
  ///
  /// Returns:
  ///   A List<int> representing the TapTweak hash.
  static List<int> hashTapTweak(ProjectiveECCPoint pubPoint) {
    return P2TRUtils.taggedHash(
      P2TRConst.tapTweakSHA256,
      BigintUtils.toBytes(pubPoint.x, length: Curves.curveSecp256k1.baselen),
    );
  }

  /// Lift the x-coordinate of a public key for P2TR.
  ///
  /// This method lifts the x-coordinate to obtain a ProjectiveECCPoint object,
  /// ensuring that it is within the curve's range.
  ///
  /// Parameters:
  ///   - pubKey: The public key to lift the x-coordinate for.
  ///
  /// Returns:
  ///   A ProjectiveECCPoint object with the lifted x-coordinate.
  ///
  /// Throws:
  ///   - Exception if the x-coordinate cannot be lifted.
  static ProjectiveECCPoint liftX(ProjectiveECCPoint pubKeyPoint) {
    final BigInt p = Curves.curveSecp256k1.p;
    final BigInt x = pubKeyPoint.x;
    if (x >= p) {
      throw MessageException("Unable to compute LiftX point");
    }
    final ySq = (x.modPow(BigInt.from(3), p) + BigInt.from(7)) % p;
    final y = ySq.modPow((p + BigInt.one) ~/ BigInt.from(4), p);
    if (y.modPow(BigInt.two, p) != ySq) {
      throw MessageException("Unable to compute LiftX point");
    }
    BigInt result = (y & BigInt.one) == BigInt.zero ? y : p - y;
    return ProjectiveECCPoint(
        curve: Curves.curveSecp256k1, x: x, y: result, z: BigInt.one);
  }

  /// _tapleafTaggedHash computes and returns the tagged hash of a script for Taproot,
  /// using the specified script. It prepends a version byte and then tags the hash with "TapLeaf".
  static List<int> _tapleafTaggedHash(List<int> script) {
    final scriptBytes = IntUtils.prependVarint(script);

    final part = [P2TRConst.leafVersionTapScript, ...scriptBytes];
    return taggedHash('TapLeaf', part);
  }

  /// _tapBranchTaggedHash computes and returns the tagged hash of two byte slices
  /// for Taproot, where 'a' and 'b' are the input byte slices. It ensures that 'a' and 'b'
  /// are sorted and concatenated before tagging the hash with "TapBranch".
  static List<int> _tapBranchTaggedHash(List<int> a, List<int> b) {
    if (isLessThanBytes(a, b)) {
      return taggedHash("TapBranch", [...a, ...b]);
    }
    return taggedHash("TapBranch", [...b, ...a]);
  }

  /// _getTagHashedMerkleRoot computes and returns the tagged hashed Merkle root for Taproot
  /// based on the provided argument. It handles different argument types, including scripts
  /// and lists of scripts.
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
    throw ArgumentException("List cannot have more than 2 branches.");
  }

  /// _calculateTweek computes and returns the TapTweak value based on the ECPublic key
  /// and an optional script. It uses the key's x-coordinate and the Merkle root of the script
  /// (if provided) to calculate the tweak.
  static List<int> calculateTweek(ProjectiveECCPoint pubPoint,
      {List<dynamic>? script}) {
    final keyX =
        BigintUtils.toBytes(pubPoint.x, length: pubPoint.curve.baselen);
    if (script == null) {
      final tweek = taggedHash("TapTweak", keyX);
      return tweek;
    }
    final merkleRoot = _getTagHashedMerkleRoot(script);
    final tweek = taggedHash("TapTweak", [...keyX, ...merkleRoot]);
    return tweek;
  }
  // /// Tweak a public key to create a P2TR address.
  // ///
  // /// This method tweaks a public key using a hashTapTweak and lifting the x-coordinate.
  // ///
  // /// Parameters:
  // ///   - pubKey: The public key to be tweaked.
  // ///
  // /// Returns:
  // ///   A List<int> representing the tweaked public key for P2TR.
  // static List<int> tweakPublicKey(ProjectiveECCPoint pubPoint) {
  //   final h = hashTapTweak(pubPoint);
  //   final n = Curves.generatorSecp256k1 * BigintUtils.fromBytes(h);
  //   final outPoint = liftX(pubPoint) + n;
  // return BigintUtils.toBytes(outPoint.x,
  //     length: Curves.curveSecp256k1.baselen);
  // }

  static ProjectiveECCPoint tweakPublicKey(ProjectiveECCPoint pubPoint,
      {List<dynamic>? script}) {
    final h = calculateTweek(pubPoint, script: script);
    final n = Curves.generatorSecp256k1 * BigintUtils.fromBytes(h);
    final outPoint = liftX(pubPoint) + n;

    return outPoint as ProjectiveECCPoint;
  }
}

/// Implementation of the [BlockchainAddressDecoder] for Segwit v1 (P2TR) addresses.
class P2TRAddrDecoder implements BlockchainAddressDecoder {
  /// Overrides the base class method to decode a P2TR (Pay-to-Taproot) address.
  ///
  /// This method decodes a P2TR address from the given input string using Bech32 encoding.
  /// It expects an optional map of keyword arguments, with the 'hrp' key specifying the
  /// Human-Readable Part (HRP) of the address. It validates the arguments, decodes the
  /// address, checks the witness version, and returns the decoded address as a List<int>.
  ///
  /// Parameters:
  ///   - addr: The Bech32-encoded P2TR address to be decoded.
  ///   - kwargs: Optional keyword arguments, with 'hrp' for the Human-Readable Part.
  ///
  /// Returns:
  ///   A List<int> containing the decoded P2TR address bytes.
  ///
  /// Throws:
  ///   - ArgumentException if the provided address has an incorrect witness version,
  ///     or if the Bech32 checksum is invalid.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate address arguments and retrieve the Human-Readable Part (HRP).
    AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    final String hrp = kwargs["hrp"];

    /// Decode the Bech32-encoded P2TR address and validate its length.
    final decode = SegwitBech32Decoder.decode(hrp, addr);
    final witVerGot = decode.item1;
    final addrDecBytes = decode.item2;

    /// Validate the byte length of the decoded address.
    AddrDecUtils.validateBytesLength(
        addrDecBytes, EcdsaKeysConst.pubKeyCompressedByteLen - 1);

    /// Check the witness version.
    if (witVerGot != P2TRConst.witnessVer) {
      throw ArgumentException(
          'Invalid witness version (expected ${P2TRConst.witnessVer}, got $witVerGot)');
    }

    /// Return the decoded P2TR address as a List<int>.
    return addrDecBytes;
  }
}

/// Implementation of the [BlockchainAddressEncoder] for Segwit v1 (P2TR) addresses.
class P2TRAddrEncoder implements BlockchainAddressEncoder {
  /// Overrides the base class method to encode a public key as a P2TR (Pay-to-Taproot) address.
  ///
  /// This method encodes a public key as a P2TR address using Bech32 encoding. It expects an
  /// optional map of keyword arguments, with the 'hrp' key specifying the Human-Readable Part
  /// (HRP) for the address. It validates the arguments, processes the public key as a Secp256k1 key,
  /// tweaks the public key, and encodes it as a P2TR address.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be encoded as a P2TR address.
  ///   - kwargs: Optional keyword arguments, with 'hrp' for the Human-Readable Part.
  ///
  /// Returns:
  ///   A String representing the P2TR address encoded from the provided public key.
  @override
  String encodeKey(List<int> pubKey, [Map<String, dynamic> kwargs = const {}]) {
    /// Validate address arguments and retrieve the Human-Readable Part (HRP).
    AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
    final String hrp = kwargs["hrp"];

    /// Validate and process the public key as a Secp256k1 key.
    final pubKeyObj = AddrKeyValidator.validateAndGetSecp256k1Key(pubKey);

    /// Tweak the public key to create a P2TR address.
    final tweakedPubKey = BigintUtils.toBytes(
        P2TRUtils.tweakPublicKey(pubKeyObj.point as ProjectiveECCPoint).x,
        length: Curves.curveSecp256k1.baselen);

    /// Encode the tweaked public key as a P2TR address using Bech32.
    return SegwitBech32Encoder.encode(hrp, P2TRConst.witnessVer, tweakedPubKey);
  }
}
