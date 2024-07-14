import 'package:blockchain_utils/bip/address/ada/ada_shelley_addr.dart';
import 'package:blockchain_utils/bip/address/ada/network.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/const/bip_conf_const.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

/// A configuration class for CIP1852 coins that defines the
class Cip1852Conf {
  // Configuration for Cardano main net (Icarus)
  static final BipCoinConfig cardanoIcarusMainNet = BipCoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    addressEncoder: ([dynamic kwargs]) => AdaShelleyAddrEncoder(),
    type: EllipticCurveTypes.ed25519Kholaw,
    addrParams: {
      "net_tag": ADANetwork.mainnet,
      "is_icarus": true,
    },
  );

  // Configuration for Cardano test net (Icarus)
  static final BipCoinConfig cardanoIcarusTestNet = BipCoinConfig(
    coinNames: CoinsConf.cardanoTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.testNetKeyNetVersions,
    wifNetVer: null,
    addressEncoder: ([dynamic kwargs]) => AdaShelleyAddrEncoder(),
    type: EllipticCurveTypes.ed25519Kholaw,
    addrParams: {
      "net_tag": ADANetwork.testnetPreview,
      "is_icarus": true,
    },
  );

  // Configuration for Cardano main net (Ledger)
  static final BipCoinConfig cardanoLedgerMainNet = BipCoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    isTestnet: false,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder: ([dynamic kwargs]) => AdaShelleyAddrEncoder(),
    addrParams: {"net_tag": ADANetwork.mainnet},
  );

  // Configuration for Cardano test net (Ledger)
  static final BipCoinConfig cardanoLedgerTestNet = BipCoinConfig(
    coinNames: CoinsConf.cardanoTestNet.coinName,
    coinIdx: Slip44.testnet,
    isTestnet: true,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.testNetKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder: ([dynamic kwargs]) => AdaShelleyAddrEncoder(),
    addrParams: {"net_tag": ADANetwork.testnetPreview},
  );
}
