import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/exception.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/utils.dart';
import 'package:blockchain_utils/bip/bip/zip32/reddsa/reddsa/orchard.dart';
import 'package:blockchain_utils/bip/bip/zip32/utils/prf_expand.dart';
import 'package:blockchain_utils/bip/bip/zip32/zip32/types.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class OrchardExtendedSpendingKey extends Zip32ExtendedSpendKey<Bip32KeyData> {
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
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(
      sk.toBytes(),
      prefix: prefix,
      lowerCase: lowerCase,
    );
  }

  @override
  List<dynamic> get variables => [sk];

  @override
  List<int> spendKeyBytes() {
    return sk.toBytes();
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
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(
      fvk.toBytes(),
      prefix: prefix,
      lowerCase: lowerCase,
    );
  }

  @override
  List<dynamic> get variables => [fvk];

  @override
  OrchardIncomingViewingKey incomingViewingKey(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainInt,
  }) {
    return fvk.toIvk(scope: scope, context: context);
  }
}

class OrchardSpendingKey with ConstantEquality<OrchardSpendingKey> {
  final List<int> sk;
  OrchardSpendingKey(List<int> sk)
    : sk = sk.exc(
        operation: "OrchardSpendingKey",
        name: "sk",
        reason: "Invalid secret key bytes length.",
        length: 32,
      );
  factory OrchardSpendingKey.fromBytes({
    required List<int> bytes,
    required ZCryptoContext context,
  }) {
    // domain ??= OrchardKeyUtils.commitIvkDomain;
    final key = OrchardSpendingKey(bytes);
    OrchardSpendAuthorizingKey.fromSpendingKey(key);
    final fvk = OrchardFullViewingKey.fromSpendKey(key);
    OrchardKeyAgreementPrivateKey.deriveInner(fvk: fvk, context: context);
    OrchardKeyAgreementPrivateKey.deriveInner(
      fvk: fvk.deriveInternal(),
      context: context,
    );
    return key;
  }
  List<int> toBytes() => sk.clone();

  @override
  List<Object?> get publicFields => [];

  @override
  List<List<int>> get secretFields => [sk];
}

class OrchardFullViewingKey with Equality {
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
        OrchardSpendAuthorizingKey.fromSpendingKey(sk).toVerificationKey(),
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
        return OrchardCommitIvkRandomness(
          VestaNativeFq.fromBytes64(
            PrfExpand.orchardRivkInternal.apply(k, data: [ak, nk]),
          ),
        );
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

  Bip44Changes? scopeForAddress({
    required OrchardAddress address,
    required ZCryptoContext context,
  }) {
    return Bip44Changes.values.firstWhereNullable(
      (e) =>
          toIvk(scope: e, context: context).diversifierIndex(address) != null,
    );
  }

  OrchardAddress addressAt({
    required DiversifierIndex j,
    required Bip44Changes scope,
    required ZCryptoContext context,
  }) {
    return toIvk(scope: scope, context: context).addressAt(j);
  }

  OrchardIncomingViewingKey toIvk({
    required Bip44Changes scope,
    required ZCryptoContext context,
  }) {
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

  List<int> toBytes() {
    return [...ak.toBytes(), ...nk.toBytes(), ...rivk.toBytes()];
  }

  @override
  List<dynamic> get variables => [ak, nk, rivk];
}

class OrchardNullifierDerivingKey with Equality {
  final PallasNativeFp inner;
  const OrchardNullifierDerivingKey(this.inner);
  factory OrchardNullifierDerivingKey.fromSpendKey(OrchardSpendingKey sk) {
    final base = PallasNativeFp.fromBytes64(PrfExpand.orchardNk.apply(sk.sk));
    return OrchardNullifierDerivingKey(base);
  }
  factory OrchardNullifierDerivingKey.fromBytes(List<int> bytes) {
    return OrchardNullifierDerivingKey(PallasNativeFp.fromBytes(bytes));
  }

  List<int> toBytes() {
    return inner.toBytes();
  }

  PallasNativeFp prfNf({
    required PallasNativeFp rho,
    required ZCryptoContext context,
  }) {
    return OrchardKeyUtils.prfNf(nk: inner, rho: rho, context: context);
  }

  @override
  List<dynamic> get variables => [inner];
}

class OrchardSpendValidatingKey with Equality {
  final OrchardSpendVerificationKey key;
  const OrchardSpendValidatingKey._(this.key);
  factory OrchardSpendValidatingKey(OrchardSpendVerificationKey pk) {
    if (pk.toBytes()[31] & 0x80 != 0) {
      throw OrchardKeyError.cryptoFailureWith(
        "OrchardSpendValidatingKey",
        reason: "Invalid spend verification key.",
      );
    }
    return OrchardSpendValidatingKey._(pk);
  }
  factory OrchardSpendValidatingKey.fromBytes(List<int> bytes) {
    final key = OrchardSpendVerificationKey.fromBytes(bytes);
    return OrchardSpendValidatingKey(key);
  }

  List<int> toBytes() {
    return key.toBytes();
  }

  @override
  List<dynamic> get variables => [key];
  Map<String, dynamic> toJson() => {"key": BytesUtils.toHexString(toBytes())};
}

class OrchardCommitIvkRandomness {
  final VestaNativeFq inner;
  const OrchardCommitIvkRandomness._(this.inner);
  factory OrchardCommitIvkRandomness(VestaNativeFq inner) {
    if (inner.isZero()) {
      throw OrchardKeyError.cryptoFailureWith("OrchardCommitIvkRandomness");
    }
    return OrchardCommitIvkRandomness._(inner);
  }
  factory OrchardCommitIvkRandomness.fromSpendKey(OrchardSpendingKey sk) {
    return OrchardCommitIvkRandomness(
      VestaNativeFq.fromBytes64(PrfExpand.orchardRivk.apply(sk.sk)),
    );
  }
  factory OrchardCommitIvkRandomness.fromBytes(List<int> bytes) {
    return OrchardCommitIvkRandomness(VestaNativeFq.fromBytes(bytes));
  }

  List<int> toBytes() {
    return inner.toBytes();
  }
}

class OrchardKeyAgreementPrivateKey {
  final VestaNativeFq scalar;
  const OrchardKeyAgreementPrivateKey._({required this.scalar});
  static PallasNativeFp commitIvk({
    required PallasNativeFp ak,
    required PallasNativeFp nk,
    required VestaNativeFq rivk,
    required ZCryptoContext context,
  }) {
    final donmain = context.getCommitDomain(
      OrchardKeyUtils.commitIvkDomainName,
    );
    final f = donmain.shortCommit(
      msg: [
        ...ak.toBits().sublist(0, PallasFPConst.numBits),
        ...nk.toBits().sublist(0, PallasFPConst.numBits),
      ],
      r: rivk,
    );
    if (f == null) {
      throw OrchardKeyError.cryptoFailureWith("commitIvk");
    }
    return f;
  }

  factory OrchardKeyAgreementPrivateKey(VestaNativeFq scalar) {
    if (scalar.isZero()) {
      throw OrchardKeyError.cryptoFailureWith(
        "OrchardKeyAgreementPrivateKey",
        reason: "Invalid scalar. scalar must not be zero.",
      );
    }
    return OrchardKeyAgreementPrivateKey._(scalar: scalar);
  }
  factory OrchardKeyAgreementPrivateKey.fromFvk({
    required OrchardFullViewingKey fvk,
    required ZCryptoContext context,
  }) {
    final base = deriveInner(fvk: fvk, context: context);
    return OrchardKeyAgreementPrivateKey(
      VestaNativeFq.fromBytes(base.toBytes()),
    );
  }
  static PallasNativeFp deriveInner({
    required OrchardFullViewingKey fvk,
    required ZCryptoContext context,
  }) {
    final ak = fvk.ak.key.point.toAffine().x;
    final scalar = commitIvk(
      ak: ak,
      nk: fvk.nk.inner,
      rivk: fvk.rivk.inner,
      context: context,
    );
    if (scalar.isZero()) {
      throw OrchardKeyError.cryptoFailureWith(
        "deriveInner",
        reason: "Key derivation failed: commitIvk produced a zero scalar.",
      );
    }
    return scalar;
  }

  OrchardAddress address(Diversifier d) {
    final pkd = OrchardDiversifiedTransmissionKey.derive(d: d, ivk: scalar);
    return OrchardAddress(diversifier: d, transmissionKey: pkd);
  }
}

class OrchardDiversifierKey {
  final List<int> key;
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
    final ffi = FF1Binary(aes: AES(key), radix: 2);
    final enc = ffi.encrypt(BinaryNumeralString(index.inner));
    return Diversifier(enc.data);
  }

  DiversifierIndex diversifierIndex(Diversifier d) {
    final ffi = FF1Binary(aes: AES(key), radix: 2);
    final dec = ffi.decrypt(BinaryNumeralString(d.inner));
    return DiversifierIndex(dec.data);
  }

  List<int> toBytes() {
    return key.clone();
  }
}

class OrchardIncomingViewingKey implements IncomingViewingKey<OrchardAddress> {
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
      ivk: OrchardKeyAgreementPrivateKey(
        VestaNativeFq.fromBytes(bytes.sublist(32)),
      ),
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
  List<int> toBytes() {
    return [...dk.toBytes(), ...ivk.scalar.toBytes()];
  }

  @override
  List<dynamic> get variables => [dk, ivk];
}

class OrchardOutgoingViewingKey {
  final List<int> key;
  OrchardOutgoingViewingKey(List<int> key)
    : key =
          key
              .exc(
                length: 32,
                operation: "OrchardOutgoingViewingKey",
                name: "key",
                reason: "Invalid outgoing view key bytes length.",
              )
              .asImmutableBytes;
  factory OrchardOutgoingViewingKey.fromFvk(OrchardFullViewingKey fvk) {
    return fvk.deriveDkOvk().$2;
  }
}

class OrchardAddress extends ShieldAddress<OrchardDiversifiedTransmissionKey> {
  const OrchardAddress({
    required super.transmissionKey,
    required super.diversifier,
  });

  PallasNativePoint gD() {
    return OrchardKeyUtils.diversifyHashNative(diversifier.inner);
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

  @override
  List<int> toBytes() {
    return [...diversifier.inner, ...transmissionKey.toBytes()];
  }
}

class OrchardDiversifiedTransmissionKey extends DiversifiedTransmissionKey {
  final PallasNativePoint point;
  const OrchardDiversifiedTransmissionKey._(this.point);
  factory OrchardDiversifiedTransmissionKey(PallasNativePoint point) {
    return OrchardDiversifiedTransmissionKey._(point);
  }

  factory OrchardDiversifiedTransmissionKey.derive({
    required VestaNativeFq ivk,
    required Diversifier d,
  }) {
    final gd = OrchardKeyUtils.diversifyHashNative(d.inner);
    return OrchardDiversifiedTransmissionKey(
      OrchardKeyUtils.kaOrchardPreparedNative(base: gd, sk: ivk),
    );
  }
  factory OrchardDiversifiedTransmissionKey.fromBytes(List<int> bytes) {
    return OrchardDiversifiedTransmissionKey(
      PallasNativePoint.fromBytes(bytes),
    );
  }

  @override
  List<int> toBytes() {
    return point.toBytes();
  }

  @override
  List<dynamic> get variables => [point];
}
