import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/substrate/conf/substrate_coin_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class SubstratePrvKey with SecretState {
  final IPrivateKey privKey;
  final SubstrateCoinConf coinConf;

  const SubstratePrvKey._(this.privKey, this.coinConf);

  /// Creates a private key of the coin's type from the provided [keyBytes]
  factory SubstratePrvKey.fromBytes(
    List<int> keyBytes,
    SubstrateCoinConf coinConf,
  ) {
    return SubstratePrvKey._(_keyFromBytes(keyBytes, coinConf.type), coinConf);
  }

  factory SubstratePrvKey.fromPrivateKey(
    IPrivateKey privateKey,
    SubstrateCoinConf coinConf,
  ) {
    if (privateKey.type != coinConf.type) {
      throw CoreErrors.invalidOperationArguments(
        "SubstratePrvKey.fromPrivateKey",
        reason: "Mismatch private key type.",
      );
    }
    return SubstratePrvKey._(privateKey, coinConf);
  }

  /// Gets the raw representation of the private key as [SecretBytes].
  SecretBytes toBytes({SecretTransform? transform}) {
    return privKey.toBytes(transform: transform);
  }

  /// Derives the corresponding Substrate public key from this private key.
  SubstratePubKey get publicKey {
    return SubstratePubKey._(privKey.publicKey, coinConf);
  }

  /// Internal method to create a private key from raw bytes for [curve].
  static IPrivateKey _keyFromBytes(List<int> keyBytes, CryptoKeyType curve) {
    try {
      return IPrivateKey.fromBytes(keyBytes, curve);
    } on BuError {
      throw const BuError(DefaultErrorType.badPrivateKey,'Invalid private key');
    }
  }

  @override
  void dispose() {
    privKey.dispose();
  }
}

class SubstratePubKey {
  final IPublicKey pubKey;

  final SubstrateCoinConf coinConf;

  const SubstratePubKey._(this.pubKey, this.coinConf);

  factory SubstratePubKey.fromBytes({
    required List<int> keyBytes,
    required SubstrateCoinConf coinConf,
  }) {
    return SubstratePubKey._(_keyFromBytes(keyBytes, coinConf.type), coinConf);
  }
  factory SubstratePubKey.fromPublicKey({
    required IPublicKey publicKey,
    required SubstrateCoinConf coinConf,
  }) {
    if (publicKey.type != coinConf.type) {
      throw CoreErrors.invalidOperationArguments(
        "SubstratePubKey.fromPublicKey",
        reason: "Mismatch public key type.",
      );
    }
    return SubstratePubKey._(publicKey, coinConf);
  }

  CryptoKeyType get curve => pubKey.type;

  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) =>
      pubKey.toBytes(mode: mode);

  String toSS58Address({int? ss58Format}) {
    return coinConf.addressEncoder(
      EncodeAddressDefaultParams(
        pubKey: pubKey.toBytes(),
        ss58Format: ss58Format,
      ),
      coinConf,
    );
  }

  String get toAddress {
    return toSS58Address();
  }

  static IPublicKey _keyFromBytes(List<int> keyBytes, CryptoKeyType curve) {
    try {
      return IPublicKey.fromBytes(keyBytes, curve);
    } catch (e) {
      throw const BuError(DefaultErrorType.badPublicKey,'Invalid public key');
    }
  }
}
