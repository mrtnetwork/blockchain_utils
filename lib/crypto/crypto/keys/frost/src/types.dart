import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// FROST threshold key-family curve selector (`0` = secp256k1,
/// `1` = Ed25519). Pure data: record/encoding curve tag shared by the
/// keys layer.
enum FrostCurve {
  secp256k1(0),
  ed25519(1);

  const FrostCurve(this.id);
  final int id;

  /// Compressed point length for the curve (33 secp256k1, 32 Ed25519).
  /// Also the length of a signature's `R` half.
  int get elementLen => this == FrostCurve.secp256k1 ? 33 : 32;
}

/// One FROST quorum member: participant identifier + share public key.
/// Implemented by [FrostK1Member] / [FrostEdMember]; the typed key
/// flowing through [BaseFrostPublicKey].
abstract class FrostMember<T> {
  int get id;
  T get key;
}

/// Final FROST Schnorr signature: `R` (curve-encoded: 33-byte
/// compressed secp256k1, 32-byte ed25519; RFC 9591 Appendix A) + `z`
/// (32-byte scalar).
class FrostSignature extends ISignature {
  final BuBytes r;
  final BuBytes z;
  FrostSignature({required List<int> r, required List<int> z})
    : r =
          ((r.length == 33 || r.length == 32)
                  ? r
                  : r.exc(
                    length: 33,
                    operation: 'FrostSignature',
                    reason: 'Invalid R.',
                  ))
              .asImmutableBytes,
      z =
          z
              .exc(
                length: 32,
                operation: 'FrostSignature',
                reason: 'Invalid z.',
              )
              .asImmutableBytes;

  @override
  BuBytes toBytes() => [...r, ...z].asImmutableBytes;

  @override
  List<dynamic> get variables => [r, z];
}

/// Parameters for threshold signing.
///
/// `subset` is optional: when null, the first `t` held shares sign
/// (requires at least `t` shares, else throws). `randomness` is
/// optional: when null, fresh backend randomness fills the per-share
/// nonces; when given it must hold 64 bytes (hiding32 + binding32)
/// per signing share in subset order. Pass explicit values for
/// deterministic tests.
class FrostSigningParams implements ISigningParams {
  final BuBytes message;
  final List<int>? subset;
  final List<int>? randomness;
  FrostSigningParams({
    required List<int> message,
    List<int>? subset,
    List<int>? randomness,
  }) : message = message.asImmutableBytes,
       subset = subset == null ? null : List<int>.unmodifiable(subset),
       randomness =
           randomness == null ? null : List<int>.unmodifiable(randomness) {
    if (subset != null &&
        randomness != null &&
        randomness.length != subset.length * 64) {
      throw CoreErrors.invalidOperationArguments(
        'FrostSigningParams',
        name: 'randomness',
        reason:
            'randomness must hold 64 bytes per subset share '
            '(need ${subset.length * 64}, got ${randomness.length}).',
      );
    }
  }
}

/// Parameters for verifying a final FROST signature.
class FrostVerifyingParams implements IVerifiyingParams {
  final BuBytes message;
  final FrostSignature signature;
  FrostVerifyingParams({required List<int> message, required this.signature})
    : message = message.asImmutableBytes;
}
