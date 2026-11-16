import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/types/types.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Sapling RedJubjub domain (spend-auth vs binding).
enum RedJubJubVariant {
  /// Spend-auth basepoint + personalization `Zcash_RedJubjubH`
  spendAuth,

  /// Binding basepoint + same personalization
  binding,
}

/// Jubjub RedDSA signing API (Native connector or pure Dart).
abstract interface class RedJubJubSigningApi {
  /// `pk = sk · G_domain` (32-byte LE compressed).
  BuBytes publicKey({
    required List<int> sk,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
  });

  /// Sign [message]. Optional [rand80] (80 bytes); if null, implementation RNG.
  ReddsaSignature sign({
    required List<int> sk,
    required List<int> message,
    List<int>? rand80,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
  });

  /// Verify 64-byte `R || s` under 32-byte [pk].
  bool verify({
    required List<int> pk,
    required List<int> message,
    required ReddsaSignature signature,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
  });

  /// Validates 32-byte [publicKey] and returns its canonical base encoding,
  /// or null when invalid (bad length, range, curve membership, or identity).
  BuBytes? normalizePublicKey(List<int> publicKey);
}

/// Validates argument lengths before delegating to the inner backend.
class ValidatedRedJubJubSigningApi implements RedJubJubSigningApi {
  ValidatedRedJubJubSigningApi(this.inner);
  final RedJubJubSigningApi inner;
  static const _tag = 'RedJubJub';

  @override
  BuBytes publicKey({
    required List<int> sk,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
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
    List<int>? rand80,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
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
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
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
