import 'package:blockchain_utils/bip/address/p2wpkh_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/bip84/bip84_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_conf_const.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

/// A configuration class for BIP84 that defines the key network versions and
/// maps each supported BIP84Coin to its corresponding BipCoinConf.
class Bip84Conf {
  /// A mapping that associates each BIP84Coin (enum) with its corresponding
  /// BipCoinConf configuration.
  static final Map<Bip84Coins, BipCoinConf> coinToConf = {
    Bip84Coins.bitcoin: Bip84Conf.bitcoinMainNet,
    Bip84Coins.bitcoinTestnet: Bip84Conf.bitcoinTestNet,
    Bip84Coins.litecoin: Bip84Conf.litecoinMainNet,
    Bip84Coins.litecoinTestnet: Bip84Conf.litecoinTestNet,
  };

  /// Retrieves the BipCoinConf for the given BIP84Coin. If the provided coin
  /// is not an instance of Bip84Coins, an error is thrown.
  static BipCoinConf getCoin(BipCoins coin) {
    if (coin is! Bip84Coins) {
      throw ArgumentError("Coin type is not an enumerative of Bip84Coins");
    }
    return coinToConf[coin.value]!;
  }

  /// The key network version for Bitcoin.
  static final Bip32KeyNetVersions bip84BtcKeyNetVer = Bip32KeyNetVersions(
    List<int>.from([0x04, 0xb2, 0x47, 0x46]),
    List<int>.from([0x04, 0xb2, 0x43, 0x0c]),
  );

  /// Configuration for Bitcoin main net
  static final BipCoinConf bitcoinMainNet = BipCoinConf(
    coinNames: CoinsConf.bitcoinMainNet.coinName,
    coinIdx: Slip44.bitcoin,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip84BtcKeyNetVer,
    wifNetVer: CoinsConf.bitcoinMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2WPKHAddrEncoder(),
    addrParams: {"hrp": CoinsConf.bitcoinMainNet.getParam("p2wpkh_hrp")},
  );

  /// Configuration for Bitcoin test net
  static final BipCoinConf bitcoinTestNet = BipCoinConf(
    coinNames: CoinsConf.bitcoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      List<int>.from([0x04, 0x5f, 0x1c, 0xf6]),
      List<int>.from([0x04, 0x5f, 0x18, 0xbc]),
    ),
    wifNetVer: CoinsConf.bitcoinTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addrParams: {"hrp": CoinsConf.bitcoinTestNet.getParam("p2wpkh_hrp")},
    addressEncoder: ([dynamic kwargs]) => P2WPKHAddrEncoder(),
  );

  /// Configuration for Litecoin main net
  static final BipCoinConf litecoinMainNet = BipCoinConf(
    coinNames: CoinsConf.litecoinMainNet.coinName,
    coinIdx: Slip44.litecoin,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip84BtcKeyNetVer,
    wifNetVer: CoinsConf.litecoinMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addrParams: {"hrp": CoinsConf.litecoinMainNet.getParam("p2wpkh_hrp")},
    addressEncoder: ([dynamic kwargs]) => P2WPKHAddrEncoder(),
  );

  /// Configuration for Litecoin test net
  static final BipCoinConf litecoinTestNet = BipCoinConf(
    coinNames: CoinsConf.litecoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      List<int>.from([0x04, 0x36, 0xf6, 0xe1]),
      List<int>.from([0x04, 0x36, 0xef, 0x7d]),
    ),
    wifNetVer: CoinsConf.litecoinTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addrParams: {"hrp": CoinsConf.litecoinTestNet.getParam("p2wpkh_hrp")},
    addressEncoder: ([dynamic kwargs]) => P2WPKHAddrEncoder(),
  );
}
