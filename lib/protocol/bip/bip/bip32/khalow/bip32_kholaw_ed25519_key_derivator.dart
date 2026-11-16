import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/ops.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/khalow/bip32_kholaw_key_derivator_base.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Bip32KholawEd25519KeyDerivator key derivator
class Bip32KholawEd25519KeyDerivator
    extends Bip32KholawEd25519KeyDerivatorBase {
  /// Implement the 'serializeIndex' method for serializing a 'Bip32KeyIndex'.
  @override
  BuBytes serializeIndex(Bip32KeyIndex index) {
    return index.toBytes(Endian.little);
  }

  /// Computes 8*ZL + kL for Cardano/Khovratovich (khalo) BIP32-Ed25519
  /// left-key derivation using byte-level shift/add — no BigInt.
  ///
  /// Intentionally NOT reduced mod the group order; that's the whole
  /// point of khalo scalars. Only checked for "≡0 mod L" separately
  /// via [Ed25519Utils.scalarReduceConst].
  static BuBytes khalowLeftPart(List<int> zlBytes, List<int> klBytes) {
    if (klBytes.length != 32 || zlBytes.length < 28) {
      throw CoreErrors.invalidOperationArguments(
        "khalowLeftPart",
        reason: "Invalid bytes argument length.",
      );
    }
    final zl = zlBytes.sublist(0, 28);

    // shift left 3 bits (== *8), little-endian, carry propagates upward
    final shifted = List<int>.filled(zl.length + 1, 0);
    int carry = 0;
    for (var i = 0; i < zl.length; i++) {
      final v = (zl[i] << 3) | carry;
      shifted[i] = v & 0xFF;
      carry = v >> 8;
    }
    shifted[zl.length] = carry; // at most 1 extra byte -> 29 bytes total

    // add shifted (<=29 bytes) + klBytes (32 bytes), little-endian, carry
    final out = BuBytes.fill(32, 0);
    int addCarry = 0;
    for (var i = 0; i < 32; i++) {
      final a = i < shifted.length ? shifted[i] : 0;
      final b = klBytes[i];
      final sum = a + b + addCarry;
      out[i] = sum & 0xFF;
      addCarry = sum >> 8;
    }

    if (addCarry != 0) {
      // Shouldn't happen for well-formed keys (kL's top bits are cleared
      // per the key-gen rules), but don't silently truncate a real overflow.
      throw const BuError(DefaultErrorType.invalidLength,
        'Computed child key overflowed 256 bits, invalid parent key',
      );
    }

    return out;
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
  BuBytes newPrivateKeyLeftPart(
    List<int> zlBytes,
    List<int> klBytes,
    CryptoKeyType curve,
  ) {
    final tobytes = khalowLeftPart(zlBytes, klBytes);
    final sc = blockchainUtils.api.ed25519.scReduce(tobytes);
    if (BytesUtils.bytesEqual(sc, List.filled(32, 0))) {
      throw const BuError(DefaultErrorType.invalidKeyData,
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
  BuBytes newPrivateKeyRightPart(List<int> zrBytes, List<int> krBytes) {
    if (zrBytes.length != 32 || krBytes.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "newPrivateKeyRightPart",
        reason: "Invalid bytes argument length.",
      );
    }
    final out = BuBytes.fill(32, 0);
    int carry = 0;
    for (var i = 0; i < 32; i++) {
      final sum = zrBytes[i] + krBytes[i] + carry;
      out[i] = sum & 0xFF;
      carry = sum >> 8;
    }
    // any carry out of byte 31 is the mod-2^256 wraparound — discard it,
    // exactly as `% (BigInt.one << 256)` does in the BigInt version.

    return out;
  }

  /// Computes 8*zL as a little-endian scalar (unreduced, ≤29 bytes of
  /// significance, zero-padded to 32) for feeding into scalarMultBase.
  static BuBytes _shiftLeft3(List<int> zl28) {
    assert(zl28.length == 28, 'zL must be 28 bytes');
    final out = BuBytes.fill(32, 0);
    int carry = 0;
    for (var i = 0; i < zl28.length; i++) {
      final v = (zl28[i] << 3) | carry;
      out[i] = v & 0xFF;
      carry = v >> 8;
    }
    out[zl28.length] =
        carry; // byte 28 absorbs the final carry, bytes 29-31 stay 0
    return out;
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
  EdwardsLimbPoint newPublicKeyPoint(Bip32PublicKey pubKey, List<int> zlBytes) {
    if (zlBytes.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "newPublicKeyPoint",
        reason: "Invalid ZL bytes length.",
      );
    }
    if (!pubKey.type.isED25519()) {
      throw CoreErrors.cryptoFailed(
        "newPublicKeyPoint",
        reason: "Invalid public key type.",
      );
    }
    final scalar = _shiftLeft3(zlBytes.sublist(0, 28));
    final genMul = blockchainUtils.api.ed25519.multBase(scalar);
    final sum = blockchainUtils.api.ed25519.add(pubKey.key.toBytes(), genMul);
    return EdwardsLimbOps.asPoint(sum);
  }
}
