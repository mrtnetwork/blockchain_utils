import 'package:blockchain_utils/bip/address/substrate_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/sr25519_keys.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coin_conf.dart';
import 'package:blockchain_utils/bip/substrate/substrate_ex.dart';

/// Represents a Substrate public key using the Sr25519 key pair. This class provides methods for
/// working with Substrate public keys, including serialization, address generation, and error handling.
class SubstratePublicKey {
  /// The underlying Sr25519 public key.
  final Sr25519PublicKey pubKey;

  /// The Substrate coin configuration associated with this public key.
  final SubstrateCoinConf coinConf;

  /// Creates a new instance of [SubstratePublicKey] with the given [pubKey] and [coinConf].
  const SubstratePublicKey(this.pubKey, this.coinConf);

  /// Creates a [SubstratePublicKey] from the provided [keyBytes] and [coinConf].
  factory SubstratePublicKey.fromBytes(
      List<int> keyBytes, SubstrateCoinConf coinConf) {
    return SubstratePublicKey(
      _keyFromBytes(keyBytes),
      coinConf,
    );
  }

  /// Gets the compressed representation of the public key as a List<int>.
  List<int> get compressed {
    return pubKey.compressed;
  }

  /// Gets the uncompressed representation of the public key as a List<int>.
  List<int> get uncompressed {
    return pubKey.uncompressed;
  }

  /// Converts the public key to a Substrate address using the specified [coinConf].
  String get toAddress {
    return SubstrateSr25519AddrEncoder().encodeKey(
      pubKey.compressed,
      coinConf.addrParams,
    );
  }

  /// Internal method to create an Sr25519 public key from raw bytes.
  static Sr25519PublicKey _keyFromBytes(List<int> keyBytes) {
    try {
      return Sr25519PublicKey.fromBytes(keyBytes);
    } catch (e) {
      throw const SubstrateKeyError('Invalid public key');
    }
  }
}

/// Represents a Substrate private key using the Sr25519 key pair. This class provides methods for
/// working with Substrate private keys, including serialization, public key derivation, and error handling.
class SubstratePrivateKey {
  /// The underlying Sr25519 private key.
  final Sr25519PrivateKey privKey;

  /// The Substrate coin configuration associated with this private key.
  final SubstrateCoinConf coinConf;

  /// Creates a new instance of [SubstratePrivateKey] with the given [privKey] and [coinConf].
  const SubstratePrivateKey._(this.privKey, this.coinConf);

  /// Creates a [SubstratePrivateKey] from the provided [keyBytes] and [coinConf].
  factory SubstratePrivateKey.fromBytes(
      List<int> keyBytes, SubstrateCoinConf coinConf) {
    return SubstratePrivateKey._(
      _keyFromBytes(keyBytes),
      coinConf,
    );
  }

  /// Gets the raw representation of the private key as a List<int>.
  List<int> get raw {
    return privKey.raw;
  }

  /// Derives the corresponding Substrate public key from this private key.
  SubstratePublicKey get publicKey {
    return SubstratePublicKey(
      privKey.publicKey,
      coinConf,
    );
  }

  /// Internal method to create an Sr25519 private key from raw bytes.
  static Sr25519PrivateKey _keyFromBytes(List<int> keyBytes) {
    try {
      return Sr25519PrivateKey.fromBytes(keyBytes);
    } catch (e) {
      throw const SubstrateKeyError('Invalid private key');
    }
  }
}
