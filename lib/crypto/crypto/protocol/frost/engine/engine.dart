import 'package:blockchain_utils/crypto/crypto/protocol/frost/engine/types.dart';

/// Shared interface of the pure-Dart FROST engines ([FrostSecp256k1]
/// / [FrostEd25519], RFC 9591 Sections 4-5 plus Appendix C) — the
/// MuSig2 precedent (`MuSig2Context` behind `DartMuSig2Api`).
///
/// `P` is the suite point type ([Secp256k1Point] on secp256k1,
/// [EdwardsLimbPoint] on Ed25519); `S` is the suite scalar field
/// ([Secp256k1Fr] on secp256k1, `Ed25519Fr` on Ed25519). Participant
/// ids are plain 1-based `int` counters (`u32` wire range). Suites
/// differ only in Hash function, scalar endianness, and point encoding;
/// every core method below is implemented by both engines with
/// identical semantics.
abstract class FrostEngine<P, S> {
  /// Ciphersuite context string (`FROST-secp256k1-SHA256-v1` /
  /// `FROST-ED25519-SHA512-v1`).
  String get contextString;

  /// Scalar length in bytes (32 on both suites).
  int get scalarLen;

  /// Encoded point length in bytes (33 secp256k1, 32 Ed25519).
  int get elementLen;

  List<int> serializeScalar(S s);
  S deserializeScalar(List<int> buf);
  List<int> serializeElement(P p);
  P deserializeElement(List<int> buf);
  P scalarBaseMult(S s);
  P scalarMult(P p, S s);

  /// Lagrange weight of `xi` over `ids` at zero (Section 4.2).
  /// `ids`/`xi` are plain participant integers (wire order).
  S deriveInterpolatingValue(List<int> ids, int xi);

  /// Horner polynomial evaluation (Section 4.2).
  S polynomialEvaluate(S x, List<S> coeffs);

  /// Interpolate the constant term through `(x, y)` points (C.1.1).
  S polynomialInterpolateConstant(List<(S, S)> points);

  /// Canonical commitment-list encoding, id-sorted (Section 4.3).
  List<int> encodeGroupCommitmentList(List<FrostEngineCommitment<P>> commitments);

  /// Participant ids in commitment-list order.
  List<int> participantsFromCommitmentList(
    List<FrostEngineCommitment<P>> commitments,
  );

  /// Binding factors `ρ_l` for every participant (Section 4.4).
  Map<int, S> computeBindingFactors(
    P groupPublicKey,
    List<FrostEngineCommitment<P>> commitments,
    List<int> msg,
  );

  S bindingFactorFor(Map<int, S> factors, int identifier);

  /// Group commitment `R = Σ (D_l + ρ_l · E_l)` (Section 4.5).
  P computeGroupCommitment(
    List<FrostEngineCommitment<P>> commitments,
    Map<int, S> factors,
  );

  /// Schnorr challenge `c = H2(R, PK, m)` (Section 4.3).
  S computeChallenge(P groupCommitment, P groupPublicKey, List<int> msg);

  /// Round-1 commit with caller randomness (Section 5.1).
  FrostEngineNonces<P, S> commitWithRandomness(
    S secretShare,
    List<int> hidingRandomness,
    List<int> bindingRandomness,
  );

  /// Round-1 commit with fresh randomness (Section 4.1).
  FrostEngineNonces<P, S> commit(S secretShare);

  /// Round-2 signature share (Section 5.2).
  S sign(
    int identifier,
    S secretShare,
    P groupPublicKey,
    FrostEngineNonces<P, S> nonces,
    List<int> msg,
    List<FrostEngineCommitment<P>> commitments,
  );

  /// Aggregate shares into `(R, z)` (Section 5.3).
  (P, S) aggregate(
    List<FrostEngineCommitment<P>> commitments,
    List<int> msg,
    P groupPublicKey,
    List<S> shares,
  );

  /// Verify one participant's share (Section 5.3).
  bool verifyShare(
    int identifier,
    P participantPublicKey,
    FrostEngineCommitment<P> commitment,
    S share,
    List<FrostEngineCommitment<P>> commitments,
    P groupPublicKey,
    List<int> msg,
  );

  /// Schnorr verification `z·G == R + c·PK` (Appendix B).
  bool verifySignature(P groupCommitment, S z, P groupPublicKey, List<int> msg);

  /// Canonical encoding (Appendix A): `R || z`.
  List<int> encodeSignature(P r, S z);

  (P, S) decodeSignature(List<int> sig);

  /// Trusted-dealer sharding (Appendix C): secret + coefficients →
  /// per-participant shares + full polynomial (secret first).
  ({List<FrostEngineShare<S>> shares, List<S> coeffs}) secretShareShard(
    S secret,
    List<S> coefficients,
    int maxParticipants,
  );

  /// Combine share records → secret (Lagrange at zero).
  S secretShareCombine(List<FrostEngineShare<S>> shares);

  /// Feldman VSS commitments `G·coeffs`.
  List<P> vssCommit(List<S> coeffs);

  /// Verify a share against VSS commitments.
  bool vssVerify(FrostEngineShare<S> share, List<P> commitment);

  /// Group key + member keys from VSS commitments.
  (P, List<P>) deriveGroupInfo(int maxParticipants, List<P> vssCommitment);

  /// Threshold reshare (additive, Rust core mirror): `n = secrets.length`,
  /// `2 <= threshold <= n`, `ids.length == n`,
  /// `coeffs.length == n * (threshold - 1)`, `ids` unique and non-zero.
  ///
  /// For secret `j`, `poly_j = [secrets[j]] + coeffs[j*(t-1)..(j+1)*(t-1)]`;
  /// new share `b_i = sum_j polynomialEvaluate(ids[i], poly_j)`;
  /// `pubs[i] = scalarBaseMult(b_i)`; `group = sum_j scalarBaseMult(a_j)`.
  ///
  /// ```dart
  /// // n = 2, threshold = 2: poly0 = [a0, c0], poly1 = [a1, c1];
  /// // b_i = poly0(ids[i]) + poly1(ids[i]); pubs[i] == G * b_i;
  /// // group == G * a0 + G * a1; any threshold (id, b) pairs combine
  /// // to (a0 + a1) via deriveInterpolatingValue.
  /// final r = engine.reshareAdditive([a0, a1], [c0, c1], [id1, id2], 2);
  /// assert(r.shares.length == 2 && r.pubs.length == 2);
  /// ```
  ({List<S> shares, List<P> pubs, P group}) reshareAdditive(
    List<S> secrets,
    List<S> coeffs,
    List<int> ids,
    int threshold,
  );
}
