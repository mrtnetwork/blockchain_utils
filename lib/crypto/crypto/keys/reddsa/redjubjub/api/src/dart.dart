import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redjubjub/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/jubjub.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/protocol/zip32/sapling/utils.dart';

/// Pure-Dart implementation of RedJubjub (Zcash Sapling RedDSA) signing/verification.
class DartRedJubJubSigningApi implements RedJubJubSigningApi {
  const DartRedJubJubSigningApi();
  static const List<int> _pers = [
    // "Zcash_RedJubjubH"
    0x5a, 0x63, 0x61, 0x73, 0x68, 0x5f, 0x52, 0x65,
    0x64, 0x4a, 0x75, 0x62, 0x6a, 0x75, 0x62, 0x48,
  ];

  static const String _tag = 'RedJubJubSigningApi';

  JubJubPoint _generator(RedJubJubVariant v) {
    return JubJubPoint.fromBytes(switch (v) {
      RedJubJubVariant.spendAuth => SaplingKeyUtils.spendAuthGeneratorBytes,
      RedJubJubVariant.binding => SaplingKeyUtils.bindingGeneratorBytes,
    });
  }

  JubJubFr _sk(List<int> sk) {
    try {
      return JubJubFr.fromBytes(sk);
    } catch (e) {
      throw CoreErrors.cryptoFailed(
        '$_tag.sk',
        reason: 'invalid 32-byte Fr: $e',
      );
    }
  }

  @override
  BuBytes publicKey({
    required List<int> sk,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
  }) {
    final s = _sk(sk);
    final pk = _generator(variant) * s;
    return pk.toBytes().asBytes;
  }

  @override
  ReddsaSignature sign({
    required List<int> sk,
    required List<int> message,
    List<int>? rand80,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
  }) {
    final scalar = _sk(sk);
    final gen = _generator(variant);
    final pkBytes = (gen * scalar).toBytes();

    final rand = rand80 ?? QuickCrypto.generateRandom(length: 80).asBytes;
    if (rand.length != 80) {
      throw CoreErrors.cryptoFailed(
        '$_tag.sign',
        reason: 'rand80 must be 80 bytes, got ${rand.length}',
      );
    }

    final nonceBytes = QuickCrypto.blake2b512Hash(
      rand,
      personalization: _pers,
      extraBlocks: [pkBytes, message],
    );
    final nonce = JubJubFr.fromBytes64(nonceBytes);

    final rPoint = gen * nonce;
    final rBytes = rPoint.toBytes();
    final cBytes = QuickCrypto.blake2b512Hash(
      rBytes,
      personalization: _pers,
      extraBlocks: [pkBytes, message],
    );

    final c = JubJubFr.fromBytes64(cBytes);
    final s = nonce + (c * scalar);
    return ReddsaSignature(rBytes: rBytes.asBytes, sBytes: s.toBytes().asBytes);
  }

  @override
  bool verify({
    required List<int> pk,
    required List<int> message,
    required ReddsaSignature signature,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
  }) {
    try {
      final point = JubJubPoint.fromBytes(pk);
      final gen = _generator(variant);

      final cBytes = QuickCrypto.blake2b512Hash(
        signature.rBytes,
        personalization: _pers,
        extraBlocks: [pk, message],
      );
      final c = JubJubFr.fromBytes64(cBytes);
      final r = JubJubPoint.fromBytes(signature.rBytes);
      final s = JubJubFr.fromBytes(signature.sBytes);

      if (r.isIdentity() || s.isZero()) return false;

      // s·G − c·A − R  is small-order (cofactor check)
      final n = (gen * s) - (point * c) - r;
      return n.isSmallOrder();
    } catch (_) {
      return false;
    }
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    try {
      final point = JubJubPoint.fromBytes(publicKey);
      if (point.isIdentity()) return null;
      return BuBytes.immutable(point.toBytes());
    } catch (_) {
      return null;
    }
  }
}
