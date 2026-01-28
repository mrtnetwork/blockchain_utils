import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/bip/types/types.dart';
import 'package:blockchain_utils/bip/ecc/keys/secp256k1_keys_ecdsa.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// Constants related to Wallet Import Format (WIF).
class WifConst {
  /// Suffix value indicating compressed public key mode in a WIF.
  static const comprPubKeySuffix = 0x01;
}

/// A class for encoding Wallet Import Format (WIF) private keys.
class WifEncoder {
  /// Encodes a private key into a WIF string.
  ///
  /// The [privKey] is the private key to be encoded, and [netVer] is an optional
  /// list of network version bytes. By default, it's an empty list.
  ///
  /// The [pubKeyMode] determines the mode of the associated public key, where
  ///
  /// Returns the WIF-encoded private key as a string.
  static String encode(
    List<int> privKey, {
    List<int> netVer = const [],
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
  }) {
    final prv = Secp256k1PrivateKey.fromBytes(privKey);

    List<int> privKeyBytes = prv.raw;

    if (pubKeyMode == PubKeyModes.compressed) {
      privKeyBytes = [...privKeyBytes, WifConst.comprPubKeySuffix];
    }
    privKeyBytes = [...netVer, ...privKeyBytes];

    return Base58Encoder.checkEncode(privKeyBytes);
  }
}

/// A class for decoding Wallet Import Format (WIF) private keys.
class WifDecoder {
  /// Decodes a WIF-encoded private key
  ///
  /// The [wif] is the WIF-encoded private key to be decoded, and [netVer] is an
  /// optional list of network version bytes. By default, it's an empty list.
  ///
  static (List<int>, PubKeyModes) decode(
    String wif, {
    List<int> netVer = const [],
  }) {
    List<int> privKeyBytes = Base58Decoder.checkDecode(wif);
    if (netVer.isEmpty || privKeyBytes[0] != netVer[0]) {
      throw ArgumentException.invalidOperationArguments(
        "decode",
        name: "netVer",
        reason: "Invalid net version.",
      );
    }
    privKeyBytes = privKeyBytes.sublist(1);
    PubKeyModes pubKeyMode;
    if (Secp256k1PrivateKey.isValidBytes(
      privKeyBytes.sublist(0, privKeyBytes.length - 1),
    )) {
      // Check the compressed public key suffix
      if (privKeyBytes[privKeyBytes.length - 1] != WifConst.comprPubKeySuffix) {
        throw ArgumentException.invalidOperationArguments(
          "decode",
          name: "wif",
          reason: "Invalid compressed public key suffix.",
        );
      }
      privKeyBytes = privKeyBytes.sublist(0, privKeyBytes.length - 1);
      pubKeyMode = PubKeyModes.compressed;
    } else {
      if (!Secp256k1PrivateKey.isValidBytes(privKeyBytes)) {
        throw ArgumentException.invalidOperationArguments(
          "decode",
          name: "wif",
          reason: "Invalid key.",
        );
      }
      pubKeyMode = PubKeyModes.uncompressed;
    }

    return (privKeyBytes, pubKeyMode);
  }
}
