import 'package:blockchain_utils/bip/address/substrate_addr.dart';
import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';

import 'package:blockchain_utils/bip/substrate/conf/substrate_coin_conf.dart';
import 'package:blockchain_utils/bip/substrate/substrate_ex.dart';

class SubstrateKeyAlgorithm {
  final EllipticCurveTypes cuve;
  const SubstrateKeyAlgorithm._(this.cuve);
  static const SubstrateKeyAlgorithm ed25519 =
      SubstrateKeyAlgorithm._(EllipticCurveTypes.ed25519);
  static const SubstrateKeyAlgorithm sr25519 =
      SubstrateKeyAlgorithm._(EllipticCurveTypes.sr25519);
  static const SubstrateKeyAlgorithm secp256k1 =
      SubstrateKeyAlgorithm._(EllipticCurveTypes.secp256k1);
}

class SubstratePrvKey {
  final IPrivateKey privKey;
  final SubstrateKeyAlgorithm algorithm;
  final SubstrateCoinConf coinConf;

  const SubstratePrvKey._(this.privKey, this.coinConf, this.algorithm);

  /// Creates a [Sr25519PrivateKey] from the provided [keyBytes] and [coinConf].
  factory SubstratePrvKey.fromBytes(List<int> keyBytes,
      SubstrateCoinConf coinConf, SubstrateKeyAlgorithm curve) {
    return SubstratePrvKey._(_keyFromBytes(keyBytes, curve), coinConf, curve);
  }

  /// Gets the raw representation of the private key as a List<int>.
  List<int> get raw {
    return privKey.raw;
  }

  /// Derives the corresponding Substrate public key from this private key.
  SubstratePubKey get publicKey {
    return SubstratePubKey._(privKey.publicKey, coinConf, algorithm);
  }

  /// Internal method to create an Sr25519 private key from raw bytes.
  static IPrivateKey _keyFromBytes(
      List<int> keyBytes, SubstrateKeyAlgorithm curve) {
    try {
      return IPrivateKey.fromBytes(keyBytes, curve.cuve);
    } catch (e) {
      throw const SubstrateKeyError('Invalid private key');
    }
  }
}

class SubstratePubKey {
  final IPublicKey pubKey;
  final SubstrateKeyAlgorithm algorithm;

  final SubstrateCoinConf coinConf;

  const SubstratePubKey._(this.pubKey, this.coinConf, this.algorithm);

  factory SubstratePubKey.fromBytes(
      {required List<int> keyBytes,
      required SubstrateCoinConf coinConf,
      required SubstrateKeyAlgorithm curve}) {
    return SubstratePubKey._(_keyFromBytes(keyBytes, curve), coinConf, curve);
  }

  EllipticCurveTypes get curve => pubKey.curve;

  List<int> get compressed {
    return pubKey.compressed;
  }

  List<int> get uncompressed {
    return pubKey.uncompressed;
  }

  String toSS58Address({int? ss58Format}) {
    final Map<String, dynamic> addrParams = {
      "ss58_format": ss58Format ?? coinConf.addrParams["ss58_format"]!
    };
    switch (pubKey.curve) {
      case EllipticCurveTypes.sr25519:
        return SubstrateSr25519AddrEncoder()
            .encodeKey(pubKey.compressed, addrParams);
      case EllipticCurveTypes.ed25519:
        return SubstrateEd25519AddrEncoder()
            .encodeKey(pubKey.compressed, addrParams);
      default:
        return SubstrateSecp256k1AddrEncoder()
            .encodeKey(pubKey.compressed, addrParams);
    }
  }

  String get toAddress {
    return toSS58Address();
  }

  static IPublicKey _keyFromBytes(
      List<int> keyBytes, SubstrateKeyAlgorithm curve) {
    try {
      return IPublicKey.fromBytes(keyBytes, curve.cuve);
    } catch (e) {
      throw const SubstrateKeyError('Invalid public key');
    }
  }
}
