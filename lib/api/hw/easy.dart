import 'package:blockchain_utils/api/hw/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/api/hw/support.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Easy mode over [HwApi]: work with [CryptoCoins] (BIP44/49/84/86/…) and
/// human paths instead of raw `int` ids and `<u32 LE>` blobs.
///
/// ```dart
/// final pk = await blockchainUtils.api.hw.getPublicKey(
///   coin: Bip44Coins.ethereum, device: BuHwDevice.ledgerNanoSPlus,
///   transport: myUsb,
/// ); // m/44'/60'/0'/0/0, validated.
/// final addr = await blockchainUtils.api.hw.getAddress(
///   coin: Bip44Coins.tezos, device: BuHwDevice.trezorSafe5, transport: myUsb,
/// ); // 'tz1…'
/// ```
extension EasyHwApiX on HwApi {
  BaseBipCoinConfig _bipConf(CryptoCoins coin, String op) {
    final conf = coin.conf;
    if (conf is! BaseBipCoinConfig) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'coin',
        reason:
            '${coin.runtimeType}.${coin.coinName} is not a BIP coin '
            '(substrate/monero/zip32 have their own derivation).',
      );
    }
    return conf;
  }

  /// Connector coin id for [coin], or throws [BuError] when the
  /// coin has no HW flow (unknown SLIP44 / unsupported curve variant).
  int hwCoinIdFor(CryptoCoins coin) {
    final conf = _bipConf(coin, 'hwCoinIdFor');
    final purpose =
        Bip32KeyIndex.unhardenIndex(coin.proposal.purpose.index).index;
    final id = hwCoinIdForSlip44(
      slip44: conf.coinIdx,
      type: conf.type,
      purpose: purpose,
    );
    if (id == null) {
      throw CoreErrors.invalidOperationArguments(
        'hwCoinIdFor',
        name: 'coin',
        reason:
            '${coin.runtimeType}.${coin.coinName} '
            '(slip44=${conf.coinIdx}, type=${conf.type.name}) '
            'has no hardware-wallet flow.',
      );
    }
    return id;
  }

  /// Offline check: does [device] speak this coin's curve?
  /// Pure backend table lookup ([HwApi.supportsCoin]) — no transport, no HW.
  bool isCoinSupportedByHw(CryptoCoins coin, {required int device}) {
    return supportsCoin(device: device, coin: hwCoinIdFor(coin));
  }

  /// Full default path `m/purpose'/coinIdx'/defPath` (`defPath` already
  /// contains the account level, e.g. BTC `0'/0/0`, Tezos `0'/0'`).
  String defaultHwPath(CryptoCoins coin) {
    final conf = _bipConf(coin, 'defaultHwPath');
    final purpose =
        Bip32KeyIndex.unhardenIndex(coin.proposal.purpose.index).index;
    return "m/$purpose'/${conf.coinIdx}'/${conf.defPath}";
  }

  /// Parse + validate + fetch pubkey in one call. [path] defaults to
  /// [defaultHwPath]. Needs a connected [transport] (USB) except the
  /// validation part — throws before touching transport on bad input.
  Future<BuBytes> getPublicKey({
    required CryptoCoins coin,
    required int device,
    String? path,
    required BuHwTransport transport,
  }) async {
    final coinId = hwCoinIdFor(coin);
    final pathU32 = parsePath(path ?? defaultHwPath(coin));
    validatePath(device: device, coin: coinId, pathU32: pathU32);
    return executeGetAddress(
      device: device,
      coin: coinId,
      pathU32: pathU32,
      transport: transport,
    );
  }

  /// [getPublicKey] + the coin's own `addressEncoder` → ready address string.
  /// (Monero intentionally throws — it has no coin-config address derivation.)
  Future<String> getAddress({
    required CryptoCoins coin,
    required int device,
    String? path,
    required BuHwTransport transport,
  }) async {
    final conf = _bipConf(coin, 'getAddress');
    final pk = await getPublicKey(
      coin: coin,
      device: device,
      path: path,
      transport: transport,
    );
    return conf.encodeAddress(EncodeAddressDefaultParams(pubKey: pk));
  }
}
