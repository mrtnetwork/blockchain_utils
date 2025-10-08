import 'package:blockchain_utils/bip/address/p2wpkh_addr.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/const/bip_conf_const.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

/// A configuration class for BIP84 that defines the key network versions and
/// maps each supported BIP84Coin to its corresponding BipCoinConfig.
class Bip84Conf {
  /// The key network version for Bitcoin.
  static final Bip32KeyNetVersions bip84BtcKeyNetVer = Bip32KeyNetVersions(
    List<int>.from([0x04, 0xb2, 0x47, 0x46]),
    List<int>.from([0x04, 0xb2, 0x43, 0x0c]),
  );

  /// Configuration for Bitcoin main net
  static final BipCoinConfig bitcoinMainNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinMainNet.coinName,
    coinIdx: Slip44.bitcoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip84BtcKeyNetVer,
    wifNetVer: CoinsConf.bitcoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2WPKHAddrEncoder(),
    addrParams: {"hrp": CoinsConf.bitcoinMainNet.params.p2wpkhHrp},
  );

  /// Configuration for Bitcoin test net
  static final BipCoinConfig bitcoinTestNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      List<int>.from([0x04, 0x5f, 0x1c, 0xf6]),
      List<int>.from([0x04, 0x5f, 0x18, 0xbc]),
    ),
    wifNetVer: CoinsConf.bitcoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addrParams: {"hrp": CoinsConf.bitcoinTestNet.params.p2wpkhHrp!},
    addressEncoder: ([dynamic kwargs]) => P2WPKHAddrEncoder(),
  );

  /// Configuration for Litecoin main net
  static final BipCoinConfig litecoinMainNet = BipCoinConfig(
    coinNames: CoinsConf.litecoinMainNet.coinName,
    coinIdx: Slip44.litecoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip84BtcKeyNetVer,
    wifNetVer: CoinsConf.litecoinMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addrParams: {"hrp": CoinsConf.litecoinMainNet.params.p2wpkhHrp!},
    addressEncoder: ([dynamic kwargs]) => P2WPKHAddrEncoder(),
  );

  /// Configuration for Litecoin test net
  static final BipCoinConfig litecoinTestNet = BipCoinConfig(
    coinNames: CoinsConf.litecoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      List<int>.from([0x04, 0x36, 0xf6, 0xe1]),
      List<int>.from([0x04, 0x36, 0xef, 0x7d]),
    ),
    wifNetVer: CoinsConf.litecoinTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addrParams: {"hrp": CoinsConf.litecoinTestNet.params.p2wpkhHrp!},
    addressEncoder: ([dynamic kwargs]) => P2WPKHAddrEncoder(),
  );

  /// Configuration for Electra Protocol main net
  static final BipCoinConfig electraProtocolMainNet = BipCoinConfig(
    coinNames: CoinsConf.electraProtocolMainNet.coinName,
    coinIdx: Slip44.electraProtocol,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      List<int>.from([0x04, 0x88, 0xb2, 0x1e]),
      List<int>.from([0x04, 0x88, 0xad, 0xe4]),
    ),
    wifNetVer: CoinsConf.electraProtocolMainNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2WPKHAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.electraProtocolMainNet.params.p2wpkhHrp!,
    },
  );

  /// Configuration for Electra Protocol test net
  static final BipCoinConfig electraProtocolTestNet = BipCoinConfig(
    coinNames: CoinsConf.electraProtocolTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32KeyNetVersions(
      List<int>.from([0x04, 0x35, 0x87, 0xcf]),
      List<int>.from([0x04, 0x35, 0x83, 0x94]),
    ),
    wifNetVer: CoinsConf.electraProtocolTestNet.params.wifNetVer,
    type: EllipticCurveTypes.secp256k1,
    addressEncoder: ([dynamic kwargs]) => P2WPKHAddrEncoder(),
    addrParams: {
      "hrp": CoinsConf.electraProtocolMainNet.params.p2wpkhHrp!,
    },
  );
}
