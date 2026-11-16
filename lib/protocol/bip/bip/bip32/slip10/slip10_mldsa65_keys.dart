import 'package:blockchain_utils/crypto/crypto/keys/ml_dsa/keys/keys.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/hd_key/types.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Key constants for SLIP-10 ML-DSA-65, mirrors `Bls12KeyConst`.
class Slip10Mldsa65KeyConst {
  /// Node secret (`xi` seed for FIPS 204 KeyGen) length in bytes.
  static const int nodeSecretByteLen = 32;
}

/// SLIP-10 ML-DSA-65 private node: the 32-byte node secret.
///
/// Unlike elliptic-curve SLIP-10 nodes, the node secret is NOT the expanded
/// secret key — it is the seed `xi` for FIPS 204 `KeyGen_internal`. The
/// expanded 4032-byte secret key is intentionally not recoverable from (and
/// never stored in) the node, so children always derive from this secret.
/// Mirrors `Bip32PrivateKey`.
class Slip10MldsaPrivateKey extends CryptoKeyBase<Bip32KeyData>
    with SecretState {
  final SecretBytes nodeSecret;

  Slip10MldsaPrivateKey._(this.nodeSecret, super.keyData);

  /// Creates a node from a 32-byte node secret, mirrors
  /// `Bip32PrivateKey.fromBytes`.
  factory Slip10MldsaPrivateKey.fromBytes(
    List<int> nodeSecret,
    Bip32KeyData keyData,
  ) {
    if (nodeSecret.length != Slip10Mldsa65KeyConst.nodeSecretByteLen) {
      throw CoreErrors.invalidOperationArguments(
        'Slip10MldsaPrivateKey',
        name: 'nodeSecret',
        reason: 'Invalid node secret bytes length.',
      );
    }
    return Slip10MldsaPrivateKey._(SecretBytes(nodeSecret), keyData);
  }

  CryptoKeyType get type => CryptoKeyType.mldsa65;

  /// Raw 32-byte node secret (clone), mirrors `Bip32PrivateKey.toBytes`.
  SecretBytes toBytes({SecretTransform? transform}) {
    return nodeSecret.cloneBytes(transform: transform);
  }

  /// Expands this node into the full ML-DSA-65 key pair via FIPS 204
  /// `KeyGen_internal(xi)`, mirrors `Bip32PrivateKey.publicKey`.
  MLDSA65PrivateKey keyPair() {
    return toBytes().useValue(
      (s) => MLDSA65PrivateKey.generate(seed: s),
      zero: true,
    );
  }

  /// Corresponding public node, mirrors `Bip32PrivateKey.publicKey`.
  Slip10MldsaPublicKey get publicKey {
    final kp = keyPair();
    try {
      return Slip10MldsaPublicKey(kp.verificationKey(), keyData);
    } finally {
      kp.dispose();
    }
  }

  @override
  void dispose() {
    nodeSecret.zero();
  }
}

/// SLIP-10 ML-DSA-65 public node (1952-byte key), mirrors `Bip32PublicKey`.
///
/// Import/watch-only holder: ML-DSA has no public derivation, so nodes
/// built from a public key cannot derive children.
class Slip10MldsaPublicKey extends CryptoKeyBase<Bip32KeyData> {
  final MLDSA65PublicKey pubKey;

  Slip10MldsaPublicKey(this.pubKey, super.keyData);

  CryptoKeyType get type => CryptoKeyType.mldsa65;

  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return pubKey.toBytes(mode: mode);
  }

  /// Creates a node from a 1952-byte ML-DSA-65 public key.
  static Slip10MldsaPublicKey fromBytes(
    List<int> keyBytes,
    Bip32KeyData keyData,
  ) {
    return Slip10MldsaPublicKey(MLDSA65PublicKey.fromBytes(keyBytes), keyData);
  }
}
