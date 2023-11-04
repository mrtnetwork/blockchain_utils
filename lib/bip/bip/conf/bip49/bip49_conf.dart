/// Bitcoin key net version for main net (ypub / yprv)

import 'package:blockchain_utils/bip/address/p2sh_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_bitcoin_cash_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_litecoin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

import '../bip_conf_const.dart';
import 'bip49_coins.dart';

/// A configuration class for BIP49 that defines the key network versions and
/// maps each supported BIP49Coin to its corresponding BipCoinConf.
class Bip49Conf {
  /// The key network version for the mainnet of Bitcoin.
  static final bip49BtcKeyNetVerMain = Bip32KeyNetVersions(
    List<int>.from([0x04, 0x9d, 0x7c, 0xb2]),
    List<int>.from([0x04, 0x9d, 0x78, 0x78]),
  );

  /// The key network version for the testnet of Bitcoin.
  static final bip49BtcKeyNetVerTest = Bip32KeyNetVersions(
    List<int>.from([0x04, 0x4a, 0x52, 0x62]),
    List<int>.from([0x04, 0x4a, 0x4e, 0x28]),
  );

  /// A mapping that associates each BIP49Coin (enum) with its corresponding
  /// BipCoinConf configuration.
  static Map<Bip49Coins, BipCoinConf> coinToConf = {
    Bip49Coins.bitcoin: Bip49Conf.bitcoinMainNet,
    Bip49Coins.bitcoinTestnet: Bip49Conf.bitcoinTestNet,
    Bip49Coins.bitcoinCash: Bip49Conf.bitcoinCashMainNet,
    Bip49Coins.bitcoinCashTestnet: Bip49Conf.bitcoinCashTestNet,
    Bip49Coins.bitcoinCashSlp: Bip49Conf.bitcoinCashSlpMainNet,
    Bip49Coins.bitcoinCashSlpTestnet: Bip49Conf.bitcoinCashSlpTestNet,
    Bip49Coins.bitcoinSv: Bip49Conf.bitcoinSvMainNet,
    Bip49Coins.bitcoinSvTestnet: Bip49Conf.bitcoinSvTestNet,
    Bip49Coins.dash: Bip49Conf.dashMainNet,
    Bip49Coins.dashTestnet: Bip49Conf.dashTestNet,
    Bip49Coins.dogecoin: Bip49Conf.dogecoinMainNet,
    Bip49Coins.dogecoinTestnet: Bip49Conf.dogecoinTestNet,
    Bip49Coins.ecash: Bip49Conf.ecashMainNet,
    Bip49Coins.ecashTestnet: Bip49Conf.ecashTestNet,
    Bip49Coins.litecoin: Bip49Conf.litecoinMainNet,
    Bip49Coins.litecoinTestnet: Bip49Conf.litecoinTestNet,
    Bip49Coins.zcash: Bip49Conf.zcashMainNet,
    Bip49Coins.zcashTestnet: Bip49Conf.zcashTestNet,
  };

  /// Retrieves the BipCoinConf for the given BIP49Coin. If the provided coin
  /// is not an instance of Bip49Coins, an error is thrown.
  static BipCoinConf getCoin(BipCoins coin) {
    if (coin is! Bip49Coins) {
      throw ArgumentError("Coin type is not an enumerative of Bip49Coins");
    }
    return coinToConf[coin.value]!;
  }

  /// Configuration for Dash main net
  static final BipCoinConf dashMainNet = BipCoinConf(
      coinNames: CoinsConf.dashMainNet.coinName,
      coinIdx: Slip44.dash,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerMain,
      wifNetVer: CoinsConf.dashMainNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.dashMainNet.getParam("p2sh_net_ver"),
      });

  /// Configuration for Dash test net
  static final BipCoinConf dashTestNet = BipCoinConf(
      coinNames: CoinsConf.dashTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerTest,
      wifNetVer: CoinsConf.dashTestNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.dashTestNet.getParam("p2sh_net_ver"),
      });

  /// Configuration for Dogecoin main net
  static final BipCoinConf dogecoinMainNet = BipCoinConf(
      coinNames: CoinsConf.dogecoinMainNet.coinName,
      coinIdx: Slip44.dogecoin,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: Bip32KeyNetVersions(
        List<int>.from([0x02, 0xfa, 0xca, 0xfd]),
        List<int>.from([0x02, 0xfa, 0xc3, 0x98]),
      ),
      wifNetVer: CoinsConf.dogecoinMainNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.dogecoinMainNet.getParam("p2sh_net_ver"),
      });

  /// Configuration for Dogecoin test net
  static final BipCoinConf dogecoinTestNet = BipCoinConf(
      coinNames: CoinsConf.dogecoinTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: Bip32KeyNetVersions(
        List<int>.from([0x04, 0x32, 0xa9, 0xa8]),
        List<int>.from([0x04, 0x32, 0xa2, 0x43]),
      ),
      wifNetVer: CoinsConf.dogecoinTestNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.dogecoinTestNet.getParam("p2sh_net_ver"),
      });

  /// Configuration for Litecoin main net
  static final BipLitecoinConf litecoinMainNet = BipLitecoinConf(
      coinNames: CoinsConf.litecoinMainNet.coinName,
      coinIdx: Slip44.litecoin,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerMain,
      altKeyNetVer: Bip32KeyNetVersions(
        List<int>.from([0x01, 0xb2, 0x6e, 0xf6]),
        List<int>.from([0x01, 0xb2, 0x67, 0x92]),
      ),

      /// Mtpv / Mtub
      wifNetVer: CoinsConf.litecoinMainNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),

      /// addrCls: P2SHAddrEncoder,
      addrParams: {
        "std_net_ver": CoinsConf.litecoinMainNet.getParam("p2sh_std_net_ver"),
        "depr_net_ver": CoinsConf.litecoinMainNet.getParam("p2sh_depr_net_ver"),
      });

  /// Configuration for Litecoin test net
  static final BipLitecoinConf litecoinTestNet = BipLitecoinConf(
      coinNames: CoinsConf.litecoinTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: Bip32KeyNetVersions(
        List<int>.from([0x04, 0x36, 0xf6, 0xe1]),
        List<int>.from([0x04, 0x36, 0xef, 0x7d]),
      ),

      /// ttub / ttpv
      altKeyNetVer: Bip32KeyNetVersions(
        List<int>.from([0x04, 0x36, 0xf6, 0xe1]),
        List<int>.from([0x04, 0x36, 0xef, 0x7d]),
      ),
      wifNetVer: CoinsConf.litecoinTestNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "std_net_ver": CoinsConf.litecoinTestNet.getParam("p2sh_std_net_ver"),
        "depr_net_ver": CoinsConf.litecoinTestNet.getParam("p2sh_depr_net_ver"),
      });

  /// Configuration for Zcash main net
  static final BipCoinConf zcashMainNet = BipCoinConf(
      coinNames: CoinsConf.zcashMainNet.coinName,
      coinIdx: Slip44.zcash,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerMain,
      wifNetVer: CoinsConf.zcashMainNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.zcashMainNet.getParam("p2sh_net_ver"),
      });

  /// Configuration for Zcash test net
  static final BipCoinConf zcashTestNet = BipCoinConf(
      coinNames: CoinsConf.zcashTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerTest,
      wifNetVer: CoinsConf.zcashTestNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),

      /// addrCls: P2SHAddrEncoder,
      addrParams: {
        "net_ver": CoinsConf.zcashTestNet.getParam("p2sh_net_ver"),
      });

  /// Configuration for Bitcoin main net
  static final BipCoinConf bitcoinMainNet = BipCoinConf(
      coinNames: CoinsConf.bitcoinMainNet.coinName,
      coinIdx: Slip44.bitcoin,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerMain,
      wifNetVer: CoinsConf.bitcoinMainNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.bitcoinMainNet.getParam("p2sh_net_ver"),
      });

  /// Configuration for Bitcoin test net
  static final BipCoinConf bitcoinTestNet = BipCoinConf(
      coinNames: CoinsConf.bitcoinTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerTest,
      wifNetVer: CoinsConf.bitcoinTestNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.bitcoinTestNet.getParam("p2sh_net_ver"),
      });

  /// Configuration for BitcoinSV main net
  static final BipCoinConf bitcoinSvMainNet = BipCoinConf(
      coinNames: CoinsConf.bitcoinSvMainNet.coinName,
      coinIdx: Slip44.bitcoinSv,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerMain,
      wifNetVer: CoinsConf.bitcoinSvMainNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.bitcoinSvMainNet.getParam("p2sh_net_ver"),
      });

  /// Configuration for BitcoinSV test net
  static final BipCoinConf bitcoinSvTestNet = BipCoinConf(
      coinNames: CoinsConf.bitcoinSvTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerTest,
      wifNetVer: CoinsConf.bitcoinSvTestNet.getParam("wif_net_ver"),
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.bitcoinSvTestNet.getParam("p2sh_net_ver"),
      });

  /// with lagacy
  /// Configuration for Bitcoin Cash main net
  static final BipBitcoinCashConf bitcoinCashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinCashMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    addrParams: {
      'std': {
        "net_ver": CoinsConf.bitcoinCashMainNet.getParam("p2sh_std_net_ver"),
        'hrp': CoinsConf.bitcoinCashMainNet.getParam("p2sh_std_hrp"),
      },
      'legacy': {
        "net_ver": CoinsConf.bitcoinCashMainNet.getParam("p2sh_legacy_net_ver"),
      },
    },
  );

  /// Configuration for Bitcoin Cash test net
  static final BipBitcoinCashConf bitcoinCashTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    keyNetVer: bip49BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinCashTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addrParams: {
      'std': {
        "net_ver": CoinsConf.bitcoinCashTestNet.getParam("p2sh_std_net_ver"),
        'hrp': CoinsConf.bitcoinCashTestNet.getParam("p2sh_std_hrp"),
      },
      'legacy': {
        "net_ver": CoinsConf.bitcoinCashTestNet.getParam("p2sh_legacy_net_ver"),
      },
    },
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol main net
  static final BipBitcoinCashConf bitcoinCashSlpMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashSlpMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinCashSlpMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    addrParams: {
      'std': {
        "net_ver": CoinsConf.bitcoinCashSlpMainNet.getParam("p2sh_std_net_ver"),
        'hrp': CoinsConf.bitcoinCashSlpMainNet.getParam("p2sh_std_hrp"),
      },
      'legacy': {
        "net_ver":
            CoinsConf.bitcoinCashSlpMainNet.getParam("p2sh_legacy_net_ver"),
      },
    },
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol test net
  static final BipBitcoinCashConf bitcoinCashSlpTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashSlpTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinCashSlpTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    addrParams: {
      'std': {
        "net_ver": CoinsConf.bitcoinCashSlpTestNet.getParam("p2sh_std_net_ver"),
        'hrp': CoinsConf.bitcoinCashSlpTestNet.getParam("p2sh_std_hrp"),
      },
      'legacy': {
        "net_ver":
            CoinsConf.bitcoinCashSlpTestNet.getParam("p2sh_legacy_net_ver"),
      },
    },

    /// addrClsLegacy: P2SHAddrEncoder,
  );

  /// Configuration for eCash main net
  static final BipBitcoinCashConf ecashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.ecashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.ecashMainNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    addrParams: {
      'std': {
        "net_ver": CoinsConf.ecashMainNet.getParam("p2sh_std_net_ver"),
        'hrp': CoinsConf.ecashMainNet.getParam("p2sh_std_hrp"),
      },
      'legacy': {
        "net_ver": CoinsConf.ecashMainNet.getParam("p2sh_legacy_net_ver"),
      },
    },
  );

  /// Configuration for eCash test net
  static final BipBitcoinCashConf ecashTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.ecashTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerTest,
    wifNetVer: CoinsConf.ecashTestNet.getParam("wif_net_ver"),
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    addrParams: {
      'std': {
        "net_ver": CoinsConf.ecashTestNet.getParam("p2sh_std_net_ver"),
        'hrp': CoinsConf.ecashTestNet.getParam("p2sh_std_hrp"),
      },
      'legacy': {
        "net_ver": CoinsConf.ecashTestNet.getParam("p2sh_legacy_net_ver"),
      },
    },
  );
}
