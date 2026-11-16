import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/secp256k1.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

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
    CryptoKeyEncoding pubKeyMode = CryptoKeyEncoding.base,
  }) {
    final key = Secp256k1PrivateKey.fromBytes(privKey);

    try {
      return encodeKey(key, netVer: netVer, pubKeyMode: pubKeyMode);
    } finally {
      key.dispose();
    }
  }

  static String encodeKey(
    Secp256k1PrivateKey key, {
    List<int> netVer = const [],
    CryptoKeyEncoding pubKeyMode = CryptoKeyEncoding.base,
  }) {
    return key.takeSecretKey().useValue((k) {
      return Base58Encoder.encodeWithChecksum([
        ...netVer,
        ...k,
        if (pubKeyMode == CryptoKeyEncoding.base) WifConst.comprPubKeySuffix,
      ]);
    });
  }
}

/// A class for decoding Wallet Import Format (WIF) private keys.
class WifDecoder {
  /// Decodes a WIF-encoded private key
  ///
  /// The [wif] is the WIF-encoded private key to be decoded, and [netVer] is an
  /// optional list of network version bytes. By default, it's an empty list.
  ///
  static (SecretBytes, CryptoKeyEncoding) decode(
    String wif, {
    List<int> netVer = const [],
  }) {
    List<int> privKeyBytes = Base58Decoder.decodeWithChecksum(wif);
    if (netVer.isEmpty || privKeyBytes[0] != netVer[0]) {
      throw CoreErrors.invalidOperationArguments(
        "decode",
        name: "netVer",
        reason: "Invalid net version.",
      );
    }
    privKeyBytes = privKeyBytes.sublist(1);
    CryptoKeyEncoding pubKeyMode;
    if (Secp256k1PrivateKey.isValidBytes(
      privKeyBytes.sublist(0, privKeyBytes.length - 1),
    )) {
      // Check the compressed public key suffix
      if (privKeyBytes[privKeyBytes.length - 1] != WifConst.comprPubKeySuffix) {
        throw CoreErrors.invalidOperationArguments(
          "decode",
          name: "wif",
          reason: "Invalid compressed public key suffix.",
        );
      }
      privKeyBytes = privKeyBytes.sublist(0, privKeyBytes.length - 1);
      pubKeyMode = CryptoKeyEncoding.base;
    } else {
      if (!Secp256k1PrivateKey.isValidBytes(privKeyBytes)) {
        throw CoreErrors.invalidOperationArguments(
          "decode",
          name: "wif",
          reason: "Invalid key.",
        );
      }
      pubKeyMode = CryptoKeyEncoding.uncompressed;
    }

    return (SecretBytes.take(privKeyBytes), pubKeyMode);
  }
}
