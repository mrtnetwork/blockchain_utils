import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/chain/address/neworks/others/xmr_addr.dart';
import 'package:blockchain_utils/protocol/bip/monero/conf/monero_coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/monero/conf/monero_coins.dart';
import 'package:blockchain_utils/protocol/bip/monero/monero_subaddr.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing Monero cryptocurrency and its associated keys and configurations.
class MoneroAccount with SecretState {
  /// Private spend key (optional)
  final ED25519MoneroPrivateKey? privSkey;

  /// Private view key
  final ED25519MoneroPrivateKey privVkey;

  /// Public spend key
  final ED25519MoneroPublicKey pubSkey;

  /// Public view key
  final ED25519MoneroPublicKey pubVkey;

  /// Monero coin configuration
  final MoneroCoinConf coinConf;

  /// Monero subaddress
  final MoneroSubaddress scubaddr;

  /// Private constructor for creating a Monero instance.
  MoneroAccount.__({
    required this.coinConf,
    required this.privSkey,
    required this.privVkey,
    required this.pubSkey,
    required this.pubVkey,
    required this.scubaddr,
  });

  /// Factory method for creating a Monero instance based on provided keys.
  ///
  /// - [privKey]: The private key to be used for Monero.
  /// - [pubKey]: An optional public key for Monero (used in watch-only mode).
  /// - [coinType]: An optional parameter to specify the coin type (default: Monero mainnet).
  ///
  factory MoneroAccount._({
    required List<int> privKey,
    List<int>? pubKey,
    MoneroCoins coinType = MoneroCoins.moneroMainnet,
  }) {
    if (pubKey == null) {
      final mPrivSkey = ED25519MoneroPrivateKey.fromBytes(privKey);
      final mPrivVkey = _viewFromSpendKey(mPrivSkey);
      final mPubSkey = mPrivSkey.publicKey;
      final mPubVkey = mPrivVkey.publicKey;
      return MoneroAccount.__(
        coinConf: coinType.conf,
        privSkey: mPrivSkey,
        privVkey: mPrivVkey,
        pubSkey: mPubSkey,
        pubVkey: mPubVkey,
        scubaddr: MoneroSubaddress(mPrivVkey, mPubSkey, mPubVkey),
      );
    }
    final mPrivVkey = ED25519MoneroPrivateKey.fromBytes(privKey);
    final mPubSkey = ED25519MoneroPublicKey.fromBytes(pubKey);
    final mPubVkey = mPrivVkey.publicKey;
    return MoneroAccount.__(
      coinConf: coinType.conf,
      privSkey: null,
      privVkey: mPrivVkey,
      pubSkey: mPubSkey,
      pubVkey: mPubVkey,
      scubaddr: MoneroSubaddress(mPrivVkey, mPubSkey, mPubVkey),
    );
  }

  factory MoneroAccount.multisig({
    required ED25519MoneroPrivateKey privVkey,
    required ED25519MoneroPublicKey pubSkey,
    required ED25519MoneroPrivateKey privSkey,
    MoneroCoins coinType = MoneroCoins.moneroMainnet,
  }) {
    final mPubVkey = privVkey.publicKey;
    return MoneroAccount.__(
      coinConf: coinType.conf,
      privSkey: privSkey,
      privVkey: privVkey,
      pubSkey: pubSkey,
      pubVkey: mPubVkey,
      scubaddr: MoneroSubaddress(privVkey, pubSkey, mPubVkey),
    );
  }

  /// Factory method to create a Monero instance from a seed.
  ///
  /// Given a [seedBytes] and an optional [coinType], this method constructs a Monero instance
  /// with the associated keys and configurations.
  factory MoneroAccount.fromSeed(
    List<int> seedBytes, {
    MoneroCoins coinType = MoneroCoins.moneroMainnet,
  }) {
    final List<int> privSkeyBytes =
        seedBytes.length == Ed25519KeysConst.privKeyByteLen
            ? seedBytes
            : QuickCrypto.keccak256Hash(seedBytes);
    return MoneroAccount.fromPrivateSpendKey(
      blockchainUtils.api.ed25519.scReduce(privSkeyBytes),
      coinType: coinType,
    );
  }

  /// Factory method to create a Monero instance from a BIP44 private key.
  ///
  /// Given a [privKey] and an optional [coinType], this method constructs a Monero instance
  /// with the associated keys and configurations.
  factory MoneroAccount.fromBip44PrivateKey(
    List<int> privKey, {
    MoneroCoins coinType = MoneroCoins.moneroMainnet,
  }) {
    final key = ED25519MoneroPrivateKey.fromBip44(privKey);
    return key.toBytes().useValue(
      (k) => MoneroAccount.fromPrivateSpendKey(k, coinType: coinType),
      zero: true,
    );
  }

  /// Factory method to create a Monero instance from a private spend key.
  ///
  /// Given a [privSkey] and an optional [coinType], this method constructs a Monero instance
  /// with the associated keys and configurations.
  factory MoneroAccount.fromPrivateSpendKey(
    List<int> privSkey, {
    MoneroCoins coinType = MoneroCoins.moneroMainnet,
  }) {
    return MoneroAccount._(privKey: privSkey, coinType: coinType);
  }

  /// Factory method to create a Monero instance from watch-only keys.
  ///
  /// Given a [privVkey], [pubSkey], and an optional [coinType], this method constructs a
  /// Monero instance with the associated keys and configurations.
  factory MoneroAccount.fromWatchOnly(
    List<int> privVkey,
    List<int> pubSkey, {
    MoneroCoins coinType = MoneroCoins.moneroMainnet,
  }) {
    return MoneroAccount._(
      privKey: privVkey,
      pubKey: pubSkey,
      coinType: coinType,
    );
  }

  /// Check if the Monero instance is watch-only (has no private spend key).
  bool get isWatchOnly {
    return privSkey == null;
  }

  /// Get the private spend key of the Monero instance.
  ED25519MoneroPrivateKey get privateSpendKey {
    if (isWatchOnly) {
      throw const BuError(
        DefaultErrorType.invalidKeyData,
        'Watch-only class does not have a private spend key',
      );
    }
    return privSkey!;
  }

  /// Get the private view key of the Monero instance.
  ED25519MoneroPrivateKey get privateViewKey {
    return privVkey;
  }

  /// Get the public spend key of the Monero instance.
  ED25519MoneroPublicKey get publicSpendKey {
    return pubSkey;
  }

  /// Get the public view key of the Monero instance.
  ED25519MoneroPublicKey get publicViewKey {
    return pubVkey;
  }

  /// Generate an integrated address by encoding the keys and payment ID.
  String integratedAddress(List<int> paymentId) {
    return XmrIntegratedAddrEncoder().encodeKey(
      pubSkey.toBytes(),
      netVersion: coinConf.intAddrNetVer,
      pubVKey: pubVkey.toBytes(),
      paymentId: paymentId,
    );
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
      minorIndex,
      majorIndex,
      coinConf.subaddrNetVer,
    );
  }

  /// Calculate and return the private view key from the private spend key.
  static ED25519MoneroPrivateKey _viewFromSpendKey(
    ED25519MoneroPrivateKey privSkey,
  ) {
    final List<int> privVkeyBytes = blockchainUtils.api.ed25519.scReduce(
      privSkey.toBytes().useValue(QuickCrypto.keccak256Hash, zero: true),
    );
    return ED25519MoneroPrivateKey.fromBytes(privVkeyBytes);
  }

  @override
  void dispose() {
    privSkey?.dispose();
    privVkey.dispose();
  }
}
