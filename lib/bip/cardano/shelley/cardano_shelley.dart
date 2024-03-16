import 'package:blockchain_utils/bip/address/ada/ada_shelley_addr.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/cip1852.dart';
import 'package:blockchain_utils/bip/cardano/shelley/cardano_shelley_keys.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// A class that represents a Cardano Shelley wallet, including both public and private keys.
class CardanoShelley {
  late final Bip44Base bip44;
  late final Bip44Base bip44Sk;

  /// Factory constructor to create a Cardano Shelley wallet from a Cip1852 Bip44 object.
  ///
  /// Parameters:
  /// - `bipObj`: The Cip1852 Bip44 object used to initialize the wallet.
  ///
  /// Throws an `ArgumentException` if the provided Bip object is not a Cip1852 instance.
  factory CardanoShelley.fromCip1852Object(Bip44Base bip) {
    if (bip is! Cip1852) {
      throw ArgumentException("The Bip object shall be a Cip1852 instance");
    }
    return CardanoShelley(bip, __deriveStakingKeys(bip));
  }

  /// Constructor to create a Cardano Shelley wallet from Bip44 objects.
  ///
  /// Parameters:
  /// - `bip`: The Bip44 Bip object for the wallet's address keys.
  /// - `bipSk`: The Bip44 Bip object for the wallet's staking keys.
  ///
  /// Throws an `ArgumentException` if the provided Bip object is below the account level or if `bipSk` is not at the address index level.
  CardanoShelley(Bip44Base bip, Bip44Base bipSk) {
    if (bip.level.value < Bip44Levels.account.value) {
      throw ArgumentException("The bipObj shall not be below account level");
    }
    if (bipSk.level != Bip44Levels.addressIndex) {
      throw ArgumentException("The bipSkObj shall be of address index level");
    }
    bip44 = bip;
    bip44Sk = bipSk;
  }

  /// Retrieves and returns the public keys associated with the wallet.
  CardanoShelleyPublicKeys get publicKeys {
    return CardanoShelleyPublicKeys(
        pubAddrKey: bip44.publicKey.key,
        pubSkKey: bip44Sk.publicKey.key,
        coinConf: bip44.coinConf);
  }

  /// Retrieves and returns the private keys associated with the wallet.
  CardanoShelleyPrivateKeys get privateKeys {
    return CardanoShelleyPrivateKeys(
        privAddrKey: bip44.privateKey.key,
        privSkKey: bip44Sk.privateKey.key,
        coinConf: bip44.coinConf);
  }

  /// Retrieves the Bip44 object for reward keys.
  Bip44Base get rewardKey {
    return stakingKey;
  }

  /// Retrieves the Bip44 object for staking keys.
  Bip44Base get stakingKey {
    return bip44Sk;
  }

  /// Checks if the wallet is public-only (no private keys).
  bool get isPublicOnly {
    return bip44.isPublicOnly;
  }

  /// Creates a new Cardano Shelley wallet with a specified change type.
  CardanoShelley change(Bip44Changes changeType) {
    return CardanoShelley(bip44.change(changeType), bip44Sk);
  }

  /// Creates a new Cardano Shelley wallet with a specified address index.
  CardanoShelley addressIndex(int addrIdx) {
    return CardanoShelley(bip44.addressIndex(addrIdx), bip44Sk);
  }

  /// Internal method to derive staking keys from the provided Bip object.
  static Bip44Base __deriveStakingKeys(Bip44Base bipObj) {
    final coinConf = bipObj.coinConf.copy(
      addressEncoder: ([dynamic kwargs]) => AdaShelleyStakingAddrEncoder(),
    );
    return Cip1852.fromBip32(bipObj.bip32Object.derivePath("2/0"), coinConf);
  }
}
