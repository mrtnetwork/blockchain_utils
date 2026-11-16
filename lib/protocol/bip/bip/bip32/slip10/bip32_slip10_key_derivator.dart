import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to the Bip32 Slip10 Derivator.
class Bip32Slip10DerivatorConst {
  /// Prefix for private key derivation in Slip10.
  static const List<int> priveKeyPrefix = [0x00];
}

class Bip32Slip10EcdsaDerivator implements IBip32ChildKeyDerivator {
  /// check if support public key derivation
  @override
  bool isPublicDerivationSupported() {
    return true;
  }

  List<int> _addScalar({
    required List<int> privKeyBytes,
    required List<int> newScalar,
    required CryptoKeyType type,
  }) {
    switch (type) {
      case CryptoKeyType.secp256k1:
        return blockchainUtils.api.secp256k1.scAdd(privKeyBytes, newScalar);
      case CryptoKeyType.nist256p1Hybrid:
      case CryptoKeyType.nist256p1:
        return blockchainUtils.api.secp256r1.scAdd(privKeyBytes, newScalar);
      default:
        throw const BuError(DefaultErrorType.invalidKeyData,"Unknow curve.");
    }
  }

  @override
  Bip32ChildKey deriveFromPublic({
    required Bip32PublicKey parent,
    required Bip32KeyIndex index,
    CryptoKeyType? type,
  }) {
    type ??= parent.type;
    final dataBytes = [...parent.toPublicKeyBytes(), ...index.toBytes()];
    final hmacHalves = QuickCrypto.hmacSha512HashHalves(
      parent.keyData.chainCode.toBytes(),
      dataBytes,
    );
    final ilBytes = hmacHalves.$1;
    final irBytes = hmacHalves.$2;
    switch (type) {
      case CryptoKeyType.secp256k1:
        final tweakPoint = blockchainUtils.api.secp256k1.multBase(ilBytes);
        final newPubKeyBytes = blockchainUtils.api.secp256k1.add(
          parent.key.toBytes(),
          tweakPoint,
        ); // parent.point + tweakPoint

        return Bip32ChildKey(
          key: newPubKeyBytes,
          chainCode: Bip32ChainCode(irBytes),
        );
      case CryptoKeyType.nist256p1Hybrid:
      case CryptoKeyType.nist256p1:
        final tweakPoint = blockchainUtils.api.secp256r1.multBase(ilBytes);
        final newPubKeyBytes = blockchainUtils.api.secp256r1.add(
          parent.key.toBytes(),
          tweakPoint,
        ); // parent.point + tweakPoint

        return Bip32ChildKey(
          key: newPubKeyBytes,
          chainCode: Bip32ChainCode(irBytes),
        );
      default:
        throw BuError(DefaultErrorType.unsupported,"Unsupported Slip10 Ecdsa key type.");
    }
  }

  @override
  Bip32ChildKey deriveFromSecret({
    required Bip32PrivateKey parent,
    required Bip32PublicKey ctx,
    required Bip32KeyIndex index,
    CryptoKeyType? type,
  }) {
    switch (type) {
      case CryptoKeyType.secp256k1:
      case CryptoKeyType.nist256p1Hybrid:
      case CryptoKeyType.nist256p1:
        break;
      default:
        throw BuError(DefaultErrorType.unsupported,"Unsupported Slip10 Ecdsa key type.");
    }
    // final privKeyBytes = parent.raw;
    return parent.toBytes().useValue((privKeyBytes) {
      List<int> dataBytes;
      if (index.isHardened) {
        dataBytes = [
          ...Bip32Slip10DerivatorConst.priveKeyPrefix,
          ...privKeyBytes,
          ...index.toBytes(),
        ];
      } else {
        dataBytes = [...ctx.toPublicKeyBytes(), ...index.toBytes()];
      }
      final hmacHalves = QuickCrypto.hmacSha512HashHalves(
        parent.keyData.chainCode.toBytes(),
        dataBytes,
      );

      final ilBytes = hmacHalves.$1;
      final irBytes = hmacHalves.$2;
      final scalar = _addScalar(
        privKeyBytes: privKeyBytes,
        newScalar: ilBytes,
        type: type ?? parent.type,
      );
      return Bip32ChildKey(key: scalar, chainCode: Bip32ChainCode(irBytes));
    }, zero: true);
  }
}

/// A class that implements the `IBip32KeyDerivator` interface for Bip32 Slip10
/// derivation using the Ed25519 elliptic curve.
class Bip32Slip10Ed25519Derivator implements IBip32ChildKeyDerivator {
  /// check if support public key derivation
  @override
  bool isPublicDerivationSupported() {
    return false;
  }

  @override
  Bip32ChildKey deriveFromPublic({
    required Bip32PublicKey parent,
    required Bip32KeyIndex index,
    CryptoKeyType? type,
  }) {
    throw const BuError(DefaultErrorType.unsupported, 'Public child derivation is not supported');
  }

  @override
  Bip32ChildKey deriveFromSecret({
    required Bip32PrivateKey parent,
    required Bip32PublicKey ctx,
    required Bip32KeyIndex index,
    CryptoKeyType? type,
  }) {
    return parent.toBytes().useValue((k) {
      final dataBytes = [
        ...Bip32Slip10DerivatorConst.priveKeyPrefix,
        ...k,
        ...index.toBytes(),
      ];
      final newKey = QuickCrypto.hmacSha512HashHalves(
        parent.keyData.chainCode.toBytes(),
        dataBytes,
      );
      return Bip32ChildKey(
        key: newKey.$1,
        chainCode: Bip32ChainCode(newKey.$2),
      );
    }, zero: true);
  }
}
