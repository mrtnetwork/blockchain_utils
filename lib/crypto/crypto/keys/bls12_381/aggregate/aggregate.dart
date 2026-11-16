import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/keys.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/bls12.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Aggregate signature / aggregate public key / aggregate-verify utilities
/// for the **min-signature-size** BLS scheme: public keys in G2
/// ([Bls12G2PublicKey]), signatures in G1 ([Bls12G2Signature]) --
/// matches [IBlsMinSigSigningKey] / [IBlsMinSigVerificationKey], whose
/// per-signer verify equation is e(H(m), pk) == e(sig, G2.generator).
///
/// Not part of blockchain_utils yet -- built on top of the min-sig
/// key/signature classes plus the low-level G1/G2/pairing primitives that
/// already ship in the package.
///
/// SECURITY -- rogue public key attacks: neither verify method here does
/// proof-of-possession or message-distinctness checking for you.
///   * [fastAggregateVerify] (one shared message): every public key
///     folded into the aggregate MUST have a verified
///     proof-of-possession, or an attacker can craft a "public key" that
///     forges an aggregate signature covering a victim's real key
///     without ever knowing the victim's private scalar.
///   * [aggregateVerify] (distinct per-signer messages): the caller MUST
///     ensure `messages` are pairwise distinct within one aggregate, or
///     the security argument the scheme relies on breaks down.
class BlsMinSigAggregateUtils {
  /// Aggregates signatures (G1 points) by point addition.
  ///
  /// Throws if [signatures] is empty, or if any signature is the
  /// identity point -- an identity-point signature must never verify,
  /// so silently folding one into the sum would let a non-contributing
  /// "signer" ride along for free.
  static Bls12G2Signature aggregateSignatures(
    List<Bls12G2Signature> signatures,
  ) {
    if (signatures.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "aggregateSignatures",
        reason: "cannot aggregate an empty signature list",
      );
    }
    var acc = G1Projective.identity;
    for (final s in signatures) {
      final p = s.signature;
      if (p.isIdentity()) {
        throw CoreErrors.cryptoFailed(
          "aggregateSignatures",
          reason: "refusing to aggregate an identity-point signature",
        );
      }
      acc = acc + p;
    }
    return Bls12G2Signature(acc);
  }

  /// Aggregates public keys (G2 points) by point addition -- this is the
  /// "aggregate key generation" step: run it once over every signer's
  /// public key to get the key you'll pass as `aggregatePublicKey` to
  /// [fastAggregateVerify].
  ///
  /// Throws if [publicKeys] is empty, or if any key is the identity
  /// point.
  static G2Projective aggregatePublicKeys(
    List<List<int>> publicKeys,
  ) {
    if (publicKeys.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "aggregatePublicKeys",
        reason: "cannot aggregate an empty public key list",
      );
    }
    var acc = G2Projective.identity;
    for (final b in publicKeys) {
      final k = G2Projective.fromBytes(b);
      if (k.isIdentity()) {
        throw CoreErrors.cryptoFailed(
          "aggregatePublicKeys",
          reason: "refusing to aggregate an identity-point public key",
        );
      }
      acc = acc + k;
    }
    return G2Projective.fromBytes(acc.toBytes());
  }

  /// FastAggregateVerify: every signer folded into [aggregatePublicKey]
  /// signed the exact same [message].
  ///
  /// Checks e(H(m), aggPk) == e(aggSig, G2.generator) -- the same
  /// identity [IBlsMinSigVerificationKey.verify] checks per-signer, just
  /// with aggregated inputs -- as one combined multi-Miller-loop plus a
  /// single final exponentiation, instead of two separate (expensive)
  /// pairings.
  static bool fastAggregateVerify({
    required List<int> aggregatePublicKey,
    required List<int> message,
    required Bls12G2Signature aggregateSignature,
    List<int>? dst,
  }) {
    final sig = aggregateSignature.signature;
    final pk = G2Projective.fromBytes(aggregatePublicKey);
    if (sig.isIdentity() || pk.isIdentity()) return false;

    final hm = BlsHashToG1.hashToG1(message, dst: dst);
    // e(H(m), pk) * e(-sig, G2Gen) == 1  <=>  e(H(m), pk) == e(sig, G2Gen)
    final terms = <(G1AffinePoint, G2Prepared)>[
      (
        G1AffinePoint.fromBytes(hm.toBytes()),
        G2Prepared.fromG2(pk.toAffine()),
      ),
      (
        (-sig).toAffine(),
        G2Prepared.fromG2(G2AffinePoint.generator),
      ),
    ];
    final ml = MultiMillerLoopBls12().multiMillerLoop(terms);
    return ml.finalExponentiation().isIdentity();
  }

  /// AggregateVerify: each signer signed a *different* message.
  ///
  /// [publicKeys] and [messages] must be the same length and
  /// index-aligned: `publicKeys[i]` must be the key that produced the
  /// signature folded into [aggregateSignature] over `messages[i]`.
  /// Checks e(aggSig, G2.generator) == prod_i e(H(messages[i]),
  /// publicKeys[i]).
  static bool aggregateVerify({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required Bls12G2Signature aggregateSignature,
    List<int>? dst,
  }) {
    if (publicKeys.isEmpty || publicKeys.length != messages.length) {
      return false;
    }
    final sig = aggregateSignature.signature;
    if (sig.isIdentity()) return false;

    final terms = <(G1AffinePoint, G2Prepared)>[
      (
        sig.toAffine(),
        G2Prepared.fromG2(G2AffinePoint.generator),
      ),
    ];
    for (var i = 0; i < publicKeys.length; i++) {
      final pk = G2Projective.fromBytes(publicKeys[i]);
      if (pk.isIdentity()) return false;
      final hm = BlsHashToG1.hashToG1(messages[i], dst: dst);
      terms.add((
        G1AffinePoint.fromBytes((-hm).toBytes()),
        G2Prepared.fromG2(pk.toAffine()),
      ));
    }
    final ml = MultiMillerLoopBls12().multiMillerLoop(terms);
    return ml.finalExponentiation().isIdentity();
  }

  /// Batch-verifies N independently-supplied `(signature, publicKey,
  /// message)` triples using randomized coefficients.
  ///
  /// This is a DIFFERENT, stronger check than [aggregateVerify] -- and
  /// solves a different problem. [aggregateVerify] only proves a
  /// relationship between an aggregate signature you were handed and
  /// the sum of the given keys/messages; because of pairing
  /// bilinearity, it cannot tell an honest sum of real per-message
  /// signatures from a malicious recombination like `sig1' = sig1 +
  /// forged`, `sig2' = sig2 - forged` (these still sum to the honest
  /// aggregate, so [aggregateVerify] on the combined signature
  /// legitimately returns true for them -- that is not a bug, it's the
  /// documented limitation the IETF draft calls out).
  ///
  /// [batchVerify] closes that gap: it takes the signatures
  /// SEPARATELY (never pre-summed by the caller), weights each triple
  /// by an independent random scalar, and checks the weighted sum in
  /// one combined pairing. A forged combination that isn't individually
  /// valid survives the unweighted sum with certainty, but survives a
  /// random-weighted sum with probability ~2^-256 -- for all practical
  /// purposes, only genuinely valid per-triple signatures pass.
  ///
  /// Use [batchVerify] whenever the signatures arrive from parties you
  /// don't fully trust to have aggregated honestly (e.g. verifying a
  /// batch of independently-submitted attestations at once, faster than
  /// checking each with [fastAggregateVerify]/[aggregateVerify]
  /// one-by-one). Use [aggregateVerify] only when you (or a trusted
  /// coordinator) performed the summation yourselves from
  /// already-individually-valid signatures.
  ///
  /// This does NOT replace proof-of-possession -- it defeats
  /// cross-signature cancellation forgeries, not rogue-key forgeries.
  /// Untrusted public keys still need a verified PoP regardless.
  static bool batchVerify({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required List<Bls12G2Signature> signatures,
    List<int>? dst,
  }) {
    final n = publicKeys.length;
    if (n == 0 || messages.length != n || signatures.length != n) {
      return false;
    }

    var sigAcc = G1Projective.identity;
    final terms = <(G1AffinePoint, G2Prepared)>[];

    for (var i = 0; i < n; i++) {
      final pk = G2Projective.fromBytes(publicKeys[i]);
      final sig = signatures[i].signature;
      if (pk.isIdentity() || sig.isIdentity()) return false;

      // r_0 == 1 (skip a scalar mult on the first triple); every other
      // r_i is an independent ~256-bit random scalar.
      final r = i == 0 ? null : JubJubFq.fromBytes64(QuickCrypto.generateRandom(length: 64));

      sigAcc = sigAcc + (r == null ? sig : sig * r);
      final hm = G1Projective.fromBytes(
        BlsHashToG1.hashToG1(messages[i], dst: dst).toBytes(),
      );
      terms.add((
        G1AffinePoint.fromBytes((r == null ? hm : hm * r).toBytes()),
        G2Prepared.fromG2(pk.toAffine()),
      ));
    }

    terms.add((
      (-sigAcc).toAffine(),
      G2Prepared.fromG2(G2AffinePoint.generator),
    ));

    final ml = MultiMillerLoopBls12().multiMillerLoop(terms);
    return ml.finalExponentiation().isIdentity();
  }
}

/// Mirror of [BlsMinSigAggregateUtils] for the **min-pubkey-size**
/// scheme: public keys in G1 ([Bls12G1PublicKey]), signatures in G2
/// ([Bls12G1Signature]) -- matches [IBlsSigningKey] / [IBlsVerificationKey],
/// whose per-signer verify equation is e(pk, H(m)) == e(G1.generator,
/// sig).
///
/// Same rogue-key / duplicate-message caveats as
/// [BlsMinSigAggregateUtils] apply here -- see its class doc.
class BlsMinPubkeyAggregateUtils {
  /// Aggregates signatures (G2 points) by point addition.
  static Bls12G1Signature aggregateSignatures(
    List<Bls12G1Signature> signatures,
  ) {
    if (signatures.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "aggregateSignatures",
        reason: "cannot aggregate an empty signature list",
      );
    }
    var acc = G2Projective.identity;
    for (final s in signatures) {
      final p = s.signature;
      if (p.isIdentity()) {
        throw CoreErrors.cryptoFailed(
          "aggregateSignatures",
          reason: "refusing to aggregate an identity-point signature",
        );
      }
      acc = acc + p;
    }
    return Bls12G1Signature(
      G2Projective.fromBytesUnchecked(acc.toBytes()),
    );
  }

  /// Aggregates public keys (G1 points) by point addition -- the
  /// "aggregate key generation" step for this scheme.
  static G1Projective aggregatePublicKeys(
    List<List<int>> publicKeys,
  ) {
    if (publicKeys.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "aggregatePublicKeys",
        reason: "cannot aggregate an empty public key list",
      );
    }
    var acc = G1Projective.identity;
    for (final b in publicKeys) {
      final k = G1Projective.fromBytes(b);
      if (k.isIdentity()) {
        throw CoreErrors.cryptoFailed(
          "aggregatePublicKeys",
          reason: "refusing to aggregate an identity-point public key",
        );
      }
      acc = acc + k;
    }
    return G1Projective.fromBytes(acc.toBytes());
  }

  /// FastAggregateVerify: every signer signed the same [message].
  /// Checks e(aggPk, H(m)) == e(G1.generator, aggSig).
  static bool fastAggregateVerify({
    required List<int> aggregatePublicKey,
    required List<int> message,
    required Bls12G1Signature aggregateSignature,
    List<int>? dst,
  }) {
    final sig = aggregateSignature.signature;
    final pk = G1Projective.fromBytes(aggregatePublicKey);
    if (sig.isIdentity() || pk.isIdentity()) return false;

    final hm = BlsHashToG2.hashToG2(message, dst: dst);
    // e(pk, H(m)) * e(-G1Gen, sig) == 1  <=>  e(pk, H(m)) == e(G1Gen, sig)
    final terms = <(G1AffinePoint, G2Prepared)>[
      (
        pk.toAffine(),
        G2Prepared.fromG2(
          G2AffinePoint.fromBytesUnchecked(hm.toBytes()),
        ),
      ),
      (
        (-G1AffinePoint.generator),
        G2Prepared.fromG2(sig.toAffine()),
      ),
    ];
    final ml = MultiMillerLoopBls12().multiMillerLoop(terms);
    return ml.finalExponentiation().isIdentity();
  }

  /// AggregateVerify: each signer signed a *different* message.
  /// [publicKeys] and [messages] must be the same length and
  /// index-aligned. Checks e(G1.generator, aggSig) == prod_i
  /// e(publicKeys[i], H(messages[i])).
  static bool aggregateVerify({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required Bls12G1Signature aggregateSignature,
    List<int>? dst,
  }) {
    if (publicKeys.isEmpty || publicKeys.length != messages.length) {
      return false;
    }
    final sig = aggregateSignature.signature;
    if (sig.isIdentity()) return false;

    final terms = <(G1AffinePoint, G2Prepared)>[
      (
        G1Projective.generator.toAffine(),
        G2Prepared.fromG2(sig.toAffine()),
      ),
    ];
    for (var i = 0; i < publicKeys.length; i++) {
      final pk = G1Projective.fromBytes(publicKeys[i]);
      if (pk.isIdentity()) return false;
      final hm = BlsHashToG2.hashToG2(messages[i], dst: dst);
      terms.add((
        (-pk).toAffine(),
        G2Prepared.fromG2(G2AffinePoint.fromBytes(hm.toBytes())),
      ));
    }
    final ml = MultiMillerLoopBls12().multiMillerLoop(terms);
    return ml.finalExponentiation().isIdentity();
  }

  /// Batch-verifies N independently-supplied `(signature, publicKey,
  /// message)` triples using randomized coefficients -- the min-pubkey
  /// (Tezos tz4 / Eth2) mirror of
  /// [BlsMinSigAggregateUtils.batchVerify]. See that method's doc for
  /// why this is a different, stronger check than [aggregateVerify] and
  /// when to use each.
  static bool batchVerify({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required List<Bls12G1Signature> signatures,
    List<int>? dst,
  }) {
    final n = publicKeys.length;
    if (n == 0 || messages.length != n || signatures.length != n) {
      return false;
    }

    var sigAcc = G2Projective.identity;
    final terms = <(G1AffinePoint, G2Prepared)>[];

    for (var i = 0; i < n; i++) {
      final pk = G1Projective.fromBytes(publicKeys[i]);
      final sig = signatures[i].signature;
      if (pk.isIdentity() || sig.isIdentity()) return false;

      // r_0 == 1 (skip a scalar mult on the first triple); every other
      // r_i is an independent ~256-bit random scalar.
      final r = i == 0 ? null : JubJubFq.fromBytes64(QuickCrypto.generateRandom(length: 64));
      final weightedPk = r == null ? pk : pk * r;

      sigAcc = sigAcc + (r == null ? sig : sig * r);

      final hm = BlsHashToG2.hashToG2(messages[i], dst: dst);
      terms.add((
        (-weightedPk).toAffine(),
        G2Prepared.fromG2(G2AffinePoint.fromBytes(hm.toBytes())),
      ));
    }

    terms.add((
      G1AffinePoint.generator,
      G2Prepared.fromG2(sigAcc.toAffine()),
    ));

    final ml = MultiMillerLoopBls12().multiMillerLoop(terms);
    return ml.finalExponentiation().isIdentity();
  }
}
