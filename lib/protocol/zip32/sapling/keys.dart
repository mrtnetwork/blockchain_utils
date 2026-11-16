import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/protocol/hd_key/types.dart';
import 'package:blockchain_utils/protocol/zip32/base/context.dart';
import 'package:blockchain_utils/protocol/zip32/base/types.dart';
import 'package:blockchain_utils/protocol/zip32/conf/config.dart';
import 'package:blockchain_utils/protocol/zip32/sapling/derivator.dart';
import 'package:blockchain_utils/protocol/zip32/sapling/utils.dart';
import 'package:blockchain_utils/protocol/zip32/utils/prf_expand.dart';
import 'package:blockchain_utils/protocol/zip32/zip32/types.dart';
import 'package:blockchain_utils/protocol/zcash/src/encoding/encoding.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class SaplingExtendedSpendingKey
    extends Zip32ExtendedSpendKey<SaplingZip32KeyData>
    with SecretState {
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

  SecretBytes toBytes() => SecretBytes([
    keyData.depth.depth,
    ...keyData.fingerPrint.toBytes(),
    ...keyData.index.toBytes(Endian.little),
    ...keyData.chainCode.toBytes(),
    ...sk.toBytes(),
    ...keyData.dk.toBytes(),
  ]);

  @override
  List<dynamic> get variables => [sk];

  @override
  SecretBytes spendKeyBytes() {
    return toBytes();
  }

  @override
  void dispose() {
    sk.dispose();
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

  BuBytes toBytes() => BuBytes([
    keyData.depth.depth,
    ...keyData.fingerPrint.toBytes(),
    ...keyData.index.toBytes(Endian.little),
    ...keyData.chainCode.toBytes(),
    ...fvk.toBytes(),
    ...keyData.dk.toBytes(),
  ]);

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
      throw CoreErrors.saplingFailed(
        "diversifier",
        reason: "Invalid sapling Diversifier index.",
      );
    }
    return diversifier;
  }

  Diversifier? _tryDiversifier(DiversifierIndex index) {
    final enc = blockchainUtils.api.ff1.encryptBinary(
      key: inner,
      pt: index.inner,
    );
    if (SaplingKeyUtils.diversifyHash<JubJubFr, JubJubPoint>(
          d: enc,
          fromBytes: JubJubPoint.fromBytes,
        ) ==
        null) {
      return null;
    }
    return Diversifier(enc);
  }

  DiversifierIndex diversifierIndex(Diversifier d) {
    final dec = blockchainUtils.api.ff1.decryptBinary(key: inner, ct: d.inner);
    return DiversifierIndex(dec);
  }

  (Diversifier, DiversifierIndex)? findDiversifier(DiversifierIndex index) {
    DiversifierIndex? j = index;
    while (j != null) {
      final d = _tryDiversifier(j);
      if (d != null) return (d, j);
      j = j.tryIncrement();
    }
    return null;
  }

  BuBytes toBytes() => BuBytes(inner.clone());

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

class SaplingExpandedSpendingKey with Equality, SecretState {
  final RedJubJubSpendPrivateKey ask;
  final BuBytes _nskBytes;
  JubJubFr? _nsk;

  /// Spend authorization scalar, decoded lazily once and cached.
  JubJubFr get nsk => _nsk ??= JubJubFr.fromBytes(_nskBytes);

  final SaplingOutgoingViewingKey ovk;
  SaplingFullViewingKey? _fvk;
  SaplingExpandedSpendingKey({
    required this.ask,
    required JubJubFr nsk,
    required this.ovk,
    SaplingFullViewingKey? fvk,
  }) : _nskBytes = BuBytes.from(nsk.toBytes()),
       _nsk = nsk;
  factory SaplingExpandedSpendingKey.fromSpendingKey(List<int> sk) {
    final ask = RedJubJubSpendPrivateKey.fromSpendingKey(sk);
    final nsk = blockchainUtils.api.jubjub.scReduce64(
      PrfExpand.saplingNsk.apply(sk),
    );
    final ovk = PrfExpand.saplingOvk.apply(sk).sublist(0, 32);
    return SaplingExpandedSpendingKey(
      ask: ask,
      nsk: JubJubFr.fromBytes(nsk),
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
    // Single validating parse of the scalar; afterwards raw bytes are kept.
    final nsk = JubJubFr.fromBytes(bytes.sublist(32, 64));
    final self = SaplingExpandedSpendingKey(
      ask: RedJubJubSpendPrivateKey.fromBytes(bytes.sublist(0, 32)),
      nsk: nsk,
      ovk: SaplingOutgoingViewingKey(bytes.sublist(64)),
    );
    self._nsk = nsk;
    return self;
  }

  BuBytes toBytes() {
    return BuBytes.unsafeMutable([
      ...ask.toBytes(),
      ..._nskBytes.cloneBytes(),
      ...ovk.inner,
    ]);
  }

  SaplingFullViewingKey toFvk() {
    return _fvk ??= SaplingFullViewingKey.fromExpandedSpendingKey(this);
  }

  @override
  List<dynamic> get variables => [ask, _nskBytes, ovk];

  @override
  void dispose() {
    ask.dispose();
    _nskBytes.forceZero();
    _fvk = null;
    _nsk = null;
  }
}

class SaplingNullifierDerivingKey with Equality {
  final BuBytes _bytes;
  JubJubPoint? _inner;

  /// Parsed nullifier key, decoded lazily once and cached.
  JubJubPoint get inner => _inner ??= JubJubPoint.fromBytes(_bytes);

  SaplingNullifierDerivingKey(JubJubPoint inner)
    : _bytes = BuBytes.from(inner.toBytes()),
      _inner = inner;
  factory SaplingNullifierDerivingKey.fromBytes(List<int> bytes) {
    // Single validating parse; afterwards only raw bytes are kept.
    final inner = JubJubPoint.fromBytes(
      bytes.exc(
        operation: "SaplingNullifierDerivingKey",
        name: "bytes",
        reason: "Invalid nullifier deriving key bytes length.",
        length: 32,
      ),
    );
    final self = SaplingNullifierDerivingKey(inner);
    self._inner = inner;
    return self;
  }
  BuBytes toBytes() {
    return _bytes.cloneBytes();
  }

  @override
  List<dynamic> get variables => [_bytes];
}

class SaplingViewingKey with Equality {
  final RedJubJubSpendPublicKey ak;
  final SaplingNullifierDerivingKey nk;
  const SaplingViewingKey({required this.ak, required this.nk});
  factory SaplingViewingKey.fromBytes(List<int> bytes) {
    bytes = bytes.exc(
      operation: "SaplingViewingKey",
      name: "bytes",
      reason: "Invalid viewing key bytes length.",
      length: 64,
    );
    final ak = RedJubJubSpendPublicKey.fromBytes(bytes.sublist(0, 32));
    final nk = SaplingNullifierDerivingKey.fromBytes(bytes.sublist(32));
    return SaplingViewingKey(ak: ak, nk: nk);
  }
  SaplingIvk ivk() {
    return SaplingIvk(
      SaplingKeyUtils.crhIvk(ak: ak.toBytes(), nk: nk.toBytes()),
    );
  }

  BuBytes toBytes() => BuBytes([...ak.toBytes(), ...nk.toBytes()]);

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
    final mult = blockchainUtils.api.jubjub.mult(
      sk.nsk.toBytes(),
      generator.toBytes(),
    );
    return SaplingFullViewingKey(
      ovk: sk.ovk,
      vk: SaplingViewingKey(
        ak: sk.ask.publicKey,
        nk: SaplingNullifierDerivingKey(JubJubPoint.fromBytes(mult)),
      ),
    );
  }

  BuBytes toBytes() {
    return BuBytes([...vk.toBytes(), ...ovk.inner]);
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
    final generator = SaplingKeyUtils.proofGenerationKeyGenerator;
    final i = QuickCrypto.blake2b256Hash(
      fvk.toBytes(),
      extraBlocks: [dk.toBytes()],
      personalization: StringUtils.encode(
        SaplingKeyUtils.saplingInternalPersonalization,
      ),
    );
    final iNSK = blockchainUtils.api.jubjub.scReduce64(
      PrfExpand.saplingZip32InternalNsk.apply(i),
    );
    final iNSKG = blockchainUtils.api.jubjub.mult(iNSK, generator.toBytes());

    final r = PrfExpand.saplingZip32InternalDkOvk.apply(i);
    final nkInternal = blockchainUtils.api.jubjub.add(
      iNSKG,
      fvk.vk.nk.inner.toBytes(),
    );
    final dkInternal = r.sublist(0, 32);
    final ovkInternal = r.sublist(32);
    return SaplingDiversifiableFullViewingKey(
      fvk: SaplingFullViewingKey(
        ovk: SaplingOutgoingViewingKey(ovkInternal),
        vk: SaplingViewingKey(
          ak: fvk.vk.ak,
          nk: SaplingNullifierDerivingKey(JubJubPoint.fromBytes(nkInternal)),
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
  BuBytes toBytes() =>
      BuBytes.unsafeMutable([...fvk.toBytes(), ...dk.toBytes()]);

  (SaplingPaymentAddress, DiversifierIndex) defaultAddress() {
    final result = toExternalIvk().findAddress(DiversifierIndex.zero());
    if (result == null) {
      throw CoreErrors.saplingFailed(
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
  final BuBytes _bytes;
  JubJubFr? _inner;

  /// Parsed agreement scalar, decoded lazily once and cached.
  JubJubFr get inner => _inner ??= JubJubFr.fromBytes(_bytes);

  SaplingIvk(JubJubFr inner)
    : _bytes = BuBytes.from(inner.toBytes()),
      _inner = inner;
  factory SaplingIvk.fromBytes(List<int> bytes) {
    // Single validating parse; afterwards only raw bytes are kept.
    final inner = JubJubFr.fromBytes(
      bytes.exc(
        operation: "SaplingIvk",
        name: "bytes",
        reason: "Invalid ivk bytes length.",
        length: 32,
      ),
    );
    final self = SaplingIvk(inner);
    self._inner = inner;
    return self;
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

  BuBytes toBytes() => _bytes.cloneBytes();

  @override
  List<dynamic> get variables => [_bytes];
}

class SaplingDiversifiedTransmissionKey extends DiversifiedTransmissionKey {
  final BuBytes inner;
  JubJubPoint? _point;
  JubJubPoint toPoint() {
    JubJubPoint? point = _point;
    if (point != null) return point;
    point = JubJubPoint.fromBytes(inner);
    if (!point.isTorsionFree()) {
      throw CoreErrors.saplingFailed("toPoint");
    }
    _point = point;
    return point;
  }

  SaplingDiversifiedTransmissionKey._(List<int> inner, JubJubPoint? point)
    : _point = point,
      inner =
          inner
              .exc(
                operation: "SaplingDiversifiedTransmissionKey",
                name: "bytes",
                reason: "Invalid diversified transmission key bytes length.",
                length: 32,
              )
              .asImmutableBytes;
  factory SaplingDiversifiedTransmissionKey(JubJubPoint point) {
    if (!point.isTorsionFree()) {
      throw CoreErrors.saplingFailed("SaplingDiversifiedTransmissionKey");
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
    required JubJubFr ivk,
  }) {
    final gd = SaplingKeyUtils.diversifyHash<JubJubFr, JubJubPoint>(
      d: d.inner,
      fromBytes: JubJubPoint.fromBytes,
    );
    if (gd == null) {
      throw CoreErrors.saplingFailed("derive");
    }
    final mult = blockchainUtils.api.jubjub.mult(ivk.toBytes(), gd.toBytes());
    return SaplingDiversifiedTransmissionKey(JubJubPoint.fromBytes(mult));
  }
  @override
  BuBytes toBytes() => inner.cloneBytes();

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
  BuBytes toBytes() {
    return BuBytes.unsafeMutable([
      ...diversifier.inner,
      ...transmissionKey.toBytes(),
    ]);
  }

  JubJubPoint gd() {
    final gd = SaplingKeyUtils.diversifyHash<JubJubFr, JubJubPoint>(
      d: diversifier.inner,
      fromBytes: JubJubPoint.fromBytes,
    );
    if (gd == null) {
      throw CoreErrors.saplingFailed(
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
  BuBytes toBytes() => BuBytes.unsafeMutable([...dk.inner, ...ivk.toBytes()]);

  @override
  SaplingPaymentAddress addressAt(DiversifierIndex index) {
    final dJ = dk.diversifier(index);
    return ivk.toPaymentAddress(dJ);
  }

  SaplingPaymentAddress? tryAddressAt(DiversifierIndex index) {
    try {
      final dJ = dk.diversifier(index);
      return ivk.toPaymentAddress(dJ);
    } on BuError catch (e) {
      if (e.type != DefaultErrorType.invalidKeyData) rethrow;
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
  final BuBytes inner;
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
  BuBytes toBytes() {
    return inner.cloneBytes();
  }
}
