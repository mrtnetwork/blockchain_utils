import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coin_conf.dart';
import 'package:blockchain_utils/bip/substrate/exception/substrate_ex.dart';

class SubstratePrvKey {
  final IPrivateKey privKey;
  final SubstrateCoinConf coinConf;

  const SubstratePrvKey._(this.privKey, this.coinConf);

  /// Creates a [Sr25519PrivateKey] from the provided [keyBytes] and [coinConf].
  factory SubstratePrvKey.fromBytes(
      List<int> keyBytes, SubstrateCoinConf coinConf) {
    return SubstratePrvKey._(_keyFromBytes(keyBytes, coinConf.type), coinConf);
  }

  /// Gets the raw representation of the private key as a List<int>.
  List<int> get raw {
    return privKey.raw;
  }

  /// Derives the corresponding Substrate public key from this private key.
  SubstratePubKey get publicKey {
    return SubstratePubKey._(privKey.publicKey, coinConf);
  }

  /// Internal method to create an Sr25519 private key from raw bytes.
  static IPrivateKey _keyFromBytes(
      List<int> keyBytes, EllipticCurveTypes curve) {
    try {
      return IPrivateKey.fromBytes(keyBytes, curve);
    } catch (e) {
      throw const SubstrateKeyError('Invalid private key');
    }
  }
}

class SubstratePubKey {
  final IPublicKey pubKey;

  final SubstrateCoinConf coinConf;

  const SubstratePubKey._(this.pubKey, this.coinConf);

  factory SubstratePubKey.fromBytes(
      {required List<int> keyBytes, required SubstrateCoinConf coinConf}) {
    return SubstratePubKey._(_keyFromBytes(keyBytes, coinConf.type), coinConf);
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
      "ss58_format": ss58Format ?? coinConf.ss58Format
    };
    return coinConf.addressEncoder().encodeKey(pubKey.compressed, addrParams);
  }

  String get toAddress {
    return toSS58Address();
  }

  static IPublicKey _keyFromBytes(
      List<int> keyBytes, EllipticCurveTypes curve) {
    try {
      return IPublicKey.fromBytes(keyBytes, curve);
    } catch (e) {
      throw const SubstrateKeyError('Invalid public key');
    }
  }
}
