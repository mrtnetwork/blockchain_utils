import 'package:blockchain_utils/bip/address/xmr_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_monero_keys.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/ed25519_utils.dart';
import 'package:blockchain_utils/bip/monero/conf/monero_coin_conf.dart';
import 'package:blockchain_utils/bip/monero/conf/monero_coins.dart';
import 'package:blockchain_utils/bip/monero/monero_exc.dart';
import 'package:blockchain_utils/bip/monero/monero_subaddr.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// A class representing Monero cryptocurrency and its associated keys and configurations.
class MoneroAccount {
  /// Private spend key (optional)
  final MoneroPrivateKey? privSkey;

  /// Private view key
  final MoneroPrivateKey privVkey;

  /// Public spend key
  final MoneroPublicKey pubSkey;

  /// Public view key
  final MoneroPublicKey pubVkey;

  /// Monero coin configuration
  final MoneroCoinConf coinConf;

  /// Monero subaddress
  final MoneroSubaddress scubaddr;

  /// Private constructor for creating a Monero instance.
  MoneroAccount.__(
      {required this.coinConf,
      required this.privSkey,
      required this.privVkey,
      required this.pubSkey,
      required this.pubVkey,
      required this.scubaddr});

  /// Factory method for creating a Monero instance based on provided keys.
  ///
  /// This factory constructor creates a Monero instance from private keys and an optional public key.
  /// It constructs the Monero configuration, private and public keys, and the associated subaddress.
  ///
  /// - [privKey]: The private key to be used for Monero.
  /// - [pubKey]: An optional public key for Monero (used in watch-only mode).
  /// - [coinType]: An optional parameter to specify the coin type (default: Monero mainnet).
  ///
  /// If no public key is provided (pubKey is null), it generates the public keys from the private keys.
  ///
  /// Returns a Monero instance configured with the provided keys and coin type.
  factory MoneroAccount._({
    required List<int> privKey,
    List<int>? pubKey,
    MoneroCoins coinType = MoneroCoins.moneroMainnet,
  }) {
    if (pubKey == null) {
      final mPrivSkey = MoneroPrivateKey.fromBytes(privKey);
      final mPrivVkey = _viewFromSpendKey(mPrivSkey);
      final mPubSkey = mPrivSkey.publicKey;
      final mPubVkey = mPrivVkey.publicKey;
      return MoneroAccount.__(
          coinConf: coinType.conf,
          privSkey: mPrivSkey,
          privVkey: mPrivVkey,
          pubSkey: mPubSkey,
          pubVkey: mPubVkey,
          scubaddr: MoneroSubaddress(mPrivVkey, mPubSkey, mPubVkey));
    }
    final mPrivVkey = MoneroPrivateKey.fromBytes(privKey);
    final mPubSkey = MoneroPublicKey.fromBytes(pubKey);
    final mPubVkey = mPrivVkey.publicKey;
    return MoneroAccount.__(
        coinConf: coinType.conf,
        privSkey: null,
        privVkey: mPrivVkey,
        pubSkey: mPubSkey,
        pubVkey: mPubVkey,
        scubaddr: MoneroSubaddress(mPrivVkey, mPubSkey, mPubVkey));
  }

  factory MoneroAccount.multisig(
      {required MoneroPrivateKey privVkey,
      required MoneroPublicKey pubSkey,
      required MoneroPrivateKey privSkey,
      MoneroCoins coinType = MoneroCoins.moneroMainnet}) {
    final mPubVkey = privVkey.publicKey;
    return MoneroAccount.__(
        coinConf: coinType.conf,
        privSkey: privSkey,
        privVkey: privVkey,
        pubSkey: pubSkey,
        pubVkey: mPubVkey,
        scubaddr: MoneroSubaddress(privVkey, pubSkey, mPubVkey));
  }

  /// Factory method to create a Monero instance from a seed.
  ///
  /// Given a [seedBytes] and an optional [coinType], this method constructs a Monero instance
  /// with the associated keys and configurations.
  factory MoneroAccount.fromSeed(List<int> seedBytes,
      {MoneroCoins coinType = MoneroCoins.moneroMainnet}) {
    final List<int> privSkeyBytes =
        seedBytes.length == Ed25519KeysConst.privKeyByteLen
            ? seedBytes
            : QuickCrypto.keccack256Hash(seedBytes);
    return MoneroAccount.fromPrivateSpendKey(
        Ed25519Utils.scalarReduce(privSkeyBytes),
        coinType: coinType);
  }

  /// Factory method to create a Monero instance from a BIP44 private key.
  ///
  /// Given a [privKey] and an optional [coinType], this method constructs a Monero instance
  /// with the associated keys and configurations.
  factory MoneroAccount.fromBip44PrivateKey(List<int> privKey,
      {MoneroCoins coinType = MoneroCoins.moneroMainnet}) {
    final key = MoneroPrivateKey.fromBip44(privKey);
    return MoneroAccount.fromPrivateSpendKey(key.key, coinType: coinType);
  }

  /// Factory method to create a Monero instance from a private spend key.
  ///
  /// Given a [privSkey] and an optional [coinType], this method constructs a Monero instance
  /// with the associated keys and configurations.
  factory MoneroAccount.fromPrivateSpendKey(List<int> privSkey,
      {MoneroCoins coinType = MoneroCoins.moneroMainnet}) {
    return MoneroAccount._(privKey: privSkey, coinType: coinType);
  }

  /// Factory method to create a Monero instance from watch-only keys.
  ///
  /// Given a [privVkey], [pubSkey], and an optional [coinType], this method constructs a
  /// Monero instance with the associated keys and configurations.
  factory MoneroAccount.fromWatchOnly(List<int> privVkey, List<int> pubSkey,
      {MoneroCoins coinType = MoneroCoins.moneroMainnet}) {
    return MoneroAccount._(
        privKey: privVkey, pubKey: pubSkey, coinType: coinType);
  }

  /// Check if the Monero instance is watch-only (has no private spend key).
  bool get isWatchOnly {
    return privSkey == null;
  }

  /// Get the private spend key of the Monero instance.
  MoneroPrivateKey get privateSpendKey {
    if (isWatchOnly) {
      throw const MoneroKeyError(
          'Watch-only class does not have a private spend key');
    }
    return privSkey!;
  }

  /// Get the private view key of the Monero instance.
  MoneroPrivateKey get privateViewKey {
    return privVkey;
  }

  /// Get the public spend key of the Monero instance.
  MoneroPublicKey get publicSpendKey {
    return pubSkey;
  }

  /// Get the public view key of the Monero instance.
  MoneroPublicKey get publicViewKey {
    return pubVkey;
  }

  /// Generate an integrated address by encoding the keys and payment ID.
  String integratedAddress(List<int> paymentId) {
    return XmrIntegratedAddrEncoder().encodeKey(pubSkey.compressed, {
      "pub_vkey": pubVkey.compressed,
      "net_ver": coinConf.intAddrNetVer,
      "payment_id": paymentId
    });
  }

  /// Get the primary address of the Monero instance.
  String get primaryAddress {
    return scubaddr.computeAndEncodeKeys(0, 0, coinConf.addrNetVer);
  }

  /// Get a subaddress based on minor and major indexes, or return the primary address if both are 0.
  String subaddress(int minorIndex, {int majorIndex = 0}) {
    if (minorIndex == 0 && majorIndex == 0) {
      return primaryAddress;
    }
    return scubaddr.computeAndEncodeKeys(
        minorIndex, majorIndex, coinConf.subaddrNetVer);
  }

  /// Calculate and return the private view key from the private spend key.
  static MoneroPrivateKey _viewFromSpendKey(MoneroPrivateKey privSkey) {
    final List<int> privVkeyBytes =
        Ed25519Utils.scalarReduce(QuickCrypto.keccack256Hash(privSkey.raw));
    return MoneroPrivateKey.fromBytes(privVkeyBytes);
  }
}
