import 'dart:typed_data';
import 'package:blockchain_utils/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/hd_key/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/exception/exception.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/keys.dart';
import 'package:blockchain_utils/bip/bip/zip32/reddsa/reddsa/orchard.dart';
import 'package:blockchain_utils/bip/bip/zip32/utils/prf_expand.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

class OrchardZip32MasterKeyGenerator implements IZip32MasterKeyGenerator {
  @override
  Bip32MasterKey generateFromSeed(List<int> seedBytes) {
    final key = QuickCrypto.blake2b512Hash(
      seedBytes,
      personalization: "ZcashIP32Orchard".codeUnits,
    );
    return Bip32MasterKey(
      key: key.sublist(0, 32),
      chainCode: Bip32ChainCode(key.sublist(32)),
    );
  }

  (OrchardExtendedSpendingKey, OrchardFullViewingKey) deriveExtendedKey(
    List<int> seedBytes,
  ) {
    final masterKey = generateFromSeed(seedBytes);
    final spendKey = OrchardSpendingKey(masterKey.key);
    final fvk = OrchardFullViewingKey.fromSpendKey(spendKey);
    final extendKey = OrchardExtendedSpendingKey(
      sk: spendKey,
      keyData: Bip32KeyData(chainCode: masterKey.chainCode),
    );
    return (extendKey, fvk);
  }
}

class OrchardZip32ChildKeyDerivator
    extends
        IChildKeyDerivator<
          Bip32ChildKey,
          OrchardExtendedSpendingKey,
          OrchardExtendedFullViewKey?,
          Bip32KeyIndex
        > {
  @override
  Bip32ChildKey deriveFromPublic({
    required OrchardExtendedFullViewKey? parent,
    required Bip32KeyIndex index,
  }) {
    throw const Zip32Error('Public child derivation is not supported');
  }

  @override
  Bip32ChildKey deriveFromSecret({
    required OrchardExtendedSpendingKey parent,
    OrchardExtendedFullViewKey? ctx,
    required Bip32KeyIndex index,
  }) {
    final cdkh = PrfExpand.orchardZip32Child.apply(
      parent.keyData.chainCode.toBytes(),
      data: [
        parent.sk.toBytes(),
        index.toBytes(Endian.little),
        [0],
        [],
      ],
    );
    return Bip32ChildKey(
      key: cdkh.sublist(0, 32),
      chainCode: Bip32ChainCode(cdkh.sublist(32)),
    );
  }

  List<int> deriveFingerPrint(OrchardFullViewingKey fvk) {
    return QuickCrypto.blake2b256Hash(
      fvk.toBytes(),
      personalization: "ZcashOrchardFVFP".codeUnits,
    );
  }

  (OrchardExtendedSpendingKey, OrchardFullViewingKey) deriveExtendedKey({
    required OrchardExtendedSpendingKey parent,
    required OrchardExtendedFullViewKey parentFvk,
    required Bip32KeyIndex index,
    required ZCryptoContext context,
  }) {
    final child = deriveFromSecret(parent: parent, index: index);
    final fp = Bip32FingerPrint(
      deriveFingerPrint(
        parentFvk.fvk,
      ).sublist(0, Bip32FingerPrint.fixedLength()),
    );
    final key = OrchardSpendingKey(child.key);
    OrchardSpendAuthorizingKey.fromSpendingKey(key);
    final fvk = OrchardFullViewingKey.fromSpendKey(key);
    OrchardKeyAgreementPrivateKey.deriveInner(fvk: fvk, context: context);
    OrchardKeyAgreementPrivateKey.deriveInner(
      fvk: fvk.deriveInternal(),
      context: context,
    );
    return (
      OrchardExtendedSpendingKey(
        sk: key,
        keyData: Bip32KeyData(
          depth: parent.keyData.depth.increase(),
          chainCode: child.chainCode,
          index: index,
          fingerPrint: fp,
        ),
      ),
      fvk,
    );
  }

  @override
  bool isPublicDerivationSupported() {
    return false;
  }
}
