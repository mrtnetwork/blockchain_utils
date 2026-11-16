import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/keys/frost/src/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/frost/src/types.dart';

/// Common interface for a FROST coordinator key holding the group's
/// shares as typed secrets in position order, plus the parallel FROST
/// participant identifiers. Signing orchestrates the protocol [FrostApi]
/// backend directly (prepare → commit → sign → aggregate) over a
/// qualifying subset; each backend handles its own secret math, the keys
/// layer only moves bytes. `T` is the member/aggregate key type flowing
/// through [verificationKey].
abstract class IFrostSigningKey<
  P extends BaseFrostPublicKey<T>,
  S,
  T extends IPublicKey<IVerifiyingParams>
>
    implements ISigningKey<FrostSignature, FrostSigningParams, P> {
  /// Curve of this quorum.
  FrostCurve get curve;

  /// Held share secrets, position order.
  List<S> get secretKeys;

  /// FROST participant identifiers parallel to [secretKeys].
  List<int> get identifiers;

  /// Threshold `t` of this quorum (`null` = full quorum).
  int? get threshold;

  /// Read held share `index`'s 32 bytes (protected memory): the raw seed
  /// for Ed25519 (expanded by the backend via `isScalar: false`), the
  /// scalar for secp256k1. No scalar math in the keys layer.
  SecretBytes takeSecretAt(int index);

  @override
  FrostSignature sign(FrostSigningParams params) {
    const op = 'IFrostSigningKey.sign';
    final vk = verificationKey();

    final members = vk.members;
    if (members == null || members.isEmpty) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'stripped aggregate key cannot sign: member keys missing.',
      );
    }

    final n = members.length;
    final t = vk.threshold ?? n;
    if (t < 2 || t > n) {
      throw CoreErrors.cryptoFailed(op, reason: 'corrupt quorum (t=$t, n=$n).');
    }
    if (secretKeys.length != identifiers.length) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'secrets/identifiers length mismatch.',
      );
    }
    final subset = params.subset ?? _autoSubset(secretKeys.length, t, op);
    if (subset.isEmpty) {
      throw CoreErrors.cryptoFailed(op, reason: 'empty signing subset.');
    }
    if (subset.length < t) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'need at least $t signers (got ${subset.length}).',
      );
    }
    if (subset.toSet().length != subset.length) {
      throw CoreErrors.cryptoFailed(op, reason: 'duplicate subset index.');
    }
    for (final i in subset) {
      if (i < 0 || i >= secretKeys.length) {
        throw CoreErrors.cryptoFailed(
          op,
          reason: 'subset index $i out of range.',
        );
      }
    }
    final randomness = params.randomness;
    if (randomness != null && randomness.length != subset.length * 64) {
      throw CoreErrors.cryptoFailed(
        op,
        reason:
            'randomness must hold 64 bytes per subset share '
            '(need ${subset.length * 64}, got ${randomness.length}).',
      );
    }
    final frost = blockchainUtils.api.frost;
    // Threshold shares `b_i` (already resharded scalars); passthrough.
    final copies = <List<int>>[];
    try {
      for (final i in subset) {
        final xBytes = takeSecretAt(i).useValue((b) => List<int>.from(b));
        if (xBytes.length != 32) {
          throw CoreErrors.cryptoFailed(
            op,
            reason: 'corrupt share at index $i.',
          );
        }
        copies.add(xBytes);
      }
      final keyShares = <FrostKeyShare>[
        for (var k = 0; k < subset.length; k++)
          FrostKeyShare(
            id: identifiers[subset[k]],
            share: copies[k],
          ),
      ];
      // Threshold-only: explicit `t` passes through (Shamir shares);
      // null (additive) encodes as 0. The backend validates ranges.
      final th = vk.threshold ?? 0;
      if (curve == FrostCurve.secp256k1) {
        final groupPt = (vk.aggKey as Secp256k1PublicKey).keyBytes;
        final xs =
            frost
                .k1PrepareShares(shares: keyShares, threshold: th)
                .toList();
        final nonces = <FrostNoncePair>[];
        final commitments = <FrostCommitment>[];
        for (var k = 0; k < subset.length; k++) {
          final np = frost.k1Commit(
            secretShare: xs.sublist(k * 32, k * 32 + 32),
            hidingRandomness: randomness?.sublist(k * 64, k * 64 + 32),
            bindingRandomness: randomness?.sublist(k * 64 + 32, k * 64 + 64),
          );
          nonces.add(np);
          commitments.add(
            FrostCommitment(
              id: keyShares[k].id,
              hiding: np.hidingCommitment,
              binding: np.bindingCommitment,
            ),
          );
        }
        final shares = <BuBytes>[];
        for (var k = 0; k < subset.length; k++) {
          shares.add(
            frost.k1Sign(
              identifier: keyShares[k].id,
              secretShare: xs.sublist(k * 32, k * 32 + 32),
              groupPublicKey: groupPt,
              nonces: nonces[k],
              commitments: commitments,
              message: params.message,
            ),
          );
        }
        final sig = frost.k1Aggregate(
          commitments: commitments,
          message: params.message,
          groupPublicKey: groupPt,
          shares: shares.map((e) => e.toList()).toList(),
        );
        return FrostSignature(r: sig.r, z: sig.z);
      }
      final groupPt = (vk.aggKey as ED25519PublicKey).keyBytes;
      // `prepare` expands seeds (`isScalar:false`) or passes scalars
      // (`true`); its output `xs` is always scalars from here on.
      final isScalar = vk.threshold != null;
      final xs =
          frost
              .edPrepareShares(
                shares: keyShares,
                threshold: th,
                isScalar: isScalar,
              )
              .toList();
      final nonces = <FrostNoncePair>[];
      final commitments = <FrostCommitment>[];
      for (var k = 0; k < subset.length; k++) {
        final np = frost.edCommit(
          secretShare: xs.sublist(k * 32, k * 32 + 32),
          hidingRandomness: randomness?.sublist(k * 64, k * 64 + 32),
          bindingRandomness: randomness?.sublist(k * 64 + 32, k * 64 + 64),
          isScalar: true,
        );
        nonces.add(np);
        commitments.add(
          FrostCommitment(
            id: keyShares[k].id,
            hiding: np.hidingCommitment,
            binding: np.bindingCommitment,
          ),
        );
      }
      final shares = <BuBytes>[];
      for (var k = 0; k < subset.length; k++) {
        shares.add(
          frost.edSign(
            identifier: keyShares[k].id,
            secretShare: xs.sublist(k * 32, k * 32 + 32),
            groupPublicKey: groupPt,
            nonces: nonces[k],
            commitments: commitments,
            message: params.message,
            isScalar: true,
          ),
        );
      }
      final sig = frost.edAggregate(
        commitments: commitments,
        message: params.message,
        groupPublicKey: groupPt,
        shares: shares.map((e) => e.toList()).toList(),
      );
      return FrostSignature(r: sig.r, z: sig.z);
    } finally {
      for (final c in copies) {
        c.fillRange(0, c.length, 0);
      }
    }
  }

  /// Default subset when none is given: the first `t` held shares.
  static List<int> _autoSubset(int have, int t, String op) {
    if (have < t) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'holding $have shares but threshold is $t.',
      );
    }
    return List<int>.generate(t, (i) => i);
  }
}

/// Common interface for a FROST aggregate public key: the group key
/// verifiers check the final threshold signature against. The typed
/// key material (`aggKey` / `members`) lives on [BaseFrostPublicKey],
/// which also implements verification.
abstract class IFrostVerificationKey
    implements IVerifiyingKey<FrostVerifyingParams> {
  /// Curve of this key.
  FrostCurve get curve;

  /// Threshold `t` of this quorum (`null` = additive full quorum).
  int? get threshold;

  /// Committee size `n` (`null` when unknown).
  int? get n;

  /// Group public key bytes (`elen` bytes for [curve]).
  BuBytes groupKeyBytes();

  /// Final-signature verification through the selected protocol backend
  /// (`blockchainUtils.api.frost`). `R` is parsed via the typed key
  /// constructors; the equation itself runs in the backend.
  bool verifyHash({
    required List<int> message,
    required FrostSignature signature,
  }) {
    final frost = blockchainUtils.api.frost;
    if (curve == FrostCurve.secp256k1) {
      return frost.k1Verify(
        commitment: Secp256k1PublicKey.fromBytes(signature.r).keyBytes,
        z: signature.z,
        groupPublicKey: Secp256k1PublicKey.fromBytes(groupKeyBytes()).keyBytes,
        message: message,
      );
    }
    return frost.edVerify(
      commitment: ED25519PublicKey.fromBytes(signature.r).keyBytes,
      z: signature.z,
      groupPublicKey: ED25519PublicKey.fromBytes(groupKeyBytes()).keyBytes,
      message: message,
    );
  }

  @override
  bool verify(FrostVerifyingParams params) =>
      verifyHash(message: params.message.toList(), signature: params.signature);
}
