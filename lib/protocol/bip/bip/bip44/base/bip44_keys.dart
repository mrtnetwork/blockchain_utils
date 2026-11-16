import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/bip_config.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/wif/wif.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Represents a BIP44 public key for a specific cryptocurrency coin. This class
/// ensures that the elliptic curve type of the public key matches the coin's
/// configuration, and provides various utility methods for working with the
/// public key.
class Bip44PublicKey {
  /// Private constructor for creating a [Bip44PublicKey].
  Bip44PublicKey._(this.pubKey, this.coinConf);

  /// The underlying BIP32 public key.
  final Bip32PublicKey pubKey;

  /// The coin configuration associated with this public key.
  final BaseBipCoinConfig coinConf;

  /// Factory constructor to create a [Bip44PublicKey] from a [Bip32PublicKey]
  /// and a [BaseBipCoinConfig]. It verifies that the elliptic curve type of the public
  /// key matches the coin's configuration.
  factory Bip44PublicKey(Bip32PublicKey pubKey, BaseBipCoinConfig coinConf) {
    if (pubKey.type != coinConf.type) {
      throw CoreErrors.invalidOperationArguments(
        "Bip44PublicKey",
        name: "pubKey",
        reason: "Invalid public key.",
      );
    }
    return Bip44PublicKey._(pubKey, coinConf);
  }

  /// Retrieves the underlying BIP32 public key.
  Bip32PublicKey get key {
    return pubKey;
  }

  /// Gets the extended public key representation.
  String get toExtended {
    return pubKey.toExtended;
  }

  /// Gets the chain code associated with the public key.
  Bip32ChainCode get chainCode {
    return pubKey.keyData.chainCode;
  }

  /// Generates an address for this public key, using the provided [kwargs]
  /// for additional parameters. The exact encoding method depends on the
  /// coin configuration. An exception is thrown for special cases like Cardano
  /// Shelley or Monero, which require using specific classes to generate
  /// addresses.
  String get toAddress {
    return coinConf.encodeAddress(
      EncodeAddressDefaultParams(
        pubKey: toPublicKeyBytes(),
        chainCode: pubKey.keyData.chainCode.toBytes(),
      ),
    );
  }

  BuBytes toPublicKeyBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) =>
      pubKey.toPublicKeyBytes(mode: mode);
}

/// Represents a BIP44 private key for a specific cryptocurrency coin. This class
/// ensures that the elliptic curve type of the private key matches the coin's
/// configuration, and provides various utility methods for working with the
/// private key.
class Bip44PrivateKey {
  /// Private constructor for creating a [Bip44PrivateKey].
  Bip44PrivateKey._(this.privKey, this.coinConf);

  /// The underlying BIP32 private key.
  final Bip32PrivateKey privKey;

  /// The coin configuration associated with this private key.
  final BaseBipCoinConfig coinConf;

  /// Factory constructor to create a [Bip44PrivateKey] from a [Bip32PrivateKey]
  /// and a [BaseBipCoinConfig]. It verifies that the elliptic curve type of the private
  /// key matches the coin's configuration.
  factory Bip44PrivateKey(Bip32PrivateKey privKey, BaseBipCoinConfig coinConf) {
    if (privKey.type != coinConf.type) {
      throw CoreErrors.invalidOperationArguments(
        "Bip44PrivateKey",
        name: "privKey",
        reason: "Invalid private key.",
      );
    }
    return Bip44PrivateKey._(privKey, coinConf);
  }

  /// Retrieves the underlying BIP32 private key.
  Bip32PrivateKey get key {
    return privKey;
  }

  /// Gets the extended private key representation.
  String get toExtended {
    return privKey.toExtended;
  }

  /// Gets the chain code associated with the private key.
  Bip32ChainCode get chainCode {
    return privKey.keyData.chainCode;
  }

  /// Gets the raw private key bytes.
  SecretBytes toBytes({SecretTransform? transform}) {
    return privKey.toBytes(transform: transform);
  }

  /// Gets the corresponding public key derived from this private key.
  Bip44PublicKey get publicKey {
    return Bip44PublicKey(privKey.publicKey, coinConf);
  }

  /// Converts the private key to Wallet Import Format (WIF) with the specified
  /// [pubKeyMode]. It uses the coin's configuration to determine the network
  /// version. If the network version is not available, an empty string is
  /// returned.
  String toWif({CryptoKeyEncoding pubKeyMode = CryptoKeyEncoding.base}) {
    final wifNetVer = coinConf.wifNetVer;
    if (wifNetVer == null) {
      throw BuError(DefaultErrorType.invalidArgument,"Missing coin wif confing.");
    }

    return privKey.toBytes().useValue(
      (k) => WifEncoder.encode(k, netVer: wifNetVer, pubKeyMode: pubKeyMode),
      zero: true,
    );
  }
}
