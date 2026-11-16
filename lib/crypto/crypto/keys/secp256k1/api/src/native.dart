import 'package:blockchain_utils/chain/signer/const/constants.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Native (FFI) implementation of secp256k1 signing/verification.
class NativeSecp256k1SigningApi implements Secp256k1SigningApi {
  final BuSecp256k1SigningApi api;
  const NativeSecp256k1SigningApi(this.api);

  @override
  IECDSASignature signSchnorr({
    required List<int> digest,
    required List<int> sk,
    required List<int> publicKey,
    List<int>? extraEntropy,
  }) {
    final signature = api
        .signSchnorr(
          sk.asBytes,
          BuSecp256k1SignParams(
            digest: digest.asBytes,
            extraEntropy: BuBytes.unsafe(
              extraEntropy ?? CryptoSignerConst.bchSchnorrRfc6979ExtraData,
            ),
          ),
        )
        .unwrapOrThrowCryptoError();

    return IECDSASignature(
      r: signature.r,
      s: signature.s,
      recoveryId: signature.recoveryId,
    );
  }

  @override
  IECDSASignature sign({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? extraEntropy,
  }) {
    final signature = api
        .signEcdsa(
          sk.asBytes,
          BuSecp256k1SignParams(
            digest: digest.asBytes,
            extraEntropy: extraEntropy?.asBytes,
          ),
        )
        .unwrapOrThrowCryptoError();
    return IECDSASignature(
      r: signature.r,
      s: signature.s,
      recoveryId: signature.recoveryId,
    );
  }

  @override
  IECDSASignature signBip340({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? aux,
    List<int>? tapTweakHash,
  }) {
    final signature = api
        .signBip340(
          sk.asBytes,
          BuSecp256k1Bip340Params(
            digest: digest.asBytes,
            aux: aux?.asBytes,
            tapTweakHash: tapTweakHash?.asBytes,
          ),
        )
        .unwrapOrThrowCryptoError();
    return IECDSASignature(
      r: signature.r,
      s: signature.s,
      recoveryId: signature.recoveryId,
    );
  }

  @override
  bool verifyBip340SignatureUsingXOnly({
    required List<int> xOnly,
    required List<int> digest,
    required IECDSASignature signature,
    List<int>? tapTweakHash,
  }) {
    if (tapTweakHash != null) {
      final tweak = api
          .tweakPublicXOnly(xOnly.asBytes, tapTweakHash.asBytes)
          .unwrapOrThrowCryptoError();
      xOnly = BuBytes.unsafe(tweak);
    }
    final result = api
        .verifyBip340(
          xOnlyPk: xOnly.asBytes,
          messageOrDigest: digest.asBytes,
          signature: BuEcdsaSignature(
            r: signature.r,
            s: signature.s,
            recoveryId: signature.recoveryId,
          ),
        )
        .unwrapOrThrowCryptoError();
    return result;
  }

  @override
  bool verifySchnorr({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  }) {
    final result = api
        .verifySchnorr(
          pk: publicKey.asBytes,
          digest: digest.asBytes,
          signature: BuEcdsaSignature(
            r: signature.r,
            s: signature.s,
            recoveryId: signature.recoveryId,
          ),
        )
        .unwrapOrThrowCryptoError();
    return result;
  }

  @override
  bool verifyMessageSignature({
    required List<int> message,
    required IECDSASignature signature,
    required List<int> publicKey,
    required String messagePrefix,
  }) {
    final result = api
        .verifyBitcoinMessage(
          pk: publicKey.asBytes,
          message: message.asBytes,
          messagePrefix: messagePrefix,
          signature: BuEcdsaSignature(
            r: signature.r,
            s: signature.s,
            recoveryId: signature.recoveryId,
          ),
        )
        .unwrapOrThrowCryptoError();
    return result;
  }

  @override
  bool verify({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  }) {
    final result = api
        .verifyEcdsa(
          pk: publicKey.asBytes,
          signature: BuEcdsaSignature(
            r: signature.r,
            s: signature.s,
            recoveryId: signature.recoveryId,
          ),
          digest: digest.asBytes,
        )
        .unwrapOrThrowCryptoError();
    return result;
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    // Pure validation: identical math on every backend (Dart decoders are
    // pinned equal to Rust by the api-comparison tests), so no FFI
    // round-trip and no new Rust exports are needed.
    final r = api.normalizePublicKey(publicKey.asBytes);
    if (!r.isOk) return null;
    return r.value;
  }
}
