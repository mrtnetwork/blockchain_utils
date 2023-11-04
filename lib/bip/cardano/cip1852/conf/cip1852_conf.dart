import 'package:blockchain_utils/bip/address/ada_shelley_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_conf_const.dart';
import 'package:blockchain_utils/bip/cardano/cip1852/conf/cip1852_coins.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

/// A configuration class for CIP1852 coins that defines the
class Cip1852Conf {
  /// A mapping that associates each Cip1852Coins (enum) with its corresponding
  /// BipCoinConf configuration.
  static final Map<BipCoins, BipCoinConf> coinToConf = {
    Cip1852Coins.cardanoIcarus: Cip1852Conf.cardanoIcarusMainNet,
    Cip1852Coins.cardanoLedger: Cip1852Conf.cardanoLedgerMainNet,
    Cip1852Coins.cardanoIcarusTestnet: Cip1852Conf.cardanoIcarusTestNet,
    Cip1852Coins.cardanoLedgerTestnet: Cip1852Conf.cardanoLedgerTestNet,
  };

  /// Retrieves the BipCoinConf for the given Cip1852Coin. If the provided coin
  /// is not an instance of Cip1852Coins, an error is thrown.
  static BipCoinConf getCoin(BipCoins coin) {
    if (coin is! Cip1852Coins) {
      throw ArgumentError("Coin type is not an enumerative of Cip1852Coins");
    }
    return coinToConf[coin.value]!;
  }

  // Configuration for Cardano main net (Icarus)
  static final BipCoinConf cardanoIcarusMainNet = BipCoinConf(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    addressEncoder: ([dynamic kwargs]) => AdaShelleyAddrEncoder(),
    type: EllipticCurveTypes.ed25519Kholaw,
    addrParams: {
      "net_tag": AdaShelleyAddrNetworkTags.mainnet,
      "is_icarus": true,
    },
  );

  // Configuration for Cardano test net (Icarus)
  static final BipCoinConf cardanoIcarusTestNet = BipCoinConf(
    coinNames: CoinsConf.cardanoTestNet.coinName,
    coinIdx: Slip44.cardano,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.testNetKeyNetVersions,
    wifNetVer: null,
    addressEncoder: ([dynamic kwargs]) => AdaShelleyAddrEncoder(),
    type: EllipticCurveTypes.ed25519Kholaw,
    addrParams: {
      "net_tag": AdaShelleyAddrNetworkTags.testnet,
      "is_icarus": true,
    },
  );

  // Configuration for Cardano main net (Ledger)
  static final BipCoinConf cardanoLedgerMainNet = BipCoinConf(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder: ([dynamic kwargs]) => AdaShelleyAddrEncoder(),
    addrParams: {"net_tag": AdaShelleyAddrNetworkTags.mainnet},
  );

  // Configuration for Cardano test net (Ledger)
  static final BipCoinConf cardanoLedgerTestNet = BipCoinConf(
    coinNames: CoinsConf.cardanoTestNet.coinName,
    coinIdx: Slip44.cardano,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.testNetKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder: ([dynamic kwargs]) => AdaShelleyAddrEncoder(),
    addrParams: {"net_tag": AdaShelleyAddrNetworkTags.testnet},
  );
}
