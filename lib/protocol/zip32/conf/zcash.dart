import 'package:blockchain_utils/chain/address/neworks/zcash/src/converter.dart';
import 'package:blockchain_utils/chain/address/neworks/zcash/src/types.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_const.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/const/bip_conf_const.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/protocol/zip32/conf/config.dart';
import 'package:blockchain_utils/protocol/bip/coin_conf/constant/coins_conf.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/slip/slip.dart';
import 'package:blockchain_utils/protocol/zcash/src/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class ZcashConf {
  final ZIP32CoinConfig zCashMainnetSapling = ZIP32CoinConfig(
    coinNames: CoinsConf.zcashTransparentMainNet.coinName,
    coinIdx: Slip44.zcash,
    type: CryptoKeyType.redJubJubSpend,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedShort,
    network: ZcashNetwork.mainnet,
    purpose: Bip32KeyIndex.hardenIndex(32),
    keyNetVer: Bip32Const.mainNetKeyNetVersions,
    addressEncoder:
        (params, config) => ZcashAddrEncoder().encodeKey(
          params.pubKey,
          addrType: ZcashAddressType.sapling,
          network: config.network,
        ),
    hrpSaplingExtendedSpendingKey: "secret-extended-key-main",
    hrpSaplingExtendedFullViewingKey: "zxviews",
    hrpSaplingPaymentAddress: "zs",
    b58SproutAddressPrefix: [0x16, 0x9a],
    b58SecretKeyPrefix: [0x80],
    b58PubkeyAddressPrefix: [0x1c, 0xb8],
    b58ScriptAddressPrefix: [0x1c, 0xbd],
    hrpTexAddress: "tex",
    hrpUnifiedAddress: "u",
    hrpUnifiedFvk: "uview",
    hrpUnifiedIvk: "uivk",
  );

  final ZIP32CoinConfig zCashTestnetSapling = ZIP32CoinConfig(
    coinNames: CoinsConf.zcashTransparentTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathHardenedShort,
    purpose: Bip32KeyIndex.hardenIndex(32),
    type: CryptoKeyType.redJubJubSpend,
    network: ZcashNetwork.testnet,
    keyNetVer: Bip32Const.testNetKeyNetVersions,
    addressEncoder:
        (params, config) => ZcashAddrEncoder().encodeKey(
          params.pubKey,
          addrType: ZcashAddressType.sapling,
          network: config.network,
        ),
    hrpSaplingExtendedSpendingKey: "secret-extended-key-test",
    hrpSaplingExtendedFullViewingKey: "zxviewtestsapling",
    hrpSaplingPaymentAddress: "ztestsapling",
    b58SproutAddressPrefix: [0x16, 0xb6],
    b58SecretKeyPrefix: [0xef],
    b58PubkeyAddressPrefix: [0x1d, 0x25],
    b58ScriptAddressPrefix: [0x1c, 0xba],
    hrpTexAddress: "textest",
    hrpUnifiedAddress: "utest",
    hrpUnifiedFvk: "uviewtest",
    hrpUnifiedIvk: "uivktest",
  );

  final ZIP32CoinConfig zCashRegtestSapling = ZIP32CoinConfig(
    coinNames: CoinsConf.zcashTransparentRegtest.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    type: CryptoKeyType.redJubJubSpend,
    purpose: Bip32KeyIndex.hardenIndex(32),
    network: ZcashNetwork.regtest,
    defPath: derPathHardenedShort,
    keyNetVer: Bip32Const.testNetKeyNetVersions,
    addressEncoder:
        (params, config) => ZcashAddrEncoder().encodeKey(
          params.pubKey,
          addrType: ZcashAddressType.sapling,
          network: config.network,
        ),
    hrpSaplingExtendedSpendingKey: "secret-extended-key-regtest",
    hrpSaplingExtendedFullViewingKey: "zxviewregtestsapling",
    hrpSaplingPaymentAddress: "zregtestsapling",
    b58SproutAddressPrefix: [0x16, 0xb6],
    b58SecretKeyPrefix: [0xef],
    b58PubkeyAddressPrefix: [0x1d, 0x25],
    b58ScriptAddressPrefix: [0x1c, 0xba],
    hrpTexAddress: "texregtest",
    hrpUnifiedAddress: "uregtest",
    hrpUnifiedFvk: "uviewregtest",
    hrpUnifiedIvk: "uivkregtest",
  );

  final ZIP32CoinConfig zCashMainnetOrchard = ZIP32CoinConfig(
    coinNames: CoinsConf.zcashTransparentMainNet.coinName,
    coinIdx: Slip44.zcash,
    type: CryptoKeyType.redPallasSpend,
    chainType: ChainType.mainnet,
    defPath: derPathHardenedShort,
    network: ZcashNetwork.mainnet,
    purpose: Bip32KeyIndex.hardenIndex(32),
    keyNetVer: Bip32Const.mainNetKeyNetVersions,
    addressEncoder:
        (params, config) => ZcashAddrEncoder().encodeKey(
          params.pubKey,
          addrType: ZcashAddressType.unified,
          network: config.network,
        ),
    hrpSaplingExtendedSpendingKey: "secret-extended-key-main",
    hrpSaplingExtendedFullViewingKey: "zxviews",
    hrpSaplingPaymentAddress: "zs",
    b58SproutAddressPrefix: [0x16, 0x9a],
    b58SecretKeyPrefix: [0x80],
    b58PubkeyAddressPrefix: [0x1c, 0xb8],
    b58ScriptAddressPrefix: [0x1c, 0xbd],
    hrpTexAddress: "tex",
    hrpUnifiedAddress: "u",
    hrpUnifiedFvk: "uview",
    hrpUnifiedIvk: "uivk",
  );

  final ZIP32CoinConfig zCashTestnetOrchard = ZIP32CoinConfig(
    coinNames: CoinsConf.zcashTransparentTestNet.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    defPath: derPathHardenedShort,
    purpose: Bip32KeyIndex.hardenIndex(32),
    type: CryptoKeyType.redPallasSpend,
    network: ZcashNetwork.testnet,
    keyNetVer: Bip32Const.testNetKeyNetVersions,
    addressEncoder:
        (params, config) => ZcashAddrEncoder().encodeKey(
          params.pubKey,
          addrType: ZcashAddressType.unified,
          network: config.network,
        ),
    hrpSaplingExtendedSpendingKey: "secret-extended-key-test",
    hrpSaplingExtendedFullViewingKey: "zxviewtestsapling",
    hrpSaplingPaymentAddress: "ztestsapling",
    b58SproutAddressPrefix: [0x16, 0xb6],
    b58SecretKeyPrefix: [0xef],
    b58PubkeyAddressPrefix: [0x1d, 0x25],
    b58ScriptAddressPrefix: [0x1c, 0xba],
    hrpTexAddress: "textest",
    hrpUnifiedAddress: "utest",
    hrpUnifiedFvk: "uviewtest",
    hrpUnifiedIvk: "uivktest",
  );

  final ZIP32CoinConfig zCashRegtestOrchard = ZIP32CoinConfig(
    coinNames: CoinsConf.zcashTransparentRegtest.coinName,
    coinIdx: Slip44.testnet,
    chainType: ChainType.testnet,
    type: CryptoKeyType.redPallasSpend,
    purpose: Bip32KeyIndex.hardenIndex(32),
    network: ZcashNetwork.regtest,
    defPath: derPathHardenedShort,
    keyNetVer: Bip32Const.testNetKeyNetVersions,
    addressEncoder:
        (params, config) => ZcashAddrEncoder().encodeKey(
          params.pubKey,
          addrType: ZcashAddressType.unified,
          network: config.network,
        ),
    hrpSaplingExtendedSpendingKey: "secret-extended-key-regtest",
    hrpSaplingExtendedFullViewingKey: "zxviewregtestsapling",
    hrpSaplingPaymentAddress: "zregtestsapling",
    b58SproutAddressPrefix: [0x16, 0xb6],
    b58SecretKeyPrefix: [0xef],
    b58PubkeyAddressPrefix: [0x1d, 0x25],
    b58ScriptAddressPrefix: [0x1c, 0xba],
    hrpTexAddress: "texregtest",
    hrpUnifiedAddress: "uregtest",
    hrpUnifiedFvk: "uviewregtest",
    hrpUnifiedIvk: "uivkregtest",
  );

  List<ZIP32CoinConfig> get _configs => [
    zCashMainnetOrchard,
    zCashRegtestOrchard,
    zCashTestnetSapling,
  ];
  ZIP32CoinConfig fromNetwork(ZcashNetwork network) {
    return _configs.firstWhere(
      (e) => e.network == network,
      orElse: () => throw BuError(DefaultErrorType.notFound, "No matching item found for the given value. $network.name"),
    );
  }

  ZIP32CoinConfig? findFromUnifiedAddressHrp(String hrp) {
    return _configs.firstWhereNullable((e) => e.hrpUnifiedAddress == hrp);
  }

  ZIP32CoinConfig? findFromTexHrp(String hrp) {
    return _configs.firstWhereNullable((e) => e.hrpTexAddress == hrp);
  }

  ZIP32CoinConfig? findFromSaplingPaymentAddressHrp(String hrp) {
    return _configs.firstWhereNullable(
      (e) => e.hrpSaplingPaymentAddress == hrp,
    );
  }

  ZIP32CoinConfig? findFromP2pkhPrefix(List<int> prefix) {
    return _configs.firstWhereNullable(
      (e) => BytesUtils.bytesEqual(prefix, e.b58PubkeyAddressPrefix),
    );
  }

  ZIP32CoinConfig? findFromP2shPrefix(List<int> prefix) {
    return _configs.firstWhereNullable(
      (e) => BytesUtils.bytesEqual(prefix, e.b58ScriptAddressPrefix),
    );
  }

  ZIP32CoinConfig? findFromSproutPrefix(List<int> prefix) {
    return _configs.firstWhereNullable(
      (e) => BytesUtils.bytesEqual(prefix, e.b58SproutAddressPrefix),
    );
  }
}
