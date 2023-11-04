import 'package:blockchain_utils/bech32/bech32_ex.dart';
import 'package:blockchain_utils/bech32/segwit_bech32.dart';
import 'package:blockchain_utils/numbers/bigint_utils.dart';
import 'package:blockchain_utils/bip/address/addr_dec_utils.dart';
import 'package:blockchain_utils/bip/address/addr_key_validator.dart';
import 'package:blockchain_utils/bip/address/decoder.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';

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
}

/// Utility class for working with P2TR (Pay-to-Taproot) addresses and operations.
class _P2TRUtils {
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
  ///   - ArgumentError if the tag is not a string or bytes.
  static List<int> taggedHash(dynamic tag, List<int> dataBytes) {
    if (tag! is String && tag! is List<int>) {
      throw ArgumentError("tag must be bytes or string");
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
  static List<int> hashTapTweak(IPublicKey pubKey) {
    return _P2TRUtils.taggedHash(
      P2TRConst.tapTweakSHA256,
      BigintUtils.toBytes(pubKey.point.x,
          length: Curves.curveSecp256k1.baselen),
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
  static ProjectiveECCPoint _liftX(IPublicKey pubKey) {
    final BigInt p = Curves.curveSecp256k1.p;
    final BigInt x = pubKey.point.x;
    if (x >= p) {
      throw Exception("Unable to compute LiftX point");
    }
    final ySq = (x.modPow(BigInt.from(3), p) + BigInt.from(7)) % p;
    final y = ySq.modPow((p + BigInt.one) ~/ BigInt.from(4), p);
    if (y.modPow(BigInt.two, p) != ySq) {
      throw Exception("Unable to compute LiftX point");
    }
    BigInt result = (y & BigInt.one) == BigInt.zero ? y : p - y;
    return ProjectiveECCPoint(
        curve: Curves.curveSecp256k1, x: x, y: result, z: BigInt.one);
  }

  /// Tweak a public key to create a P2TR address.
  ///
  /// This method tweaks a public key using a hashTapTweak and lifting the x-coordinate.
  ///
  /// Parameters:
  ///   - pubKey: The public key to be tweaked.
  ///
  /// Returns:
  ///   A List<int> representing the tweaked public key for P2TR.
  static List<int> tweakPublicKey(IPublicKey pubKey) {
    final h = hashTapTweak(pubKey);
    final n = Curves.generatorSecp256k1 * BigintUtils.fromBytes(h);
    final outPoint = _liftX(pubKey) + n;
    return BigintUtils.toBytes(outPoint.x,
        length: Curves.curveSecp256k1.baselen);
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
  ///   - ArgumentError if the provided address has an incorrect witness version,
  ///     or if the Bech32 checksum is invalid.
  @override
  List<int> decodeAddr(String addr, [Map<String, dynamic> kwargs = const {}]) {
    try {
      /// Validate address arguments and retrieve the Human-Readable Part (HRP).
      AddrKeyValidator.validateAddressArgs<String>(kwargs, "hrp");
      final String hrp = kwargs["hrp"];

      /// Decode the Bech32-encoded P2TR address and validate its length.
      final decode = SegwitBech32Decoder.decode(hrp, addr);
      final witVerGot = decode.$1;
      final addrDecBytes = decode.$2;

      /// Validate the byte length of the decoded address.
      AddrDecUtils.validateBytesLength(
          addrDecBytes, EcdsaKeysConst.pubKeyCompressedByteLen - 1);

      /// Check the witness version.
      if (witVerGot != P2TRConst.witnessVer) {
        throw ArgumentError(
            'Invalid witness version (expected ${P2TRConst.witnessVer}, got $witVerGot)');
      }

      /// Return the decoded P2TR address as a List<int>.
      return addrDecBytes;
    } on Bech32ChecksumError catch (e) {
      throw ArgumentError('Invalid bech32 checksum', e.toString());
    }
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
    final tweakedPubKey = _P2TRUtils.tweakPublicKey(pubKeyObj);

    /// Encode the tweaked public key as a P2TR address using Bech32.
    return SegwitBech32Encoder.encode(hrp, P2TRConst.witnessVer, tweakedPubKey);
  }
}
