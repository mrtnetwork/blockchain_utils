import 'dart:typed_data';
import 'package:blockchain_utils/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/hd_key/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/exception/exception.dart';
import 'package:blockchain_utils/bip/bip/zip32/reddsa/reddsa/sapling.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/keys.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/utils.dart';
import 'package:blockchain_utils/bip/bip/zip32/utils/prf_expand.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class SaplingZip32MasterKeyGenerator implements IZip32MasterKeyGenerator {
  @override
  Bip32MasterKey generateFromSeed(List<int> seedBytes) {
    final personalizationBytes = StringUtils.encode("ZcashIP32Sapling");
    final hash = QuickCrypto.blake2b512Hash(
      seedBytes,
      personalization: personalizationBytes,
    );
    return Bip32MasterKey(
      key: hash.sublist(0, 32),
      chainCode: Bip32ChainCode(hash.sublist(32)),
    );
  }

  SaplingExtendedSpendingKey deriveInternal(SaplingExtendedSpendingKey master) {
    final fvk = master.sk.toFvk();
    final i = QuickCrypto.blake2b256Hash(
      fvk.toBytes(),
      extraBlocks: [master.keyData.dk.toBytes()],
      personalization: SaplingKeyUtils.saplingInternalPersonalization.codeUnits,
    );
    final iNsk = JubJubFr.fromBytes64(
      PrfExpand.saplingZip32InternalNsk.apply(i),
    );
    final r = PrfExpand.saplingZip32InternalDkOvk.apply(i);
    final nskInternal = iNsk + master.sk.nsk;
    final dkInternal = r.sublist(0, 32);
    final ovkInternal = r.sublist(32);
    return SaplingExtendedSpendingKey(
      sk: SaplingExpandedSpendingKey(
        ask: master.sk.ask,
        nsk: nskInternal,
        ovk: SaplingOutgoingViewingKey(ovkInternal),
      ),
      keyData: SaplingZip32KeyData(
        dk: SaplingDiversifierKey(dkInternal),
        chainCode: master.keyData.chainCode,
        depth: master.keyData.depth,
        fingerPrint: master.keyData.fingerPrint,
        index: master.keyData.index,
      ),
    );
  }

  SaplingExtendedFullViewKey fvkDeriveInternal(
    SaplingExtendedFullViewKey master,
  ) {
    final generator = SaplingKeyUtils.proofGenerationKeyGeneratorNative;
    final fvk = master.fvk;
    final i = QuickCrypto.blake2b256Hash(
      fvk.toBytes(),
      extraBlocks: [master.keyData.dk.toBytes()],
      personalization: SaplingKeyUtils.saplingInternalPersonalization.codeUnits,
    );
    final iNsk = JubJubNativeFr.fromBytes64(
      PrfExpand.saplingZip32InternalNsk.apply(i),
    );
    final r = PrfExpand.saplingZip32InternalDkOvk.apply(i);
    final nkInternal = generator * iNsk + fvk.vk.nk.inner;
    final dkInternal = r.sublist(0, 32);
    final ovkInternal = r.sublist(32);
    return SaplingExtendedFullViewKey(
      fvk: SaplingFullViewingKey(
        vk: SaplingViewingKey(
          ak: fvk.vk.ak,
          nk: SaplingNullifierDerivingKey(nkInternal),
        ),
        ovk: SaplingOutgoingViewingKey(ovkInternal),
      ),
      keyData: SaplingZip32KeyData(
        dk: SaplingDiversifierKey(dkInternal),
        chainCode: master.keyData.chainCode,
        depth: master.keyData.depth,
        fingerPrint: master.keyData.fingerPrint,
        index: master.keyData.index,
      ),
    );
  }

  SaplingExtendedSpendingKey deriveExtendedKey(Bip32MasterKey masterKey) {
    return SaplingExtendedSpendingKey(
      sk: SaplingExpandedSpendingKey.fromSpendingKey(masterKey.key),
      keyData: SaplingZip32KeyData(
        dk: SaplingDiversifierKey(
          PrfExpand.saplingZip32MasterDk.apply(masterKey.key).sublist(0, 32),
        ),
        chainCode: masterKey.chainCode,
      ),
    );
  }
}

class SaplingZip32ChildKeyDerivator
    extends
        IChildKeyDerivator<
          Bip32ChildKey,
          SaplingExtendedSpendingKey,
          SaplingExtendedSpendingKey?,
          Bip32KeyIndex
        > {
  @override
  Bip32ChildKey deriveFromPublic({
    SaplingExtendedSpendingKey? parent,
    required Bip32KeyIndex index,
  }) {
    throw const Zip32Error('Public child derivation is not supported');
  }

  @override
  Bip32ChildKey deriveFromSecret({
    required SaplingExtendedSpendingKey parent,
    SaplingExtendedSpendingKey? ctx,
    required Bip32KeyIndex index,
  }) {
    final indexBytes = index.toBytes(Endian.little);
    final tmp = PrfExpand.saplingZip32ChildHardened.apply(
      parent.keyData.chainCode.toBytes(),
      data: [parent.sk.toBytes(), parent.keyData.dk.toBytes(), indexBytes],
    );
    return Bip32ChildKey(
      key: tmp.sublist(0, 32),
      chainCode: Bip32ChainCode(tmp.sublist(32)),
    );
  }

  SaplingOutgoingViewingKey deriveChildOvk({
    required SaplingOutgoingViewingKey parentOvk,
    required List<int> childSk,
  }) {
    return SaplingOutgoingViewingKey(
      PrfExpand.saplingZip32ChildOvk
          .apply(childSk, data: [parentOvk.inner])
          .sublist(0, 32),
    );
  }

  SaplingExtendedSpendingKey deriveExpandedSpendingKey({
    required SaplingExtendedSpendingKey parent,
    required Bip32KeyIndex index,
  }) {
    final ctx = deriveFromSecret(parent: parent, index: index);
    JubJubFr ask = JubJubFr.fromBytes64(
      PrfExpand.saplingZip32ChildIAsk.apply(ctx.key),
    );
    JubJubFr nsk = JubJubFr.fromBytes64(
      PrfExpand.saplingZip32ChildINsk.apply(ctx.key),
    );
    ask += parent.sk.ask.inner;
    nsk += parent.sk.nsk;
    final sk = SaplingExpandedSpendingKey(
      ask: SaplingSpendAuthorizingKey(ask),
      nsk: nsk,
      ovk: deriveChildOvk(parentOvk: parent.sk.ovk, childSk: ctx.key),
    );

    final fvk = parent.sk.toFvk();
    final pfBytes = QuickCrypto.blake2b256Hash(
      fvk.toBytes(),
      personalization: "ZcashSaplingFVFP".codeUnits,
    );
    return SaplingExtendedSpendingKey(
      sk: sk,
      keyData: SaplingZip32KeyData(
        depth: parent.keyData.depth.increase(),
        fingerPrint: Bip32FingerPrint(pfBytes),
        index: index,
        chainCode: ctx.chainCode,
        dk: parent.keyData.dk.deriveChild(ctx.key),
      ),
    );
  }

  @override
  bool isPublicDerivationSupported() {
    return false;
  }
}
