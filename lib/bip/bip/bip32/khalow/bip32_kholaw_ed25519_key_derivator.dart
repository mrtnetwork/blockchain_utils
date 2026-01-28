import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/crypto.dart';

import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/bip32/khalow/bip32_kholaw_key_derivator_base.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_getter.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_kholaw_keys.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Bip32KholawEd25519KeyDerivator key derivator
class Bip32KholawEd25519KeyDerivator
    extends Bip32KholawEd25519KeyDerivatorBase {
  /// Implement the 'serializeIndex' method for serializing a 'Bip32KeyIndex'.
  @override
  List<int> serializeIndex(Bip32KeyIndex index) {
    return index.toBytes(Endian.little);
  }

  /// Computes the new left part of the private key based on ZL bytes, KL bytes, and the elliptic curve type.
  ///
  /// Parameters:
  /// - [zlBytes]: The ZL bytes, representing part of the private key.
  /// - [klBytes]: The KL bytes, representing part of the private key.
  /// - [curve]: The elliptic curve type used for the key derivation.
  ///
  /// Throws:
  /// - [Bip32KeyError]: If the computed child key is not valid, indicating a very unlucky index.
  @override
  List<int> newPrivateKeyLeftPart(
    List<int> zlBytes,
    List<int> klBytes,
    EllipticCurveTypes curve,
  ) {
    final BigInt zlInt = BigintUtils.fromBytes(
      zlBytes.sublist(0, 28),
      byteOrder: Endian.little,
    );
    final BigInt klInt = BigintUtils.fromBytes(
      klBytes,
      byteOrder: Endian.little,
    );

    final BigInt prvlInt = (zlInt * BigInt.from(8)) + klInt;
    final tobytes = BigintUtils.toBytes(
      prvlInt,
      order: Endian.little,
      length: Ed25519KholawKeysConst.privKeyByteLen ~/ 2,
    );
    final sc = Ed25519Utils.scalarReduceConst(tobytes);
    if (BytesUtils.bytesEqual(sc, CryptoOpsConst.zero)) {
      throw const Bip32KeyError(
        'Computed child key is not valid, very unlucky index',
      );
    }

    return tobytes;
  }

  /// Computes the new right part of the private key based on ZR bytes and KR bytes.
  ///
  /// Parameters:
  /// - [zrBytes]: The ZR bytes, representing part of the private key.
  /// - [krBytes]: The KR bytes, representing part of the private key.
  ///
  @override
  List<int> newPrivateKeyRightPart(List<int> zrBytes, List<int> krBytes) {
    final BigInt zrInt = BigintUtils.fromBytes(
      zrBytes,
      byteOrder: Endian.little,
    );
    final BigInt kprInt = BigintUtils.fromBytes(
      krBytes,
      byteOrder: Endian.little,
    );
    final BigInt krInt = (zrInt + kprInt) % (BigInt.one << 256);
    final tobytes = BigintUtils.toBytes(
      krInt,
      order: Endian.little,
      length: Ed25519KholawKeysConst.privKeyByteLen ~/ 2,
    );
    return tobytes;
  }

  /// Computes a new public key point based on the provided Bip32PublicKey and ZL bytes.
  /// The ZL bytes represent the left part of the private key.
  ///
  /// Parameters:
  /// - [pubKey]: The Bip32PublicKey to derive a new point from.
  /// - [zlBytes]: The ZL bytes, representing the left part of the private key.
  ///
  /// Throws:
  /// - [Bip32KeyError] if the computed public child key is not valid.
  @override
  EDPoint newPublicKeyPoint(Bip32PublicKey pubKey, List<int> zlBytes) {
    final point = pubKey.point.cast<EDPoint>();
    final BigInt zlInt = BigintUtils.fromBytes(
      zlBytes.sublist(0, 28),
      byteOrder: Endian.little,
    );
    final EDPoint generator =
        EllipticCurveGetter.generatorFromType(pubKey.curveType).cast<EDPoint>();
    return point + (generator * (zlInt * BigInt.from(8)));
  }
}
