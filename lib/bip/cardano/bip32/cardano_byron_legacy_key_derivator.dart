import 'dart:typed_data';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/bip32/khalow/bip32_kholaw_key_derivator_base.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_getter.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';

/// A class responsible for deriving key pairs using the Cardano Byron legacy key derivation process
class CardanoByronLegacyKeyDerivator
    extends Bip32KholawEd25519KeyDerivatorBase {
  /// Derives the left part of a new private key based on input bytes and curve type.
  @override
  List<int> newPrivateKeyLeftPart(
      List<int> zlBytes, List<int> klBytes, EllipticCurveTypes type) {
    List<int> multiPly = zlBytes.map((e) => (e * 8) & mask8).toList();
    BigInt zl8Int = BigintUtils.fromBytes(multiPly, byteOrder: Endian.little);
    BigInt klInt = BigintUtils.fromBytes(klBytes, byteOrder: Endian.little);
    final curve = EllipticCurveGetter.generatorFromType(type);
    BigInt newPrivateKeyInt = (zl8Int + klInt) % curve.order!;
    return BigintUtils.toBytes(newPrivateKeyInt,
        length: 32, order: Endian.little);
  }

  /// Derives the right part of a new private key based on input bytes.
  @override
  List<int> newPrivateKeyRightPart(List<int> zrBytes, List<int> krBytes) {
    return List<int>.generate(
      zrBytes.length,
      (index) => (zrBytes[index] + krBytes[index]) & mask8,
    );
  }

  /// Derives a new public key point based on the provided public key and input bytes.
  @override
  EDPoint newPublicKeyPoint(Bip32PublicKey pubKey, List<int> zlBytes) {
    final curve = EllipticCurveGetter.generatorFromType(pubKey.curveType);
    final multiply = zlBytes.map((e) => (e * 8) & mask8).toList();
    BigInt zl8Int = BigintUtils.fromBytes(multiply, byteOrder: Endian.little);

    return pubKey.point + (curve * zl8Int) as EDPoint;
  }

  /// Serializes a Bip32KeyIndex object to bytes.
  @override
  List<int> serializeIndex(Bip32KeyIndex index) {
    return index.toBytes();
  }
}
