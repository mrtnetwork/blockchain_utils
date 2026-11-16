// Dart backend for [Dkls23KeysApi]: delegates every call to [DklsUtils], the
// pure-Dart protocol engine in `lib/crypto/crypto/protocol/dkls23` (the FROST
// precedent: `DartFrostApi` delegates to `FrostSecp256k1` / `FrostEd25519`).
//
// Same honest in-process effect as the Rust oneshots (`dkg_oneshot`,
// `sign_oneshot`, `import_secrets`, `refresh_oneshot`, ECDSA verify, point-sum
// agg, x-only): deterministic under `(seeds, sid)`, framed blobs parse with
// the native codec both directions. Raw KAT bytes intentionally diverge from
// Rust (extra commitment-salt draws), but every output is protocol-valid and
// cross-verifies with the native backend.
import 'package:blockchain_utils/crypto/crypto/protocol/dkls23/engine/engine.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart'
    show BuBytes;

import 'package:blockchain_utils/crypto/crypto/keys/dkls23/api/src/api.dart';

/// [Dkls23KeysApi] backed by this package's pure-Dart DKLs23 engine.
class DartDkls23KeysApi implements Dkls23KeysApi {
  const DartDkls23KeysApi();

  static DklsProtocolCurve _proto(Dkls23Curve c) =>
      c == Dkls23Curve.secp256k1
          ? DklsProtocolCurve.k1
          : DklsProtocolCurve.r1;

  static List<List<int>> _chunks(List<int> flat, int size, String op) {
    if (flat.length % size != 0) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'length',
        reason: 'must hold whole $size-byte items.',
      );
    }
    return [
      for (var i = 0; i < flat.length; i += size) flat.sublist(i, i + size),
    ];
  }

  static List<DklsProtocolShare> _parseBlob(List<int> blob, String op) {
    final raws = DklsUtils.unframe(blob);
    if (raws.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'sharesBlob',
        reason: 'empty shares blob.',
      );
    }
    return [for (final r in raws) DklsUtils.parseKeyshare(r)];
  }

  static void _checkCurve(List<DklsProtocolShare> shares, DklsProtocolCurve curve, String op) {
    for (final sh in shares) {
      if (sh.curve != curve) {
        throw CoreErrors.invalidOperationArguments(
          op,
          name: 'sharesBlob',
          reason: 'mixed quorum records.',
        );
      }
    }
  }

  @override
  BuBytes dkg({
    required Dkls23Curve curve,
    required List<int> sid,
    required int n,
    required int t,
    required List<int> seeds,
  }) {
    const op = 'Dkls23.dkg';
    final parts = _chunks(seeds, 32, op);
    if (parts.length != n) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'seeds',
        reason: 'need n 32-byte seeds.',
      );
    }
    final shares = DklsUtils.dkg(
      curve: _proto(curve),
      sid: sid,
      n: n,
      t: t,
      seeds: parts,
    );
    return BuBytes(
      DklsUtils.frame([for (final s in shares) DklsUtils.keyshareBytes(s)]),
    );
  }

  @override
  BuBytes sign({
    required Dkls23Curve curve,
    required List<int> sid,
    required List<int> msgHash,
    required List<int> sharesBlob,
    required List<int> seeds,
  }) {
    const op = 'Dkls23.sign';
    final proto = _proto(curve);
    final shares = _parseBlob(sharesBlob, op);
    _checkCurve(shares, proto, op);
    final parts = _chunks(seeds, 32, op);
    if (parts.length != shares.length) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'seeds',
        reason: 'need one 32-byte seed per signing share.',
      );
    }
    return BuBytes(
      DklsUtils.sign(
        shares: shares,
        sid: sid,
        msgHash: msgHash,
        seeds: parts,
      ),
    );
  }

  @override
  BuBytes refresh({
    required List<int> sid,
    required List<int> sharesBlob,
    required List<int> seeds,
  }) {
    const op = 'Dkls23.refresh';
    final olds = _parseBlob(sharesBlob, op);
    _checkCurve(olds, olds.first.curve, op);
    final parts = _chunks(seeds, 32, op);
    if (parts.length != olds.length) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'seeds',
        reason: 'need one 32-byte seed per share.',
      );
    }
    final fresh = DklsUtils.refresh(olds: olds, sid: sid, seeds: parts);
    return BuBytes(
      DklsUtils.frame([for (final s in fresh) DklsUtils.keyshareBytes(s)]),
    );
  }

  @override
  bool verify({
    required Dkls23Curve curve,
    required List<int> groupPk,
    required List<int> msgHash,
    required List<int> signature,
  }) {
    return DklsUtils.verify(
      curve: _proto(curve),
      groupPk: groupPk,
      msgHash: msgHash,
      signature: signature,
    );
  }

  @override
  BuBytes aggPublicKeys({
    required Dkls23Curve curve,
    required List<int> members,
    required int n,
    int? threshold,
  }) {
    const op = 'Dkls23.aggPublicKeys';
    final parts = _chunks(members, 33, op);
    if (parts.length != n) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'members',
        reason: 'need n 33-byte members.',
      );
    }
    return BuBytes(DklsUtils.agg(curve: _proto(curve), members: parts));
  }

  @override
  BuBytes xOnly({required Dkls23Curve curve, required List<int> groupPk}) {
    return BuBytes(DklsUtils.xOnly(curve: _proto(curve), groupPk: groupPk));
  }

  @override
  BuBytes importSecrets({
    required Dkls23Curve curve,
    required List<int> secrets,
    required int n,
  }) {
    const op = 'Dkls23.importSecrets';
    final parts = _chunks(secrets, 32, op);
    if (parts.length != n) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'secrets',
        reason: 'need n 32-byte secrets.',
      );
    }
    final shares = DklsUtils.importSecrets(
      curve: _proto(curve),
      secrets: parts,
    );
    return BuBytes(
      DklsUtils.frame([for (final s in shares) DklsUtils.keyshareBytes(s)]),
    );
  }
}
