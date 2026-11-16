import 'package:blockchain_utils/crypto/crypto/keys/ml_dsa/keys/keys.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65_keys.dart';
import 'package:blockchain_utils/protocol/bip/bip/nep649/nep649_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Represents a NEP-649 public key for a specific coin, mirrors
/// `Bip44PublicKey`. Verifies the key type matches the coin configuration.
class Nep649PublicKey {
  /// Private constructor for creating a [Nep649PublicKey].
  Nep649PublicKey._(this.pubKey, this.coinConf);

  /// The underlying SLIP-10 ML-DSA-65 public node.
  final Slip10MldsaPublicKey pubKey;

  /// The coin configuration associated with this public key.
  final Nep649CoinConfig coinConf;

  /// Factory constructor to create a [Nep649PublicKey] from a
  /// [Slip10MldsaPublicKey] and a [Nep649CoinConfig].
  factory Nep649PublicKey(
    Slip10MldsaPublicKey pubKey,
    Nep649CoinConfig coinConf,
  ) {
    if (pubKey.type != coinConf.type) {
      throw CoreErrors.invalidOperationArguments(
        "Nep649PublicKey",
        name: "pubKey",
        reason: "Invalid public key.",
      );
    }
    return Nep649PublicKey._(pubKey, coinConf);
  }

  /// Retrieves the underlying public node.
  Slip10MldsaPublicKey get key {
    return pubKey;
  }

  /// Gets the chain code associated with the public key.
  Bip32ChainCode get chainCode {
    return pubKey.keyData.chainCode;
  }

  /// Generates an address for this public key (e.g. `ml-dsa-65:...`).
  String get toAddress {
    return coinConf.encodeAddress(
      EncodeAddressDefaultParams(
        pubKey: toPublicKeyBytes(),
        chainCode: pubKey.keyData.chainCode.toBytes(),
      ),
    );
  }

  BuBytes toPublicKeyBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) =>
      pubKey.toBytes(mode: mode);
}

/// Represents a NEP-649 private key for a specific coin, mirrors
/// `Bip44PrivateKey`. Holds the 32-byte node secret (FIPS 204 seed).
class Nep649PrivateKey {
  /// Private constructor for creating a [Nep649PrivateKey].
  Nep649PrivateKey._(this.privKey, this.coinConf);

  /// The underlying SLIP-10 ML-DSA-65 private node.
  final Slip10MldsaPrivateKey privKey;

  /// The coin configuration associated with this private key.
  final Nep649CoinConfig coinConf;

  /// Factory constructor to create a [Nep649PrivateKey] from a
  /// [Slip10MldsaPrivateKey] and a [Nep649CoinConfig].
  factory Nep649PrivateKey(
    Slip10MldsaPrivateKey privKey,
    Nep649CoinConfig coinConf,
  ) {
    if (privKey.type != coinConf.type) {
      throw CoreErrors.invalidOperationArguments(
        "Nep649PrivateKey",
        name: "privKey",
        reason: "Invalid private key.",
      );
    }
    return Nep649PrivateKey._(privKey, coinConf);
  }

  /// Retrieves the underlying private node.
  Slip10MldsaPrivateKey get key {
    return privKey;
  }

  /// Gets the chain code associated with the private key.
  Bip32ChainCode get chainCode {
    return privKey.keyData.chainCode;
  }

  /// Gets the raw 32-byte node secret.
  SecretBytes toBytes({SecretTransform? transform}) {
    return privKey.toBytes(transform: transform);
  }

  /// Expands this node into the full ML-DSA-65 key pair.
  MLDSA65PrivateKey get keyPair {
    return privKey.keyPair();
  }

  /// Gets the corresponding public key derived from this private key.
  Nep649PublicKey get publicKey {
    return Nep649PublicKey(privKey.publicKey, coinConf);
  }
}
