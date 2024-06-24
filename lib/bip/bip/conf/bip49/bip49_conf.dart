import 'package:blockchain_utils/bip/address/p2sh_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_bitcoin_cash_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_litecoin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

import '../bip_conf_const.dart';

/// A configuration class for BIP49 that defines the key network versions and
/// maps each supported BIP49Coin to its corresponding CoinConfig.
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

  /// Configuration for Dash main net
  static final CoinConfig dashMainNet = CoinConfig(
      coinNames: CoinsConf.dashMainNet.coinName,
      coinIdx: Slip44.dash,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerMain,
      wifNetVer: CoinsConf.dashMainNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.dashMainNet.params.p2shNetVer!,
      });

  /// Configuration for Dash test net
  static final CoinConfig dashTestNet = CoinConfig(
      coinNames: CoinsConf.dashTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerTest,
      wifNetVer: CoinsConf.dashTestNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.dashTestNet.params.p2shNetVer,
      });

  /// Configuration for Dogecoin main net
  static final CoinConfig dogecoinMainNet = CoinConfig(
      coinNames: CoinsConf.dogecoinMainNet.coinName,
      coinIdx: Slip44.dogecoin,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: Bip32KeyNetVersions(
        List<int>.from([0x02, 0xfa, 0xca, 0xfd]),
        List<int>.from([0x02, 0xfa, 0xc3, 0x98]),
      ),
      wifNetVer: CoinsConf.dogecoinMainNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.dogecoinMainNet.params.p2shNetVer!,
      });

  /// Configuration for Dogecoin test net
  static final CoinConfig dogecoinTestNet = CoinConfig(
      coinNames: CoinsConf.dogecoinTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: Bip32KeyNetVersions(
        List<int>.from([0x04, 0x32, 0xa9, 0xa8]),
        List<int>.from([0x04, 0x32, 0xa2, 0x43]),
      ),
      wifNetVer: CoinsConf.dogecoinTestNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.dogecoinTestNet.params.p2shNetVer!,
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
      wifNetVer: CoinsConf.litecoinMainNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),

      /// addrCls: P2SHAddrEncoder,
      addrParams: {
        "std_net_ver": CoinsConf.litecoinMainNet.params.p2shStdNetVer,
        "depr_net_ver": CoinsConf.litecoinMainNet.params.p2shDeprNetVer,
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
      wifNetVer: CoinsConf.litecoinTestNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "std_net_ver": CoinsConf.litecoinTestNet.params.p2shStdNetVer!,
        "depr_net_ver": CoinsConf.litecoinTestNet.params.p2shDeprNetVer!,
      });

  /// Configuration for Zcash main net
  static final CoinConfig zcashMainNet = CoinConfig(
      coinNames: CoinsConf.zcashMainNet.coinName,
      coinIdx: Slip44.zcash,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerMain,
      wifNetVer: CoinsConf.zcashMainNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.zcashMainNet.params.p2shNetVer!,
      });

  /// Configuration for Zcash test net
  static final CoinConfig zcashTestNet = CoinConfig(
      coinNames: CoinsConf.zcashTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerTest,
      wifNetVer: CoinsConf.zcashTestNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),

      /// addrCls: P2SHAddrEncoder,
      addrParams: {
        "net_ver": CoinsConf.zcashTestNet.params.p2shNetVer!,
      });

  /// Configuration for Bitcoin main net
  static final CoinConfig bitcoinMainNet = CoinConfig(
      coinNames: CoinsConf.bitcoinMainNet.coinName,
      coinIdx: Slip44.bitcoin,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerMain,
      wifNetVer: CoinsConf.bitcoinMainNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.bitcoinMainNet.params.p2shNetVer!,
      });

  /// Configuration for Bitcoin test net
  static final CoinConfig bitcoinTestNet = CoinConfig(
      coinNames: CoinsConf.bitcoinTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerTest,
      wifNetVer: CoinsConf.bitcoinTestNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.bitcoinTestNet.params.p2shNetVer!,
      });

  /// Configuration for BitcoinSV main net
  static final CoinConfig bitcoinSvMainNet = CoinConfig(
      coinNames: CoinsConf.bitcoinSvMainNet.coinName,
      coinIdx: Slip44.bitcoinSv,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerMain,
      wifNetVer: CoinsConf.bitcoinSvMainNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.bitcoinSvMainNet.params.p2shNetVer!,
      });

  /// Configuration for BitcoinSV test net
  static final CoinConfig bitcoinSvTestNet = CoinConfig(
      coinNames: CoinsConf.bitcoinSvTestNet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: bip49BtcKeyNetVerTest,
      wifNetVer: CoinsConf.bitcoinSvTestNet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.bitcoinSvTestNet.params.p2shNetVer!,
      });

  /// with lagacy
  /// Configuration for Bitcoin Cash main net
  static final BipBitcoinCashConf bitcoinCashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinCashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    addrParams: {
      'std': {
        "net_ver": CoinsConf.bitcoinCashMainNet.params.p2shStdNetVer!,
        'hrp': CoinsConf.bitcoinCashMainNet.params.p2shStdHrp,
      },
      'legacy': {
        "net_ver": CoinsConf.bitcoinCashMainNet.params.p2shLegacyNetVer,
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
    wifNetVer: CoinsConf.bitcoinCashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addrParams: {
      'std': {
        "net_ver": CoinsConf.bitcoinCashTestNet.params.p2shStdNetVer!,
        'hrp': CoinsConf.bitcoinCashTestNet.params.p2shStdHrp!,
      },
      'legacy': {
        "net_ver": CoinsConf.bitcoinCashTestNet.params.p2shLegacyNetVer!,
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
    wifNetVer: CoinsConf.bitcoinCashSlpMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    addrParams: {
      'std': {
        "net_ver": CoinsConf.bitcoinCashSlpMainNet.params.p2shStdNetVer!,
        'hrp': CoinsConf.bitcoinCashSlpMainNet.params.p2shStdHrp!,
      },
      'legacy': {
        "net_ver": CoinsConf.bitcoinCashSlpMainNet.params.p2shLegacyNetVer!,
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
    wifNetVer: CoinsConf.bitcoinCashSlpTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    addrParams: {
      'std': {
        "net_ver": CoinsConf.bitcoinCashSlpTestNet.params.p2shStdNetVer!,
        'hrp': CoinsConf.bitcoinCashSlpTestNet.params.p2shStdHrp!,
      },
      'legacy': {
        "net_ver": CoinsConf.bitcoinCashSlpTestNet.params.p2shLegacyNetVer!,
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
    wifNetVer: CoinsConf.ecashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    addrParams: {
      'std': {
        "net_ver": CoinsConf.ecashMainNet.params.p2shStdNetVer!,
        'hrp': CoinsConf.ecashMainNet.params.p2shStdHrp!,
      },
      'legacy': {
        "net_ver": CoinsConf.ecashMainNet.params.p2shLegacyNetVer!,
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
    wifNetVer: CoinsConf.ecashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic legacy]) {
      if (legacy == true) {
        return P2SHAddrEncoder();
      }
      return BchP2SHAddrEncoder();
    },
    addrParams: {
      'std': {
        "net_ver": CoinsConf.ecashTestNet.params.p2shStdNetVer!,
        'hrp': CoinsConf.ecashTestNet.params.p2shStdHrp!,
      },
      'legacy': {
        "net_ver": CoinsConf.ecashTestNet.params.p2shLegacyNetVer!,
      },
    },
  );

  /// Configuration for pepecoin main net
  static final CoinConfig pepeMainnet = CoinConfig(
      coinNames: CoinsConf.pepeMainnet.coinName,
      coinIdx: Slip44.pepecoin,
      isTestnet: false,
      defPath: derPathNonHardenedFull,
      keyNetVer: Bip32KeyNetVersions(
        List<int>.from([0x02, 0xfa, 0xca, 0xfd]),
        List<int>.from([0x02, 0xfa, 0xc3, 0x98]),
      ),
      wifNetVer: CoinsConf.pepeMainnet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.pepeMainnet.params.p2shNetVer!,
      });

  /// Configuration for pepecoin test net
  static final CoinConfig pepeTestnet = CoinConfig(
      coinNames: CoinsConf.pepeTestnet.coinName,
      coinIdx: Slip44.testnet,
      isTestnet: true,
      defPath: derPathNonHardenedFull,
      keyNetVer: Bip32KeyNetVersions(
        List<int>.from([0x04, 0x32, 0xa9, 0xa8]),
        List<int>.from([0x04, 0x32, 0xa2, 0x43]),
      ),
      wifNetVer: CoinsConf.pepeTestnet.params.wifNetVer,
      type: EllipticCurveTypes.secp256k1,
      addressEncoder: ([dynamic kwargs]) => P2SHAddrEncoder(),
      addrParams: {
        "net_ver": CoinsConf.pepeTestnet.params.p2shNetVer!,
      });
}
