import 'package:blockchain_utils/crypto/crypto/group/x25519/src/api/src/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/api/validation/validate.dart';

/// [X25519Api] backed by a native (FFI/platform) implementation.
class NativeX25519Api implements X25519Api {
  NativeX25519Api(this._api);
  final BuX25519Api _api;

  @override
  BuBytes x25519({required List<int> scalar, required List<int> u}) => _api
      .x25519(scalar: scalar, u: u)
      .unwrapOrThrowCryptoError();

  @override
  BuBytes publicKey(List<int> privateKey) =>
      _api.publicKey(privateKey).unwrapOrThrowCryptoError();

  @override
  BuBytes diffieHellman({
    required List<int> privateKey,
    required List<int> peerPublic,
  }) => _api
      .diffieHellman(privateKey: privateKey, peerPublic: peerPublic)
      .unwrapOrThrowCryptoError();

  @override
  BuBytes fromEd25519PublicKey(List<int> ed25519Pk) => _api
      .fromEd25519PublicKey(ed25519Pk)
      .unwrapOrThrowCryptoError();

  @override
  BuBytes fromEd25519Seed(List<int> seed) => _api
      .fromEd25519Seed(seed)
      .unwrapOrThrowCryptoError();
}

/// [X25519Api] wrapper that validates every argument's length before delegating.
class ValidatedX25519Api implements X25519Api {
  ValidatedX25519Api(this.inner);
  final X25519Api inner;
  static const _tag = 'X25519';

  @override
  BuBytes x25519({required List<int> scalar, required List<int> u}) {
    ApiValidate.length(scalar, 32, operation: '$_tag.x25519', name: 'scalar');
    ApiValidate.length(u, 32, operation: '$_tag.x25519', name: 'u');
    return inner.x25519(scalar: scalar, u: u);
  }

  @override
  BuBytes publicKey(List<int> privateKey) {
    ApiValidate.length(
      privateKey,
      32,
      operation: '$_tag.publicKey',
      name: 'privateKey',
    );
    return inner.publicKey(privateKey);
  }

  @override
  BuBytes diffieHellman({
    required List<int> privateKey,
    required List<int> peerPublic,
  }) {
    ApiValidate.length(
      privateKey,
      32,
      operation: '$_tag.dh',
      name: 'privateKey',
    );
    ApiValidate.length(
      peerPublic,
      32,
      operation: '$_tag.dh',
      name: 'peerPublic',
    );
    return inner.diffieHellman(privateKey: privateKey, peerPublic: peerPublic);
  }

  @override
  BuBytes fromEd25519PublicKey(List<int> ed25519Pk) {
    ApiValidate.length(
      ed25519Pk,
      32,
      operation: '$_tag.fromEd25519Pk',
      name: 'ed25519Pk',
    );
    return inner.fromEd25519PublicKey(ed25519Pk);
  }

  @override
  BuBytes fromEd25519Seed(List<int> seed) {
    ApiValidate.length(
      seed,
      32,
      operation: '$_tag.fromEd25519Seed',
      name: 'seed',
    );
    return inner.fromEd25519Seed(seed);
  }
}
