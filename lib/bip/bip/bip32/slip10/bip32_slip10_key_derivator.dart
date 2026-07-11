import 'package:blockchain_utils/bip/bip/bip32/bip32_ex.dart';
import 'package:blockchain_utils/crypto/crypto/ec/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/secp256k1/secp256k1.dart';

import 'package:blockchain_utils/bip/bip/bip32/base/derivator.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_getter.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

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

  BigInt _addScalar({
    required List<int> privKeyBytes,
    required List<int> newScalar,
    required EllipticCurveTypes type,
  }) {
    switch (type) {
      case EllipticCurveTypes.secp256k1:
        Secp256k1Scalar privKeyScalar = Secp256k1Scalar();
        Secp256k1.secp256k1ScalarSetB32(privKeyScalar, privKeyBytes);
        Secp256k1Scalar newSc = Secp256k1Scalar();
        Secp256k1.secp256k1ScalarSetB32(newSc, newScalar);
        Secp256k1Scalar result = Secp256k1Scalar();
        Secp256k1.secp256k1ScalarAdd(result, privKeyScalar, newSc);
        final scBytes = List<int>.filled(32, 0);
        Secp256k1.secp256k1ScalarGetB32(scBytes, result);
        final nd = BigintUtils.fromBytes(scBytes);
        return nd;
      case EllipticCurveTypes.nist256p1Hybrid:
      case EllipticCurveTypes.nist256p1:
        final ilInt = BigintUtils.fromBytes(newScalar);
        final privKeyInt = BigintUtils.fromBytes(privKeyBytes);
        return (ilInt + privKeyInt) % Curves.generator256.order!;
      default:
        throw const Bip32KeyError("Unknow curve.");
    }
  }

  @override
  Bip32ChildKey deriveFromPublic({
    required Bip32PublicKey parent,
    required Bip32KeyIndex index,
    EllipticCurveTypes? type,
  }) {
    type ??= parent.curveType;
    final dataBytes = [...parent.compressed, ...index.toBytes()];
    final hmacHalves = QuickCrypto.hmacSha512HashHalves(
      parent.keyData.chainCode.toBytes(),
      dataBytes,
    );

    final ilBytes = hmacHalves.$1;
    final irBytes = hmacHalves.$2;
    final ilInt = BigintUtils.fromBytes(ilBytes);
    final generator = EllipticCurveGetter.generatorFromType(type);

    final newPubKeyPoint = parent.point + (generator * ilInt);
    return Bip32ChildKey(
      key: newPubKeyPoint.toBytes(),
      chainCode: Bip32ChainCode(irBytes),
    );
  }

  @override
  Bip32ChildKey deriveFromSecret({
    required Bip32PrivateKey parent,
    required Bip32PublicKey ctx,
    required Bip32KeyIndex index,
    EllipticCurveTypes? type,
  }) {
    type ??= parent.curveType;
    final privKeyBytes = parent.raw;
    List<int> dataBytes;
    if (index.isHardened) {
      dataBytes = [
        ...Bip32Slip10DerivatorConst.priveKeyPrefix,
        ...privKeyBytes,
        ...index.toBytes(),
      ];
    } else {
      dataBytes = [...ctx.compressed, ...index.toBytes()];
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
      type: type,
    );
    final newPrivKeyBytes = scalar.toBeBytes(length: parent.privKey.length);
    return Bip32ChildKey(
      key: newPrivKeyBytes,
      chainCode: Bip32ChainCode(irBytes),
    );
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
    EllipticCurveTypes? type,
  }) {
    throw Bip32KeyError.publicDerivationNotSupported;
  }

  @override
  Bip32ChildKey deriveFromSecret({
    required Bip32PrivateKey parent,
    required Bip32PublicKey ctx,
    required Bip32KeyIndex index,
    EllipticCurveTypes? type,
  }) {
    final dataBytes = [
      ...Bip32Slip10DerivatorConst.priveKeyPrefix,
      ...parent.raw,
      ...index.toBytes(),
    ];
    final newKey = QuickCrypto.hmacSha512HashHalves(
      parent.keyData.chainCode.toBytes(),
      dataBytes,
    );
    return Bip32ChildKey(key: newKey.$1, chainCode: Bip32ChainCode(newKey.$2));
  }
}
