import 'package:blockchain_utils/bip/address/ada/ada_shelley_addr.dart';
import 'package:blockchain_utils/bip/address/encoder.dart';
import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/address/xmr_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/wif/wif.dart';
import 'package:blockchain_utils/exception/exception.dart';

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
  final CoinConfig coinConf;

  /// Factory constructor to create a [Bip44PublicKey] from a [Bip32PublicKey]
  /// and a [CoinConfig]. It verifies that the elliptic curve type of the public
  /// key matches the coin's configuration.
  factory Bip44PublicKey(Bip32PublicKey pubKey, CoinConfig coinConf) {
    if (pubKey.curveType != coinConf.type) {
      throw ArgumentException(
        'The public key elliptic curve (${pubKey.curveType}) shall match '
        'the coin configuration one (${coinConf.type})',
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
    return pubKey.chainCode;
  }

  /// Gets the compressed public key bytes.
  List<int> get compressed {
    return pubKey.compressed;
  }

  /// Gets the uncompressed public key bytes.
  List<int> get uncompressed {
    return pubKey.uncompressed;
  }

  /// Generates an address for this public key, using the provided [kwargs]
  /// for additional parameters. The exact encoding method depends on the
  /// coin configuration. An exception is thrown for special cases like Cardano
  /// Shelley or Monero, which require using specific classes to generate
  /// addresses.
  String get toAddress {
    BlockchainAddressEncoder encoder = coinConf.encoder();
    if (encoder is AdaShelleyAddrEncoder) {
      throw ArgumentException(
          'Use the CardanoShelley class to get Cardano Shelley addresses');
    }
    // Exception for Monero
    if (encoder is XmrAddrEncoder) {
      throw ArgumentException('Use the Monero class to get Monero addresses');
    }
    return encoder.encodeKey(
        pubKey.pubKey.compressed, coinConf.getParams(pubKey));
  }
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
  final CoinConfig coinConf;

  /// Factory constructor to create a [Bip44PrivateKey] from a [Bip32PrivateKey]
  /// and a [CoinConfig]. It verifies that the elliptic curve type of the private
  /// key matches the coin's configuration.
  factory Bip44PrivateKey(Bip32PrivateKey privKey, CoinConfig coinConf) {
    if (privKey.curveType != coinConf.type) {
      throw ArgumentException(
        'The private key elliptic curve (${privKey.curveType}) shall match the coin configuration one (${coinConf.type})',
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
    return privKey.chainCode;
  }

  /// Gets the raw private key bytes.
  List<int> get raw {
    return privKey.raw;
  }

  /// Gets the corresponding public key derived from this private key.
  Bip44PublicKey get publicKey {
    return Bip44PublicKey(privKey.publicKey, coinConf);
  }

  /// Converts the private key to Wallet Import Format (WIF) with the specified
  /// [pubKeyMode]. It uses the coin's configuration to determine the network
  /// version. If the network version is not available, an empty string is
  /// returned.
  String toWif({PubKeyModes pubKeyMode = PubKeyModes.compressed}) {
    final wifNetVer = coinConf.wifNetVer;

    return wifNetVer != null
        ? WifEncoder.encode(privKey.raw,
            netVer: wifNetVer, pubKeyMode: pubKeyMode)
        : '';
  }
}
