import 'dart:typed_data';

import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/secp256k1_keys_ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';

/// Electrum V1 is a class that represents a pair of public and private keys for the Secp256k1 elliptic curve.
class ElectrumV1 {
  final IPrivateKey? privateKey;
  final IPublicKey publicKey;

  /// Private constructor to create an Electrum V1 instance with a private key and its corresponding public key.
  ElectrumV1._(this.privateKey, this.publicKey);

  /// Create an Electrum V1 instance from a seed represented as [List<int>].
  factory ElectrumV1.fromSeed(List<int> seedBytes) {
    return ElectrumV1.fromPrivateKey(seedBytes);
  }

  /// Create an Electrum V1 instance from a private key represented as [List<int>].
  factory ElectrumV1.fromPrivateKey(List<int> privKey) {
    final privateKey = Secp256k1PrivateKeyEcdsa.fromBytes(privKey);
    return ElectrumV1._(privateKey, privateKey.publicKey);
  }

  /// Create an Electrum V1 instance from a public key represented as [List<int>].
  static ElectrumV1 fromPublicKey(List<int> pubKey) {
    final publicKey = Secp256k1PublicKeyEcdsa.fromBytes(pubKey);
    return ElectrumV1._(null, publicKey);
  }

  /// Checks if this key contains only public information.
  bool get isPublicOnly {
    return privateKey == null;
  }

  /// Get the master private key, throwing an exception if it's a public-only key.
  IPrivateKey get masterPrivateKey {
    if (isPublicOnly) {
      throw const MessageException(
          'Public-only deterministic keys have no private half');
    }
    return privateKey!;
  }

  /// Get the master public key.
  IPublicKey get masterPublicKey {
    return publicKey;
  }

  /// Get a private key for a specific change and address index, throwing an exception if it's a public-only key.
  IPrivateKey getPrivateKey(int changeIndex, int addrIndex) {
    if (isPublicOnly) {
      throw const MessageException(
          'Public-only deterministic keys have no private half');
    }
    return _derivePrivateKey(changeIndex, addrIndex);
  }

  /// Get a public key for a specific change and address index.
  IPublicKey getPublicKey(int changeIndex, int addressIndex) {
    return isPublicOnly
        ? _derivePublicKey(changeIndex, addressIndex)
        : getPrivateKey(changeIndex, addressIndex).publicKey;
  }

  /// Get the P2PKH address for a specific change and address index.
  String getAddress(int changeIndex, int addressIndex) {
    return P2PKHAddrEncoder()
        .encodeKey(getPublicKey(changeIndex, addressIndex).compressed, {
      "net_ver": CoinsConf.bitcoinMainNet.params.p2pkhNetVer,
      "pub_key_mode": PubKeyModes.uncompressed
    });
  }

  /// Derive a private key for a specific change and address index.
  IPrivateKey _derivePrivateKey(int changeIndex, int addressIndex) {
    _validateIndexes(changeIndex, addressIndex);
    final seqBytes = _getSequence(changeIndex, addressIndex);
    final privBig =
        BigintUtils.fromBytes(privateKey!.raw, byteOrder: Endian.big);
    final newPriveBig = BigintUtils.fromBytes(seqBytes, byteOrder: Endian.big);
    final p = (privBig + newPriveBig) % Curves.generatorSecp256k1.order!;
    final toBytes =
        BigintUtils.toBytes(p, length: EcdsaKeysConst.privKeyByteLen);
    return Secp256k1PrivateKeyEcdsa.fromBytes(toBytes);
  }

  /// Derive a public key for a specific change and address index.
  IPublicKey _derivePublicKey(int changeIndex, int addressIndex) {
    _validateIndexes(changeIndex, addressIndex);
    final seqBytes = _getSequence(changeIndex, addressIndex);

    final pubPoint = masterPublicKey.point;

    final newPubPoint = Curves.generatorSecp256k1 *
        BigintUtils.fromBytes(seqBytes, byteOrder: Endian.big);
    return Secp256k1PublicKeyEcdsa.fromBytes(
        (pubPoint + newPubPoint).toBytes());
  }

  /// Generate a sequence of bytes based on change and address index.
  List<int> _getSequence(int changeIndex, int addrIndex) {
    return QuickCrypto.sha256DoubleHash(
      List<int>.from([
        ...StringUtils.encode('$addrIndex:$changeIndex:'),
        ...masterPublicKey.uncompressed.sublist(1)
      ]),
    );
  }

  /// Validate change and address indexes to ensure they are non-negative.
  static void _validateIndexes(int changeIndex, int addrIndex) {
    Bip32KeyIndex(changeIndex);
    Bip32KeyIndex(addrIndex);
  }
}
