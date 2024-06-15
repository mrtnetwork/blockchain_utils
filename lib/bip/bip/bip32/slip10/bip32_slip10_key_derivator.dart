import 'dart:typed_data';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/ibip32_key_derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_getter.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Constants related to the Bip32 Slip10 Derivator.
class Bip32Slip10DerivatorConst {
  /// Prefix for private key derivation in Slip10.
  static const List<int> priveKeyPrefix = [0x00];
}

/// A class implementing the `IBip32KeyDerivator` interface for Bip32 Slip10 key derivation
/// with the ECDSA curve.
class Bip32Slip10EcdsaDerivator implements IBip32KeyDerivator {
  /// check if support public key derivation
  @override
  bool isPublicDerivationSupported() {
    return true;
  }

  /// Derive a child private key from the given parent private key and public key
  /// using the provided index and elliptic curve type.
  ///
  /// This method implements the child private key derivation for Bip32 Slip10
  /// with the ECDSA curve. It calculates the child private key and returns it
  /// along with the chain code.
  ///
  /// Parameters:
  /// - [privKey]: The parent private key from which to derive the child private key.
  /// - [pubKey]: The corresponding public key associated with the parent private key.
  /// - [index]: The index to derive the child key.
  /// - [type]: The elliptic curve type.
  ///
  /// Returns:
  /// A tuple containing the derived child private key and the chain code.
  @override
  Tuple<List<int>, List<int>> ckdPriv(Bip32PrivateKey privKey,
      Bip32PublicKey pubKey, Bip32KeyIndex index, EllipticCurveTypes type) {
    final privKeyBytes = privKey.raw;
    List<int> dataBytes;
    if (index.isHardened) {
      dataBytes = List<int>.from([
        ...Bip32Slip10DerivatorConst.priveKeyPrefix,
        ...privKeyBytes,
        ...index.toBytes()
      ]);
    } else {
      dataBytes = List<int>.from([...pubKey.compressed, ...index.toBytes()]);
    }
    final hmacHalves = QuickCrypto.hmacSha512HashHalves(
        privKey.chainCode.toBytes(), dataBytes);

    final ilBytes = hmacHalves.item1;
    final irBytes = hmacHalves.item2;
    final ilInt = BigintUtils.fromBytes(ilBytes);
    final privKeyInt = BigintUtils.fromBytes(privKeyBytes);
    final generator = EllipticCurveGetter.generatorFromType(type);
    final scalar = (ilInt + privKeyInt) % generator.order!;
    final newPrivKeyBytes = BigintUtils.toBytes(scalar,
        order: Endian.big, length: privKey.privKey.length);

    return Tuple(newPrivKeyBytes, irBytes);
  }

  /// Derive a child public key from the given parent public key using the provided
  /// index and elliptic curve type.
  ///
  /// This method implements the child public key derivation for Bip32 Slip10 with
  /// the ECDSA curve. It calculates the child public key point and returns it along
  /// with the chain code.
  ///
  /// Parameters:
  /// - [pubKey]: The parent public key from which to derive the child public key.
  /// - [index]: The index to derive the child key.
  /// - [type]: The elliptic curve type.
  ///
  /// Returns:
  /// A tuple containing the derived child public key point and the chain code.
  @override
  Tuple<List<int>, List<int>> ckdPub(
      Bip32PublicKey pubKey, Bip32KeyIndex index, EllipticCurveTypes type) {
    final dataBytes =
        List<int>.from([...pubKey.compressed, ...index.toBytes()]);
    final hmacHalves =
        QuickCrypto.hmacSha512HashHalves(pubKey.chainCode.toBytes(), dataBytes);

    final ilBytes = hmacHalves.item1;
    final irBytes = hmacHalves.item2;
    final ilInt = BigintUtils.fromBytes(ilBytes);
    final generator = EllipticCurveGetter.generatorFromType(type);

    final newPubKeyPoint = pubKey.point + (generator * ilInt);
    return Tuple(newPubKeyPoint.toBytes(), irBytes);
  }
}

/// A class that implements the `IBip32KeyDerivator` interface for Bip32 Slip10
/// derivation using the Ed25519 elliptic curve.
///
/// This class provides methods for deriving child private and public keys using
/// the Ed25519 elliptic curve for Bip32 Slip10 standard.
///
/// To use this class, create an instance of it and use its methods to perform
/// key derivation.
class Bip32Slip10Ed25519Derivator implements IBip32KeyDerivator {
  /// Derive a new private key and chain code based on a given private key, public key,
  /// an index, and an elliptic curve type.
  ///
  /// This method computes a new private key and chain code by applying the CKD (Child Key
  /// Derivation) algorithm for the specified private key, public key, index, and elliptic curve type.
  ///
  /// Parameters:
  /// - `privKey`: The parent private key for derivation.
  /// - `pubKey`: The corresponding parent public key.
  /// - `index`: The index for the child key.
  /// - `type`: The elliptic curve type used for key derivation.
  ///
  /// Returns a tuple containing the new private key bytes and the chain code bytes.
  @override
  Tuple<List<int>, List<int>> ckdPriv(Bip32PrivateKey privKey,
      Bip32PublicKey pubKey, Bip32KeyIndex index, EllipticCurveTypes type) {
    final dataBytes = List<int>.from([
      ...Bip32Slip10DerivatorConst.priveKeyPrefix,
      ...privKey.raw,
      ...index.toBytes()
    ]);
    return QuickCrypto.hmacSha512HashHalves(
        privKey.chainCode.toBytes(), dataBytes);
  }

  /// public derivation
  /// [Bip32Slip10Ed25519Derivator] does not support public key derivation
  @override
  Tuple<List<int>, List<int>> ckdPub(
      Bip32PublicKey pubKey, Bip32KeyIndex index, EllipticCurveTypes type) {
    throw UnimplementedError("$type does not support public key derivation");
  }

  /// check if support public key derivation
  @override
  bool isPublicDerivationSupported() {
    return false;
  }
}
