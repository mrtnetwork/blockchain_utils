import 'package:blockchain_utils/chain/address/neworks/zcash/zcash.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/protocol/zip32/base/context.dart';
import 'package:blockchain_utils/protocol/zip32/base/types.dart';
import 'package:blockchain_utils/protocol/zip32/conf/coins.dart';
import 'package:blockchain_utils/protocol/zip32/conf/config.dart';
import 'package:blockchain_utils/protocol/zip32/orchard/zip32.dart';
import 'package:blockchain_utils/protocol/zip32/sapling/zip32.dart';
import 'package:blockchain_utils/protocol/zip32/zip32/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/zcash/src/types.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class Zip32Const {
  /// The purpose index for ZIP-32, derived as a hardened index (32').
  static Bip32KeyIndex get purpose => Bip32KeyIndex.hardenIndex(32);
}

class Zip32 {
  final Zip32Base zip32;
  final ZIP32CoinConfig coinConf;
  final ZCryptoContext context;
  const Zip32._({
    required this.zip32,
    required this.coinConf,
    required this.context,
  });

  factory Zip32.fromSeed({
    required List<int> seed,
    required ZIP32Coins coin,
    required ZCryptoContext context,
  }) {
    final coinConf = coin.conf;
    switch (coinConf.type) {
      case CryptoKeyType.redJubJubSpend:
        return Zip32._(
          zip32: Zip32Sapling.fromSeed(seed),
          coinConf: coinConf,
          context: context,
        );
      case CryptoKeyType.redPallasSpend:
        return Zip32._(
          zip32: Zip32Orchard.fromSeed(seed),
          coinConf: coinConf,
          context: context,
        );
      default:
        throw BuError(DefaultErrorType.unsupported,"Unsupported zip32 coin.");
    }
  }
  factory Zip32.fromSpendKey({
    required List<int> sk,
    required ZIP32Coins coin,
    required ZCryptoContext context,
  }) {
    final coinConf = coin.conf;
    switch (coinConf.type) {
      case CryptoKeyType.redJubJubSpend:
        return Zip32._(
          zip32: Zip32Sapling.fromSpendKey(sk),
          coinConf: coinConf,
          context: context,
        );
      case CryptoKeyType.redPallasSpend:
        return Zip32._(
          zip32: Zip32Orchard.fromSpendKey(sk: sk, context: context),
          coinConf: coinConf,
          context: context,
        );
      default:
        throw BuError(DefaultErrorType.unsupported,"Unsupported zip32 coin.");
    }
  }

  factory Zip32.fromExtendedKey({
    required List<int> sk,
    required ZIP32CoinConfig coinConf,
    required ZCryptoContext context,
  }) {
    switch (coinConf.type) {
      case CryptoKeyType.redJubJubSpend:
        return Zip32._(
          zip32: Zip32Sapling.fromSpendKey(sk),
          coinConf: coinConf,
          context: context,
        );
      case CryptoKeyType.redPallasSpend:
        return Zip32._(
          zip32: Zip32Orchard.fromSpendKey(sk: sk, context: context),
          coinConf: coinConf,
          context: context,
        );
      default:
        throw BuError(DefaultErrorType.unsupported,"Unsupported zip32 coin.");
    }
  }

  /// check level with current bip-44 level
  bool isLevel(Bip44Levels level) {
    return zip32.depth.depth == level.value;
  }

  Zip32 get purpose {
    if (!isLevel(Bip44Levels.master)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${zip32.depth.toInt()}) is not suitable for deriving purpose",
      );
    }
    return Zip32._(
      zip32: zip32.childKey(coinConf.purpose, context: context) as Zip32Base,
      coinConf: coinConf,
      context: context,
    );
  }

  Zip32 get deriveDefaultPath {
    final Zip32 bipObj = purpose.coin;
    return Zip32._(
      zip32:
          bipObj.zip32.derivePath(bipObj.coinConf.defPath, context: context)
              as Zip32Base,
      coinConf: coinConf,
      context: context,
    );
  }

  Zip32 get coin {
    if (!isLevel(Bip44Levels.purpose)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${zip32.depth.toInt()}) is not suitable for deriving coin",
      );
    }
    final coinIndex = coinConf.coinIdx;
    return Zip32._(
      zip32:
          zip32.childKey(Bip32KeyIndex.hardenIndex(coinIndex), context: context)
              as Zip32Base,
      coinConf: coinConf,
      context: context,
    );
  }

  Zip32 account(int accIndex) {
    if (!isLevel(Bip44Levels.coin)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Current depth (${zip32.depth.toInt()}) is not suitable for deriving account",
      );
    }
    return Zip32._(
      zip32:
          zip32.childKey(Bip32KeyIndex.hardenIndex(accIndex), context: context)
              as Zip32Base,
      coinConf: coinConf,
      context: context,
    );
  }

  IncomingViewingKey getViewKey({Bip44Changes scope = Bip44Changes.chainExt}) =>
      zip32.publicKey.incomingViewingKey(context);

  String addressAt(
    DiversifierIndex index, {
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    final viewKey = getViewKey(scope: scope);
    final addressBytes = viewKey.addressAt(index).toBytes();
    switch (coinConf.type) {
      case CryptoKeyType.redJubJubSpend:
        return coinConf.encodeAddress(
          EncodeAddressDefaultParams(pubKey: addressBytes),
        );
      default:
        return ZcashUnifiedAddrEncoder().encodeUnifiedReceivers([
          ReceiverOrchard(
            data: addressBytes,
            mode: UnifiedReceiverMode.address,
          ),
        ]);
    }
  }

  ShieldAddress? findAddress({
    DiversifierIndex? from,
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    final viewKey = getViewKey(scope: scope);
    return viewKey.findAddress(from ?? DiversifierIndex.zero())?.$1;
  }

  ShieldAddress? defaultAddress() {
    final key = findAddress(scope: Bip44Changes.chainExt);
    return key;
  }

  String? findAndEncodeAddress({
    DiversifierIndex? from,
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    final address = findAddress(from: from, scope: scope);
    if (address == null) return null;
    final addressBytes = address.toBytes();
    switch (coinConf.type) {
      case CryptoKeyType.redJubJubSpend:
        return coinConf.encodeAddress(
          EncodeAddressDefaultParams(pubKey: addressBytes),
        );
      default:
        return ZcashUnifiedAddrEncoder().encodeUnifiedReceivers([
          ReceiverOrchard(
            data: addressBytes,
            mode: UnifiedReceiverMode.address,
          ),
        ]);
    }
  }

  String get specName {
    return "ZIP-32";
  }
}
