import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65_key_derivator.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65_keys.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65_mst_key_generator.dart';
import 'package:blockchain_utils/protocol/hd_key/types.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// SLIP-10 hierarchical deterministic node for ML-DSA-65 (NEP-649).
///
/// Same public surface as `Bip32Base` (`fromSeed` / `fromNodeSecret` /
/// `fromPublicKey`, `childKey`, `derivePath`, `convertToPublic`, `dispose`)
/// and follows `HDKeyManager`: chain code is real SLIP-10 state carried in
/// `Bip32KeyData`, fingerprint stays zero (SLIP-10 defines none).
/// Only hardened secret derivation is supported.
class Slip10Mldsa65
    with SecretState
    implements
        HDKeyManager<
          Slip10MldsaPrivateKey,
          Slip10MldsaPublicKey,
          Bip32KeyIndex,
          Slip10Mldsa65
        > {
  Slip10MldsaPrivateKey? _privKey;
  @override
  late final Slip10MldsaPublicKey publicKey;

  /// Gets the private node of this key.
  @override
  Slip10MldsaPrivateKey get privateKey {
    final key = _privKey;
    if (isPublicOnly || key == null) {
      throw const BuError(
        DefaultErrorType.invalidKeyData,
        'Public-only deterministic keys have no private half',
      );
    }
    return key;
  }

  Slip10Mldsa65._({
    required Slip10MldsaPrivateKey? privKey,
    required Slip10MldsaPublicKey pubKey,
  }) {
    _privKey = privKey;
    publicKey = pubKey;
  }

  /// Creates a node from a BIP-39 seed (128 to 512 bits).
  Slip10Mldsa65.fromSeed(List<int> seedBytes) {
    seedBytes = seedBytes.asImmutableBytes;
    final result = masterKeyGenerator.generateFromSeed(seedBytes);
    final keyData = Bip32KeyData(chainCode: result.chainCode);
    _privKey = Slip10MldsaPrivateKey.fromBytes(result.key, keyData);
    publicKey = _privKey!.publicKey;
  }

  /// Creates a node from a 32-byte node secret.
  Slip10Mldsa65.fromNodeSecret(List<int> nodeSecret, [Bip32KeyData? keyData]) {
    nodeSecret = nodeSecret.asImmutableBytes;
    keyData ??= Bip32KeyData();
    _privKey = Slip10MldsaPrivateKey.fromBytes(nodeSecret, keyData);
    publicKey = _privKey!.publicKey;
  }

  /// Creates a watch-only node from a 1952-byte ML-DSA-65 public key.
  Slip10Mldsa65.fromPublicKey(List<int> pubKey, [Bip32KeyData? keyData]) {
    pubKey = pubKey.asImmutableBytes;
    keyData ??= Bip32KeyData();
    _privKey = null;
    publicKey = Slip10MldsaPublicKey.fromBytes(pubKey, keyData);
  }

  /// Derives a key along a path (e.g. `"m/44'/397'/0'"`).
  @override
  Slip10Mldsa65 derivePath(String path) {
    final pathInstance = Bip32PathParser.parse(path);
    if (depth.depth > 0 && pathInstance.isAbsolute) {
      throw CoreErrors.invalidOperationArguments(
        'derivePath',
        name: 'path',
        reason:
            'Absolute paths can only be derived from a master key, not child ones',
      );
    }
    Slip10Mldsa65 derivedObject = this;

    for (final pathElement in pathInstance.elems) {
      final parent = derivedObject;
      derivedObject = parent.childKey(pathElement);

      if (!identical(parent, this)) {
        parent.dispose();
      }
    }
    return derivedObject;
  }

  /// Derives a hardened child node from the current node.
  @override
  Slip10Mldsa65 childKey(Bip32KeyIndex index) {
    final isPublic = isPublicOnly;
    if (!isPublic) {
      if (!index.isHardened) {
        throw const BuError(
          DefaultErrorType.unsupported,
          'Private child derivation with not-hardened index is not supported',
        );
      }
      final result = keyDerivator.deriveFromSecret(
        parent: privateKey,
        ctx: publicKey,
        index: index,
      );
      final keyData = Bip32KeyData(
        chainCode: result.chainCode,
        depth: depth.increase(),
        index: index,
        fingerPrint: fingerPrint,
      );
      final childPriv = Slip10MldsaPrivateKey.fromBytes(result.key, keyData);
      return Slip10Mldsa65._(privKey: childPriv, pubKey: childPriv.publicKey);
    }
    throw const BuError(
      DefaultErrorType.unsupported,
      'Public child derivation is not supported',
    );
  }

  /// Converts this node to a public-only node.
  void convertToPublic({bool disposeKey = true}) {
    if (disposeKey) {
      _privKey?.dispose();
    }
    _privKey = null;
  }

  /// Checks if this node is public-only.
  bool get isPublicOnly => _privKey == null;

  /// Gets the current depth of this node.
  Bip32Depth get depth => publicKey.keyData.depth;

  /// Gets the current index of this node.
  Bip32KeyIndex get index => publicKey.keyData.index;

  /// Gets the chain code associated with this node.
  Bip32ChainCode get chainCode => publicKey.keyData.chainCode;

  /// Gets the fingerprint (always zero: SLIP-10 defines none).
  Bip32FingerPrint get fingerPrint => publicKey.keyData.fingerPrint;

  /// Checks if public derivation is supported for this node (never).
  bool get isPublicDerivationSupported =>
      keyDerivator.isPublicDerivationSupported();

  /// Gets the key type for this node.
  CryptoKeyType get type => CryptoKeyType.mldsa65;

  /// Gets the key derivator for this node.
  ISlip10Mldsa65ChildDerivator get keyDerivator =>
      const Slip10Mldsa65Derivator();

  /// Gets the master key generator for this node.
  ISlip10Mldsa65MstKeyGenerator get masterKeyGenerator =>
      const Slip10Mldsa65MstKeyGenerator();

  @override
  void dispose() {
    convertToPublic(disposeKey: true);
  }
}
