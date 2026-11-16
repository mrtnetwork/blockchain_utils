import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256r1/secp256r1.dart';
import 'package:blockchain_utils/crypto/crypto/keys/dkls23/api/src/api.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/crypto/crypto/keys/dkls23/src/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/dkls23/src/verify_signing.dart';

/// One parsed keyshare record from a framed shares blob:
/// `[party,n,t,curve:u32 LE][x:32][pk:33][shares: n*33]`.
class _ShareRecord {
  final int party;
  final int n;
  final int? t;
  final int curve;
  final BuBytes x;
  final BuBytes pk;
  final List<BuBytes> shares;
  _ShareRecord({
    required this.party,
    required this.n,
    required this.t,
    required this.curve,
    required this.x,
    required this.pk,
    required this.shares,
  });
}

/// Key-share blob codec + quorum validation shared by the DKLs23
/// coordinator keys (both curves).
class _DklsKeyRecords {
  static int readU32(List<int> b, int off) =>
      IntUtils.fromBytes(b, offset: off, length: 4, byteOrder: Endian.little);

  /// Split `frame([share, …])` into raw record bytes.
  static List<BuBytes> unframe(List<int> blob) {
    final out = <BuBytes>[];
    var at = 0;
    while (at < blob.length) {
      if (at + 4 > blob.length) {
        throw CoreErrors.cryptoFailed(
          'Dkls23.unframe',
          reason: 'truncated frame header',
        );
      }
      final len = readU32(blob, at);
      at += 4;
      if (at + len > blob.length) {
        throw CoreErrors.cryptoFailed(
          'Dkls23.unframe',
          reason: 'truncated frame body',
        );
      }
      out.add(BuBytes.from(blob.sublist(at, at + len)));
      at += len;
    }
    return out;
  }

  /// Parse one `[party,n,t,curve:u32 LE][x:32][pk:33][shares: n*33]` record.
  static _ShareRecord parseRecord(List<int> raw) {
    if (raw.length < 16 + 32 + 33) {
      throw CoreErrors.cryptoFailed(
        'Dkls23.parseShare',
        reason: 'short share record',
      );
    }
    final party = readU32(raw, 0);
    final n = readU32(raw, 4);
    final t = readU32(raw, 8);
    final curve = readU32(raw, 12);
    if (raw.length != 16 + 32 + 33 + n * 33) {
      throw CoreErrors.cryptoFailed(
        'Dkls23.parseShare',
        reason: 'share record length mismatch',
      );
    }
    var at = 16;
    final x = BuBytes.from(raw.sublist(at, at + 32));
    at += 32;
    final pk = BuBytes.from(raw.sublist(at, at + 33));
    at += 33;
    final shares = <BuBytes>[];
    for (var i = 0; i < n; i++) {
      shares.add(BuBytes.from(raw.sublist(at, at + 33)));
      at += 33;
    }
    return _ShareRecord(
      party: party,
      n: n,
      t: t == 0 ? null : t,
      curve: curve,
      x: x,
      pk: pk,
      shares: shares,
    );
  }

  static Dkls23Curve curveFromId(int id, String where) {
    if (id == 0) return Dkls23Curve.secp256k1;
    if (id == 1) return Dkls23Curve.secp256r1;
    throw CoreErrors.cryptoFailed(where, reason: 'unknown curve id $id.');
  }

  /// Resolve an optional threshold against `n`: null → `n` (full quorum).
  /// Enforces `n >= 2` and `2 <= t <= n`.
  static int resolveThreshold(int n, int? threshold, String where) {
    if (n < 2) {
      throw CoreErrors.cryptoFailed(
        where,
        reason: 'at least 2 member keys required (got $n).',
      );
    }
    final t = threshold ?? n;
    if (t < 2 || t > n) {
      throw CoreErrors.cryptoFailed(
        where,
        reason: 'need 2 <= threshold <= n (got t=$t, n=$n).',
      );
    }
    return t;
  }

  /// Validate constructor arguments shared by both curves: members (when
  /// present) hold at least 2 keys, `n` (when known) is at least 2 and
  /// matches the member count, `threshold` (when known) satisfies
  /// `2 <= t <= n`.
  static void checkQuorum({
    required String op,
    required int? memberCount,
    required int? threshold,
    required int? n,
  }) {
    if (memberCount != null && memberCount < 2) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'at least 2 member keys required (got $memberCount).',
      );
    }
    if (n != null && n < 2) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'at least 2 parties required (got n=$n).',
      );
    }
    if (n != null && memberCount != null && n != memberCount) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'n=$n does not match $memberCount member keys.',
      );
    }
    if (threshold != null) {
      final bound = memberCount ?? n;
      if (threshold < 2 || (bound != null && threshold > bound)) {
        throw CoreErrors.cryptoFailed(
          op,
          reason: 'need 2 <= threshold <= ${bound ?? 'n'} (got $threshold).',
        );
      }
    }
  }

  /// Parse a framed shares blob into records sorted by party index,
  /// requiring exactly `n` records on `curveId`.
  static List<_ShareRecord> sortedRecords(
    List<int> blob,
    int n,
    int curveId,
    String op,
  ) {
    final recs = unframe(blob).map(parseRecord).toList();
    if (recs.length != n) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'expected $n shares (got ${recs.length}).',
      );
    }
    for (final r in recs) {
      if (r.curve != curveId || r.n != n) {
        throw CoreErrors.cryptoFailed(op, reason: 'mixed quorum records.');
      }
    }
    final parties = recs.map((r) => r.party).toSet();
    if (parties.length != recs.length) {
      throw CoreErrors.cryptoFailed(op, reason: 'duplicate party records.');
    }
    recs.sort((a, b) => a.party.compareTo(b.party));
    return recs;
  }
}

// ---------------------------------------------------------------------------
// Public keys.
// ---------------------------------------------------------------------------

/// Base class for a DKLs23 aggregate public key: the group key verifiers
/// check the final threshold signature against, plus the member keys of
/// the quorum.
///
/// The base holds no key bytes itself: each concrete subclass stores
/// strongly-typed curve points (`Secp256k1PublicKey` /
/// `Secp256r1PublicKey`). All signing/verification behavior lives in
/// [IDkls23VerificationKey] (`verify_signing.dart`).
abstract class BaseDkls23PublicKey<T extends IPublicKey<IVerifiyingParams>>
    extends IDkls23VerificationKey
    with Equality
    implements IPublicKey<Dkls23VerifyParams> {
  /// Aggregate (group) key: the key verifiers check the final threshold
  /// signature against.
  abstract final T aggKey;

  /// Member keys of the quorum (`null` when stripped).
  abstract final List<T>? members;

  @override
  CryptoKeyType get type;

  /// 32-byte x-only form of the group key.
  BuBytes xOnly() =>
      blockchainUtils.api.dkls23.xOnly(curve: curve, groupPk: aggKey.toBytes());

  /// Verify a threshold signature over a 32-byte message hash.
  bool verifyHash({
    required List<int> msgHash,
    required IECDSASignature signature,
  }) {
    return blockchainUtils.api.dkls23.verify(
      curve: curve,
      groupPk: aggKey.toBytes(),
      msgHash: msgHash,
      signature: signature.toBytes(),
    );
  }

  @override
  bool verify(Dkls23VerifyParams params) =>
      verifyHash(msgHash: params.msgHash, signature: params.signature);

  /// Dispatching parse: reads the embedded curve id and returns the
  /// matching subclass.
  static BaseDkls23PublicKey fromBytes(List<int> bytes) {
    return layout().deserialize(bytes).value;
  }

  static bool isValidBytes(List<int> keyBytes) {
    try {
      BaseDkls23PublicKey.fromBytes(keyBytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    if (encoding != CryptoKeyEncoding.base) return false;
    return isValidBytes(keyBytes);
  }

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return CryptoKeysUtils.ensureSupportPubKeyMode(
      mode: mode,
      type: type,
      onModeBytes: (mode) => layout().serialize(this),
    );
  }

  @override
  List<dynamic> get variables => [curve, threshold, n, aggKey.toBytes()];

  static Layout<BaseDkls23PublicKey> layout() =>
      ObjSeqLayout<BaseDkls23PublicKey>(
        [
          LayoutConst.u32(property: 'curve'),
          LayoutConst.fixedBlobN(33, property: 'groupPk'),
          LayoutConst.optional(
            LayoutConst.vec(LayoutConst.fixedBlobN(33), property: 'members'),
            property: 'members',
          ),
          LayoutConst.optional(LayoutConst.u32(), property: 'threshold'),
          LayoutConst.optional(LayoutConst.u32(), property: 'n'),
        ],
        build: (values) {
          final curveId = JsonParser.valueAs<int>(values.elementAtOrNull(0));
          final pk = JsonParser.valueAsBytes(values.elementAtOrNull(1));
          if (pk == null) {
            throw CoreErrors.cryptoFailed(
              'Dkls23AggregatePublicKey',
              reason: 'missing group key.',
            );
          }
          final members =
              JsonParser.valueAsList<List<List<int>>?>(
                values.elementAtOrNull(2),
              )?.map((e) => BuBytes.from(e)).toList();
          final tRaw = values.elementAtOrNull(3);
          final nRaw = values.elementAtOrNull(4);
          final threshold = tRaw is int ? tRaw : null;
          final n = nRaw is int ? nRaw : null;
          final curve = _DklsKeyRecords.curveFromId(
            curveId,
            'Dkls23AggregatePublicKey',
          );
          if (curve == Dkls23Curve.secp256k1) {
            return Dkls23Secp256k1PublicKey._(
              Secp256k1PublicKey.fromBytes(pk),
              members?.map((e) => Secp256k1PublicKey.fromBytes(e)).toList(),
              threshold: threshold,
              n: n,
            );
          }
          return Dkls23Secp256r1PublicKey._(
            Secp256r1PublicKey.fromBytes(pk),
            members?.map((e) => Secp256r1PublicKey.fromBytes(e)).toList(),
            threshold: threshold,
            n: n,
          );
        },
        unbuild:
            (value) => [
              value.curve.id,
              value.aggKey.toBytes(),
              value.members?.map((e) => e.toBytes()).toList(),
              value.threshold,
              value.n,
            ],
      );
}

/// DKLs23 aggregate public key over secp256k1.
class Dkls23Secp256k1PublicKey extends BaseDkls23PublicKey<Secp256k1PublicKey> {
  @override
  final Secp256k1PublicKey aggKey;
  @override
  final List<Secp256k1PublicKey>? members;
  @override
  final int? threshold;
  @override
  final int? n;
  Dkls23Secp256k1PublicKey._(
    this.aggKey,
    List<Secp256k1PublicKey>? members, {
    this.threshold,
    int? n,
  }) : members = members?.emptyAsNull?.immutable,
       n = n ?? members?.length {
    _DklsKeyRecords.checkQuorum(
      op: 'Dkls23Secp256k1PublicKey',
      memberCount: this.members?.length,
      threshold: threshold,
      n: this.n,
    );
  }

  @override
  Dkls23Curve get curve => Dkls23Curve.secp256k1;
  @override
  CryptoKeyType get type => CryptoKeyType.dkls23K1;

  /// Aggregate typed member public keys. `threshold` defaults to `n`
  /// (full quorum); enforced as `2 <= t <= n`, `n >= 2`.
  factory Dkls23Secp256k1PublicKey.aggPublicKeys(
    List<Secp256k1PublicKey> keys, {
    int? threshold,
  }) {
    final t = _DklsKeyRecords.resolveThreshold(
      keys.length,
      threshold,
      'Dkls23Secp256k1PublicKey.aggPublicKeys',
    );
    final agg = blockchainUtils.api.dkls23.aggPublicKeys(
      curve: Dkls23Curve.secp256k1,
      members: keys.expand((e) => e.toBytes()).toList(),
      n: keys.length,
      threshold: t,
    );
    return Dkls23Secp256k1PublicKey._(
      Secp256k1PublicKey.fromBytes(agg),
      keys,
      threshold: t,
      n: keys.length,
    );
  }

  factory Dkls23Secp256k1PublicKey.fromBytes(List<int> bytes) {
    final key = BaseDkls23PublicKey.fromBytes(bytes);
    if (key is! Dkls23Secp256k1PublicKey) {
      throw CoreErrors.cryptoFailed(
        'Dkls23Secp256k1PublicKey',
        reason: 'curve mismatch.',
      );
    }
    return key;
  }

  static bool isValidBytes(List<int> keyBytes) =>
      BaseDkls23PublicKey.isValidBytes(keyBytes);

  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) => BaseDkls23PublicKey.isValidKeyEncoding(keyBytes, encoding);
}

/// DKLs23 aggregate public key over secp256r1 (NIST P-256).
class Dkls23Secp256r1PublicKey extends BaseDkls23PublicKey<Secp256r1PublicKey> {
  @override
  final Secp256r1PublicKey aggKey;
  @override
  final List<Secp256r1PublicKey>? members;
  @override
  final int? threshold;
  @override
  final int? n;
  Dkls23Secp256r1PublicKey._(
    this.aggKey,
    List<Secp256r1PublicKey>? members, {
    this.threshold,
    int? n,
  }) : members = members?.emptyAsNull?.immutable,
       n = n ?? members?.length {
    _DklsKeyRecords.checkQuorum(
      op: 'Dkls23Secp256r1PublicKey',
      memberCount: this.members?.length,
      threshold: threshold,
      n: this.n,
    );
  }

  @override
  Dkls23Curve get curve => Dkls23Curve.secp256r1;
  @override
  CryptoKeyType get type => CryptoKeyType.dkls23R1;

  /// Aggregate typed member public keys. `threshold` defaults to `n`
  /// (full quorum); enforced as `2 <= t <= n`, `n >= 2`.
  factory Dkls23Secp256r1PublicKey.aggPublicKeys(
    List<Secp256r1PublicKey> keys, {
    int? threshold,
  }) {
    final t = _DklsKeyRecords.resolveThreshold(
      keys.length,
      threshold,
      'Dkls23Secp256r1PublicKey.aggPublicKeys',
    );
    final agg = blockchainUtils.api.dkls23.aggPublicKeys(
      curve: Dkls23Curve.secp256r1,
      members: keys.expand((e) => e.toBytes()).toList(),
      n: keys.length,
      threshold: t,
    );
    return Dkls23Secp256r1PublicKey._(
      Secp256r1PublicKey.fromBytes(agg),
      keys.toList(),
      threshold: t,
      n: keys.length,
    );
  }

  factory Dkls23Secp256r1PublicKey.fromBytes(List<int> bytes) {
    final key = BaseDkls23PublicKey.fromBytes(bytes);
    if (key is! Dkls23Secp256r1PublicKey) {
      throw CoreErrors.cryptoFailed(
        'Dkls23Secp256r1PublicKey',
        reason: 'curve mismatch.',
      );
    }
    return key;
  }

  static bool isValidBytes(List<int> keyBytes) =>
      BaseDkls23PublicKey.isValidBytes(keyBytes);

  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) => BaseDkls23PublicKey.isValidKeyEncoding(keyBytes, encoding);
}

// ---------------------------------------------------------------------------
// Private keys.
// ---------------------------------------------------------------------------

/// DKLs23 coordinator key over secp256k1, mirroring [Musig2PrivateKey]:
/// typed share secrets in party order plus the aggregate public key.
/// The [sign] behavior itself lives in [IDkls23SigningKey]
/// (`verify_signing.dart`).
class Dkls23Secp256k1PrivateKey
    extends
        IDkls23SigningKey<
          Dkls23Secp256k1PublicKey,
          Secp256k1PrivateKey,
          Secp256k1PublicKey
        >
    with Equality
    implements
        IPrivateKey<
          IECDSASignature,
          Dkls23SignParams,
          Dkls23Secp256k1PublicKey
        > {
  @override
  final Dkls23Secp256k1PublicKey publicKey;
  @override
  final List<Secp256k1PrivateKey> secretKeys;
  @override
  Dkls23Curve get curve => Dkls23Curve.secp256k1;
  @override
  CryptoKeyType get type => CryptoKeyType.dkls23K1;
  @override
  int? get threshold => publicKey.threshold;
  Dkls23Secp256k1PrivateKey._(
    this.publicKey,
    List<Secp256k1PrivateKey> secretKeys,
  ) : secretKeys = secretKeys.immutable;

  @override
  SecretBytes takeSecretAt(int index) => secretKeys[index].takeSecretKey();

  /// Assemble from parsed ceremony records (party order).
  static Dkls23Secp256k1PrivateKey _fromRecords(
    List<_ShareRecord> recs,
    int t,
  ) {
    final first = recs.first;
    return Dkls23Secp256k1PrivateKey._(
      Dkls23Secp256k1PublicKey._(
        Secp256k1PublicKey.fromBytes(first.pk),
        first.shares.map((e) => Secp256k1PublicKey.fromBytes(e)).toList(),
        threshold: t,
        n: first.n,
      ),
      recs.map((r) => Secp256k1PrivateKey.fromBytes(r.x)).toList(),
    );
  }

  /// Run DKG and collect all `n` party shares.
  ///
  /// `threshold` defaults to `n` (full quorum); enforced as
  /// `2 <= t <= n`, `n >= 2`. `sid` is the session id: domain-separation
  /// bytes binding every message of one ceremony (same `sid` twice
  /// replays the transcript domain — always use a fresh random `sid`
  /// per ceremony). `seeds` holds one 32-byte seed per party and drives
  /// deterministic ChaCha20 randomness (no OS RNG: WASM-safe and
  /// test-reproducible). Production callers MUST fill seeds from an OS
  /// CSPRNG.
  factory Dkls23Secp256k1PrivateKey.generate({
    required List<int> sid,
    required int n,
    required List<int> seeds,
    int? threshold,
  }) {
    const op = 'Dkls23Secp256k1PrivateKey.generate';
    final t = _DklsKeyRecords.resolveThreshold(n, threshold, op);
    final blob = blockchainUtils.api.dkls23.dkg(
      curve: Dkls23Curve.secp256k1,
      sid: sid,
      n: n,
      t: t,
      seeds: seeds,
    );
    return Dkls23Secp256k1PrivateKey._fromRecords(
      _DklsKeyRecords.sortedRecords(blob, n, Dkls23Curve.secp256k1.id, op),
      t,
    );
  }

  /// Build an additive quorum from pre-existing private keys (no DKG):
  /// each key's secret becomes party `i`'s additive share of the joint
  /// key, and the group key is derived from the members' public keys.
  /// Threshold is `n` (every party signs). Secrets are read (not
  /// consumed) via `takeSecretKey`.
  factory Dkls23Secp256k1PrivateKey.fromSecretKeys(
    List<Secp256k1PrivateKey> keys,
  ) {
    const op = 'Dkls23Secp256k1PrivateKey.fromSecretKeys';
    if (keys.length < 2) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'at least 2 secret keys required.',
      );
    }
    final secrets = <int>[];
    try {
      for (final k in keys) {
        k.takeSecretKey().useValue(secrets.addAll);
      }
      final blob = blockchainUtils.api.dkls23.importSecrets(
        curve: Dkls23Curve.secp256k1,
        secrets: secrets,
        n: keys.length,
      );
      return Dkls23Secp256k1PrivateKey._fromRecords(
        _DklsKeyRecords.sortedRecords(
          blob,
          keys.length,
          Dkls23Curve.secp256k1.id,
          op,
        ),
        keys.length,
      );
    } finally {
      secrets.fillRange(0, secrets.length, 0);
    }
  }

  /// Assemble from an aggregate key plus held shares (MuSig2 `partial`
  /// mirror). `secretKeys[i]` must be party `i`'s share.
  factory Dkls23Secp256k1PrivateKey.partial({
    required Dkls23Secp256k1PublicKey publicKey,
    List<Secp256k1PrivateKey> secretKeys = const [],
  }) {
    return Dkls23Secp256k1PrivateKey._(publicKey, secretKeys);
  }

  /// Rotate shares (group key unchanged), returning the refreshed key.
  /// `sid`/`seeds` default to fresh OS randomness when null; explicit
  /// `seeds` must hold 32 bytes per held share.
  Dkls23Secp256k1PrivateKey refresh({List<int>? sid, List<int>? seeds}) {
    const op = 'Dkls23Secp256k1PrivateKey.refresh';
    final t = publicKey.threshold ?? publicKey.n ?? secretKeys.length;
    final indices = List<int>.generate(secretKeys.length, (i) => i);
    final useSeeds =
        seeds ?? QuickCrypto.generateRandom(length: indices.length * 32);
    if (useSeeds.length != indices.length * 32) {
      throw CoreErrors.cryptoFailed(
        op,
        reason:
            'seeds must hold 32 bytes per share '
            '(need ${indices.length * 32}, got ${useSeeds.length}).',
      );
    }
    final blob = withRecordsBlob(
      indices,
      (frames) => blockchainUtils.api.dkls23.refresh(
        sid: sid ?? QuickCrypto.generateRandom(length: 32),
        sharesBlob: frames,
        seeds: useSeeds,
      ),
    );
    return Dkls23Secp256k1PrivateKey._fromRecords(
      _DklsKeyRecords.sortedRecords(
        blob,
        secretKeys.length,
        Dkls23Curve.secp256k1.id,
        op,
      ),
      t,
    );
  }

  factory Dkls23Secp256k1PrivateKey.fromBytes(List<int> bytes) {
    return layout().deserialize(bytes).value;
  }

  static bool isValidBytes(List<int> keyBytes) {
    try {
      Dkls23Secp256k1PrivateKey.fromBytes(keyBytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Layout<Dkls23Secp256k1PrivateKey> layout() =>
      ObjSeqLayout<Dkls23Secp256k1PrivateKey>(
        [
          BaseDkls23PublicKey.layout(),
          LayoutConst.vec(LayoutConst.fixedBlobN(32), property: 'secrets'),
        ],
        build: (values) {
          final pub = JsonParser.valueAs(values.elementAtOrNull(0));
          if (pub is! Dkls23Secp256k1PublicKey) {
            throw CoreErrors.cryptoFailed(
              'Dkls23Secp256k1PrivateKey',
              reason: 'curve mismatch.',
            );
          }
          final secretKeys =
              JsonParser.valueEnsureAsList<List<int>>(
                values.elementAtOrNull(1),
              ).map((e) => Secp256k1PrivateKey.fromBytes(e)).toList();
          return Dkls23Secp256k1PrivateKey.partial(
            publicKey: pub,
            secretKeys: secretKeys,
          );
        },
        unbuild:
            (value) => [
              value.publicKey,
              value.secretKeys.map((e) => e.takeSecretKey()).toList(),
            ],
      );

  @override
  Dkls23Secp256k1PublicKey verificationKey() => publicKey;

  @override
  SecretBytes takeSecretKey({SecretTransform? transform}) {
    return SecretBytes.take(layout().serialize(this), transform: transform);
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    return takeSecretKey(transform: transform);
  }

  @override
  void dispose() {
    for (final k in secretKeys) {
      k.dispose();
    }
  }

  @override
  List<dynamic> get variables => [publicKey];
}

/// DKLs23 coordinator key over secp256r1 (NIST P-256), mirroring
/// [Musig2PrivateKey]: typed share secrets in party order plus the
/// aggregate public key. The [sign] behavior itself lives in
/// [IDkls23SigningKey] (`verify_signing.dart`).
class Dkls23Secp256r1PrivateKey
    extends
        IDkls23SigningKey<
          Dkls23Secp256r1PublicKey,
          Secp256r1PrivateKey,
          Secp256r1PublicKey
        >
    with Equality
    implements
        IPrivateKey<
          IECDSASignature,
          Dkls23SignParams,
          Dkls23Secp256r1PublicKey
        > {
  @override
  final Dkls23Secp256r1PublicKey publicKey;
  @override
  final List<Secp256r1PrivateKey> secretKeys;
  @override
  Dkls23Curve get curve => Dkls23Curve.secp256r1;
  @override
  CryptoKeyType get type => CryptoKeyType.dkls23R1;
  @override
  int? get threshold => publicKey.threshold;
  Dkls23Secp256r1PrivateKey._(
    this.publicKey,
    List<Secp256r1PrivateKey> secretKeys,
  ) : secretKeys = secretKeys.immutable;

  @override
  SecretBytes takeSecretAt(int index) => secretKeys[index].takeSecretKey();

  /// Assemble from parsed ceremony records (party order).
  static Dkls23Secp256r1PrivateKey _fromRecords(
    List<_ShareRecord> recs,
    int t,
  ) {
    final first = recs.first;
    return Dkls23Secp256r1PrivateKey._(
      Dkls23Secp256r1PublicKey._(
        Secp256r1PublicKey.fromBytes(first.pk),
        first.shares.map((e) => Secp256r1PublicKey.fromBytes(e)).toList(),
        threshold: t,
        n: first.n,
      ),
      recs.map((r) => Secp256r1PrivateKey.fromBytes(r.x)).toList(),
    );
  }

  /// Run DKG and collect all `n` party shares.
  ///
  /// `threshold` defaults to `n` (full quorum); enforced as
  /// `2 <= t <= n`, `n >= 2`. `sid` is the session id: domain-separation
  /// bytes binding every message of one ceremony (same `sid` twice
  /// replays the transcript domain — always use a fresh random `sid`
  /// per ceremony). `seeds` holds one 32-byte seed per party and drives
  /// deterministic ChaCha20 randomness (no OS RNG: WASM-safe and
  /// test-reproducible). Production callers MUST fill seeds from an OS
  /// CSPRNG.
  factory Dkls23Secp256r1PrivateKey.generate({
    required List<int> sid,
    required int n,
    required List<int> seeds,
    int? threshold,
  }) {
    const op = 'Dkls23Secp256r1PrivateKey.generate';
    final t = _DklsKeyRecords.resolveThreshold(n, threshold, op);
    final blob = blockchainUtils.api.dkls23.dkg(
      curve: Dkls23Curve.secp256r1,
      sid: sid,
      n: n,
      t: t,
      seeds: seeds,
    );
    return Dkls23Secp256r1PrivateKey._fromRecords(
      _DklsKeyRecords.sortedRecords(blob, n, Dkls23Curve.secp256r1.id, op),
      t,
    );
  }

  /// Build an additive quorum from pre-existing private keys (no DKG):
  /// each key's secret becomes party `i`'s additive share of the joint
  /// key, and the group key is derived from the members' public keys.
  /// Threshold is `n` (every party signs). Secrets are read (not
  /// consumed) via `takeSecretKey`.
  factory Dkls23Secp256r1PrivateKey.fromSecretKeys(
    List<Secp256r1PrivateKey> keys,
  ) {
    const op = 'Dkls23Secp256r1PrivateKey.fromSecretKeys';
    if (keys.length < 2) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'at least 2 secret keys required.',
      );
    }
    final secrets = <int>[];
    try {
      for (final k in keys) {
        k.takeSecretKey().useValue(secrets.addAll);
      }
      final blob = blockchainUtils.api.dkls23.importSecrets(
        curve: Dkls23Curve.secp256r1,
        secrets: secrets,
        n: keys.length,
      );
      return Dkls23Secp256r1PrivateKey._fromRecords(
        _DklsKeyRecords.sortedRecords(
          blob,
          keys.length,
          Dkls23Curve.secp256r1.id,
          op,
        ),
        keys.length,
      );
    } finally {
      secrets.fillRange(0, secrets.length, 0);
    }
  }

  /// Assemble from an aggregate key plus held shares (MuSig2 `partial`
  /// mirror). `secretKeys[i]` must be party `i`'s share.
  factory Dkls23Secp256r1PrivateKey.partial({
    required Dkls23Secp256r1PublicKey publicKey,
    List<Secp256r1PrivateKey> secretKeys = const [],
  }) {
    return Dkls23Secp256r1PrivateKey._(publicKey, secretKeys.toList());
  }

  /// Rotate shares (group key unchanged), returning the refreshed key.
  /// `sid`/`seeds` default to fresh OS randomness when null; explicit
  /// `seeds` must hold 32 bytes per held share.
  Dkls23Secp256r1PrivateKey refresh({List<int>? sid, List<int>? seeds}) {
    const op = 'Dkls23Secp256r1PrivateKey.refresh';
    final t = publicKey.threshold ?? publicKey.n ?? secretKeys.length;
    final indices = List<int>.generate(secretKeys.length, (i) => i);
    final useSeeds =
        seeds ?? QuickCrypto.generateRandom(length: indices.length * 32);
    if (useSeeds.length != indices.length * 32) {
      throw CoreErrors.cryptoFailed(
        op,
        reason:
            'seeds must hold 32 bytes per share '
            '(need ${indices.length * 32}, got ${useSeeds.length}).',
      );
    }
    final blob = withRecordsBlob(
      indices,
      (frames) => blockchainUtils.api.dkls23.refresh(
        sid: sid ?? QuickCrypto.generateRandom(length: 32),
        sharesBlob: frames,
        seeds: useSeeds,
      ),
    );
    return Dkls23Secp256r1PrivateKey._fromRecords(
      _DklsKeyRecords.sortedRecords(
        blob,
        secretKeys.length,
        Dkls23Curve.secp256r1.id,
        op,
      ),
      t,
    );
  }

  factory Dkls23Secp256r1PrivateKey.fromBytes(List<int> bytes) {
    return layout().deserialize(bytes).value;
  }

  static bool isValidBytes(List<int> keyBytes) {
    try {
      Dkls23Secp256r1PrivateKey.fromBytes(keyBytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Layout<Dkls23Secp256r1PrivateKey> layout() =>
      ObjSeqLayout<Dkls23Secp256r1PrivateKey>(
        [
          BaseDkls23PublicKey.layout(),
          LayoutConst.vec(LayoutConst.fixedBlobN(32), property: 'secrets'),
        ],
        build: (values) {
          final pub = JsonParser.valueAs(values.elementAtOrNull(0));
          if (pub is! Dkls23Secp256r1PublicKey) {
            throw CoreErrors.cryptoFailed(
              'Dkls23Secp256r1PrivateKey',
              reason: 'curve mismatch.',
            );
          }
          final secretKeys =
              JsonParser.valueEnsureAsList<List<int>>(
                values.elementAtOrNull(1),
              ).map((e) => Secp256r1PrivateKey.fromBytes(e)).toList();
          return Dkls23Secp256r1PrivateKey.partial(
            publicKey: pub,
            secretKeys: secretKeys,
          );
        },
        unbuild:
            (value) => [
              value.publicKey,
              value.secretKeys.map((e) => e.takeSecretKey()).toList(),
            ],
      );

  @override
  Dkls23Secp256r1PublicKey verificationKey() => publicKey;

  @override
  SecretBytes takeSecretKey({SecretTransform? transform}) {
    return SecretBytes.take(layout().serialize(this), transform: transform);
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    return takeSecretKey(transform: transform);
  }

  @override
  void dispose() {
    for (final k in secretKeys) {
      k.dispose();
    }
  }

  @override
  List<dynamic> get variables => [publicKey];
}
