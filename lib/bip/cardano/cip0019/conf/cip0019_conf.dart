import 'package:blockchain_utils/bip/address/ada/ada_byron_addr.dart';
import 'package:blockchain_utils/bip/address/ada/network.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/models/coins_name.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/slip/slip44/slip44.dart';

/// A configuration class for CIP1852 coins that defines the
class Cip0019Conf {
  final BipCoinConfig byronLegacy = BipCoinConfig(
    coinNames: const CoinNames("Byron legacy", "ADA"),
    coinIdx: 0,
    chainType: ChainType.mainnet,
    defPath: "0/0",
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder:
        (params, config) => AdaByronLegacyAddrEncoder().encodeKey(
          params.pubKey,
          chainCode: params.chainCode,
          hdPathKey: params.hdPathKey,
          path: params.path,
        ),
  );
  final BipCoinConfig byronLegacyTestnet = BipCoinConfig(
    coinNames: const CoinNames("Byron legacy testnet", "ADA"),
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: "0/0",
    keyNetVer: Bip32Const.kholawKeyNetVersions,
    wifNetVer: null,
    type: EllipticCurveTypes.ed25519Kholaw,
    addressEncoder:
        (params, config) => AdaByronLegacyAddrEncoder().encodeKey(
          params.pubKey,
          chainCode: params.chainCode,
          hdPathKey: params.hdPathKey,
          path: params.path,
          network: ADANetwork.testnet,
        ),
  );
}
