import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/base/eip2333_derivator.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_keys.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_path.dart';
import 'package:blockchain_utils/protocol/hd_key/types.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Abstract base for EIP-2333 keys, mirrors `Bip32Base`.
///
/// No chain code, no xpub/xpriv, no public derivation: every level
/// derives via the Lamport intermediate (`derive_child_SK`).
abstract class Eip2333Base<EIP extends Eip2333Base<EIP>>
    with SecretState
    implements
        HDKeyManager<
          Eip2333PrivateKey,
          Eip2333PublicKey,
          Eip2333KeyIndex,
          EIP
        > {
  Eip2333PrivateKey? _privKey;
  @override
  late final Eip2333PublicKey publicKey;

  @override
  Eip2333PrivateKey get privateKey {
    final key = _privKey;
    if (isPublicOnly || key == null) {
      throw const BuError(DefaultErrorType.invalidKeyData,
        'Public-only deterministic keys have no private half',
      );
    }
    return key;
  }

  Eip2333Base.fromSeed(List<int> seedBytes) {
    seedBytes = seedBytes.asImmutableBytes;
    final result = masterKeyGenerator.generateFromSeed(seedBytes);
    final keyData = Eip2333KeyData();
    _privKey = Eip2333PrivateKey(result.key.privKey, keyData);
    publicKey = _privKey!.publicKey;
  }

  Eip2333Base.fromPrivateKey(List<int> privKey, [Eip2333KeyData? keyData]) {
    privKey = privKey.asImmutableBytes;
    keyData ??= Eip2333KeyData();
    _privKey = Eip2333PrivateKey.fromBytes(privKey, keyData);
    publicKey = _privKey!.publicKey;
  }

  Eip2333Base.fromPublicKey(List<int> pubKey, [Eip2333KeyData? keyData]) {
    pubKey = pubKey.asImmutableBytes;
    keyData ??= Eip2333KeyData();
    _privKey = null;
    publicKey = Eip2333PublicKey.fromBytes(pubKey, keyData);
  }

  Eip2333Base({
    required Eip2333PrivateKey? privKey,
    required Eip2333PublicKey pubKey,
  }) {
    _privKey = privKey;
    publicKey = pubKey;
  }

  @override
  EIP derivePath(String path) {
    final pathInstance = Eip2333PathParser.parse(path);
    if (depth.depth > 0 && pathInstance.isAbsolute) {
      throw CoreErrors.invalidOperationArguments(
        'derivePath',
        name: 'path',
        reason:
            'Absolute paths can only be derived from a master key, not child ones',
      );
    }
    EIP derivedObject = this as EIP;
    for (final pathElement in pathInstance.elems) {
      final parent = derivedObject;
      derivedObject = parent.childKey(pathElement);

      if (!identical(parent, this)) {
        parent.dispose();
      }
    }
    return derivedObject;
  }

  @override
  EIP childKey(Eip2333KeyIndex index);

  void convertToPublic({bool disposeKey = true}) {
    if (disposeKey) {
      _privKey?.dispose();
    }
    _privKey = null;
  }

  bool get isPublicOnly => _privKey == null;

  Eip2333Depth get depth => publicKey.keyData.depth;
  Eip2333KeyIndex get index => publicKey.keyData.index;

  bool get isPublicDerivationSupported =>
      keyDerivator.isPublicDerivationSupported();

  CryptoKeyType get type;
  IEip2333ChildKeyDerivator get keyDerivator;
  IEip2333MstKeyGenerator get masterKeyGenerator;

  @override
  void dispose() {
    convertToPublic(disposeKey: true);
  }
}
