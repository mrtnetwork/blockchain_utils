import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';

import 'package:blockchain_utils/crypto/crypto/keys/frost/src/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/frost/src/verify_signing.dart';

/// One member entry: FROST identifier + share public key.
class FrostK1Member implements FrostMember<Secp256k1PublicKey> {
  @override
  final int id;
  @override
  final Secp256k1PublicKey key;
  const FrostK1Member({required this.id, required this.key});
}

/// One member entry: FROST identifier + share public key.
class FrostEdMember implements FrostMember<ED25519PublicKey> {
  @override
  final int id;
  @override
  final ED25519PublicKey key;
  const FrostEdMember({required this.id, required this.key});
}

/// Key-structure validation shared by the FROST coordinator keys (both
/// curves): quorum/threshold checks, identifier checks, share randomness.
class _FrostKeys {
  /// Resolve an optional threshold against `n`: null → `n` (full quorum).
  /// Enforces `n >= 2` and `2 <= t <= n`.
  static int resolveThreshold(int n, int? threshold, String where) {
    if (n < 2) {
      throw CoreErrors.cryptoFailed(
        where,
        reason: 'at least 2 participants required (got $n).',
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

  /// Default FROST identifiers `1..=n`.
  static List<int> defaultIds(int n) => List<int>.generate(n, (i) => i + 1);

  /// Wire `u64` member id to a validated participant id (u32 range).
  static int idFromWire(BigInt v, String where) {
    if (v <= BigInt.zero || v > BigInt.from(0xFFFFFFFF)) {
      throw CoreErrors.cryptoFailed(where, reason: 'identifier out of range.');
    }
    return v.toInt();
  }

  /// Unique non-zero identifiers (u32 range for native interop).
  static List<int> checkIds(List<int> ids, int n, String where) {
    if (ids.length != n) {
      throw CoreErrors.cryptoFailed(
        where,
        reason: 'identifiers/secrets length mismatch.',
      );
    }
    final seen = <int>{};
    for (final id in ids) {
      if (id <= 0 || id > 0xFFFFFFFF || !seen.add(id)) {
        throw CoreErrors.cryptoFailed(
          where,
          reason: 'identifiers must be unique in 1..0xFFFFFFFF.',
        );
      }
    }
    return ids.toList();
  }

  /// Fresh uniform secp256k1 scalar bytes from a typed random key.
  /// Validity comes from the key type itself; the keys layer never
  /// range-checks scalars (that choice lives in the backend).
  static List<int> randomK1ScalarBytes() {
    final key = Secp256k1PrivateKey.random();
    try {
      return key.takeSecretKey().useValue((b) => List<int>.from(b));
    } finally {
      key.dispose();
    }
  }

  /// Validate constructor arguments shared by both curves.
  static void checkQuorum({
    required String op,
    required int? memberCount,
    required int? threshold,
    required int? n,
    required List<int>? ids,
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
    if (ids != null) {
      final seen = <int>{};
      for (final id in ids) {
        if (id <= 0 || id > 0xFFFFFFFF || !seen.add(id)) {
          throw CoreErrors.cryptoFailed(
            op,
            reason: 'identifiers must be unique in 1..0xFFFFFFFF.',
          );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Public keys.
// ---------------------------------------------------------------------------

/// Base class for a FROST aggregate public key: the group key verifiers
/// check the final threshold signature against, plus the member
/// entries `(id, key)` of the quorum.
///
/// `T` is the member/aggregate key type (`Secp256k1PublicKey` /
/// `ED25519PublicKey`) flowing through signing and [verificationKey].
/// All signing/verification behavior lives in [IFrostVerificationKey]
/// and [IFrostSigningKey] (`verify_signing.dart`).
abstract class BaseFrostPublicKey<T extends IPublicKey<IVerifiyingParams>>
    extends IFrostVerificationKey
    with Equality
    implements IPublicKey<FrostVerifyingParams> {
  /// Aggregate (group) key: the key verifiers check the final
  /// threshold signature against.
  abstract final T aggKey;

  /// Member entries of the quorum (`null` when stripped).
  abstract final List<FrostMember<T>>? members;

  @override
  CryptoKeyType get type;

  @override
  BuBytes groupKeyBytes() => aggKey.toBytes();

  @override
  List<dynamic> get variables => [curve, threshold, n, aggKey.toBytes()];
}

/// A FROST(secp256k1) group public key: group key + member entries +
/// threshold.
class FrostSecp256k1PublicKey extends BaseFrostPublicKey<Secp256k1PublicKey> {
  @override
  final Secp256k1PublicKey aggKey;
  @override
  final List<FrostK1Member>? members;
  @override
  final int? threshold;
  @override
  final int? n;
  FrostSecp256k1PublicKey._(
    this.aggKey,
    List<FrostK1Member>? members, {
    this.threshold,
    int? n,
  }) : members = members?.emptyAsNull?.immutable,
       n = n ?? members?.length {
    _FrostKeys.checkQuorum(
      op: 'FrostSecp256k1PublicKey',
      memberCount: this.members?.length,
      threshold: threshold,
      n: this.n,
      ids: this.members?.map((m) => m.id).toList(),
    );
  }

  @override
  FrostCurve get curve => FrostCurve.secp256k1;
  @override
  CryptoKeyType get type => CryptoKeyType.frostK1;

  /// Aggregate typed member public keys. `identifiers` default to
  /// `1..=n`; `threshold` defaults to `n` (full quorum). A null
  /// threshold sums the members (additive quorum); an explicit `t`
  /// Lagrange-interpolates them at zero (threshold quorum).
  factory FrostSecp256k1PublicKey.aggPublicKeys(
    List<Secp256k1PublicKey> keys, {
    List<int>? identifiers,
    int? threshold,
  }) {
    const op = 'FrostSecp256k1PublicKey.aggPublicKeys';
    final ids =
        identifiers == null
            ? _FrostKeys.defaultIds(keys.length)
            : _FrostKeys.checkIds(identifiers, keys.length, op);
    final group = blockchainUtils.api.frost.k1GroupFromMembers(
      ids: ids,
      pubsConcat: keys.expand((e) => e.toBytes()).toList(),
      threshold: threshold ?? 0,
    );
    return FrostSecp256k1PublicKey._(
      Secp256k1PublicKey.fromBytes(group),
      [
        for (var k = 0; k < keys.length; k++)
          FrostK1Member(id: ids[k], key: keys[k]),
      ],
      threshold: threshold,
      n: keys.length,
    );
  }

  factory FrostSecp256k1PublicKey.fromBytes(List<int> bytes) {
    return layout().deserialize(bytes).value;
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      FrostSecp256k1PublicKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    switch (encoding) {
      case CryptoKeyEncoding.base:
        try {
          final decode = layout().deserialize(keyBytes);
          return decode.consumed == keyBytes.length;
        } catch (_) {
          return false;
        }
      case CryptoKeyEncoding.uncompressed:
        return false;
    }
  }

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return CryptoKeysUtils.ensureSupportPubKeyMode(
      mode: mode,
      type: type,
      onModeBytes:
          (mode) => switch (mode) {
            CryptoKeyEncoding.base => layout().serialize(this),
            CryptoKeyEncoding.uncompressed => null,
          },
    );
  }

  static Layout<FrostSecp256k1PublicKey> layout() =>
      ObjSeqLayout<FrostSecp256k1PublicKey>(
        [
          LayoutConst.fixedBlobN(33, property: 'group'),
          LayoutConst.optional(
            LayoutConst.vec(
              LayoutConst.struct([
                LayoutConst.u64(property: 'id'),
                LayoutConst.fixedBlobN(33, property: 'key'),
              ]),
              property: 'members',
            ),
            property: 'members',
          ),
          LayoutConst.u16(property: 't'),
          LayoutConst.optional(LayoutConst.u32(), property: 'n'),
        ],
        build: (values) {
          var at = 0;
          final group = Secp256k1PublicKey.fromBytes(
            JsonParser.valueAsBytes(values[at++])!,
          );
          final members =
              JsonParser.valueAsList<List<Map<String, dynamic>>?>(
                values[at++],
              )?.map((m) {
                final keyBytes = JsonParser.valueAsBytes(m['key']);
                if (keyBytes == null) {
                  throw CoreErrors.cryptoFailed(
                    'FrostPublicKey',
                    reason: 'missing member.',
                  );
                }
                return FrostK1Member(
                  id: _FrostKeys.idFromWire(
                    JsonParser.valueAsBigInt<BigInt>(m['id']),
                    'FrostSecp256k1PublicKey',
                  ),
                  key: Secp256k1PublicKey.fromBytes(keyBytes),
                );
              }).toList();
          final tRaw = (values[at++] as int);
          final nRaw = values[at++];
          return FrostSecp256k1PublicKey._(
            group,
            members,
            threshold: tRaw == 0 ? null : tRaw,
            n: nRaw is int ? nRaw : null,
          );
        },
        unbuild:
            (value) => [
              value.aggKey.toBytes(),
              value.members
                  ?.map(
                    (m) => {'id': BigInt.from(m.id), 'key': m.key.toBytes()},
                  )
                  .toList(),
              value.threshold ?? 0,
              value.n,
            ],
      );
}

/// A FROST(Ed25519) group public key: group key + member entries +
/// threshold.
class FrostEd25519PublicKey extends BaseFrostPublicKey<ED25519PublicKey> {
  @override
  final ED25519PublicKey aggKey;
  @override
  final List<FrostEdMember>? members;
  @override
  final int? threshold;
  @override
  final int? n;
  FrostEd25519PublicKey._(
    this.aggKey,
    List<FrostEdMember>? members, {
    this.threshold,
    int? n,
  }) : members = members?.emptyAsNull?.immutable,
       n = n ?? members?.length {
    _FrostKeys.checkQuorum(
      op: 'FrostEd25519PublicKey',
      memberCount: this.members?.length,
      threshold: threshold,
      n: this.n,
      ids: this.members?.map((m) => m.id).toList(),
    );
  }

  @override
  FrostCurve get curve => FrostCurve.ed25519;
  @override
  CryptoKeyType get type => CryptoKeyType.frostEd25519;

  /// Aggregate typed member public keys. `identifiers` default to
  /// `1..=n`; `threshold` defaults to `n` (full quorum). A null
  /// threshold sums the members (additive quorum); an explicit `t`
  /// Lagrange-interpolates them at zero (threshold quorum).
  factory FrostEd25519PublicKey.aggPublicKeys(
    List<ED25519PublicKey> keys, {
    List<int>? identifiers,
    int? threshold,
  }) {
    const op = 'FrostEd25519PublicKey.aggPublicKeys';
    final ids =
        identifiers == null
            ? _FrostKeys.defaultIds(keys.length)
            : _FrostKeys.checkIds(identifiers, keys.length, op);
    final group = blockchainUtils.api.frost.edGroupFromMembers(
      ids: ids,
      pubsConcat: keys.expand((e) => e.toBytes()).toList(),
      threshold: threshold ?? 0,
    );
    return FrostEd25519PublicKey._(
      ED25519PublicKey.fromBytes(group),
      [
        for (var k = 0; k < keys.length; k++)
          FrostEdMember(id: ids[k], key: keys[k]),
      ],
      threshold: threshold,
      n: keys.length,
    );
  }

  factory FrostEd25519PublicKey.fromBytes(List<int> bytes) {
    return layout().deserialize(bytes).value;
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      FrostEd25519PublicKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    switch (encoding) {
      case CryptoKeyEncoding.base:
        try {
          final decode = layout().deserialize(keyBytes);
          return decode.consumed == keyBytes.length;
        } catch (_) {
          return false;
        }
      case CryptoKeyEncoding.uncompressed:
        return false;
    }
  }

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return CryptoKeysUtils.ensureSupportPubKeyMode(
      mode: mode,
      type: type,
      onModeBytes:
          (mode) => switch (mode) {
            CryptoKeyEncoding.base => layout().serialize(this),
            CryptoKeyEncoding.uncompressed => null,
          },
    );
  }

  static Layout<FrostEd25519PublicKey> layout() =>
      ObjSeqLayout<FrostEd25519PublicKey>(
        [
          LayoutConst.fixedBlobN(32, property: 'group'),
          LayoutConst.optional(
            LayoutConst.vec(
              LayoutConst.struct([
                LayoutConst.u64(property: 'id'),
                LayoutConst.fixedBlobN(32, property: 'key'),
              ]),
              property: 'members',
            ),
            property: 'members',
          ),
          LayoutConst.u16(property: 't'),
          LayoutConst.optional(LayoutConst.u32(), property: 'n'),
        ],
        build: (values) {
          var at = 0;
          final group = ED25519PublicKey.fromBytes(
            JsonParser.valueAsBytes(values[at++])!,
          );
          final members =
              JsonParser.valueAsList<List<Map<String, dynamic>>?>(
                values[at++],
              )?.map((m) {
                final keyBytes = JsonParser.valueAsBytes(m['key']);
                if (keyBytes == null) {
                  throw CoreErrors.cryptoFailed(
                    'FrostPublicKey',
                    reason: 'missing member.',
                  );
                }
                return FrostEdMember(
                  id: _FrostKeys.idFromWire(
                    JsonParser.valueAsBigInt<BigInt>(m['id']),
                    'FrostEd25519PublicKey',
                  ),
                  key: ED25519PublicKey.fromBytes(keyBytes),
                );
              }).toList();
          final tRaw = (values[at++] as int);
          final nRaw = values[at++];
          return FrostEd25519PublicKey._(
            group,
            members,
            threshold: tRaw == 0 ? null : tRaw,
            n: nRaw is int ? nRaw : null,
          );
        },
        unbuild:
            (value) => [
              value.aggKey.toBytes(),
              value.members
                  ?.map(
                    (m) => {'id': BigInt.from(m.id), 'key': m.key.toBytes()},
                  )
                  .toList(),
              value.threshold ?? 0,
              value.n,
            ],
      );
}

// ---------------------------------------------------------------------------
// Private keys.
// ---------------------------------------------------------------------------

/// A FROST(secp256k1) coordinator key: typed share secrets in position
/// order, parallel FROST identifiers, and the aggregate public key —
/// mirroring [Musig2PrivateKey]. The [sign] behavior itself lives in
/// [IFrostSigningKey] (`verify_signing.dart`).
class FrostSecp256k1PrivateKey
    extends
        IFrostSigningKey<
          FrostSecp256k1PublicKey,
          Secp256k1PrivateKey,
          Secp256k1PublicKey
        >
    with Equality
    implements
        IPrivateKey<
          FrostSignature,
          FrostSigningParams,
          FrostSecp256k1PublicKey
        > {
  @override
  final List<Secp256k1PrivateKey> secretKeys;
  @override
  final FrostSecp256k1PublicKey publicKey;

  /// FROST identifiers parallel to [secretKeys].
  @override
  final List<int> identifiers;
  @override
  FrostCurve get curve => FrostCurve.secp256k1;
  @override
  CryptoKeyType get type => CryptoKeyType.frostK1;
  @override
  int? get threshold => publicKey.threshold;

  FrostSecp256k1PrivateKey._(
    List<Secp256k1PrivateKey> secretKeys,
    this.publicKey,
    List<int> identifiers,
  ) : secretKeys = secretKeys.immutable,
      identifiers = identifiers.immutable;

  @override
  SecretBytes takeSecretAt(int index) => secretKeys[index].takeSecretKey();

  /// Threshold creation from independent secrets. `threshold` null =
  /// additive (stores inputs, full set signs); explicit `2 <= t <= n` =
  /// reshare into correlated shares `b_i` (any `>=t` subset signs).
  /// `coefficients` holds `n*(t-1)` explicit 32-byte scalars for
  /// deterministic tests; null generates fresh randomness (reshare only).
  factory FrostSecp256k1PrivateKey.fromSecretKeys(
    List<Secp256k1PrivateKey> keys, {
    List<int>? identifiers,
    int? threshold,
    List<int>? coefficients,
  }) {
    const op = 'FrostSecp256k1PrivateKey.fromSecretKeys';
    if (keys.isEmpty) {
      throw CoreErrors.cryptoFailed(op, reason: 'No secrets.');
    }
    final ids =
        identifiers == null
            ? _FrostKeys.defaultIds(keys.length)
            : _FrostKeys.checkIds(identifiers, keys.length, op);
    _FrostKeys.resolveThreshold(keys.length, threshold, op);
    if (threshold == null) {
      final memberKeys = keys.map((e) => e.publicKey).toList();
      final group = blockchainUtils.api.frost.k1GroupFromMembers(
        ids: ids,
        pubsConcat: memberKeys.expand((e) => e.toBytes()).toList(),
        threshold: 0,
      );
      return FrostSecp256k1PrivateKey._(
        keys.toList(),
        FrostSecp256k1PublicKey._(
          Secp256k1PublicKey.fromBytes(group),
          [
            for (var k = 0; k < keys.length; k++)
              FrostK1Member(id: ids[k], key: memberKeys[k]),
          ],
          threshold: null,
          n: keys.length,
        ),
        ids,
      );
    }
    final t = threshold;
    final secretsConcat = <int>[];
    for (final k in keys) {
      secretsConcat.addAll(
        k.takeSecretKey().useValue((b) => List<int>.from(b)),
      );
    }
    final need = keys.length * (t - 1) * 32;
    final generatedCoeffs = coefficients == null;
    final coeffConcat =
        coefficients ??
        [
          for (var k = 0; k < keys.length * (t - 1); k++)
            ..._FrostKeys.randomK1ScalarBytes(),
        ].toList();
    if (coeffConcat.length != need) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'coefficients must hold n*(t-1) scalars (need $need).',
      );
    }
    try {
      final r = blockchainUtils.api.frost.k1Reshare(
        ids: ids,
        secretsConcat: secretsConcat,
        coeffsConcat: coeffConcat,
        threshold: t,
      );
      final shares = [
        for (var at = 0; at < r.sharesConcat.length; at += 32)
          Secp256k1PrivateKey.fromBytes(r.sharesConcat.sublist(at, at + 32)),
      ];
      return FrostSecp256k1PrivateKey._(
        shares,
        FrostSecp256k1PublicKey._(
          Secp256k1PublicKey.fromBytes(r.group),
          [
            for (var k = 0; k < r.pubs.length; k++)
              FrostK1Member(
                id: ids[k],
                key: Secp256k1PublicKey.fromBytes(r.pubs[k]),
              ),
          ],
          threshold: t,
          n: keys.length,
        ),
        ids,
      );
    } finally {
      BinaryOps.zero(secretsConcat);
      if (generatedCoeffs) {
        BinaryOps.zero(coeffConcat);
      }
    }
  }

  factory FrostSecp256k1PrivateKey.partial({
    required FrostSecp256k1PublicKey publicKey,
    List<Secp256k1PrivateKey> secretKeys = const [],
    List<int> identifiers = const [],
  }) {
    return FrostSecp256k1PrivateKey._(secretKeys, publicKey, identifiers);
  }

  factory FrostSecp256k1PrivateKey.fromBytes(List<int> bytes) {
    return layout().deserialize(bytes).value;
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      FrostSecp256k1PrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  List<dynamic> get variables => [publicKey];

  @override
  FrostSecp256k1PublicKey verificationKey() => publicKey;

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    return SecretBytes.take(layout().serialize(this), transform: transform);
  }

  @override
  SecretBytes takeSecretKey({SecretTransform? transform}) {
    return toBytes(transform: transform);
  }

  @override
  void dispose() {
    for (final s in secretKeys) {
      s.dispose();
    }
  }

  static Layout<FrostSecp256k1PrivateKey> layout() =>
      ObjSeqLayout<FrostSecp256k1PrivateKey>(
        [
          FrostSecp256k1PublicKey.layout(),
          LayoutConst.vec(LayoutConst.fixedBlobN(32), property: 'secrets'),
          LayoutConst.vec(LayoutConst.u64(), property: 'ids'),
        ],
        build: (values) {
          var at = 0;
          final pub = values[at++];
          final FrostSecp256k1PublicKey publicKey;
          if (pub is FrostSecp256k1PublicKey) {
            publicKey = pub;
          } else if (pub is List<int>) {
            publicKey = FrostSecp256k1PublicKey.fromBytes(pub);
          } else {
            throw CoreErrors.cryptoFailed(
              'FrostPrivateKey',
              reason: 'invalid public key encoding.',
            );
          }
          final secrets =
              JsonParser.valueEnsureAsList<List<int>>(
                values[at++],
              ).map(Secp256k1PrivateKey.fromBytes).toList();
          final ids =
              JsonParser.valueEnsureAsList<BigInt>(values[at++])
                  .map((e) => _FrostKeys.idFromWire(e, 'FrostPrivateKey'))
                  .toList();
          return FrostSecp256k1PrivateKey.partial(
            publicKey: publicKey,
            secretKeys: secrets,
            identifiers: ids,
          );
        },
        unbuild:
            (value) => [
              value.publicKey,
              value.secretKeys.map((e) => e.toBytes()).toList(),
              value.identifiers.map(BigInt.from).toList(),
            ],
      );
}

/// A FROST(Ed25519) coordinator key: threshold shares in position order,
/// parallel FROST identifiers, and the aggregate public key. The [sign]
/// behavior itself lives in [IFrostSigningKey] (`verify_signing.dart`).
///
/// Input to [fromSecretKeys] is seeds ([ED25519PrivateKey]); stored
/// [secretKeys] are the resharded threshold shares `b_i` in the same
/// 32-byte wrapper (not the original seeds). The backend expands seeds
/// once at creation (`isScalar:false`) and uses stored shares as scalars
/// after (`isScalar:true`).
class FrostEd25519PrivateKey
    extends
        IFrostSigningKey<
          FrostEd25519PublicKey,
          ED25519PrivateKey,
          ED25519PublicKey
        >
    with Equality
    implements
        IPrivateKey<FrostSignature, FrostSigningParams, FrostEd25519PublicKey> {
  /// Threshold shares `b_i` (resharded scalars in seed wrapper), parallel
  /// to [identifiers].
  @override
  final List<ED25519PrivateKey> secretKeys;
  @override
  final FrostEd25519PublicKey publicKey;

  /// FROST identifiers parallel to [secretKeys].
  @override
  final List<int> identifiers;
  @override
  FrostCurve get curve => FrostCurve.ed25519;
  @override
  CryptoKeyType get type => CryptoKeyType.frostEd25519;
  @override
  int? get threshold => publicKey.threshold;

  FrostEd25519PrivateKey._(
    List<ED25519PrivateKey> secretKeys,
    this.publicKey,
    List<int> identifiers,
  ) : secretKeys = secretKeys.immutable,
      identifiers = identifiers.immutable;

  /// Resharded share bytes at [index] (threshold) or seed bytes
  /// (additive). Backend `isScalar` follows `threshold==null?false:true`.
  @override
  SecretBytes takeSecretAt(int index) => secretKeys[index].takeSecretKey();

  /// Threshold creation from independent seeds. `threshold` null =
  /// additive (stores seeds, full set signs); explicit `2 <= t <= n` =
  /// reshare into correlated shares `b_i` (any `>=t` subset signs).
  /// Stored [secretKeys] are seeds (additive) or `b_i` shares in the same
  /// wrapper (threshold). `coefficients` holds `n*(t-1)` explicit 32-byte
  /// seeds for deterministic tests; null generates fresh seeds (reshare).
  factory FrostEd25519PrivateKey.fromSecretKeys(
    List<ED25519PrivateKey> keys, {
    List<int>? identifiers,
    int? threshold,
    List<int>? coefficients,
  }) {
    const op = 'FrostEd25519PrivateKey.fromSecretKeys';
    if (keys.length < 2) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'at least 2 participants required (got ${keys.length}).',
      );
    }
    final ids =
        identifiers == null
            ? _FrostKeys.defaultIds(keys.length)
            : _FrostKeys.checkIds(identifiers, keys.length, op);
    if (threshold == null) {
      final memberKeys = keys.map((e) => e.publicKey).toList();
      final group = blockchainUtils.api.frost.edGroupFromMembers(
        ids: ids,
        pubsConcat: memberKeys.expand((e) => e.toBytes()).toList(),
        threshold: 0,
      );
      return FrostEd25519PrivateKey._(
        keys.toList(),
        FrostEd25519PublicKey._(
          ED25519PublicKey.fromBytes(group),
          [
            for (var k = 0; k < keys.length; k++)
              FrostEdMember(id: ids[k], key: memberKeys[k]),
          ],
          threshold: null,
          n: keys.length,
        ),
        ids,
      );
    }
    _FrostKeys.resolveThreshold(keys.length, threshold, op);
    final t = threshold;
    final seedsConcat = <int>[];
    for (final k in keys) {
      seedsConcat.addAll(k.takeSecretKey().useValue((b) => List<int>.from(b)));
    }
    final need = keys.length * (t - 1) * 32;
    List<int> coeffConcat;
    if (coefficients != null) {
      coeffConcat = coefficients;
    } else {
      final tmp = List.generate(
        keys.length * (t - 1),
        (_) => ED25519PrivateKey.random(),
      );
      try {
        coeffConcat = [
          for (final c in tmp)
            ...c.takeSecretKey().useValue((b) => List<int>.from(b)),
        ];
      } finally {
        for (final c in tmp) {
          c.dispose();
        }
      }
    }
    if (coeffConcat.length != need) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: 'coefficients must hold n*(t-1) seeds (need $need).',
      );
    }
    final wipeCoeffs = coefficients == null;
    try {
      final r = blockchainUtils.api.frost.edReshare(
        ids: ids,
        seedsConcat: seedsConcat,
        coeffSeedsConcat: coeffConcat,
        threshold: t,
      );
      final shares = [
        for (var at = 0; at < r.sharesConcat.length; at += 32)
          ED25519PrivateKey.fromBytes(r.sharesConcat.sublist(at, at + 32)),
      ];
      return FrostEd25519PrivateKey._(
        shares,
        FrostEd25519PublicKey._(
          ED25519PublicKey.fromBytes(r.group),
          [
            for (var k = 0; k < r.pubs.length; k++)
              FrostEdMember(
                id: ids[k],
                key: ED25519PublicKey.fromBytes(r.pubs[k]),
              ),
          ],
          threshold: t,
          n: keys.length,
        ),
        ids,
      );
    } finally {
      BinaryOps.tryZero(seedsConcat);
      if (wipeCoeffs) {
        BinaryOps.tryZero(coeffConcat);
      }
    }
  }

  factory FrostEd25519PrivateKey.partial({
    required FrostEd25519PublicKey publicKey,
    List<ED25519PrivateKey> secretKeys = const [],
    List<int> identifiers = const [],
  }) {
    return FrostEd25519PrivateKey._(secretKeys, publicKey, identifiers);
  }

  factory FrostEd25519PrivateKey.fromBytes(List<int> bytes) {
    return layout().deserialize(bytes).value;
  }

  static bool isValidBytes(List<int> bytes) {
    try {
      FrostEd25519PrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  List<dynamic> get variables => [publicKey];

  @override
  FrostEd25519PublicKey verificationKey() => publicKey;

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    return SecretBytes.take(layout().serialize(this), transform: transform);
  }

  @override
  SecretBytes takeSecretKey({SecretTransform? transform}) {
    return toBytes(transform: transform);
  }

  @override
  void dispose() {
    for (final s in secretKeys) {
      s.dispose();
    }
  }

  static Layout<FrostEd25519PrivateKey> layout() =>
      ObjSeqLayout<FrostEd25519PrivateKey>(
        [
          FrostEd25519PublicKey.layout(),
          LayoutConst.vec(LayoutConst.fixedBlobN(32), property: 'secrets'),
          LayoutConst.vec(LayoutConst.u64(), property: 'ids'),
        ],
        build: (values) {
          var at = 0;
          final pub = values[at++];
          final FrostEd25519PublicKey publicKey;
          if (pub is FrostEd25519PublicKey) {
            publicKey = pub;
          } else if (pub is List<int>) {
            publicKey = FrostEd25519PublicKey.fromBytes(pub);
          } else {
            throw CoreErrors.cryptoFailed(
              'FrostPrivateKey',
              reason: 'invalid public key encoding.',
            );
          }
          final secrets =
              JsonParser.valueEnsureAsList<List<int>>(
                values[at++],
              ).map(ED25519PrivateKey.fromBytes).toList();
          final ids =
              JsonParser.valueEnsureAsList<BigInt>(values[at++])
                  .map((e) => _FrostKeys.idFromWire(e, 'FrostPrivateKey'))
                  .toList();
          return FrostEd25519PrivateKey.partial(
            publicKey: publicKey,
            secretKeys: secrets,
            identifiers: ids,
          );
        },
        unbuild:
            (value) => [
              value.publicKey,
              value.secretKeys.map((e) => e.toBytes()).toList(),
              value.identifiers.map(BigInt.from).toList(),
            ],
      );
}
