import 'package:blockchain_utils/crypto/crypto/protocol/musig2/api/src/api.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/utils/utils_const.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [MuSig2Api] backed by a native (FFI/platform) implementation.
class NativeMuSig2Api implements MuSig2Api {
  final BuMusig2Api api;
  const NativeMuSig2Api(this.api);
  @override
  Secp256k1Point aggPublicKeys(List<List<int>> keys) {
    final agg = api.keyAgg(keys.map((e) => e.asBytes).toList());
    return agg
        .map((e) => Secp256k1Point.fromBytes(e))
        .unwrapOrThrowCryptoError();
  }

  @override
  Secp256k1Point keyAggAndTweak({
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
  }) {
    final agg = api.keyAggAndTweak(
      keys: publicKeys.map((e) => e.asBytes).toList(),
      tweaks:
          tweaks
              .map((e) => BuMusig2Tweak(tweak32: e.tweak, isXOnly: e.isXOnly))
              .toList(),
    );
    return agg
        .map((e) => Secp256k1Point.fromBytes(e))
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes nonceAgg(List<List<int>> pubnonces) {
    final agg = api.nonceAgg(pubnonces.map((e) => e.asBytes).toList());
    return agg.unwrapOrThrowCryptoError().asBytes;
  }

  @override
  MuSig2Nonce nonceGenerate({
    required List<int> publicKey,
    List<int>? rand,
    List<int>? sk,
    List<int>? aggPubKey,
    List<int>? msg,
    List<int>? extra,
  }) {
    final result = api.nonceGenerate(
      publicKey: publicKey.asBytes,
      aggPubKey: aggPubKey?.asBytes,
      extra: extra?.asBytes,
      msg: msg?.asBytes,
      rand: (rand ?? QuickCrypto.generateRandom()).asBytes,
      sk: sk?.asBytes,
    );

    return result
        .map((e) => MuSig2Nonce(pubnonce: e.pubnonce, secnonce: e.secnonce))
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes partialSigAgg({
    required List<List<int>> signatures,
    required MuSig2Session session,
  }) {
    final result = api.partialSigAgg(
      aggnonce: session.aggnonce,
      msg: session.msg,
      partials: signatures.map((e) => e.asBytes).toList(),
      publicKeys: session.publicKeys,
      tweaks:
          session.tweaks
              .map((e) => BuMusig2Tweak(tweak32: e.tweak, isXOnly: e.isXOnly))
              .toList(),
    );
    return result.unwrapOrThrowCryptoError().asBytes;
  }

  @override
  bool partialSigVerify({
    required List<int> signature,
    required List<int> pubnonce,
    required List<int> pk,
    required MuSig2Session session,
  }) {
    final result = api.partialSigVerify(
      aggnonce: session.aggnonce,
      msg: session.msg,
      partial: signature.asBytes,
      pk: pk.asBytes,
      pubnonce: pubnonce.asBytes,
      publicKeys: session.publicKeys,
      tweaks:
          session.tweaks
              .map((e) => BuMusig2Tweak(tweak32: e.tweak, isXOnly: e.isXOnly))
              .toList(),
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes sign({
    required List<int> secnonce,
    required List<int> sk,
    required MuSig2Session session,
  }) {
    final result = api.partialSign(
      aggnonce: session.aggnonce,
      msg: session.msg,
      secnonce: secnonce.asBytes,
      sk: sk.asBytes,
      publicKeys: session.publicKeys,
      tweaks:
          session.tweaks
              .map((e) => BuMusig2Tweak(tweak32: e.tweak, isXOnly: e.isXOnly))
              .toList(),
    );
    return result.unwrapOrThrowCryptoError().asBytes;
  }

  @override
  List<BuBytes> sortPublicKeys(List<List<int>> keys) {
    return MuSig2UtilsConst.sortPublicKeys(
      keys.map((e) => e.asImmutableBytes).toList(),
    );
  }

  @override
  MuSig2DeterministicSignature deterministicSign({
    required List<int> sk,
    required List<int> aggotherNonce,
    required List<List<int>> publicKeys,
    List<MuSig2Tweak> tweaks = const [],
    required List<int> msg,
    List<int>? rand,
  }) {
    final result = api
        .deterministicSign(
          sk: sk.asBytes,
          aggotherNonce66: aggotherNonce.asBytes,
          publicKeys: publicKeys.map((e) => e.asBytes).toList(),
          msg: msg.asBytes,
          rand: rand?.asBytes,
          tweaks:
              tweaks
                  .map(
                    (e) => BuMusig2Tweak(tweak32: e.tweak, isXOnly: e.isXOnly),
                  )
                  .toList(),
        )
        .unwrapOrThrowCryptoError();
    return MuSig2DeterministicSignature(
      signature: result.partial,
      pubnonce: result.pubnonce,
    );
  }

  @override
  bool verifyAggregate({
    required List<int> message,
    required List<int> signature,
    required List<int> aggXOnly,
  }) {
    final result = api.verifyAggregate(
      message: message.asBytes,
      signature64: signature.asBytes,
      aggXOnly32: aggXOnly.asBytes,
    );
    return result.unwrapOrThrowCryptoError();
  }
}
