import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/types/types.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Orchard RedPallas domain (spend-auth vs binding).
enum RedPallasVariant {
  /// Orchard spend-auth basepoint + `Zcash_RedPallasH`
  spendAuth,

  /// Orchard binding basepoint + same personalization
  binding,
}

/// Pallas RedDSA signing API (Native connector or pure Dart).
abstract interface class RedPallasSigningApi {
  /// `pk = sk · G_domain` (32-byte LE Pasta compressed).
  BuBytes publicKey({
    required List<int> sk,
    RedPallasVariant variant = RedPallasVariant.spendAuth,
  });

  /// Sign [message]. [rand80] optional (80 bytes); null → implementation RNG.
  ReddsaSignature sign({
    required List<int> sk,
    required List<int> message,
    BuBytes? rand80,
    RedPallasVariant variant = RedPallasVariant.spendAuth,
  });

  /// Verifies RedDSA [signature] (`R || s`) over [message] under 32-byte [pk]. Returns false if invalid; throws on malformed [pk] length.
  bool verify({
    required List<int> pk,
    required List<int> message,
    required ReddsaSignature signature,
    RedPallasVariant variant = RedPallasVariant.spendAuth,
  });

  /// Validates 32-byte [publicKey] and returns its canonical base encoding,
  /// or null when invalid (bad length, range, curve membership, or identity).
  BuBytes? normalizePublicKey(List<int> publicKey);
}

/// Validates argument lengths before delegating to the inner backend.
class ValidatedRedPallasSigningApi implements RedPallasSigningApi {
  ValidatedRedPallasSigningApi(this.inner);
  final RedPallasSigningApi inner;
  static const _tag = 'RedPallas';

  @override
  BuBytes publicKey({
    required List<int> sk,
    RedPallasVariant variant = RedPallasVariant.spendAuth,
  }) {
    ApiValidate.length(sk, 32, operation: '$_tag.publicKey', name: 'sk');
    return ApiValidate.call(
      '$_tag.publicKey',
      () => inner.publicKey(sk: sk, variant: variant),
    );
  }

  @override
  ReddsaSignature sign({
    required List<int> sk,
    required List<int> message,
    BuBytes? rand80,
    RedPallasVariant variant = RedPallasVariant.spendAuth,
  }) {
    ApiValidate.length(sk, 32, operation: '$_tag.sign', name: 'sk');
    if (rand80 != null) {
      ApiValidate.length(rand80, 80, operation: '$_tag.sign', name: 'rand80');
    }
    return ApiValidate.call(
      '$_tag.sign',
      () => inner.sign(
        sk: sk,
        message: message,
        rand80: rand80,
        variant: variant,
      ),
    );
  }

  @override
  bool verify({
    required List<int> pk,
    required List<int> message,
    required ReddsaSignature signature,
    RedPallasVariant variant = RedPallasVariant.spendAuth,
  }) {
    ApiValidate.length(pk, 32, operation: '$_tag.verify', name: 'pk');
    return ApiValidate.call(
      '$_tag.verify',
      () => inner.verify(
        pk: pk,
        message: message,
        signature: signature,
        variant: variant,
      ),
    );
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    return inner.normalizePublicKey(publicKey);
  }
}
