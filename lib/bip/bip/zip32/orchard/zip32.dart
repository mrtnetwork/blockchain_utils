import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/exception/exception.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/derivator.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/keys.dart';
import 'package:blockchain_utils/bip/bip/zip32/reddsa/reddsa/orchard.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

class Zip32Orchard
    implements
        Zip32Base<
          OrchardExtendedSpendingKey,
          OrchardExtendedFullViewKey,
          Bip32KeyIndex,
          OrchardZip32ChildKeyDerivator,
          OrchardZip32MasterKeyGenerator,
          Zip32Orchard
        > {
  Zip32Orchard._({
    required OrchardExtendedSpendingKey? privateKey,
    required this.publicKey,
  }) : _privateKey = privateKey;

  OrchardExtendedSpendingKey? _privateKey;

  bool get isPublicOnly {
    return _privateKey == null;
  }

  @override
  OrchardExtendedSpendingKey get privateKey {
    final prvKey = _privateKey;
    if (prvKey == null) {
      throw const Zip32Error(
        'Public-only deterministic keys have no private half',
      );
    }
    return prvKey;
  }

  @override
  final OrchardExtendedFullViewKey publicKey;

  factory Zip32Orchard.fromSpendKey({
    required List<int> sk,
    ZCryptoContext? context,
    Bip32KeyData? keyData,
    bool check = true,
  }) {
    keyData ??= Bip32KeyData();
    final spendKey = OrchardSpendingKey(sk);
    final fvk = OrchardFullViewingKey.fromSpendKey(spendKey);
    if (check) {
      context ??= DefaultZCryptoContext();
      OrchardSpendAuthorizingKey.fromSpendingKey(spendKey);
      OrchardKeyAgreementPrivateKey.deriveInner(fvk: fvk, context: context);
      OrchardKeyAgreementPrivateKey.deriveInner(
        fvk: fvk.deriveInternal(),
        context: context,
      );
    }
    final prvKey = OrchardExtendedSpendingKey(sk: spendKey, keyData: keyData);
    return Zip32Orchard._(
      privateKey: prvKey,
      publicKey: OrchardExtendedFullViewKey(fvk: fvk, keyData: keyData),
    );
  }
  factory Zip32Orchard.fromFullViewKey({
    required List<int> fvk,
    required ZCryptoContext context,
    Bip32KeyData? keyData,
  }) {
    final pk = OrchardExtendedFullViewKey.fromFullViewKey(
      bytes: fvk,
      context: context,
      keyData: keyData,
    );
    return Zip32Orchard._(privateKey: null, publicKey: pk);
  }
  factory Zip32Orchard.fromFullViewKeyUnchecked({
    required List<int> fvk,
    Bip32KeyData? keyData,
  }) {
    final pk = OrchardExtendedFullViewKey.fromFullViewKeyUnchecked(
      fvk,
      keyData: keyData,
    );
    return Zip32Orchard._(privateKey: null, publicKey: pk);
  }
  factory Zip32Orchard.fromSeed(List<int> seedBytes) {
    final generator = OrchardZip32MasterKeyGenerator();
    final extendedKey = generator.deriveExtendedKey(seedBytes);
    return Zip32Orchard._(
      privateKey: extendedKey.$1,
      publicKey: OrchardExtendedFullViewKey(
        fvk: extendedKey.$2,
        keyData: extendedKey.$1.keyData,
      ),
    );
  }

  @override
  Zip32Orchard childKey(Bip32KeyIndex index, {ZCryptoContext? context}) {
    context ??= DefaultZCryptoContext();
    final prvKey = _privateKey;

    if (prvKey == null) {
      throw const Zip32Error('Public child derivation is not supported');
    }
    if (!index.isHardened) {
      throw const Zip32Error(
        'Private child derivation with not-hardened index is not supported',
      );
    }
    final extendedKey = keyDerivator.deriveExtendedKey(
      parent: prvKey,
      parentFvk: publicKey,
      context: context,
      index: index,
    );
    return Zip32Orchard._(
      privateKey: extendedKey.$1,
      publicKey: OrchardExtendedFullViewKey(
        fvk: extendedKey.$2,
        keyData: extendedKey.$1.keyData,
      ),
    );
  }

  @override
  OrchardZip32ChildKeyDerivator get keyDerivator =>
      OrchardZip32ChildKeyDerivator();

  @override
  OrchardZip32MasterKeyGenerator get masterKeyGenerator =>
      OrchardZip32MasterKeyGenerator();

  @override
  Zip32Orchard derivePath(String path, {ZCryptoContext? context}) {
    context ??= DefaultZCryptoContext();
    final pathInstance = Bip32PathParser.parse(path);

    if (depth.depth > 0 && pathInstance.isAbsolute) {
      throw ArgumentException.invalidOperationArguments(
        "derivePath",
        name: "path",
        reason:
            'Absolute paths can only be derived from a master key, not child ones',
      );
    }
    Zip32Orchard derivedObject = this;

    for (final pathElement in pathInstance.elems) {
      derivedObject = derivedObject.childKey(pathElement, context: context);
    }
    return derivedObject;
  }

  /// Gets the current depth of this key.
  @override
  Bip32Depth get depth {
    return publicKey.keyData.depth;
  }

  /// Gets the current index of this key.
  Bip32KeyIndex get index {
    return publicKey.keyData.index;
  }

  /// Gets the chain code associated with this key.
  @override
  Bip32ChainCode get chainCode {
    return publicKey.keyData.chainCode;
  }

  /// Get public key fingerprint.
  @override
  Bip32FingerPrint get fingerPrint {
    return publicKey.keyData.fingerPrint;
  }
}
