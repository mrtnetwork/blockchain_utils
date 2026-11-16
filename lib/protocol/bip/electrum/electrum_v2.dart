import 'package:blockchain_utils/chain/address/protocol/p2pkh_addr.dart';
import 'package:blockchain_utils/chain/address/protocol/p2wpkh_addr.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_secp256k1.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';

/// An abstract base class for Electrum V2 implementations
abstract class ElectrumV2Base {
  final Bip32Slip10Secp256k1 bip32;

  const ElectrumV2Base(this.bip32);
  // Check if the instance contains only public keys (no private keys).
  bool get isPublicOnly {
    return bip32.isPublicOnly;
  }

  /// Get the master private key.
  Bip32PrivateKey get masterPrivateKey {
    return bip32.privateKey;
  }

  /// Get the master public key.
  Bip32PublicKey get masterPublicKey {
    return bip32.publicKey;
  }

  /// Get a specific private key based on change and address indexes.
  Bip32PrivateKey getPrivateKey(int changeIndex, int addressIndex);

  /// Get a specific public key based on change and address indexes.
  Bip32PublicKey getPublicKey(int changeIndex, int addressIndex);

  /// Get the address for a specific change and address index.
  String getAddress(int changeIndex, int addressIndex);
}

/// Implementation of Electrum V2 for the standard type wallet.
class ElectrumV2Standard extends ElectrumV2Base {
  ElectrumV2Standard(super.bip32);

  /// Factory method to create an instance from a seed.
  factory ElectrumV2Standard.fromSeed(List<int> seedBytes) {
    final bip = Bip32Slip10Secp256k1.fromSeed(seedBytes);
    return ElectrumV2Standard(bip);
  }

  /// Get a specific private key based on change and address indexes.
  @override
  Bip32PrivateKey getPrivateKey(int changeIndex, int addressIndex) {
    return _deriveKey(changeIndex, addressIndex).privateKey;
  }

  /// Get a specific public key based on change and address indexes.
  @override
  Bip32PublicKey getPublicKey(int changeIndex, int addressIndex) {
    return _deriveKey(changeIndex, addressIndex).publicKey;
  }

  /// Get the P2PKH (pay-to-pub-key-hash) address for a specific change and address index.
  @override
  String getAddress(int changeIndex, int addressIndex) {
    return P2PKHAddrEncoder().encodeKey(
      getPublicKey(changeIndex, addressIndex).toPublicKeyBytes(),
      netVersion: CoinsConf.bitcoinMainNet.params.p2pkhNetVer,
    );
  }

  /// Derive a key for a specific change and address index.
  Bip32Base _deriveKey(int changeIndex, int addressIndex) {
    return bip32.derivePath('m/$changeIndex/$addressIndex');
  }
}

/// Implementation of Electrum V2 for the segwit type wallet.
class ElectrumV2Segwit extends ElectrumV2Base {
  final Bip32Base bip32Account;

  ElectrumV2Segwit(super.bip32) : bip32Account = bip32.derivePath("m/0'");

  /// Factory method to create an instance from a seed.
  factory ElectrumV2Segwit.fromSeed(List<int> seedBytes) {
    final bip = Bip32Slip10Secp256k1.fromSeed(seedBytes);
    return ElectrumV2Segwit(bip);
  }

  /// Get a specific private key based on change and address indexes.
  @override
  Bip32PrivateKey getPrivateKey(int changeIndex, int addressIndex) {
    return _deriveKey(changeIndex, addressIndex).privateKey;
  }

  /// Get a specific public key based on change and address indexes.
  @override
  Bip32PublicKey getPublicKey(int changeIndex, int addressIndex) {
    return _deriveKey(changeIndex, addressIndex).publicKey;
  }

  /// Get the P2WPKH (pay-to-witness-pub-key-hash) address for a specific change and address index.
  @override
  String getAddress(int changeIndex, int addressIndex) {
    return P2WPKHAddrEncoder().encodeKey(
      getPublicKey(changeIndex, addressIndex).toPublicKeyBytes(),
      hrp: CoinsConf.bitcoinMainNet.params.p2wpkhHrp,
    );
  }

  /// Derive a key for a specific change and address index.
  Bip32Base<dynamic> _deriveKey(int changeIndex, int addressIndex) {
    return bip32Account.derivePath('$changeIndex/$addressIndex');
  }
}
