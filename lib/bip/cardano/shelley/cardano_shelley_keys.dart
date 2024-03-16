import 'package:blockchain_utils/bip/address/ada/ada_shelley_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';

/// A class that represents public keys associated with a Cardano Shelley wallet.
class CardanoShelleyPublicKeys {
  final Bip32PublicKey pubAddrKey;
  final Bip32PublicKey pubSkKey;
  final CoinConfig coinConf;

  /// Constructor to create a Cardano Shelley Public Keys instance.
  ///
  /// Parameters:
  /// - `pubAddrKey`: The public address key.
  /// - `pubSkKey`: The public spending key.
  /// - `coinConf`: The configuration for the associated coin.
  CardanoShelleyPublicKeys(
      {required this.pubAddrKey,
      required this.pubSkKey,
      required this.coinConf});

  /// Retrieves and returns the public key associated with the wallet's address.
  Bip32PublicKey get addressKey {
    return pubAddrKey;
  }

  /// Retrieves and returns the public key associated with the wallet's reward key.
  Bip32PublicKey get rewardKey {
    return stakingKey;
  }

  /// Retrieves and returns the public key associated with the wallet's staking key.
  Bip32PublicKey get stakingKey {
    return pubSkKey;
  }

  /// Converts the public staking key to a reward address.
  String get toRewardAddress {
    return toStakingAddress;
  }

  /// Converts the public staking key to a staking address.
  String get toStakingAddress {
    return AdaShelleyStakingAddrEncoder()
        .encodeKey(pubSkKey.key.compressed, coinConf.addrParams);
  }

  /// Converts the public address key to a Cardano Shelley address.
  String get toAddress {
    return AdaShelleyAddrEncoder().encodeKey(pubAddrKey.key.compressed,
        {"pub_skey": pubSkKey.key.compressed, ...coinConf.addrParams});
  }
}

/// A class that represents private keys associated with a Cardano Shelley wallet.
class CardanoShelleyPrivateKeys {
  final Bip32PrivateKey privAddrKey;
  final Bip32PrivateKey privSkKey;
  final CoinConfig coinConf;

  /// Constructor to create a Cardano Shelley Private Keys instance.
  ///
  /// Parameters:
  /// - `privAddrKey`: The private address key.
  /// - `privSkKey`: The private spending key.
  /// - `coinConf`: The configuration for the associated coin.
  CardanoShelleyPrivateKeys(
      {required this.privAddrKey,
      required this.privSkKey,
      required this.coinConf});

  /// Retrieves and returns the private key associated with the wallet's address.
  Bip32PrivateKey get addressKey {
    return privAddrKey;
  }

  /// Retrieves and returns the private key associated with the wallet's reward key.
  Bip32PrivateKey get rewardKey {
    return stakingKey;
  }

  /// Retrieves and returns the private key associated with the wallet's staking key.
  Bip32PrivateKey get stakingKey {
    return privSkKey;
  }

  /// Retrieves and returns the corresponding public keys associated with the private keys.
  CardanoShelleyPublicKeys get publicKeys {
    return CardanoShelleyPublicKeys(
        pubAddrKey: privAddrKey.publicKey,
        pubSkKey: privSkKey.publicKey,
        coinConf: coinConf);
  }
}
