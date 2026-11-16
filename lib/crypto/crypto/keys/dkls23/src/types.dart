import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// Parameters for a DKLs23 threshold signing operation.
///
/// `subset` is optional: when null, the first `t` held shares sign
/// (requires at least `t` shares in the key, else throws). `sid` and
/// `seeds` are optional: when null, fresh OS randomness
/// ([QuickCrypto.generateRandom]) fills them — a fresh 32-byte `sid`
/// per ceremony and one 32-byte seed per signing party. Pass explicit
/// values for deterministic tests. When provided, `sid` must be
/// non-empty; `seeds` must hold exactly 32 bytes per signing party in
/// subset order (`seeds[i]` belongs to the `i`-th selected party, or
/// to party `i` when `subset` is null and the first `t` sign).
class Dkls23SignParams implements ISigningParams {
  final List<int>? sid;
  final List<int> msgHash;
  final List<int>? subset;
  final List<int>? seeds;
  Dkls23SignParams({
    required List<int> msgHash,
    List<int>? subset,
    List<int>? sid,
    List<int>? seeds,
  }) : msgHash =
           msgHash
               .exc(
                 length: 32,
                 operation: 'Dkls23SignParams',
                 reason: 'Message hash must be 32 bytes.',
               )
               .asImmutableBytes,
       subset = subset == null ? null : List<int>.unmodifiable(subset),
       sid = sid == null ? null : List<int>.unmodifiable(sid),
       seeds = seeds == null ? null : List<int>.unmodifiable(seeds) {
    if (sid != null && sid.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        'Dkls23SignParams',
        name: 'sid',
        reason: 'sid must not be empty.',
      );
    }
    if (subset != null && seeds != null && seeds.length != subset.length * 32) {
      throw CoreErrors.invalidOperationArguments(
        'Dkls23SignParams',
        name: 'seeds',
        reason:
            'seeds must hold 32 bytes per subset party '
            '(need ${subset.length * 32}, got ${seeds.length}).',
      );
    }
  }
}

/// Parameters for verifying a DKLs23 threshold signature.
class Dkls23VerifyParams implements IVerifiyingParams {
  final List<int> msgHash;
  final IECDSASignature signature;
  Dkls23VerifyParams({required List<int> msgHash, required this.signature})
    : msgHash =
          msgHash
              .exc(
                length: 32,
                operation: 'Dkls23VerifyParams',
                reason: 'Message hash must be 32 bytes.',
              )
              .asImmutableBytes;
}
