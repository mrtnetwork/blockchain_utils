import 'package:blockchain_utils/bip/bip/bip32/bip32.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/exception/exception.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/derivator.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/keys.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';

class Zip32Sapling
    implements
        Zip32Base<
          SaplingExtendedSpendingKey,
          SaplingExtendedFullViewKey,
          Bip32KeyIndex,
          SaplingZip32ChildKeyDerivator,
          SaplingZip32MasterKeyGenerator,
          Zip32Sapling
        > {
  Zip32Sapling({
    SaplingExtendedSpendingKey? privateKey,
    required this.publicKey,
  }) : _privateKey = privateKey;
  SaplingExtendedSpendingKey? _privateKey;

  @override
  SaplingExtendedSpendingKey get privateKey {
    final prvKey = _privateKey;
    if (prvKey == null) {
      throw const Zip32Error(
        'Public-only deterministic keys have no private half',
      );
    }
    return prvKey;
  }

  @override
  final SaplingExtendedFullViewKey publicKey;

  factory Zip32Sapling.fromSeed(List<int> seedBytes) {
    final generator = SaplingZip32MasterKeyGenerator();
    final masterKey = generator.generateFromSeed(seedBytes);
    final extendedKey = generator.deriveExtendedKey(masterKey);
    return Zip32Sapling(
      privateKey: extendedKey,
      publicKey: extendedKey.toExtendedFvk(),
    );
  }

  factory Zip32Sapling.fromSpendKey(List<int> sk) {
    sk = sk.exc(
      operation: "Zip32Sapling",
      name: "sk",
      reason: "Invalid secret key bytes length.",
      length: 32,
    );
    final generator = SaplingZip32MasterKeyGenerator();
    final extendedKey = generator.deriveExtendedKey(
      Bip32MasterKey(key: sk, chainCode: Bip32ChainCode()),
    );
    return Zip32Sapling(
      privateKey: extendedKey,
      publicKey: extendedKey.toExtendedFvk(),
    );
  }
  factory Zip32Sapling.fromExtendedSpendingKeyBytes(List<int> bytes) {
    final prvKey = SaplingExtendedSpendingKey.fromBytes(bytes);
    return Zip32Sapling(privateKey: prvKey, publicKey: prvKey.toExtendedFvk());
  }
  factory Zip32Sapling.fromExtendedFullViewKey(List<int> bytes) {
    final fvk = SaplingExtendedFullViewKey.fromBytes(bytes);
    return Zip32Sapling(privateKey: null, publicKey: fvk);
  }
  @override
  Zip32Sapling childKey(Bip32KeyIndex index, ZCryptoContext context) {
    final extendedKey = keyDerivator.deriveExpandedSpendingKey(
      parent: privateKey,
      index: index,
    );
    return Zip32Sapling(
      privateKey: extendedKey,
      publicKey: extendedKey.toExtendedFvk(),
    );
  }

  @override
  SaplingZip32ChildKeyDerivator get keyDerivator =>
      SaplingZip32ChildKeyDerivator();

  @override
  SaplingZip32MasterKeyGenerator get masterKeyGenerator =>
      SaplingZip32MasterKeyGenerator();

  @override
  Zip32Sapling derivePath(String path, ZCryptoContext context) {
    final pathInstance = Bip32PathParser.parse(path);

    if (depth.depth > 0 && pathInstance.isAbsolute) {
      throw ArgumentException.invalidOperationArguments(
        "derivePath",
        name: "path",
        reason:
            'Absolute paths can only be derived from a master key, not child ones',
      );
    }
    Zip32Sapling derivedObject = this;

    for (final pathElement in pathInstance.elems) {
      derivedObject = derivedObject.childKey(pathElement, context);
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
