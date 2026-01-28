import 'package:blockchain_utils/bip/address/p2sh_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/const/bip_conf_const.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_bitcoin_cash_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_litecoin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

/// A configuration class for BIP49 that defines the key network versions and
/// maps each supported BIP49Coin to its corresponding BipCoinConfig.
class Bip49Conf {
  /// The key network version for the mainnet of Bitcoin.
  static const bip49BtcKeyNetVerMain = Bip32KeyNetVersions.unsafe(
    [0x04, 0x9d, 0x7c, 0xb2],
    [0x04, 0x9d, 0x78, 0x78],
  );

  /// The key network version for the testnet of Bitcoin.
  static const bip49BtcKeyNetVerTest = Bip32KeyNetVersions.unsafe(
    [0x04, 0x4a, 0x52, 0x62],
    [0x04, 0x4a, 0x4e, 0x28],
  );

  /// Configuration for Dash main net
  final BipCoinConfig dashMainNet = BipCoinConfig(
    coinNames: CoinsConf.dashMainNet.coinName,
    coinIdx: Slip44.dash,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.dashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.dashMainNet.params.p2shNetVer,
        ),
  );

  /// Configuration for Dash test net
  final BipCoinConfig dashTestNet = BipCoinConfig(
    coinNames: CoinsConf.dashTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerTest,
    wifNetVer: CoinsConf.dashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.dashTestNet.params.p2shNetVer,
        ),
  );

  /// Configuration for Dogecoin main net
  final BipCoinConfig dogecoinMainNet = BipCoinConfig(
    coinNames: CoinsConf.dogecoinMainNet.coinName,
    coinIdx: Slip44.dogecoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x02, 0xfa, 0xca, 0xfd],
      [0x02, 0xfa, 0xc3, 0x98],
    ),
    wifNetVer: CoinsConf.dogecoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.dogecoinMainNet.params.p2shNetVer,
        ),
  );

  /// Configuration for Dogecoin test net
  final BipCoinConfig dogecoinTestNet = BipCoinConfig(
    coinNames: CoinsConf.dogecoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x04, 0x32, 0xa9, 0xa8],
      [0x04, 0x32, 0xa2, 0x43],
    ),
    wifNetVer: CoinsConf.dogecoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.dogecoinTestNet.params.p2shNetVer,
        ),
  );

  /// Configuration for Litecoin main net
  final BipLitecoinConf litecoinMainNet = BipLitecoinConf(
    coinNames: CoinsConf.litecoinMainNet.coinName,
    coinIdx: Slip44.litecoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    altKeyNetVer: Bip32KeyNetVersions(
      [0x01, 0xb2, 0x6e, 0xf6],
      [0x01, 0xb2, 0x67, 0x92],
    ),

    /// Mtpv / Mtub
    wifNetVer: CoinsConf.litecoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: switch (config.useDeprAddress) {
            false => CoinsConf.litecoinMainNet.params.p2shStdNetVer,
            true => CoinsConf.litecoinMainNet.params.p2shDeprNetVer,
          },
        ),
  );

  /// Configuration for Litecoin test net
  final BipLitecoinConf litecoinTestNet = BipLitecoinConf(
    coinNames: CoinsConf.litecoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x04, 0x36, 0xf6, 0xe1],
      [0x04, 0x36, 0xef, 0x7d],
    ),

    /// ttub / ttpv
    altKeyNetVer: Bip32KeyNetVersions(
      [0x04, 0x36, 0xf6, 0xe1],
      [0x04, 0x36, 0xef, 0x7d],
    ),
    wifNetVer: CoinsConf.litecoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: switch (config.useDeprAddress) {
            false => CoinsConf.litecoinTestNet.params.p2shStdNetVer,
            true => CoinsConf.litecoinTestNet.params.p2shDeprNetVer,
          },
        ),
  );

  /// Configuration for Zcash main net
  final BipCoinConfig zcashMainNet = BipCoinConfig(
    coinNames: CoinsConf.zcashTransparentMainNet.coinName,
    coinIdx: Slip44.zcash,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.zcashTransparentMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.zcashTransparentMainNet.params.p2shNetVer,
        ),
  );

  /// Configuration for Zcash test net
  final BipCoinConfig zcashTestNet = BipCoinConfig(
    coinNames: CoinsConf.zcashTransparentTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerTest,
    wifNetVer: CoinsConf.zcashTransparentTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.zcashTransparentTestNet.params.p2shNetVer,
        ),
  );

  /// Configuration for Bitcoin main net
  final BipCoinConfig bitcoinMainNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinMainNet.coinName,
    coinIdx: Slip44.bitcoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinMainNet.params.p2shNetVer,
        ),
  );

  /// Configuration for Bitcoin test net
  final BipCoinConfig bitcoinTestNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinTestNet.params.p2shNetVer,
        ),
  );

  /// Configuration for BitcoinSV main net
  final BipCoinConfig bitcoinSvMainNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinSvMainNet.coinName,
    coinIdx: Slip44.bitcoinSv,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinSvMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinSvMainNet.params.p2shNetVer,
        ),
  );

  /// Configuration for BitcoinSV test net
  final BipCoinConfig bitcoinSvTestNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinSvTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinSvTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinSvTestNet.params.p2shNetVer,
        ),
  );

  /// with lagacy
  /// Configuration for Bitcoin Cash main net
  final BipBitcoinCashConf bitcoinCashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinCashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinCashMainNet.params.p2shLegacyNetVer,
        );
      }
      return BchP2SHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.bitcoinCashMainNet.params.p2shStdHrp,
        netVersion: CoinsConf.bitcoinCashMainNet.params.p2shStdNetVer,
      );
    },
  );

  /// Configuration for Bitcoin Cash test net
  final BipBitcoinCashConf bitcoinCashTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinCashTestNet.params.p2shLegacyNetVer,
        );
      }
      return BchP2SHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.bitcoinCashTestNet.params.p2shStdHrp,
        netVersion: CoinsConf.bitcoinCashTestNet.params.p2shStdNetVer,
      );
    },
    keyNetVer: bip49BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinCashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol main net
  final BipBitcoinCashConf bitcoinCashSlpMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashSlpMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.bitcoinCashSlpMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinCashSlpMainNet.params.p2shLegacyNetVer,
        );
      }
      return BchP2SHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.bitcoinCashSlpMainNet.params.p2shStdHrp,
        netVersion: CoinsConf.bitcoinCashSlpMainNet.params.p2shStdNetVer,
      );
    },
  );

  /// Configuration for Bitcoin Cash Simple Ledger Protocol test net
  final BipBitcoinCashConf bitcoinCashSlpTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.bitcoinCashSlpTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinCashSlpTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.bitcoinCashSlpTestNet.params.p2shLegacyNetVer,
        );
      }
      return BchP2SHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.bitcoinCashSlpTestNet.params.p2shStdHrp,
        netVersion: CoinsConf.bitcoinCashSlpTestNet.params.p2shStdNetVer,
      );
    },

    /// addrClsLegacy: P2SHAddrEncoder,
  );

  /// Configuration for eCash main net
  final BipBitcoinCashConf ecashMainNet = BipBitcoinCashConf(
    coinNames: CoinsConf.ecashMainNet.coinName,
    coinIdx: Slip44.bitcoinCash,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerMain,
    wifNetVer: CoinsConf.ecashMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.ecashMainNet.params.p2shLegacyNetVer,
        );
      }
      return BchP2SHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.ecashMainNet.params.p2shStdHrp,
        netVersion: CoinsConf.ecashMainNet.params.p2shStdNetVer,
      );
    },
  );

  /// Configuration for eCash test net
  final BipBitcoinCashConf ecashTestNet = BipBitcoinCashConf(
    coinNames: CoinsConf.ecashTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip49BtcKeyNetVerTest,
    wifNetVer: CoinsConf.ecashTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: (params, config) {
      if (config.useLagacyAdder) {
        return P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.ecashTestNet.params.p2shLegacyNetVer,
        );
      }
      return BchP2SHAddrEncoder().encodeKey(
        params.pubKey,
        hrp: CoinsConf.ecashTestNet.params.p2shStdHrp,
        netVersion: CoinsConf.ecashTestNet.params.p2shStdNetVer,
      );
    },
  );

  /// Configuration for pepecoin main net
  final BipCoinConfig pepeMainnet = BipCoinConfig(
    coinNames: CoinsConf.pepeMainnet.coinName,
    coinIdx: Slip44.pepecoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x02, 0xfa, 0xca, 0xfd],
      [0x02, 0xfa, 0xc3, 0x98],
    ),
    wifNetVer: CoinsConf.pepeMainnet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.pepeMainnet.params.p2shNetVer,
        ),
  );

  /// Configuration for pepecoin test net
  final BipCoinConfig pepeTestnet = BipCoinConfig(
    coinNames: CoinsConf.pepeTestnet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x04, 0x32, 0xa9, 0xa8],
      [0x04, 0x32, 0xa2, 0x43],
    ),
    wifNetVer: CoinsConf.pepeTestnet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.pepeTestnet.params.p2shNetVer,
        ),
  );

  /// Configuration for Electra Protocol main net
  final BipCoinConfig electraProtocolMainNet = BipCoinConfig(
    coinNames: CoinsConf.electraProtocolMainNet.coinName,
    coinIdx: Slip44.electraProtocol,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x04, 0x88, 0xb2, 0x1e],
      [0x04, 0x88, 0xad, 0xe4],
    ),
    wifNetVer: CoinsConf.electraProtocolMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.electraProtocolMainNet.params.p2shNetVer,
        ),
  );

  /// Configuration for Electra Protocol test net
  final BipCoinConfig electraProtocolTestNet = BipCoinConfig(
    coinNames: CoinsConf.electraProtocolTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      [0x04, 0x35, 0x87, 0xcf],
      [0x04, 0x35, 0x83, 0x94],
    ),
    wifNetVer: CoinsConf.electraProtocolTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder:
        (params, config) => P2SHAddrEncoder().encodeKey(
          params.pubKey,
          netVersion: CoinsConf.electraProtocolTestNet.params.p2shNetVer,
        ),
  );
}
