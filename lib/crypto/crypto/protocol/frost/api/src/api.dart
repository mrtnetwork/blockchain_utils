import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// One FROST key share: 1-based participant identifier (`u32`, mirrors
/// `BuFrostShare`) + 32-byte secret scalar.
class FrostKeyShare {
  final int id;
  final BuBytes share;
  FrostKeyShare({required int id, required List<int> share})
    : share =
          share
              .exc(
                length: 32,
                operation: 'FrostKeyShare',
                reason: 'Invalid share length.',
              )
              .asImmutableBytes,
      id = id.asU32;
}

/// One participant's entry in the commitment list: identifier + raw
/// hiding/binding commitment points (33 bytes secp256k1, 32 bytes
/// Ed25519; mirrors `BuFrostCommitment`).
class FrostCommitment {
  final int id;
  final BuBytes hiding;
  final BuBytes binding;
  FrostCommitment({
    required this.id,
    required List<int> hiding,
    required List<int> binding,
  }) : hiding = hiding.asImmutableBytes,
       binding = binding.asImmutableBytes;
}

/// Round-1 nonce output: hiding/binding scalars (32 bytes each) plus
/// their commitments as raw point bytes (mirrors `BuFrostNonces`).
class FrostNoncePair {
  final BuBytes hiding;
  final BuBytes binding;
  final BuBytes hidingCommitment;
  final BuBytes bindingCommitment;
  FrostNoncePair({
    required List<int> hiding,
    required List<int> binding,
    required List<int> hidingCommitment,
    required List<int> bindingCommitment,
  }) : hiding =
           hiding
               .exc(
                 length: 32,
                 operation: 'FrostNoncePair',
                 reason: 'Invalid hiding nonce length.',
               )
               .asImmutableBytes,
       binding =
           binding
               .exc(
                 length: 32,
                 operation: 'FrostNoncePair',
                 reason: 'Invalid binding nonce length.',
               )
               .asImmutableBytes,
       hidingCommitment = hidingCommitment.asImmutableBytes,
       bindingCommitment = bindingCommitment.asImmutableBytes;
}

/// Trusted-dealer shard output: per-participant share records plus the
/// full polynomial coefficients (32 bytes each, secret first; mirrors
/// `BuFrostShard`).
class FrostDealerShard {
  final List<FrostKeyShare> shares;
  final BuBytes poly;
  FrostDealerShard({
    required List<FrostKeyShare> shares,
    required List<int> poly,
  }) : shares = shares.immutable,
       poly = poly.asImmutableBytes;
}

/// Final FROST threshold signature `(R, z)`: `R` as raw point bytes
/// (33 bytes secp256k1, 32 bytes Ed25519) + 32-byte scalar (mirrors
/// `BuFrostSignature`).
class FrostThresholdSignature {
  final BuBytes r;
  final BuBytes z;
  FrostThresholdSignature({required List<int> r, required List<int> z})
    : r = r.asImmutableBytes,
      z =
          z
              .exc(
                length: 32,
                operation: 'FrostThresholdSignature',
                reason: 'Invalid z length.',
              )
              .asImmutableBytes;
}

/// RFC 9591 FROST signing surface (both ciphersuites).
///
/// `k1` = FROST(secp256k1, SHA-256): points 33 bytes, `R` 33 bytes.
/// `ed` = FROST(Ed25519, SHA-512): points 32 bytes, `R` 32 bytes.
/// Identifiers are 1-based (`u32` on the native side).
///
/// Two backends implement this interface with no shared crypto between
/// them: [DartFrostApi] runs the pure-Dart engines in this package,
/// [NativeFrostApi] maps every call onto the connector's `BuFrostApi`
/// (Rust/FFI or WASM) via `unwrapOrThrowCryptoError`, exactly like
/// `NativeMuSig2Api` maps onto `BuMusig2Api`. The `isScalar: false`
/// Ed25519 inputs are RFC 8032 seeds, expanded inside each backend;
/// `threshold: 0` selects the additive quorum convention, otherwise an
/// explicit `2 <= t <= n`.
abstract interface class FrostApi {
  /// Dealer shard: 32-byte [secret] + concatenated 32-byte polynomial
  /// [coefficients] (secret excluded) → one share record per
  /// participant (`1..=[maxParticipants]`).
  FrostDealerShard k1Shard({
    required List<int> secret,
    required List<int> coefficients,
    required int maxParticipants,
  });

  /// Combine share records → 32-byte secret (Lagrange at zero).
  BuBytes k1Combine(List<FrostKeyShare> shares);

  /// Round-1 commit: 32-byte [secretShare] + caller 32-byte
  /// [hidingRandomness]/[bindingRandomness] (or fresh randomness when
  /// null) → nonce scalars + commitments.
  FrostNoncePair k1Commit({
    required List<int> secretShare,
    List<int>? hidingRandomness,
    List<int>? bindingRandomness,
  });

  /// Round-2 signature share (32 bytes) for [identifier].
  BuBytes k1Sign({
    required int identifier,
    required List<int> secretShare,
    required List<int> groupPublicKey,
    required FrostNoncePair nonces,
    required List<FrostCommitment> commitments,
    required List<int> message,
  });

  /// Aggregate signature shares → `(R, z)`.
  FrostThresholdSignature k1Aggregate({
    required List<FrostCommitment> commitments,
    required List<int> message,
    required List<int> groupPublicKey,
    required List<List<int>> shares,
  });

  /// Verify one participant's signature share.
  bool k1VerifyShare({
    required int identifier,
    required List<int> participantPublicKey,
    required FrostCommitment commitment,
    required List<int> share,
    required List<FrostCommitment> commitments,
    required List<int> groupPublicKey,
    required List<int> message,
  });

  /// Verify a final `(R, z)` signature (Appendix B Schnorr).
  bool k1Verify({
    required List<int> commitment,
    required List<int> z,
    required List<int> groupPublicKey,
    required List<int> message,
  });

  /// Signing-share preparation: expand + additive-rescale `shares`
  /// (`[id:u32 LE][share:32]` records) → `n` 32-byte scalars, same order.
  /// `threshold`: 0 = additive full-set rescale, else Shamir passthrough.
  /// All secret math happens inside the backend; shape errors throw.
  BuBytes k1PrepareShares({
    required List<FrostKeyShare> shares,
    required int threshold,
  });

  /// Group key from member points: `ids` + `pubsConcat` (`n` x 33 B).
  /// `threshold`: 0 = additive sum, else Lagrange interpolation at zero.
  /// Pure public-key math inside the backend.
  BuBytes k1GroupFromMembers({
    required List<int> ids,
    required List<int> pubsConcat,
    required int threshold,
  });

  /// Feldman VSS commitment: `nCoeffs` scalars → `nCoeffs` 33-byte points.
  BuBytes k1VssCommit({required List<int> coeffsConcat, required int nCoeffs});

  /// Group key + `max` member keys from a VSS commitment (`nComms`
  /// concatenated 33-byte points, secret commitment first).
  FrostGroupInfo k1GroupInfo({
    required List<int> vssConcat,
    required int nComms,
    required int max,
  });

  /// Threshold reshare (additive): `ids` (`n` participant identifiers) +
  /// `secretsConcat` (`n` 32-byte scalars) + `coeffsConcat`
  /// (`n * (threshold - 1)` 32-byte scalars, row-major) → fresh shares,
  /// member pubs and group key. Requires `n >= 2`, `2 <= threshold <= n`.
  FrostReshare k1Reshare({
    required List<int> ids,
    required List<int> secretsConcat,
    required List<int> coeffsConcat,
    required int threshold,
  });

  /// Dealer shard (Ed25519 suite): same shapes, 32-byte points.
  /// `isScalar`: true (default) = canonical scalars, false = RFC 8032 seeds
  /// expanded in the backend.
  FrostDealerShard edShard({
    required List<int> secret,
    required List<int> coefficients,
    required int maxParticipants,
    bool isScalar = true,
  });

  /// Combine share records → 32-byte secret (Ed25519 suite).
  BuBytes edCombine(List<FrostKeyShare> shares, {bool isScalar = true});

  /// Round-1 commit (Ed25519 suite).
  FrostNoncePair edCommit({
    required List<int> secretShare,
    List<int>? hidingRandomness,
    List<int>? bindingRandomness,
    bool isScalar = true,
  });

  /// Round-2 signature share (Ed25519 suite).
  BuBytes edSign({
    required int identifier,
    required List<int> secretShare,
    required List<int> groupPublicKey,
    required FrostNoncePair nonces,
    required List<FrostCommitment> commitments,
    required List<int> message,
    bool isScalar = true,
  });

  /// Aggregate signature shares → `(R, z)` (Ed25519 suite).
  FrostThresholdSignature edAggregate({
    required List<FrostCommitment> commitments,
    required List<int> message,
    required List<int> groupPublicKey,
    required List<List<int>> shares,
  });

  /// Verify one participant's signature share (Ed25519 suite).
  bool edVerifyShare({
    required int identifier,
    required List<int> participantPublicKey,
    required FrostCommitment commitment,
    required List<int> share,
    required List<FrostCommitment> commitments,
    required List<int> groupPublicKey,
    required List<int> message,
  });

  /// Verify a final `(R, z)` signature (Ed25519 suite).
  bool edVerify({
    required List<int> commitment,
    required List<int> z,
    required List<int> groupPublicKey,
    required List<int> message,
  });

  /// Signing-share preparation (Ed25519 suite): expand seeds when
  /// `isScalar` is false, then additive-rescale like [k1PrepareShares].
  BuBytes edPrepareShares({
    required List<FrostKeyShare> shares,
    required int threshold,
    bool isScalar = true,
  });

  /// Group key from member points (Ed25519 suite): `ids` + `pubsConcat`
  /// (`n` x 32 B). `threshold`: 0 = additive sum, else Lagrange at zero.
  BuBytes edGroupFromMembers({
    required List<int> ids,
    required List<int> pubsConcat,
    required int threshold,
  });

  /// Feldman VSS commitment (Ed25519 suite): `nCoeffs` scalars →
  /// `nCoeffs` 32-byte points.
  BuBytes edVssCommit({required List<int> coeffsConcat, required int nCoeffs});

  /// Group key + `max` member keys from a VSS commitment (Ed25519 suite).
  FrostGroupInfo edGroupInfo({
    required List<int> vssConcat,
    required int nComms,
    required int max,
  });

  /// Threshold reshare (additive, Ed25519 suite): `ids` + `seedsConcat`
  /// (`n` 32-byte RFC 8032 seeds, expanded in the backend) +
  /// `coeffSeedsConcat` (`n * (threshold - 1)` 32-byte seeds) → fresh
  /// shares, member pubs and group key. Requires `n >= 2`,
  /// `2 <= threshold <= n`.
  FrostReshare edReshare({
    required List<int> ids,
    required List<int> seedsConcat,
    required List<int> coeffSeedsConcat,
    required int threshold,
  });
}

/// Group info output: group key + member public keys, in id order
/// (`1..=max`).
class FrostGroupInfo {
  final BuBytes group;
  final List<BuBytes> memberKeys;
  FrostGroupInfo({
    required List<int> group,
    required List<List<int>> memberKeys,
  }) : group = BuBytes(group),
       memberKeys =
           memberKeys.map((e) => e.asImmutableBytes).toList().immutable;
}

/// Threshold-reshare output: fresh per-participant shares as one
/// concatenated blob (`n` x 32-byte scalars, `ids` order) + member public
/// keys (`n` elements) + group key.
class FrostReshare {
  final BuBytes sharesConcat;
  final List<BuBytes> pubs;
  final BuBytes group;
  FrostReshare({
    required List<int> sharesConcat,
    required List<List<int>> pubs,
    required List<int> group,
  }) : sharesConcat = sharesConcat.asImmutableBytes,
       pubs = pubs.map((e) => e.asImmutableBytes).toList().immutable,
       group = group.asImmutableBytes;
}
