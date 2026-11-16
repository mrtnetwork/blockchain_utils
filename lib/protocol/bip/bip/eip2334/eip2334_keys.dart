import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_keys.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Represents an EIP-2334 public key for a specific coin, mirrors
/// `Bip44PublicKey`. Verifies the key type matches the coin configuration.
///
/// Validator keys have no addresses: use the 48-byte public key bytes.
class Eip2334PublicKey {
  /// Private constructor for creating a [Eip2334PublicKey].
  Eip2334PublicKey._(this.pubKey, this.coinConf);

  /// The underlying EIP-2333 public node.
  final Eip2333PublicKey pubKey;

  /// The coin configuration associated with this public key.
  final Eip2334CoinConfig coinConf;

  /// Factory constructor to create a [Eip2334PublicKey] from a
  /// [Eip2333PublicKey] and a [Eip2334CoinConfig].
  factory Eip2334PublicKey(
    Eip2333PublicKey pubKey,
    Eip2334CoinConfig coinConf,
  ) {
    if (pubKey.type != coinConf.type) {
      throw CoreErrors.invalidOperationArguments(
        "Eip2334PublicKey",
        name: "pubKey",
        reason: "Invalid public key.",
      );
    }
    return Eip2334PublicKey._(pubKey, coinConf);
  }

  /// Retrieves the underlying public node.
  Eip2333PublicKey get key {
    return pubKey;
  }

  /// Generates an address for this public key. Always throws: BLS
  /// validator keys have no addresses (Hedera precedent).
  String get toAddress {
    return coinConf.encodeAddress(
      EncodeAddressDefaultParams(pubKey: toPublicKeyBytes()),
    );
  }

  BuBytes toPublicKeyBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) =>
      pubKey.toBytes(mode: mode);
}

/// Represents an EIP-2334 private key for a specific coin, mirrors
/// `Bip44PrivateKey`. Holds the 32-byte BLS scalar.
class Eip2334PrivateKey {
  /// Private constructor for creating a [Eip2334PrivateKey].
  Eip2334PrivateKey._(this.privKey, this.coinConf);

  /// The underlying EIP-2333 private node.
  final Eip2333PrivateKey privKey;

  /// The coin configuration associated with this private key.
  final Eip2334CoinConfig coinConf;

  /// Factory constructor to create a [Eip2334PrivateKey] from a
  /// [Eip2333PrivateKey] and a [Eip2334CoinConfig].
  factory Eip2334PrivateKey(
    Eip2333PrivateKey privKey,
    Eip2334CoinConfig coinConf,
  ) {
    if (privKey.type != coinConf.type) {
      throw CoreErrors.invalidOperationArguments(
        "Eip2334PrivateKey",
        name: "privKey",
        reason: "Invalid private key.",
      );
    }
    return Eip2334PrivateKey._(privKey, coinConf);
  }

  /// Retrieves the underlying private node.
  Eip2333PrivateKey get key {
    return privKey;
  }

  /// Gets the raw 32-byte scalar.
  SecretBytes toBytes({SecretTransform? transform}) {
    return privKey.toBytes(transform: transform);
  }

  /// Gets the corresponding public key derived from this private key.
  Eip2334PublicKey get publicKey {
    return Eip2334PublicKey(privKey.publicKey, coinConf);
  }
}
