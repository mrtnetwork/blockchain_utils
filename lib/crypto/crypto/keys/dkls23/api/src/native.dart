import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/crypto/crypto/keys/dkls23/api/src/api.dart';

/// [Dkls23KeysApi] backed by a native (FFI/platform) implementation.
class NativeDkls23KeysApi implements Dkls23KeysApi {
  final BuDkls23Api api;
  const NativeDkls23KeysApi(this.api);

  static BuDkls23Curve _curve(Dkls23Curve c) =>
      c == Dkls23Curve.secp256k1
          ? BuDkls23Curve.secp256k1
          : BuDkls23Curve.secp256r1;

  @override
  BuBytes dkg({
    required Dkls23Curve curve,
    required List<int> sid,
    required int n,
    required int t,
    required List<int> seeds,
  }) {
    return api
        .dkg(
          curve: _curve(curve),
          sid: sid.asBytes,
          n: n,
          t: t,
          seeds: seeds.asBytes,
        )
        .unwrapOrThrowCryptoError()
        .asBytes;
  }

  @override
  BuBytes sign({
    required Dkls23Curve curve,
    required List<int> sid,
    required List<int> msgHash,
    required List<int> sharesBlob,
    required List<int> seeds,
  }) {
    return api
        .sign(
          curve: _curve(curve),
          sid: sid.asBytes,
          msgHash32: msgHash.asBytes,
          sharesBlob: sharesBlob.asBytes,
          seeds: seeds.asBytes,
        )
        .unwrapOrThrowCryptoError()
        .asBytes;
  }

  @override
  BuBytes refresh({
    required List<int> sid,
    required List<int> sharesBlob,
    required List<int> seeds,
  }) {
    return api
        .refresh(
          sid: sid.asBytes,
          sharesBlob: sharesBlob.asBytes,
          seeds: seeds.asBytes,
        )
        .unwrapOrThrowCryptoError()
        .asBytes;
  }

  @override
  bool verify({
    required Dkls23Curve curve,
    required List<int> groupPk,
    required List<int> msgHash,
    required List<int> signature,
  }) {
    return api
        .verify(
          curve: _curve(curve),
          groupPk33: groupPk.asBytes,
          msgHash32: msgHash.asBytes,
          sig64: signature.asBytes,
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes aggPublicKeys({
    required Dkls23Curve curve,
    required List<int> members,
    required int n,
    int? threshold,
  }) {
    return api
        .aggKeys(curve: _curve(curve), membersConcat: members.asBytes, n: n)
        .unwrapOrThrowCryptoError()
        .asBytes;
  }

  @override
  BuBytes importSecrets({
    required Dkls23Curve curve,
    required List<int> secrets,
    required int n,
  }) {
    return api
        .importSecrets(
          curve: _curve(curve),
          secretsConcat: secrets.asBytes,
          n: n,
        )
        .unwrapOrThrowCryptoError()
        .asBytes;
  }

  @override
  BuBytes xOnly({required Dkls23Curve curve, required List<int> groupPk}) {
    return api
        .xOnly(curve: _curve(curve), groupPk33: groupPk.asBytes)
        .unwrapOrThrowCryptoError()
        .asBytes;
  }
}
