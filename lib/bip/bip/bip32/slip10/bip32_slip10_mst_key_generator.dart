import 'package:blockchain_utils/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

class Bip32Slip10MstKeyGeneratorConst {
  /// The minimum length in bytes for a valid seed.
  static const int seedMinByteLen = 16;

  /// HMAC key bytes for Ed25519 curve.
  static const List<int> hmacKeyEd25519Bytes = [
    101,
    100,
    50,
    53,
    53,
    49,
    57,
    32,
    115,
    101,
    101,
    100,
  ];

  /// HMAC key bytes for NIST P-256 curve.
  static const List<int> hmacKeyNist256p1Bytes = [
    78,
    105,
    115,
    116,
    50,
    53,
    54,
    112,
    49,
    32,
    115,
    101,
    101,
    100,
  ];

  /// HMAC key bytes for secp256k1 curve.
  static const List<int> hmacKeySecp256k1Bytes = [
    66,
    105,
    116,
    99,
    111,
    105,
    110,
    32,
    115,
    101,
    101,
    100,
  ];
}

/// A private class responsible for generating a master key using Slip-10.
class _Bip32Slip10MstKeyGenerator {
  /// Generates a master key from the specified seed and HMAC key, and returns a tuple
  /// containing private key bytes and chain code bytes.
  ///
  /// Throws:
  /// - [ArgumentException]: If the seed length is not valid.
  ///
  static Bip32MasterKey generateFromSeed(
    List<int> seedBytes,
    List<int> hmacKeyBytes,
    EllipticCurveTypes curveType,
  ) {
    if (seedBytes.length < Bip32Slip10MstKeyGeneratorConst.seedMinByteLen) {
      throw ArgumentException.invalidOperationArguments(
        "generateFromSeed",
        name: "seedBytes",
        reason: "Invalid seed length.",
      );
    }
    const hmacHalfLen = QuickCrypto.hmacSha512DigestSize ~/ 2;
    List<int> hmac = List.empty();
    List<int> hmacData = seedBytes;
    bool success = false;
    while (!success) {
      hmac = QuickCrypto.hmacSha512Hash(hmacKeyBytes, hmacData);
      success = IPrivateKey.isValidBytes(
        hmac.sublist(0, hmacHalfLen),
        curveType,
      );

      if (!success) {
        hmacData = hmac;
      }
    }
    return Bip32MasterKey(
      key: hmac.sublist(0, hmacHalfLen),
      chainCode: Bip32ChainCode(hmac.sublist(hmacHalfLen)),
    );
  }
}

/// A class implementing the `IBip32MstKeyGenerator` interface to generate master
/// keys for the Ed25519 elliptic curve using Slip-10.
class Bip32Slip10Ed25519MstKeyGenerator implements IBip32MstKeyGenerator {
  /// Generates a master key from the specified seed, and returns a tuple
  /// containing private key bytes and chain code bytes.
  ///
  /// Throws:
  /// - [ArgumentException]: If the seed length is not valid.
  ///
  @override
  Bip32MasterKey generateFromSeed(List<int> seedBytes) {
    return _Bip32Slip10MstKeyGenerator.generateFromSeed(
      seedBytes,
      Bip32Slip10MstKeyGeneratorConst.hmacKeyEd25519Bytes,
      EllipticCurveTypes.ed25519,
    );
  }
}

/// A class implementing the `IBip32MstKeyGenerator` interface to generate master
/// keys for the Nist256p1 elliptic curve using Slip-10.
class Bip32Slip10Nist256p1MstKeyGenerator implements IBip32MstKeyGenerator {
  /// Generates a master key from the specified seed, and returns a tuple
  /// containing private key bytes and chain code bytes.
  ///
  /// Throws:
  /// - [ArgumentException]: If the seed length is not valid.
  ///
  @override
  Bip32MasterKey generateFromSeed(List<int> seedBytes) {
    return _Bip32Slip10MstKeyGenerator.generateFromSeed(
      seedBytes,
      Bip32Slip10MstKeyGeneratorConst.hmacKeyNist256p1Bytes,
      EllipticCurveTypes.nist256p1,
    );
  }
}

/// A class implementing the `IBip32MstKeyGenerator` interface to generate master
/// keys for the secp256k1 elliptic curve using Slip-10.
class Bip32Slip10Secp256k1MstKeyGenerator extends IBip32MstKeyGenerator {
  /// Generates a master key from the specified seed, and returns a tuple
  /// containing private key bytes and chain code bytes.
  ///
  /// Throws:
  /// - [ArgumentException]: If the seed length is not valid.
  ///
  @override
  Bip32MasterKey generateFromSeed(List<int> seedBytes) {
    return _Bip32Slip10MstKeyGenerator.generateFromSeed(
      seedBytes,
      Bip32Slip10MstKeyGeneratorConst.hmacKeySecp256k1Bytes,
      EllipticCurveTypes.secp256k1,
    );
  }
}
