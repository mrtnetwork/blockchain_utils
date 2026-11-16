import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/dkls23/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/dkls23/src/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'package:blockchain_utils/crypto/crypto/keys/dkls23/src/types.dart';

/// Common interface for a DKLs23 coordinator key holding the group's
/// shares as typed single-key secrets (`secp256k1` / `secp256r1`
/// private keys, party order: `secretKeys[i]` is party `i`'s share).
/// Signing rebuilds the native share records from these scalars plus
/// the aggregate key (`P`) metadata and runs a qualifying subset; `T`
/// is the member/aggregate key type flowing through [verificationKey].
abstract class IDkls23SigningKey<
  P extends BaseDkls23PublicKey<T>,
  S,
  T extends IPublicKey<IVerifiyingParams>
>
    implements ISigningKey<IECDSASignature, Dkls23SignParams, P> {
  /// Curve of this quorum.
  Dkls23Curve get curve;

  /// Held share scalars as typed secrets, party order.
  List<S> get secretKeys;

  /// Threshold `t` of this quorum (`null` = full quorum).
  int? get threshold;

  /// Read party `index`'s 32-byte share scalar (protected memory).
  SecretBytes takeSecretAt(int index);

  /// Encode one keyshare record, mirroring `codec::keyshare_bytes`:
  /// `[party,n,t,curve:u32 LE][x:32][pk:33][shares: n*33]`.
  static BuBytes _encodeRecord({
    required int party,
    required int n,
    required int t,
    required int curve,
    required List<int> x,
    required List<int> pk,
    required List<List<int>> shares,
  }) {
    List<int> u32(int v) =>
        IntUtils.toBytes(v, length: 4, byteOrder: Endian.little).toList();
    final out = <int>[];
    out.addAll(u32(party));
    out.addAll(u32(n));
    out.addAll(u32(t));
    out.addAll(u32(curve));
    out.addAll(x);
    out.addAll(pk);
    for (final s in shares) {
      out.addAll(s);
    }
    return BuBytes(out);
  }

  static BuBytes _frame(List<BuBytes> items) {
    final out = <int>[];
    for (final it in items) {
      out.addAll(
        IntUtils.toBytes(it.length, length: 4, byteOrder: Endian.little),
      );
      out.addAll(it);
    }
    return BuBytes(out);
  }

  /// Run `use` with the framed native records for `indices`, wiping
  /// every secret copy afterwards. Advanced: [sign] uses this for the
  /// signing subset; refresh uses it for the full share set.
  TRes withRecordsBlob<TRes>(
    List<int> indices,
    TRes Function(BuBytes blob) use,
  ) {
    const op = 'IDkls23SigningKey.sign';
    final vk = verificationKey();
    final members = vk.members;
    if (members == null || members.isEmpty) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'stripped aggregate key cannot sign: member keys missing.',
      );
    }
    final memberBlobs = members.map((e) => e.toBytes().toList()).toList();
    final n = memberBlobs.length;
    final t = vk.threshold ?? n;
    if (t < 2 || t > n) {
      throw CoreErrors.cryptoFailed(op, reason: 'corrupt quorum (t=$t, n=$n).');
    }
    final groupBytes = vk.aggKey.toBytes().toList();
    final records = <BuBytes>[];
    final copies = <BuBytes>[];
    try {
      for (final i in indices) {
        if (i < 0 || i >= secretKeys.length) {
          throw CoreErrors.cryptoFailed(
            op,
            reason: 'subset index $i out of range.',
          );
        }
        final x = takeSecretAt(i).toBytes();
        copies.add(x);
        if (x.length != 32) {
          throw CoreErrors.cryptoFailed(
            op,
            reason: 'corrupt share at index $i.',
          );
        }
        records.add(
          _encodeRecord(
            party: i,
            n: n,
            t: t,
            curve: curve.id,
            x: x,
            pk: groupBytes,
            shares: memberBlobs,
          ),
        );
      }
      return use(_frame(records));
    } finally {
      for (final r in records) {
        r.zero();
      }
      for (final c in copies) {
        c.forceZero();
      }
    }
  }

  /// Low-S normalization without any order constant: keeps the
  /// lexicographically smaller of 32-byte big-endian `s` and `n - s`.
  static BuBytes _lowSSig(BuBytes s, Dkls23Curve curve) {
    final neg =
        curve == Dkls23Curve.secp256k1
            ? (-Secp256k1Fr.fromBytes(s)).toBytes()
            : (-Secp256r1Fr.fromBytes(s)).toBytes();
    return BytesUtils.compareBytes(s, neg) <= 0 ? s : neg;
  }

  @override
  IECDSASignature sign(Dkls23SignParams params) {
    const op = 'IDkls23SigningKey.sign';
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
    final sid = params.sid ?? QuickCrypto.generateRandom(length: 32);
    final seeds =
        params.seeds ?? QuickCrypto.generateRandom(length: subset.length * 32);
    if (seeds.length != subset.length * 32) {
      throw CoreErrors.cryptoFailed(
        op,
        reason:
            'seeds must hold 32 bytes per subset party '
            '(need ${subset.length * 32}, got ${seeds.length}).',
      );
    }
    if (sid.isEmpty) {
      throw CoreErrors.cryptoFailed(op, reason: 'empty session id.');
    }
    final sig = withRecordsBlob(
      subset,
      (blob) => blockchainUtils.api.dkls23.sign(
        curve: curve,
        sid: sid,
        msgHash: params.msgHash,
        sharesBlob: blob,
        seeds: seeds,
      ),
    );
    // Compact `r || s` from the backend plus a locally recovered id
    // (same derivation the wallet previously did at its call site).
    final r = sig.sublist(0, 32).toList();
    var s = sig.sublist(32).toList();
    var signature = IECDSASignature(r: r, s: s);
    final groupBytes = verificationKey().aggKey.toBytes() as List<int>;
    int? recoveryId;
    if (curve == Dkls23Curve.secp256k1) {
      recoveryId = Secp256k1EcdsaUtils.recoverId(
        hash: params.msgHash,
        signature: signature,
        pubKey: groupBytes,
      );
    } else {
      recoveryId = Secp256r1EcdsaUtils.recoverId(
        hash: params.msgHash,
        signature: signature,
        pubKey: groupBytes,
      );
    }
    if (recoveryId == null) {
      throw CoreErrors.cryptoFailed(op, reason: 'unrecoverable signature.');
    }
    final lowS = _lowSSig(s, curve);
    if (!BytesUtils.bytesEqual(lowS, s)) {
      s = lowS;
      signature = IECDSASignature(r: r, s: s);
      recoveryId ^= 1;
    }
    return IECDSASignature(r: r, s: s, recoveryId: recoveryId);
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

/// Common interface for a DKLs23 aggregate public key: the group key
/// verifiers check the final threshold signature against. The typed
/// key material (`aggKey` / `members`) lives on
/// [BaseDkls23PublicKey], which also implements verification.
abstract class IDkls23VerificationKey
    implements IVerifiyingKey<Dkls23VerifyParams> {
  /// Curve of this key.
  Dkls23Curve get curve;

  /// Threshold `t` of this quorum (`null` = full quorum of `n`).
  int? get threshold;

  /// Committee size `n` (`null` when unknown).
  int? get n;
}
