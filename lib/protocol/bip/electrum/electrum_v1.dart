import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/chain/address/protocol/p2pkh_addr.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Electrum V1 is a class that represents a pair of public and private keys for the Secp256k1 elliptic curve.
class ElectrumV1 with SecretState {
  Secp256k1PrivateKey? _privateKey;
  final Secp256k1PublicKey publicKey;

  Secp256k1PrivateKey? get privateKey => _privateKey;

  /// Private constructor to create an Electrum V1 instance with a private key and its corresponding public key.
  ElectrumV1._(this._privateKey, this.publicKey);

  /// Create an Electrum V1 instance from a seed.
  factory ElectrumV1.fromSeed(List<int> seedBytes) {
    return ElectrumV1.fromPrivateKey(seedBytes);
  }

  /// Create an Electrum V1 instance from a private key.
  factory ElectrumV1.fromPrivateKey(List<int> privKey) {
    final privateKey = Secp256k1PrivateKey.fromBytes(privKey);
    return ElectrumV1._(privateKey, privateKey.publicKey);
  }

  /// Create an Electrum V1 instance from a public key.
  static ElectrumV1 fromPublicKey(List<int> pubKey) {
    final publicKey = Secp256k1PublicKey.fromBytes(pubKey);
    return ElectrumV1._(null, publicKey);
  }

  /// Checks if this key contains only public information.
  bool get isPublicOnly {
    return privateKey == null;
  }

  /// Get the master private key, throwing an exception if it's a public-only key.
  IPrivateKey get masterPrivateKey {
    if (isPublicOnly) {
      throw const BuError(DefaultErrorType.invalidKeyData,
        'Public-only deterministic keys have no private half',
      );
    }
    return privateKey!;
  }

  /// Get the master public key.
  Secp256k1PublicKey get masterPublicKey {
    return publicKey;
  }

  /// Get a private key for a specific change and address index, throwing an exception if it's a public-only key.
  Secp256k1PrivateKey getPrivateKey(int changeIndex, int addrIndex) {
    if (isPublicOnly) {
      throw const BuError(DefaultErrorType.invalidKeyData,
        'Public-only deterministic keys have no private half',
      );
    }
    return _derivePrivateKey(changeIndex, addrIndex);
  }

  /// Get a public key for a specific change and address index.
  Secp256k1PublicKey getPublicKey(int changeIndex, int addressIndex) {
    return isPublicOnly
        ? _derivePublicKey(changeIndex, addressIndex)
        : getPrivateKey(changeIndex, addressIndex).publicKey;
  }

  /// Get the P2PKH address for a specific change and address index.
  String getAddress(int changeIndex, int addressIndex) {
    return P2PKHAddrEncoder().encodeKey(
      getPublicKey(
        changeIndex,
        addressIndex,
      ).toBytes(mode: CryptoKeyEncoding.base),
      netVersion: CoinsConf.bitcoinMainNet.params.p2pkhNetVer,
      pubKeyMode: CryptoKeyEncoding.uncompressed,
    );
  }

  /// Derive a private key for a specific change and address index.
  Secp256k1PrivateKey _derivePrivateKey(int changeIndex, int addressIndex) {
    _validateIndexes(changeIndex, addressIndex);
    final seqBytes = _getSequence(changeIndex, addressIndex);
    final sum = privateKey!.takeSecretKey().useValue(
      (k) => blockchainUtils.api.secp256k1.scAdd(seqBytes, k),
    );
    try {
      return Secp256k1PrivateKey.fromBytes(sum);
    } finally {
      sum.forceZero();
    }
  }

  /// Derive a public key for a specific change and address index.
  Secp256k1PublicKey _derivePublicKey(int changeIndex, int addressIndex) {
    _validateIndexes(changeIndex, addressIndex);
    final seqBytes = _getSequence(changeIndex, addressIndex);

    final pubPoint = masterPublicKey.keyBytes;
    final multBase = blockchainUtils.api.secp256k1.multBase(seqBytes);
    final sum = blockchainUtils.api.secp256k1.add(pubPoint, multBase);
    return Secp256k1PublicKey.fromBytes(sum);
  }

  /// Generate a sequence of bytes based on change and address index.
  List<int> _getSequence(int changeIndex, int addrIndex) {
    return QuickCrypto.sha256DoubleHash([
      ...StringUtils.encode('$addrIndex:$changeIndex:'),
      ...masterPublicKey
          .toBytes(mode: CryptoKeyEncoding.uncompressed)
          .sublist(1),
    ]);
  }

  /// Validate change and address indexes to ensure they are non-negative.
  static void _validateIndexes(int changeIndex, int addrIndex) {
    Bip32KeyIndex(changeIndex);
    Bip32KeyIndex(addrIndex);
  }

  void convertToPublic({bool disposeKey = true}) {
    if (disposeKey) {
      _privateKey?.dispose();
    }
    _privateKey = null;
  }

  @override
  void dispose() {
    convertToPublic(disposeKey: true);
  }
}
