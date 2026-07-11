import 'dart:typed_data';
import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/hd_key/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/config.dart';
import 'package:blockchain_utils/bip/bip/zip32/reddsa/reddsa/sapling.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/derivator.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/exception.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/utils.dart';
import 'package:blockchain_utils/bip/bip/zip32/utils/prf_expand.dart';
import 'package:blockchain_utils/bip/bip/zip32/zip32/types.dart';
import 'package:blockchain_utils/bip/zcash/src/encoding/encoding.dart';
import 'package:blockchain_utils/crypto/crypto/aes/aes.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/jubjub.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/ff1/ff1.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class SaplingExtendedSpendingKey
    extends Zip32ExtendedSpendKey<SaplingZip32KeyData> {
  SaplingExtendedSpendingKey({
    required this.sk,
    required SaplingZip32KeyData keyData,
  }) : super(keyData);
  final SaplingExpandedSpendingKey sk;

  factory SaplingExtendedSpendingKey.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "SaplingExtendedSpendingKey",
      name: "bytes",
      reason: "Invalid sapling extended spending key bytes length.",
      length: 169,
    );
    return SaplingExtendedSpendingKey(
      sk: SaplingExpandedSpendingKey.fromBytes(
        bytes.sublist(9 + 32, 9 + 32 + 96),
      ),
      keyData: SaplingZip32KeyData(
        depth: Bip32Depth(bytes[0]),
        fingerPrint: Bip32FingerPrint(bytes.sublist(1, 5)),
        index: Bip32KeyIndex.fromBytes(bytes.sublist(5, 9)),
        chainCode: Bip32ChainCode(bytes.sublist(9, 9 + 32)),
        dk: SaplingDiversifierKey(bytes.sublist(9 + 32 + 96)),
      ),
    );
  }

  factory SaplingExtendedSpendingKey.master(List<int> seeBytes) {
    final generator = SaplingZip32MasterKeyGenerator();
    final masterKey = generator.generateFromSeed(seeBytes);
    return generator.deriveExtendedKey(masterKey);
  }

  SaplingExtendedSpendingKey deriveInternal() {
    final generator = SaplingZip32MasterKeyGenerator();
    return generator.deriveInternal(this);
  }

  SaplingExtendedFullViewKey toExtendedFvk() {
    return SaplingExtendedFullViewKey(fvk: sk.toFvk(), keyData: keyData);
  }

  @override
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(
      sk.toBytes(),
      prefix: prefix,
      lowerCase: lowerCase,
    );
  }

  List<int> toBytes() => [
    keyData.depth.depth,
    ...keyData.fingerPrint.toBytes(),
    ...keyData.index.toBytes(Endian.little),
    ...keyData.chainCode.toBytes(),
    ...sk.toBytes(),
    ...keyData.dk.toBytes(),
  ];

  @override
  List<dynamic> get variables => [sk];

  @override
  List<int> spendKeyBytes() {
    return toBytes();
  }
}

class SaplingExtendedFullViewKey
    extends
        Zip32ExtendedFullViewKey<
          SaplingIncomingViewingKey,
          SaplingZip32KeyData
        > {
  SaplingExtendedFullViewKey({
    required this.fvk,
    required SaplingZip32KeyData keyData,
  }) : super(keyData);
  factory SaplingExtendedFullViewKey.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "SaplingExtendedFullViewKey",
      name: "bytes",
      reason: "Invalid sapling extended full view key bytes length.",
      length: 169,
    );
    return SaplingExtendedFullViewKey(
      fvk: SaplingFullViewingKey.fromBytes(bytes.sublist(9 + 32, 9 + 32 + 96)),
      keyData: SaplingZip32KeyData(
        depth: Bip32Depth(bytes[0]),
        fingerPrint: Bip32FingerPrint(bytes.sublist(1, 5)),
        index: Bip32KeyIndex.fromBytes(bytes.sublist(5, 9)),
        chainCode: Bip32ChainCode(bytes.sublist(9, 9 + 32)),
        dk: SaplingDiversifierKey(bytes.sublist(9 + 32 + 96)),
      ),
    );
  }
  final SaplingFullViewingKey fvk;
  SaplingExtendedFullViewKey deriveInternal() {
    final generator = SaplingZip32MasterKeyGenerator();
    return generator.fvkDeriveInternal(this);
  }

  SaplingDiversifiableFullViewingKey toDiversifiableFullViewingKey() {
    return SaplingDiversifiableFullViewingKey(fvk: fvk, dk: keyData.dk);
  }

  List<int> toBytes() => [
    keyData.depth.depth,
    ...keyData.fingerPrint.toBytes(),
    ...keyData.index.toBytes(Endian.little),
    ...keyData.chainCode.toBytes(),
    ...fvk.toBytes(),
    ...keyData.dk.toBytes(),
  ];
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
  SaplingIncomingViewingKey incomingViewingKey(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainInt,
  }) {
    final d = toDiversifiableFullViewingKey();
    return d.toIvk(scope);
  }

  /// Encodes the Sapling extended full viewing key as a Bech32 string.
  String encodeExtendedFullViewKey(ZIP32CoinConfig config) {
    return ZcashEncodingUtils.encodeBech32Address(
      bytes: toBytes(),
      encoding: Bech32Encodings.bech32,
      hrp: config.hrpSaplingExtendedFullViewingKey,
    );
  }
}

class SaplingDiversifierKey with Equality {
  final List<int> inner;
  SaplingDiversifierKey(List<int> bytes)
    : inner =
          bytes
              .exc(
                operation: "SaplingDiversifierKey",
                name: "bytes",
                reason: "Invalid sapling diversifier key bytes length.",
                length: 32,
              )
              .asImmutableBytes;
  factory SaplingDiversifierKey.master(List<int> sk) {
    return SaplingDiversifierKey(
      PrfExpand.saplingZip32MasterDk.apply(sk).sublist(0, 32),
    );
  }
  SaplingDiversifierKey deriveChild(List<int> iL) {
    return SaplingDiversifierKey(
      PrfExpand.saplingZip32ChildDk.apply(iL, data: [inner]).sublist(0, 32),
    );
  }

  Diversifier diversifier(DiversifierIndex index) {
    final diversifier = _tryDiversifier(index);
    if (diversifier == null) {
      throw SaplingKeyError.failed(
        "diversifier",
        reason: "Invalid sapling Diversifier index.",
      );
    }
    return diversifier;
  }

  Diversifier? _tryDiversifier(DiversifierIndex index, {FF1Binary? ff}) {
    ff ??= FF1Binary(aes: AES(inner), radix: 2);
    final enc = ff.encrypt(BinaryNumeralString(index.inner));
    if (SaplingKeyUtils.diversifyHash<JubJubNativeFr, JubJubNativePoint>(
          d: enc.data,
          fromBytes: JubJubNativePoint.fromBytes,
        ) ==
        null) {
      return null;
    }
    return Diversifier(enc.data);
  }

  DiversifierIndex diversifierIndex(Diversifier d) {
    final ff = FF1Binary(aes: AES(inner), radix: 2);
    final dec = ff.decrypt(BinaryNumeralString(d.inner));
    return DiversifierIndex(dec.data);
  }

  (Diversifier, DiversifierIndex)? findDiversifier(DiversifierIndex index) {
    final ff = FF1Binary(aes: AES(inner), radix: 2);
    DiversifierIndex? j = index;
    while (j != null) {
      final d = _tryDiversifier(j, ff: ff);
      if (d != null) return (d, j);
      j = j.tryIncrement();
    }
    return null;
  }

  List<int> toBytes() => inner.clone();

  @override
  List<dynamic> get variables => [inner];
}

class SaplingZip32KeyData
    with Equality
    implements
        BaseCryptoKeyData<
          Bip32ChainCode,
          Bip32KeyIndex,
          Bip32Depth,
          Bip32FingerPrint
        > {
  @override
  final Bip32Depth depth;
  @override
  final Bip32KeyIndex index;
  @override
  final Bip32ChainCode chainCode;
  @override
  final Bip32FingerPrint fingerPrint;
  final SaplingDiversifierKey dk;

  SaplingZip32KeyData({
    Bip32Depth? depth,
    Bip32KeyIndex? index,
    Bip32ChainCode? chainCode,
    Bip32FingerPrint? fingerPrint,
    required this.dk,
  }) : depth = depth ?? Bip32Depth(0),
       index = index ?? Bip32KeyIndex(0),
       chainCode = chainCode ?? Bip32ChainCode(),
       fingerPrint = fingerPrint ?? Bip32FingerPrint();

  @override
  List<dynamic> get variables => [depth, index, chainCode, fingerPrint];
}

class SaplingExpandedSpendingKey with Equality {
  final SaplingSpendAuthorizingKey ask;
  final JubJubFr nsk;
  final SaplingOutgoingViewingKey ovk;
  SaplingFullViewingKey? _fvk;
  SaplingExpandedSpendingKey({
    required this.ask,
    required this.nsk,
    required this.ovk,
    SaplingFullViewingKey? fvk,
  }) : _fvk = fvk;
  factory SaplingExpandedSpendingKey.fromSpendingKey(List<int> sk) {
    final ask = SaplingSpendAuthorizingKey.fromSpendingKey(sk);
    final nsk = JubJubFr.fromBytes64(PrfExpand.saplingNsk.apply(sk));
    final ovk = PrfExpand.saplingOvk.apply(sk).sublist(0, 32);
    return SaplingExpandedSpendingKey(
      ask: ask,
      nsk: nsk,
      ovk: SaplingOutgoingViewingKey(ovk),
    );
  }
  factory SaplingExpandedSpendingKey.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "SaplingExpandedSpendingKey",
      name: "bytes",
      reason: "Invalid sapling extended spending key bytes length.",
      length: 96,
    );
    return SaplingExpandedSpendingKey(
      ask: SaplingSpendAuthorizingKey.fromBytes(bytes.sublist(0, 32)),
      nsk: JubJubFr.fromBytes(bytes.sublist(32, 64)),
      ovk: SaplingOutgoingViewingKey(bytes.sublist(64)),
    );
  }

  List<int> toBytes() {
    return [...ask.toBytes(), ...nsk.toBytes(), ...ovk.inner];
  }

  SaplingFullViewingKey toFvk() {
    return _fvk ??= SaplingFullViewingKey.fromExpandedSpendingKey(this);
  }

  @override
  List<dynamic> get variables => [ask, nsk, ovk];
}

class SaplingNullifierDerivingKey with Equality {
  final JubJubNativePoint inner;
  const SaplingNullifierDerivingKey(this.inner);
  factory SaplingNullifierDerivingKey.fromBytes(List<int> bytes) {
    return SaplingNullifierDerivingKey(
      JubJubNativePoint.fromBytes(
        bytes.exc(
          operation: "SaplingNullifierDerivingKey",
          name: "bytes",
          reason: "Invalid nullifier deriving key bytes length.",
          length: 32,
        ),
      ),
    );
  }
  List<int> toBytes() {
    return inner.toBytes();
  }

  @override
  List<dynamic> get variables => [inner];
}

class SaplingViewingKey with Equality {
  final SaplingSpendVerificationKey ak;
  final SaplingNullifierDerivingKey nk;
  const SaplingViewingKey({required this.ak, required this.nk});
  factory SaplingViewingKey.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "SaplingViewingKey",
      name: "bytes",
      reason: "Invalid viewing key bytes length.",
      length: 64,
    );
    final ak = SaplingSpendVerificationKey.fromBytes(bytes.sublist(0, 32));
    final nk = SaplingNullifierDerivingKey.fromBytes(bytes.sublist(32));
    return SaplingViewingKey(ak: ak, nk: nk);
  }
  SaplingIvk ivk() {
    return SaplingIvk(
      SaplingKeyUtils.crhIvk(ak: ak.toBytes(), nk: nk.toBytes()),
    );
  }

  List<int> toBytes() => [...ak.toBytes(), ...nk.toBytes()];

  @override
  List<dynamic> get variables => [ak, nk];
}

class SaplingFullViewingKey with Equality {
  final SaplingOutgoingViewingKey ovk;
  final SaplingViewingKey vk;
  SaplingFullViewingKey({required this.ovk, required this.vk});
  factory SaplingFullViewingKey.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "SaplingFullViewingKey",
      name: "bytes",
      reason: "Invalid full view key bytes length.",
      length: 96,
    );
    return SaplingFullViewingKey(
      ovk: SaplingOutgoingViewingKey(bytes.sublist(64)),
      vk: SaplingViewingKey.fromBytes(bytes.sublist(0, 64)),
    );
  }
  factory SaplingFullViewingKey.fromExpandedSpendingKey(
    SaplingExpandedSpendingKey sk,
  ) {
    final generator = SaplingKeyUtils.proofGenerationKeyGenerator;
    final mult = generator * sk.nsk;
    return SaplingFullViewingKey(
      ovk: sk.ovk,
      vk: SaplingViewingKey(
        ak: sk.ask.toVerificationKey(),
        nk: SaplingNullifierDerivingKey(
          JubJubNativePoint.fromBytes(mult.toBytes()),
        ),
      ),
    );
  }

  List<int> toBytes() {
    return [...vk.toBytes(), ...ovk.inner];
  }

  @override
  List<dynamic> get variables => [ovk, vk];
}

class SaplingDiversifiableFullViewingKey
    extends
        DiversifiableFullViewingKey<
          SaplingPaymentAddress,
          SaplingIncomingViewingKey,
          SaplingOutgoingViewingKey,
          SaplingIvk
        > {
  final SaplingFullViewingKey fvk;
  final SaplingDiversifierKey dk;
  const SaplingDiversifiableFullViewingKey({
    required this.fvk,
    required this.dk,
  });
  factory SaplingDiversifiableFullViewingKey.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "SaplingDiversifiableFullViewingKey",
      name: "bytes",
      reason: "Invalid diversifiable full view key bytes length.",
      length: 128,
    );
    final fvk = SaplingFullViewingKey.fromBytes(bytes.sublist(0, 96));
    final dk = SaplingDiversifierKey(bytes.sublist(96));
    return SaplingDiversifiableFullViewingKey(fvk: fvk, dk: dk);
  }

  SaplingDiversifiableFullViewingKey deriveInternal() {
    final generator = SaplingKeyUtils.proofGenerationKeyGeneratorNative;
    final i = QuickCrypto.blake2b256Hash(
      fvk.toBytes(),
      extraBlocks: [dk.toBytes()],
      personalization: SaplingKeyUtils.saplingInternalPersonalization.codeUnits,
    );
    final iNsk = JubJubNativeFr.fromBytes64(
      PrfExpand.saplingZip32InternalNsk.apply(i),
    );
    final r = PrfExpand.saplingZip32InternalDkOvk.apply(i);
    final nkInternal = generator * iNsk + fvk.vk.nk.inner;
    final dkInternal = r.sublist(0, 32);
    final ovkInternal = r.sublist(32);
    return SaplingDiversifiableFullViewingKey(
      fvk: SaplingFullViewingKey(
        ovk: SaplingOutgoingViewingKey(ovkInternal),
        vk: SaplingViewingKey(
          ak: fvk.vk.ak,
          nk: SaplingNullifierDerivingKey(nkInternal),
        ),
      ),
      dk: SaplingDiversifierKey(dkInternal),
    );
  }

  SaplingFullViewingKey toInternalFvk() => deriveInternal().fvk;

  SaplingNullifierDerivingKey toNk(Bip44Changes scope) => switch (scope) {
    Bip44Changes.chainExt => fvk.vk.nk,
    Bip44Changes.chainInt => deriveInternal().fvk.vk.nk,
  };
  @override
  SaplingIncomingViewingKey toIvk(
    Bip44Changes scope, {
    ZCryptoContext? context,
  }) {
    final ivk = switch (scope) {
      Bip44Changes.chainExt => fvk.vk.ivk(),
      Bip44Changes.chainInt => deriveInternal().fvk.vk.ivk(),
    };
    return SaplingIncomingViewingKey(dk: dk, ivk: ivk);
  }

  @override
  SaplingOutgoingViewingKey toOvk(Bip44Changes scope) {
    return switch (scope) {
      Bip44Changes.chainExt => fvk.ovk,
      Bip44Changes.chainInt => deriveInternal().fvk.ovk,
    };
  }

  SaplingIncomingViewingKey toExternalIvk() => toIvk(Bip44Changes.chainExt);

  @override
  List<int> toBytes() => [...fvk.toBytes(), ...dk.toBytes()];

  (SaplingPaymentAddress, DiversifierIndex) defaultAddress() {
    final result = toExternalIvk().findAddress(DiversifierIndex.zero());
    if (result == null) {
      throw SaplingKeyError.failed(
        "defaultAddress",
        reason: "Failed to find address from index 0.",
      );
    }
    return result;
  }

  (SaplingPaymentAddress, DiversifierIndex) changeAddress() {
    return deriveInternal().defaultAddress();
  }

  SaplingPaymentAddress diversifiedAaddress(Diversifier diversifier) {
    return toExternalIvk().address(diversifier);
  }

  @override
  Bip44Changes? scopeForAddress({
    required SaplingPaymentAddress address,
    ZCryptoContext? context,
  }) {
    return Bip44Changes.values.firstWhereNullable(
      (e) => toIvk(e, context: context).diversifierIndex(address) != null,
    );
  }

  @override
  List<dynamic> get variables => [protocol, fvk, dk];

  @override
  ZcashProtocol get protocol => ZcashProtocol.sapling;

  @override
  SaplingIvk keyAgreement(Bip44Changes scope, {ZCryptoContext? context}) {
    return toIvk(scope, context: context).ivk;
  }
}

class SaplingIvk extends KeyAgreementPrivateKey {
  final JubJubNativeFr inner;
  const SaplingIvk(this.inner);
  factory SaplingIvk.fromBytes(List<int> bytes) {
    return SaplingIvk(
      JubJubNativeFr.fromBytes(
        bytes.exc(
          operation: "SaplingIvk",
          name: "bytes",
          reason: "Invalid ivk bytes length.",
          length: 32,
        ),
      ),
    );
  }
  SaplingPaymentAddress toPaymentAddress(Diversifier diversifier) {
    final pkd = SaplingDiversifiedTransmissionKey.derive(
      d: diversifier,
      ivk: inner,
    );
    return SaplingPaymentAddress(
      transmissionKey: pkd,
      diversifier: diversifier,
    );
  }

  List<int> toBytes() => inner.toBytes();

  @override
  List<dynamic> get variables => [inner];
}

class SaplingDiversifiedTransmissionKey extends DiversifiedTransmissionKey {
  final List<int> inner;
  JubJubNativePoint? _point;
  JubJubNativePoint toPoint() {
    JubJubNativePoint? point = _point;
    if (point != null) return point;
    point = JubJubNativePoint.fromBytes(inner);
    if (!point.isTorsionFree()) {
      throw SaplingKeyError.failed("toPoint");
    }
    _point = point;
    return point;
  }

  SaplingDiversifiedTransmissionKey._(List<int> inner, JubJubNativePoint? point)
    : _point = point,
      inner = inner.exc(
        operation: "SaplingDiversifiedTransmissionKey",
        name: "bytes",
        reason: "Invalid diversified transmission key bytes length.",
        length: 32,
      );
  factory SaplingDiversifiedTransmissionKey(JubJubNativePoint point) {
    if (!point.isTorsionFree()) {
      throw SaplingKeyError.failed("SaplingDiversifiedTransmissionKey");
    }
    return SaplingDiversifiedTransmissionKey._(point.toBytes(), point);
  }
  factory SaplingDiversifiedTransmissionKey.fromBytesUnchecked(
    List<int> bytes,
  ) {
    return SaplingDiversifiedTransmissionKey._(bytes, null);
  }
  factory SaplingDiversifiedTransmissionKey.fromBytes(List<int> bytes) {
    final key = SaplingDiversifiedTransmissionKey._(bytes, null);
    key.toPoint();
    return key;
  }
  factory SaplingDiversifiedTransmissionKey.derive({
    required Diversifier d,
    required JubJubNativeFr ivk,
  }) {
    final gd = SaplingKeyUtils.diversifyHash<JubJubNativeFr, JubJubNativePoint>(
      d: d.inner,
      fromBytes: JubJubNativePoint.fromBytes,
    );
    if (gd == null) {
      throw SaplingKeyError.failed("derive");
    }
    return SaplingDiversifiedTransmissionKey(gd * ivk);
  }
  @override
  List<int> toBytes() => inner.clone();

  @override
  List<dynamic> get variables => [inner];
}

class SaplingPaymentAddress
    extends ShieldAddress<SaplingDiversifiedTransmissionKey> {
  const SaplingPaymentAddress({
    required super.transmissionKey,
    required super.diversifier,
  });
  factory SaplingPaymentAddress.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "SaplingPaymentAddress",
      name: "bytes",
      reason: "Invalid sapling address bytes length.",
      length: 43,
    );
    return SaplingPaymentAddress(
      transmissionKey: SaplingDiversifiedTransmissionKey.fromBytes(
        bytes.sublist(11),
      ),
      diversifier: Diversifier(bytes.sublist(0, 11)),
    );
  }
  factory SaplingPaymentAddress.fromBytesUnchecked(List<int> bytes) {
    bytes = bytes.exc(
      operation: "SaplingPaymentAddress",
      name: "bytes",
      reason: "Invalid sapling address bytes length.",
      length: 43,
    );
    return SaplingPaymentAddress(
      transmissionKey: SaplingDiversifiedTransmissionKey.fromBytesUnchecked(
        bytes.sublist(11),
      ),
      diversifier: Diversifier(bytes.sublist(0, 11)),
    );
  }
  @override
  List<int> toBytes() {
    return [...diversifier.inner, ...transmissionKey.toBytes()];
  }

  JubJubNativePoint gd() {
    final gd = SaplingKeyUtils.diversifyHash<JubJubNativeFr, JubJubNativePoint>(
      d: diversifier.inner,
      fromBytes: JubJubNativePoint.fromBytes,
    );
    if (gd == null) {
      throw SaplingKeyError.failed(
        "derive",
        reason: "Failed to derive point from diversifier.",
      );
    }
    return gd;
  }
}

class SaplingIncomingViewingKey
    extends IncomingViewingKey<SaplingPaymentAddress> {
  final SaplingDiversifierKey dk;
  final SaplingIvk ivk;
  const SaplingIncomingViewingKey({required this.dk, required this.ivk});
  factory SaplingIncomingViewingKey.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "SaplingIncomingViewingKey",
      name: "bytes",
      reason: "Invalid incoming view key bytes length.",
      length: 64,
    );
    return SaplingIncomingViewingKey(
      dk: SaplingDiversifierKey(bytes.sublist(0, 32)),
      ivk: SaplingIvk.fromBytes(bytes.sublist(32)),
    );
  }
  @override
  List<int> toBytes() => [...dk.inner, ...ivk.toBytes()];

  @override
  SaplingPaymentAddress addressAt(DiversifierIndex index) {
    final dJ = dk.diversifier(index);
    return ivk.toPaymentAddress(dJ);
  }

  SaplingPaymentAddress? tryAddressAt(DiversifierIndex index) {
    try {
      final dJ = dk.diversifier(index);
      return ivk.toPaymentAddress(dJ);
    } on SaplingKeyError {
      return null;
    }
  }

  @override
  SaplingPaymentAddress address(Diversifier diversifier) {
    return ivk.toPaymentAddress(diversifier);
  }

  @override
  (SaplingPaymentAddress, DiversifierIndex)? findAddress(
    DiversifierIndex index,
  ) {
    final j = dk.findDiversifier(index);
    if (j != null) return (address(j.$1), j.$2);
    return null;
  }

  @override
  DiversifierIndex? diversifierIndex(SaplingPaymentAddress addr) {
    final j = dk.diversifierIndex(addr.diversifier);
    if (addressAt(j) == addr) {
      return j;
    }
    return null;
  }

  @override
  List<dynamic> get variables => [dk, ivk];

  @override
  ZcashProtocol get protocol => ZcashProtocol.sapling;
}

class SaplingOutgoingViewingKey extends OutgoingViewingKey {
  final List<int> inner;
  SaplingOutgoingViewingKey(List<int> inner)
    : inner =
          inner
              .exc(
                operation: "SaplingOutgoingViewingKey",
                name: "bytes",
                reason: "Invalid outgoing viewing key bytes length.",
                length: 32,
              )
              .asImmutableBytes;

  @override
  List<dynamic> get variables => [inner];

  @override
  List<int> toBytes() {
    return inner.clone();
  }
}
