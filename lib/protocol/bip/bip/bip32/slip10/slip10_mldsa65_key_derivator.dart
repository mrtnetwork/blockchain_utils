import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65_keys.dart';
import 'package:blockchain_utils/protocol/hd_key/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Derived child node DTO, mirrors `Bip32ChildKey`.
class Slip10Mldsa65ChildKey implements IChildKey {
  /// secret node secret (32 bytes)
  final SecretBytes key;

  /// chain code
  final Bip32ChainCode chainCode;
  Slip10Mldsa65ChildKey({required List<int> key, required this.chainCode})
    : key = SecretBytes(key);
}

/// Derived master node DTO, mirrors `Bip32MasterKey`.
class Slip10Mldsa65MasterKey implements IMasterKey {
  /// master node secret (32 bytes)
  final SecretBytes key;

  /// chain code
  final Bip32ChainCode chainCode;
  Slip10Mldsa65MasterKey({required List<int> key, required this.chainCode})
    : key = SecretBytes(key);
}

/// Child derivator interface, mirrors `IBip32ChildKeyDerivator`.
///
/// Only hardened secret derivation exists (NEP-649): ML-DSA public keys are
/// rounded/lossy, so no public-derivation analog exists.
abstract class ISlip10Mldsa65ChildDerivator
    implements
        IChildKeyDerivator<
          Slip10Mldsa65ChildKey,
          Slip10MldsaPrivateKey,
          Slip10MldsaPublicKey,
          Bip32KeyIndex
        > {
  @override
  Slip10Mldsa65ChildKey deriveFromSecret({
    required Slip10MldsaPrivateKey parent,
    required Slip10MldsaPublicKey ctx,
    required Bip32KeyIndex index,
  });

  @override
  Slip10Mldsa65ChildKey deriveFromPublic({
    required Slip10MldsaPublicKey parent,
    required Bip32KeyIndex index,
  });
}

/// Master generator interface, mirrors `IBip32MstKeyGenerator`.
abstract class ISlip10Mldsa65MstKeyGenerator
    implements IMasterKeyKeyGenerator<Slip10Mldsa65MasterKey> {
  @override
  Slip10Mldsa65MasterKey generateFromSeed(List<int> seedBytes);
}

/// SLIP-10 ML-DSA-65 child key derivator, mirrors
/// `Bip32Slip10Ed25519Derivator` (hardened-only, secret-only).
class Slip10Mldsa65Derivator implements ISlip10Mldsa65ChildDerivator {
  const Slip10Mldsa65Derivator();

  @override
  bool isPublicDerivationSupported() => false;

  @override
  Slip10Mldsa65ChildKey deriveFromPublic({
    required Slip10MldsaPublicKey parent,
    required Bip32KeyIndex index,
  }) {
    throw const BuError(DefaultErrorType.unsupported, 'Public child derivation is not supported');
  }

  @override
  Slip10Mldsa65ChildKey deriveFromSecret({
    required Slip10MldsaPrivateKey parent,
    required Slip10MldsaPublicKey ctx,
    required Bip32KeyIndex index,
  }) {
    return parent.toBytes().useValue((k) {
      // 0x00 pads the 32-byte node secret to 33 bytes (SLIP-10).
      // index.toBytes() defaults to big-endian = ser32(i).
      final dataBytes = [0x00, ...k, ...index.toBytes()];
      final newKey = QuickCrypto.hmacSha512HashHalves(
        parent.keyData.chainCode.toBytes(),
        dataBytes,
      );
      return Slip10Mldsa65ChildKey(
        key: newKey.$1,
        chainCode: Bip32ChainCode(newKey.$2),
      );
    }, zero: true);
  }
}
