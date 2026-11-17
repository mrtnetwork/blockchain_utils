import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/base/eip2333_derivator.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_const.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_keys.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

import 'dart:typed_data';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// EIP-2333 child key derivator, mirrors `Bip32Slip10Ed25519Derivator`.
///
/// Only secret derivation is supported (EIP-2333 has no public derivation).
class Eip2333KeyDerivator implements IEip2333ChildKeyDerivator {
  const Eip2333KeyDerivator();

  static List<int> _i2osp(BigInt value, int length) {
    return value.toBytes(length: length, byteOrder: Endian.big);
  }

  static List<int> _i2ospInt(int value, int length) {
    return value.toBytes(length: length, byteOrder: Endian.big);
  }

  static BigInt _os2ip(List<int> bytes) {
    return BigintUtils.fromBytes(bytes, byteOrder: Endian.big);
  }

  static List<int> _flipBits(List<int> bytes) {
    return [for (final b in bytes) (~b) & 0xFF];
  }

  /// `IKM_to_lamport_SK`: stretch `IKM` into 255 × 32-byte lamport secrets.
  /// Routed through [QuickCrypto.hkdfDerive] (active backend, RFC 5869).
  static List<List<int>> ikmToLamportSk(List<int> ikm, List<int> salt) {
    final okm = QuickCrypto.hkdfDeriveSha256(
      ikm: ikm.asImmutableBytes,
      length: Eip2333Const.lamportHkdfLen,
      salt: salt,
      info: const [],
    );
    try {
      final out = <List<int>>[];
      for (int i = 0; i < Eip2333Const.lamportCount; i++) {
        out.add(
          okm
              .sublist(
                i * Eip2333Const.sha256DigestLen,
                (i + 1) * Eip2333Const.sha256DigestLen,
              )
              .asImmutableBytes,
        );
      }
      return out;
    } finally {
      okm.forceZero();
    }
  }

  /// `parent_SK_to_lamport_PK`: compress parent key + index into 32 bytes.
  static List<int> parentSkToLamportPk(BigInt parentSk, int index) {
    final salt = _i2ospInt(index, 4);
    final ikm = _i2osp(parentSk, 32);
    final lamport0 = ikmToLamportSk(ikm, salt);
    final lamport1 = ikmToLamportSk(_flipBits(ikm), salt);
    final pk = <int>[];
    for (final s in lamport0) {
      pk.addAll(QuickCrypto.sha256Hash(s));
    }
    for (final s in lamport1) {
      pk.addAll(QuickCrypto.sha256Hash(s));
    }
    return QuickCrypto.sha256Hash(pk);
  }

  /// `HKDF_mod_r`: hash arbitrary `IKM` into `0 <= SK < r`.
  /// Routed through [QuickCrypto.hkdfDerive] (active backend, RFC 5869).
  static BigInt hkdfModR(List<int> ikm, {List<int>? keyInfo}) {
    keyInfo ??= const [];
    List<int> salt = StringUtils.encode(Eip2333Const.blsKeygenSalt);
    BigInt sk = BigInt.zero;
    while (sk == BigInt.zero) {
      salt = QuickCrypto.sha256Hash(salt);
      final prkInput = [...ikm, 0x00];
      final info = [
        ...keyInfo,
        ..._i2ospInt(Eip2333Const.hkdfModROutputLen, 2),
      ];
      final okm = QuickCrypto.hkdfDeriveSha256(
        ikm: prkInput,
        length: Eip2333Const.hkdfModROutputLen,
        salt: salt,
        info: info,
      );
      try {
        sk = _os2ip(okm) % Eip2333Const.orderR;
      } finally {
        okm.forceZero();
      }
    }
    return sk;
  }

  /// `derive_child_SK`.
  static BigInt deriveChildSk(BigInt parentSk, int index) {
    if (index < 0 || index > Eip2333Const.maxIndex) {
      throw const BuError(
        DefaultErrorType.invalidArgument,
        'Invalid child index.',
      );
    }
    final compressed = parentSkToLamportPk(parentSk, index);
    return hkdfModR(compressed);
  }

  /// `derive_master_SK`.
  static BigInt deriveMasterSk(List<int> seed) {
    if (seed.length < Eip2333Const.seedMinByteLen) {
      throw const BuError(
        DefaultErrorType.invalidLength,
        'Invalid seed length.',
      );
    }
    return hkdfModR(seed);
  }

  @override
  bool isPublicDerivationSupported() => false;

  @override
  Eip2333ChildKey deriveFromPublic({
    required Eip2333PrivateKey parent,
    required Eip2333KeyIndex index,
  }) {
    throw const BuError(
      DefaultErrorType.unsupported,
      'Public child derivation is not supported',
    );
  }

  @override
  Eip2333ChildKey deriveFromSecret({
    required Eip2333PrivateKey parent,
    required Eip2333PrivateKey ctx,
    required Eip2333KeyIndex index,
  }) {
    final parentSk = parent.toBigInt();
    final childSk = deriveChildSk(parentSk, index.toInt());
    return Eip2333ChildKey(key: Eip2333PrivateKey.fromBigInt(childSk));
  }
}
