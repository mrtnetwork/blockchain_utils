import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redpallas/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/pasta.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/protocol/zip32/orchard/utils.dart'; // OrchardKeyUtils

/// Pure-Dart implementation of RedPallas (Zcash Orchard RedDSA) signing/verification.
class DartRedPallasSigningApi implements RedPallasSigningApi {
  const DartRedPallasSigningApi();
  // "Zcash_RedPallasH"
  static const List<int> _pers = [
    0x5a,
    0x63,
    0x61,
    0x73,
    0x68,
    0x5f,
    0x52,
    0x65,
    0x64,
    0x50,
    0x61,
    0x6c,
    0x6c,
    0x61,
    0x73,
    0x48,
  ];

  static const String _tag = 'RedPallasSigningApi';

  PallasPoint _generator(RedPallasVariant v) {
    return PallasPoint.fromBytes(switch (v) {
      RedPallasVariant.spendAuth =>
        OrchardKeyUtils.orchardSpendAuthSigBasepointBytes,
      RedPallasVariant.binding =>
        OrchardKeyUtils.orchardBindingSigBasepointBytes,
    });
  }

  VestaFq _sk(List<int> sk) {
    return VestaFq.fromBytes(sk);
  }

  @override
  BuBytes publicKey({
    required List<int> sk,
    RedPallasVariant variant = RedPallasVariant.spendAuth,
  }) {
    final s = _sk(sk);
    return (_generator(variant) * s).toBytes().asBytes;
  }

  @override
  ReddsaSignature sign({
    required List<int> sk,
    required List<int> message,
    List<int>? rand80,
    RedPallasVariant variant = RedPallasVariant.spendAuth,
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
    final nonce = VestaFq.fromBytes64(nonceBytes);
    final rPoint = gen * nonce;
    final rBytes = rPoint.toBytes();

    final cBytes = QuickCrypto.blake2b512Hash(
      rBytes,
      personalization: _pers,
      extraBlocks: [pkBytes, message],
    );
    final c = VestaFq.fromBytes64(cBytes);
    final s = nonce + (c * scalar);

    return ReddsaSignature(rBytes: rBytes.asBytes, sBytes: s.toBytes().asBytes);
  }

  @override
  bool verify({
    required List<int> pk,
    required List<int> message,
    required ReddsaSignature signature,
    RedPallasVariant variant = RedPallasVariant.spendAuth,
  }) {
    try {
      final point = PallasPoint.fromBytes(pk);
      final gen = _generator(variant);

      final cBytes = QuickCrypto.blake2b512Hash(
        signature.rBytes,
        personalization: _pers,
        extraBlocks: [pk, message],
      );
      final c = VestaFq.fromBytes64(cBytes);
      final r = PallasPoint.fromBytes(signature.rBytes);
      final s = VestaFq.fromBytes(signature.sBytes);

      if (r.isIdentity() || s.isZero()) return false;

      final n = (gen * s) - (point * c) - r;
      return n.isSmallOrder();
    } catch (_) {
      return false;
    }
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    try {
      final point = PallasPoint.fromBytes(publicKey);
      if (point.isIdentity()) return null;
      return BuBytes.immutable(point.toBytes());
    } catch (_) {
      return null;
    }
  }
}
