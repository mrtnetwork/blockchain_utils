import 'package:blockchain_utils/crypto/crypto/key_derivation/api/src/api.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [KeyDerivationApi] backed by a native (FFI/platform) implementation.
class NativeKeyDerivationApi implements KeyDerivationApi {
  NativeKeyDerivationApi(this._bindings);
  final BuPlatformBindings _bindings;

  @override
  BuBytes pbkdf2Sha256DeriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    final result = BuKdf.pbkdf2(
      _bindings,
      prf: BuKdfPrf.sha256,
      password: password,
      salt: salt,
      iterations: iterations,
      length: length,
    );
    return result.unwrapOrThrowCryptoError().asBytes;
  }

  @override
  BuBytes pbkdf2Sha512DeriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    final result = BuKdf.pbkdf2(
      _bindings,
      prf: BuKdfPrf.sha512,
      password: password,
      salt: salt,
      iterations: iterations,
      length: length,
    );
    return result.unwrapOrThrowCryptoError().asBytes;
  }

  @override
  BuBytes scryptDeriveKey({
    required List<int> password,
    required List<int> salt,
    required int dkLen,
    required int r,
    required int n,
    required int p,
  }) {
    final result = BuKdf.scrypt(
      _bindings,
      password: password,
      salt: salt,
      n: n,
      p: p,
      r: r,
      length: dkLen,
    );
    return result.unwrapOrThrowCryptoError().asBytes;
  }

  @override
  BuBytes hkdfSha256DeriveKey({
    required List<int> ikm,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  }) {
    final result = BuHkdf(
      bindings: _bindings,
      prf: BuKdfPrf.sha256,
      ikm: BuBytes(ikm),
      salt: salt == null ? null : BuBytes(salt),
      info: info == null ? null : BuBytes(info),
    ).expand(length: length);
    return result.unwrapOrThrowCryptoError().asBytes;
  }

  @override
  BuBytes hkdfSha512DeriveKey({
    required List<int> ikm,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  }) {
    final result = BuHkdf(
      bindings: _bindings,
      prf: BuKdfPrf.sha512,
      ikm: BuBytes(ikm),
      salt: salt == null ? null : BuBytes(salt),
      info: info == null ? null : BuBytes(info),
    ).expand(length: length);
    return result.unwrapOrThrowCryptoError().asBytes;
  }
}
