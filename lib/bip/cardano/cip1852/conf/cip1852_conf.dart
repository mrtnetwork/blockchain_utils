import 'package:blockchain_utils/bip/address/exception/exception.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/const/bip_conf_const.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

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
            throw AddressConverterException(
              "Address derivation is not supported using coinConfig. Please use the CardanoShelley class instead.",
            ),
    type: EllipticCurveTypes.ed25519Kholaw,
    defaultHdKeyDerivator: DefaultHdKeyDerivator.icarus,
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
            throw AddressConverterException(
              "Address derivation is not supported using coinConfig. Please use the CardanoShelley class instead.",
            ),
    type: EllipticCurveTypes.ed25519Kholaw,
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
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder:
        (params, config) =>
            throw AddressConverterException(
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
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder:
        (params, config) =>
            throw AddressConverterException(
              "Address derivation is not supported using coinConfig. Please use the CardanoShelley class instead.",
            ),
  );
}
