import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/const/bip_conf_const.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/slip/slip44/slip44.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/hw/hw_variant_support_data.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A configuration class for CIP1852 coins that defines the
class Cip1852Conf {
  // Configuration for Cardano main net (Icarus)
  final BipCoinConfig cardanoIcarusMainNet = BipCoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    addressEncoder:
        (params, config) =>
            throw BuError(
              DefaultErrorType.unsupported,
              "Address derivation is not supported using coinConfig. Please use the CardanoShelley class instead.",
            ),
    type: CryptoKeyType.ed25519Kholaw,
    defaultHdKeyDerivator: DefaultHdKeyDerivator.icarus,
    hwSupport: HwVariants.cardano,
  );

  // Configuration for Cardano test net (Icarus)
  final BipCoinConfig cardanoIcarusTestNet = BipCoinConfig(
    coinNames: CoinsConf.cardanoTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.testNetKeyNetVersions,
    wifNetVer: null,
    addressEncoder:
        (params, config) =>
            throw BuError(
              DefaultErrorType.unsupported,
              "Address derivation is not supported using coinConfig. Please use the CardanoShelley class instead.",
            ),
    type: CryptoKeyType.ed25519Kholaw,
    defaultHdKeyDerivator: DefaultHdKeyDerivator.icarus,
  );

  // Configuration for Cardano main net (Ledger)
  final BipCoinConfig cardanoLedgerMainNet = BipCoinConfig(
    coinNames: CoinsConf.cardanoMainNet.coinName,
    coinIdx: Slip44.cardano,
    chainType: ChainType.mainnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: CryptoKeyType.ed25519Kholaw,
    addressEncoder:
        (params, config) =>
            throw BuError(
              DefaultErrorType.unsupported,
              "Address derivation is not supported using coinConfig. Please use the CardanoShelley class instead.",
            ),
  );

  // Configuration for Cardano test net (Ledger)
  final BipCoinConfig cardanoLedgerTestNet = BipCoinConfig(
    coinNames: CoinsConf.cardanoTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathNonHardenedFull,
    keyNetVer: Bip32Const.testNetKeyNetVersions,
    wifNetVer: null,
    type: CryptoKeyType.ed25519Kholaw,
    addressEncoder:
        (params, config) =>
            throw BuError(
              DefaultErrorType.unsupported,
              "Address derivation is not supported using coinConfig. Please use the CardanoShelley class instead.",
            ),
  );
}
