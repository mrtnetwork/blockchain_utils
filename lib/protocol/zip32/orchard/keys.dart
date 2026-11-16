import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/protocol/zip32/base/context.dart';
import 'package:blockchain_utils/protocol/zip32/base/types.dart';
import 'package:blockchain_utils/protocol/zip32/orchard/utils.dart';
import 'package:blockchain_utils/protocol/zip32/utils/prf_expand.dart';
import 'package:blockchain_utils/protocol/zip32/zip32/types.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils/utils/equatable/equatable.dart';

class OrchardExtendedSpendingKey extends Zip32ExtendedSpendKey<Bip32KeyData>
    with SecretState {
  OrchardExtendedSpendingKey({required this.sk, required Bip32KeyData keyData})
    : super(keyData);
  final OrchardSpendingKey sk;
  OrchardExtendedFullViewKey toExtendedFvk() {
    return OrchardExtendedFullViewKey(
      fvk: OrchardFullViewingKey.fromSpendKey(sk),
      keyData: keyData,
    );
  }

  @override
  List<dynamic> get variables => [sk];

  @override
  SecretBytes spendKeyBytes() {
    return sk.toBytes();
  }

  @override
  void dispose() {
    sk.dispose();
  }
}

class OrchardExtendedFullViewKey
    extends Zip32ExtendedFullViewKey<OrchardIncomingViewingKey, Bip32KeyData> {
  OrchardExtendedFullViewKey({required this.fvk, required Bip32KeyData keyData})
    : super(keyData);
  final OrchardFullViewingKey fvk;

  factory OrchardExtendedFullViewKey.fromFullViewKey({
    required List<int> bytes,
    required ZCryptoContext context,
    Bip32KeyData? keyData,
  }) {
    keyData ??= Bip32KeyData();
    return OrchardExtendedFullViewKey(
      fvk: OrchardFullViewingKey.fromBytes(bytes: bytes, context: context),
      keyData: keyData,
    );
  }
  factory OrchardExtendedFullViewKey.fromFullViewKeyUnchecked(
    List<int> bytes, {
    Bip32KeyData? keyData,
  }) {
    keyData ??= Bip32KeyData();
    return OrchardExtendedFullViewKey(
      fvk: OrchardFullViewingKey.fromBytesUnchecked(bytes),
      keyData: keyData,
    );
  }

  @override
  List<dynamic> get variables => [fvk];

  @override
  OrchardIncomingViewingKey incomingViewingKey(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainInt,
  }) {
    return fvk.toIvk(scope, context: context);
  }
}

class OrchardSpendingKey
    with ConstantEquality<OrchardSpendingKey>, SecretState {
  final SecretBytes sk;
  OrchardSpendingKey(List<int> sk)
    : sk = SecretBytes(
        sk.exc(
          operation: "OrchardSpendingKey",
          name: "sk",
          reason: "Invalid secret key bytes length.",
          length: 32,
        ),
      );
  factory OrchardSpendingKey.fromBytes({
    required List<int> bytes,
    required ZCryptoContext context,
  }) {
    final key = OrchardSpendingKey(bytes);
    RedPallasSpendPrivateKey.fromSpendingKey(key);
    final fvk = OrchardFullViewingKey.fromSpendKey(key);
    OrchardKeyAgreementPrivateKey.deriveInner(fvk: fvk, context: context);
    OrchardKeyAgreementPrivateKey.deriveInner(
      fvk: fvk.deriveInternal(),
      context: context,
    );
    return key;
  }
  SecretBytes toBytes() => sk.cloneBytes();

  @override
  List<Object?> get publicFields => [];

  @override
  List<List<int>> get secretFields => [sk];

  @override
  void dispose() {
    sk.zero();
  }
}

class OrchardFullViewingKey
    extends
        DiversifiableFullViewingKey<
          OrchardAddress,
          OrchardIncomingViewingKey,
          OrchardOutgoingViewingKey,
          OrchardKeyAgreementPrivateKey
        > {
  final OrchardSpendValidatingKey ak;
  final OrchardNullifierDerivingKey nk;
  final OrchardCommitIvkRandomness rivk;
  const OrchardFullViewingKey({
    required this.ak,
    required this.nk,
    required this.rivk,
  });
  factory OrchardFullViewingKey.fromSpendKey(OrchardSpendingKey sk) {
    return OrchardFullViewingKey(
      nk: OrchardNullifierDerivingKey.fromSpendKey(sk),
      rivk: OrchardCommitIvkRandomness.fromSpendKey(sk),
      ak: OrchardSpendValidatingKey(
        RedPallasSpendPrivateKey.fromSpendingKey(sk).publicKey,
      ),
    );
  }
  factory OrchardFullViewingKey.fromBytes({
    required List<int> bytes,
    required ZCryptoContext context,
  }) {
    final fvk = OrchardFullViewingKey.fromBytesUnchecked(bytes);
    OrchardKeyAgreementPrivateKey.deriveInner(fvk: fvk, context: context);
    OrchardKeyAgreementPrivateKey.deriveInner(
      fvk: fvk.deriveInternal(),
      context: context,
    );
    return fvk;
  }
  factory OrchardFullViewingKey.fromBytesUnchecked(List<int> bytes) {
    bytes = bytes.exc(
      operation: "OrchardFullViewingKey",
      name: "bytes",
      reason: "Invalid full view key bytes length.",
      length: 96,
    );
    final ak = OrchardSpendValidatingKey.fromBytes(bytes.sublist(0, 32));
    final nk = OrchardNullifierDerivingKey.fromBytes(bytes.sublist(32, 64));
    final rivk = OrchardCommitIvkRandomness.fromBytes(bytes.sublist(64));
    return OrchardFullViewingKey(ak: ak, nk: nk, rivk: rivk);
  }
  OrchardCommitIvkRandomness rivkFromScope(Bip44Changes scope) {
    switch (scope) {
      case Bip44Changes.chainExt:
        return rivk;
      case Bip44Changes.chainInt:
        final k = rivk.toBytes();
        final ak = this.ak.toBytes();
        final nk = this.nk.toBytes();
        final scalar = blockchainUtils.api.pallas.scReduce64(
          PrfExpand.orchardRivkInternal.apply(k, data: [ak, nk]),
        );
        return OrchardCommitIvkRandomness.fromBytes(scalar);
    }
  }

  (OrchardDiversifierKey, OrchardOutgoingViewingKey) deriveDkOvk() {
    final k = rivk.toBytes();
    final b = [ak.toBytes(), nk.toBytes()];
    final r = PrfExpand.orchardDkOvk.apply(k, data: b);
    return (
      OrchardDiversifierKey(r.sublist(0, 32)),
      OrchardOutgoingViewingKey(r.sublist(32)),
    );
  }

  OrchardAddress address({
    required Diversifier d,
    required Bip44Changes scope,
    required ZCryptoContext context,
  }) {
    return switch (scope) {
      Bip44Changes.chainInt => OrchardKeyAgreementPrivateKey.fromFvk(
        fvk: deriveInternal(),
        context: context,
      ),
      Bip44Changes.chainExt => OrchardKeyAgreementPrivateKey.fromFvk(
        fvk: this,
        context: context,
      ),
    }.address(d);
  }

  @override
  Bip44Changes? scopeForAddress({
    required OrchardAddress address,
    ZCryptoContext? context,
    Bip44Changes? tryFirst,
  }) {
    return Bip44Changes.values.firstWhereNullable(
      (e) => toIvk(e, context: context).diversifierIndex(address) != null,
    );
  }

  OrchardAddress addressAt({
    required DiversifierIndex j,
    required Bip44Changes scope,
    required ZCryptoContext context,
  }) {
    return toIvk(scope, context: context).addressAt(j);
  }

  @override
  OrchardIncomingViewingKey toIvk(
    Bip44Changes scope, {
    ZCryptoContext? context,
  }) {
    context ??= DefaultZCryptoContext();
    return switch (scope) {
      Bip44Changes.chainInt => OrchardIncomingViewingKey.fromFvk(
        fvk: deriveInternal(),
        context: context,
      ),
      Bip44Changes.chainExt => OrchardIncomingViewingKey.fromFvk(
        fvk: this,
        context: context,
      ),
    };
  }

  @override
  OrchardOutgoingViewingKey toOvk(Bip44Changes scope) {
    return switch (scope) {
      Bip44Changes.chainInt => OrchardOutgoingViewingKey.fromFvk(
        deriveInternal(),
      ),
      Bip44Changes.chainExt => OrchardOutgoingViewingKey.fromFvk(this),
    };
  }

  OrchardFullViewingKey deriveInternal() {
    return OrchardFullViewingKey(
      ak: ak,
      nk: nk,
      rivk: rivkFromScope(Bip44Changes.chainInt),
    );
  }

  @override
  BuBytes toBytes() {
    return BuBytes.unsafeMutable([
      ...ak.toBytes(),
      ...nk.toBytes(),
      ...rivk.toBytes(),
    ]);
  }

  @override
  List<dynamic> get variables => [protocol, ak, nk, rivk];

  @override
  ZcashProtocol get protocol => ZcashProtocol.orchard;

  @override
  OrchardKeyAgreementPrivateKey keyAgreement(
    Bip44Changes scope, {
    ZCryptoContext? context,
  }) {
    return toIvk(scope, context: context).ivk;
  }
}

class OrchardNullifierDerivingKey with Equality {
  final BuBytes _bytes;

  OrchardNullifierDerivingKey._(BuBytes bytes)
    : _bytes = bytes.asImmutableBytes;
  factory OrchardNullifierDerivingKey.fromSpendKey(OrchardSpendingKey sk) {
    return OrchardNullifierDerivingKey._(
      blockchainUtils.api.vesta.scReduce64(PrfExpand.orchardNk.apply(sk.sk)),
    );
  }
  factory OrchardNullifierDerivingKey.fromBytes(List<int> bytes) {
    // Single validating check; afterwards only raw bytes are kept.
    if (!blockchainUtils.api.vesta.scCheck(bytes)) {
      throw CoreErrors.orchardFailed(
        "OrchardNullifierDerivingKey",
        reason: "Invalid nullifier deriving key bytes.",
      );
    }
    return OrchardNullifierDerivingKey._(BuBytes.from(bytes));
  }

  BuBytes toBytes() {
    return _bytes.cloneBytes();
  }

  BuBytes prfNf({required List<int> rho, required ZCryptoContext context}) {
    return OrchardKeyUtils.prfNf(nk: toBytes(), rho: rho, context: context);
  }

  @override
  List<dynamic> get variables => [_bytes];
}

class OrchardSpendValidatingKey with Equality {
  final BuBytes _bytes;
  RedPallasSpendPublicKey? _key;

  /// Parsed spend authority, decoded lazily once and cached.
  RedPallasSpendPublicKey get key =>
      _key ??= RedPallasSpendPublicKey.fromBytes(_bytes);

  OrchardSpendValidatingKey._(BuBytes bytes, [RedPallasSpendPublicKey? key])
    : _bytes = bytes.asImmutableBytes,
      _key = key;
  factory OrchardSpendValidatingKey(RedPallasSpendPublicKey pk) {
    if (pk.toBytes()[31] & 0x80 != 0) {
      throw CoreErrors.orchardFailed(
        "OrchardSpendValidatingKey",
        reason: "Invalid spend verification key.",
      );
    }
    return OrchardSpendValidatingKey._(BuBytes.from(pk.toBytes()), pk);
  }
  factory OrchardSpendValidatingKey.fromBytes(List<int> bytes) {
    if (bytes.exc(
              length: 32,
              operation: "OrchardSpendValidatingKey",
              reason: "Invalid OrchardSpendValidatingKey bytes length.",
            )[31] &
            0x80 !=
        0) {
      throw CoreErrors.orchardFailed(
        "OrchardSpendValidatingKey",
        reason: "Invalid spend verification key.",
      );
    }
    // Single validating parse (includes the identity check); afterwards
    // only raw bytes are kept.
    final key = RedPallasSpendPublicKey.fromBytes(bytes);
    return OrchardSpendValidatingKey._(BuBytes.from(bytes), key);
  }

  BuBytes toBytes() {
    return _bytes.cloneBytes();
  }

  @override
  List<dynamic> get variables => [_bytes];
}

class OrchardCommitIvkRandomness with Equality {
  final BuBytes _bytes;

  OrchardCommitIvkRandomness._(BuBytes bytes)
    : _bytes = bytes.asImmutableBytes;
  static void _checkScalar(List<int> bytes, String operation) {
    if (!blockchainUtils.api.pallas.scCheck(bytes) ||
        BytesUtils.isZeroConst(bytes)) {
      throw CoreErrors.orchardFailed(
        operation,
        reason: "Invalid randomness scalar bytes.",
      );
    }
  }
  factory OrchardCommitIvkRandomness.fromSpendKey(OrchardSpendingKey sk) {
    final scalar = blockchainUtils.api.pallas.scReduce64(
      PrfExpand.orchardRivk.apply(sk.sk),
    );
    _checkScalar(scalar, "OrchardCommitIvkRandomness");
    return OrchardCommitIvkRandomness._(BuBytes.from(scalar));
  }
  factory OrchardCommitIvkRandomness.fromBytes(List<int> bytes) {
    // Single validating check; afterwards only raw bytes are kept.
    _checkScalar(bytes, "OrchardCommitIvkRandomness");
    return OrchardCommitIvkRandomness._(BuBytes.from(bytes));
  }

  BuBytes toBytes() {
    return _bytes.cloneBytes();
  }

  @override
  List<dynamic> get variables => [_bytes];
}

class OrchardKeyAgreementPrivateKey extends KeyAgreementPrivateKey {
  final BuBytes _bytes;
  VestaFq? _scalar;

  /// Parsed agreement scalar, decoded lazily once and cached.
  VestaFq get scalar => _scalar ??= VestaFq.fromBytes(_bytes);

  OrchardKeyAgreementPrivateKey._(BuBytes bytes)
    : _bytes = bytes.asImmutableBytes;
  static BuBytes commitIvk({
    required List<int> ak,
    required List<int> nk,
    required List<int> rivk,
    required ZCryptoContext context,
  }) {
    final f = context.sinsemillaShortCommit(
      r: rivk,
      domain: "z.cash:Orchard-CommitIvk",
      bits: [
        ...PallasFp.fromBytes(ak).toBits().sublist(0, PallasFPConst.numBits),
        ...PallasFp.fromBytes(nk).toBits().sublist(0, PallasFPConst.numBits),
      ],
    );
    if (f == null) {
      throw CoreErrors.orchardFailed("commitIvk");
    }
    return f;
  }

  factory OrchardKeyAgreementPrivateKey.fromBytes(List<int> bytes) {
    // Single validating check; the field object materializes lazily via
    // [scalar] only where point math genuinely needs it.
    if (!blockchainUtils.api.pallas.scCheck(bytes) ||
        BytesUtils.isZeroConst(bytes)) {
      throw CoreErrors.orchardFailed(
        "OrchardKeyAgreementPrivateKey",
        reason: "Invalid scalar. scalar must not be zero.",
      );
    }
    return OrchardKeyAgreementPrivateKey._(BuBytes.from(bytes));
  }
  factory OrchardKeyAgreementPrivateKey.fromFvk({
    required OrchardFullViewingKey fvk,
    required ZCryptoContext context,
  }) {
    final base = deriveInner(fvk: fvk, context: context);
    return OrchardKeyAgreementPrivateKey.fromBytes(base);
  }
  static BuBytes deriveInner({
    required OrchardFullViewingKey fvk,
    required ZCryptoContext context,
  }) {
    final ak = PallasAffinePoint.fromBytes(fvk.ak.key.keyBytes).x.toBytes();
    final scalar = commitIvk(
      ak: ak,
      nk: fvk.nk.toBytes(),
      rivk: fvk.rivk.toBytes(),
      context: context,
    );
    if (BytesUtils.isZeroConst(scalar)) {
      throw CoreErrors.orchardFailed(
        "deriveInner",
        reason: "commitIvk produced a zero scalar.",
      );
    }
    return scalar;
  }

  OrchardAddress address(Diversifier d) {
    final pkd = OrchardDiversifiedTransmissionKey.derive(d: d, ivk: scalar);
    return OrchardAddress(diversifier: d, transmissionKey: pkd);
  }

  BuBytes toBytes() {
    return _bytes.cloneBytes();
  }

  @override
  List<dynamic> get variables => [_bytes];
}

class OrchardDiversifierKey with Equality {
  final BuBytes key;
  OrchardDiversifierKey(List<int> key)
    : key =
          key
              .exc(
                length: 32,
                operation: "OrchardDiversifierKey",
                name: "key",
                reason: "Invalid diversifier key length.",
              )
              .asImmutableBytes;

  Diversifier get(DiversifierIndex index) {
    final enc = blockchainUtils.api.ff1.encryptBinary(
      key: key,
      pt: index.inner,
    );
    return Diversifier(enc);
  }

  DiversifierIndex diversifierIndex(Diversifier d) {
    final dec = blockchainUtils.api.ff1.decryptBinary(key: key, ct: d.inner);
    return DiversifierIndex(dec);
  }

  BuBytes toBytes() {
    return key.cloneBytes();
  }

  @override
  List<dynamic> get variables => [key];
}

class OrchardIncomingViewingKey extends IncomingViewingKey<OrchardAddress> {
  final OrchardDiversifierKey dk;
  final OrchardKeyAgreementPrivateKey ivk;
  const OrchardIncomingViewingKey({required this.dk, required this.ivk});
  factory OrchardIncomingViewingKey.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "OrchardIncomingViewingKey",
      name: "bytes",
      reason: "Invalid incoming view key bytes length.",
      length: 64,
    );
    return OrchardIncomingViewingKey(
      dk: OrchardDiversifierKey(bytes.sublist(0, 32)),
      ivk: OrchardKeyAgreementPrivateKey.fromBytes(bytes.sublist(32)),
    );
  }
  factory OrchardIncomingViewingKey.fromFvk({
    required OrchardFullViewingKey fvk,
    required ZCryptoContext context,
  }) {
    return OrchardIncomingViewingKey(
      dk: fvk.deriveDkOvk().$1,
      ivk: OrchardKeyAgreementPrivateKey.fromFvk(fvk: fvk, context: context),
    );
  }

  @override
  OrchardAddress address(Diversifier d) {
    return ivk.address(d);
  }

  @override
  OrchardAddress addressAt(DiversifierIndex j) {
    return address(dk.get(j));
  }

  @override
  DiversifierIndex? diversifierIndex(OrchardAddress address) {
    final j = dk.diversifierIndex(address.diversifier);
    if (addressAt(j) == address) {
      return j;
    }
    return null;
  }

  @override
  (OrchardAddress, DiversifierIndex)? findAddress(DiversifierIndex index) {
    return (addressAt(index), index);
  }

  @override
  BuBytes toBytes() {
    return BuBytes.unsafeMutable([...dk.toBytes(), ...ivk.toBytes()]);
  }

  @override
  List<dynamic> get variables => [dk, ivk];

  @override
  ZcashProtocol get protocol => ZcashProtocol.orchard;
}

class OrchardOutgoingViewingKey extends OutgoingViewingKey {
  final BuBytes inner;
  OrchardOutgoingViewingKey(List<int> inner)
    : inner =
          inner
              .exc(
                length: 32,
                operation: "OrchardOutgoingViewingKey",
                name: "inner",
                reason: "Invalid outgoing view key bytes length.",
              )
              .asImmutableBytes;
  factory OrchardOutgoingViewingKey.fromFvk(OrchardFullViewingKey fvk) {
    return fvk.deriveDkOvk().$2;
  }

  @override
  List<dynamic> get variables => [inner];

  @override
  BuBytes toBytes() {
    return inner.cloneBytes();
  }
}

class OrchardAddress extends ShieldAddress<OrchardDiversifiedTransmissionKey> {
  const OrchardAddress({
    required super.transmissionKey,
    required super.diversifier,
  });

  BuBytes gD() {
    return OrchardKeyUtils.diversifyHash(diversifier.inner);
  }

  List<int> toAddressBytes() {
    return [...diversifier.inner, ...transmissionKey.toBytes()];
  }

  factory OrchardAddress.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "OrchardAddress",
      name: "bytes",
      reason: "Invalid orchard address bytes length.",
      length: 43,
    );
    return OrchardAddress(
      diversifier: Diversifier(bytes.sublist(0, 11)),
      transmissionKey: OrchardDiversifiedTransmissionKey.fromBytes(
        bytes.sublist(11),
      ),
    );
  }
  factory OrchardAddress.fromBytesUnckecked(List<int> bytes) {
    bytes = bytes.exc(
      operation: "OrchardAddress",
      name: "bytes",
      reason: "Invalid orchard address bytes length.",
      length: 43,
    );
    return OrchardAddress(
      diversifier: Diversifier(bytes.sublist(0, 11)),
      transmissionKey: OrchardDiversifiedTransmissionKey.fromBytesUnchecked(
        bytes.sublist(11),
      ),
    );
  }

  @override
  BuBytes toBytes() {
    return BuBytes.unsafeMutable([
      ...diversifier.inner,
      ...transmissionKey.toBytes(),
    ]);
  }
}

class OrchardDiversifiedTransmissionKey extends DiversifiedTransmissionKey {
  final BuBytes inner;
  OrchardDiversifiedTransmissionKey._(List<int> inner, PallasPoint? point)
    : _point = point,
      inner =
          inner
              .exc(
                length: 32,
                operation: "OrchardDiversifiedTransmissionKey",
                reason: "Invalid TransmissionKey bytes length.",
              )
              .asImmutableBytes;
  PallasPoint? _point;
  PallasPoint toPoint() => _point ??= PallasPoint.fromBytes(inner);
  factory OrchardDiversifiedTransmissionKey(PallasPoint point) {
    return OrchardDiversifiedTransmissionKey._(point.toBytes(), point);
  }

  factory OrchardDiversifiedTransmissionKey.derive({
    required VestaFq ivk,
    required Diversifier d,
  }) {
    final gd = OrchardKeyUtils.diversifyHash(d.inner);
    return OrchardDiversifiedTransmissionKey(
      OrchardKeyUtils.kaOrchard(base: gd, sk: ivk),
    );
  }
  factory OrchardDiversifiedTransmissionKey.fromBytes(List<int> bytes) {
    return OrchardDiversifiedTransmissionKey(PallasPoint.fromBytes(bytes));
  }
  factory OrchardDiversifiedTransmissionKey.fromBytesUnchecked(
    List<int> bytes,
  ) {
    return OrchardDiversifiedTransmissionKey._(bytes, null);
  }

  @override
  BuBytes toBytes() {
    return inner.cloneBytes();
  }

  @override
  List<dynamic> get variables => [inner];
}
