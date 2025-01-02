import 'dart:typed_data';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/bip32/khalow/bip32_kholaw_key_derivator_base.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_getter.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_kholaw_keys.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';

/// Define a class, 'Bip32KholawEd25519KeyDerivator', that extends 'Bip32KholawEd25519KeyDerivatorBase'
/// for Ed25519 key derivation.
class Bip32KholawEd25519KeyDerivator
    extends Bip32KholawEd25519KeyDerivatorBase {
  /// Implement the 'serializeIndex' method for serializing a 'Bip32KeyIndex'.
  @override
  List<int> serializeIndex(Bip32KeyIndex index) {
    return index.toBytes(Endian.little);
  }

  /// Computes the new left part of the private key based on ZL bytes, KL bytes, and the elliptic curve type.
  ///
  /// This method takes ZL and KL bytes and combines them to compute the new left part of the private key.
  /// It ensures that the computed child key is valid by checking if it's not a very unlucky index.
  ///
  /// Parameters:
  /// - [zlBytes]: The ZL bytes, representing part of the private key.
  /// - [klBytes]: The KL bytes, representing part of the private key.
  /// - [curve]: The elliptic curve type used for the key derivation.
  ///
  /// Returns:
  /// - The new left part of the private key as a `List<int>`.
  ///
  /// Throws:
  /// - [Bip32KeyError]: If the computed child key is not valid, indicating a very unlucky index.
  @override
  List<int> newPrivateKeyLeftPart(
      List<int> zlBytes, List<int> klBytes, EllipticCurveTypes curve) {
    final BigInt zlInt =
        BigintUtils.fromBytes(zlBytes.sublist(0, 28), byteOrder: Endian.little);
    final BigInt klInt =
        BigintUtils.fromBytes(klBytes, byteOrder: Endian.little);

    final EDPoint generator =
        EllipticCurveGetter.generatorFromType(curve) as EDPoint;
    final BigInt prvlInt = (zlInt * BigInt.from(8)) + klInt;
    if (prvlInt % generator.order! == BigInt.zero) {
      throw const Bip32KeyError(
          'Computed child key is not valid, very unlucky index');
    }
    final tobytes = BigintUtils.toBytes(prvlInt,
        order: Endian.little,
        length: Ed25519KholawKeysConst.privKeyByteLen ~/ 2);
    return tobytes;
  }

  /// Computes the new right part of the private key based on ZR bytes and KR bytes.
  ///
  /// This method adds ZR and KR, taking the result modulo 2^256, and returns it as a `List<int>`.
  /// The resulting bytes are then converted to match the format of a private key.
  ///
  /// Parameters:
  /// - [zrBytes]: The ZR bytes, representing part of the private key.
  /// - [krBytes]: The KR bytes, representing part of the private key.
  ///
  /// Returns:
  /// - The new right part of the private key as a `List<int>`.
  @override
  List<int> newPrivateKeyRightPart(List<int> zrBytes, List<int> krBytes) {
    final BigInt zrInt =
        BigintUtils.fromBytes(zrBytes, byteOrder: Endian.little);
    final BigInt kprInt =
        BigintUtils.fromBytes(krBytes, byteOrder: Endian.little);
    final BigInt krInt = (zrInt + kprInt) % (BigInt.one << 256);
    final tobytes = BigintUtils.toBytes(krInt,
        order: Endian.little,
        length: Ed25519KholawKeysConst.privKeyByteLen ~/ 2);
    return tobytes;
  }

  /// Computes a new public key point based on the provided Bip32PublicKey and ZL bytes.
  /// The ZL bytes represent the left part of the private key.
  ///
  /// This method adds the product of the left part of the private key and curve h to the public key point.
  ///
  /// Parameters:
  /// - [pubKey]: The Bip32PublicKey to derive a new point from.
  /// - [zlBytes]: The ZL bytes, representing the left part of the private key.
  ///
  /// Returns:
  /// - The new public key point as an EDPoint.
  ///
  /// Throws:
  /// - [Bip32KeyError] if the computed public child key is not valid.
  @override
  EDPoint newPublicKeyPoint(Bip32PublicKey pubKey, List<int> zlBytes) {
    assert(pubKey.point is EDPoint);
    final BigInt zlInt =
        BigintUtils.fromBytes(zlBytes.sublist(0, 28), byteOrder: Endian.little);
    final EDPoint generator =
        EllipticCurveGetter.generatorFromType(pubKey.curveType) as EDPoint;
    return (pubKey.point as EDPoint) + (generator * (zlInt * BigInt.from(8)));
  }
}
