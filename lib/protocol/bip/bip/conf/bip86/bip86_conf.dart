import 'package:blockchain_utils/chain/address/protocol/p2tr_addr.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/const/bip_conf_const.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/slip/slip44/slip44.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/hw/hw_variant_support_data.dart';

/// A configuration class for BIP86 that defines the key network versions and
/// maps each supported BIP86Coin to its corresponding BipCoinConfig.
class Bip86Conf {
  /// The key network version for the mainnet of Bitcoin.
  static const bip86BtcKeyNetVer = Bip32Const.mainNetKeyNetVersions;

  /// The key network version for the testnet of Bitcoin.
  static const bip86BtcKeyNetVerTest = Bip32Const.testNetKeyNetVersions;

  /// Configuration for Bitcoin main net
  final BipCoinConfig bitcoinMainNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinMainNet.coinName,
    coinIdx: Slip44.bitcoin,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: bip86BtcKeyNetVer,
    wifNetVer: CoinsConf.bitcoinMainNet.params.wifNetVer,
    addressEncoder:
        (params, config) => P2TRAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.bitcoinMainNet.params.p2trHrp,
        ),
    type: CryptoKeyType.secp256k1,
    hwSupport: HwVariants.bitcoinP2tr,
  );

  /// Configuration for Bitcoin test net
  final BipCoinConfig bitcoinTestNet = BipCoinConfig(
    coinNames: CoinsConf.bitcoinTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    addressEncoder:
        (params, config) => P2TRAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.bitcoinTestNet.params.p2trHrp,
        ),
    keyNetVer: bip86BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinTestNet.params.wifNetVer,
    type: CryptoKeyType.secp256k1,
    hwSupport: HwVariants.bitcoinP2tr,
  );

  final BipCoinConfig bitcoinRegtest = BipCoinConfig(
    coinNames: CoinsConf.bitcoinRegtest.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    addressEncoder:
        (params, config) => P2TRAddrEncoder().encodeKey(
          params.pubKey,
          hrp: CoinsConf.bitcoinRegtest.params.p2trHrp,
        ),
    keyNetVer: bip86BtcKeyNetVerTest,
    wifNetVer: CoinsConf.bitcoinRegtest.params.wifNetVer,
    type: CryptoKeyType.secp256k1,
    hwSupport: HwVariants.bitcoinP2tr,
  );
}
