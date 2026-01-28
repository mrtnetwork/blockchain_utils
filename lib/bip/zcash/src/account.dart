import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/address/p2sh_addr.dart';
import 'package:blockchain_utils/bip/address/zcash/src/converter.dart';
import 'package:blockchain_utils/bip/address/zcash/src/types.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_secp256k1.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/bip44/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/types/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/config.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/zcash.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/zip32.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/zip32.dart';
import 'package:blockchain_utils/bip/bip/zip32/zip32/types.dart';
import 'package:blockchain_utils/bip/zcash/src/encoding/encoding.dart';
import 'package:blockchain_utils/bip/zcash/src/exception.dart';
import 'package:blockchain_utils/bip/zcash/src/types.dart';
import 'package:blockchain_utils/bip/zcash/src/ufsk.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

enum ZCashAccountValidation { standard, deny }

class ZCashAccountConfig {
  final bool? orchard;
  final bool? sapling;
  final bool? transparent;
  final ZIP32CoinConfig coinConfig;
  const ZCashAccountConfig._({
    this.orchard,
    this.sapling,
    this.transparent,
    required this.coinConfig,
  });
  factory ZCashAccountConfig({
    final bool? orchard,
    final bool? sapling,
    final bool? transparent,
    required ZcashNetwork network,
  }) {
    if (orchard == false && sapling == false && transparent == false) {
      throw ArgumentException.invalidOperationArguments(
        "ZCashAccountConfig",
        reason:
            "Invalid account configuration: at least one key type must be enabled.",
      );
    }
    final conf = ZcashConf();
    return ZCashAccountConfig._(
      coinConfig: conf.fromNetwork(network),
      orchard: orchard,
      sapling: sapling,
      transparent: transparent,
    );
  }
  factory ZCashAccountConfig.shield(ZcashNetwork network) {
    return ZCashAccountConfig(
      network: network,
      orchard: true,
      sapling: true,
      transparent: false,
    );
  }
  factory ZCashAccountConfig.transparent(ZcashNetwork network) {
    return ZCashAccountConfig(
      network: network,
      orchard: false,
      sapling: false,
      transparent: true,
    );
  }

  bool get orchardRequired => orchard ?? false;
  bool get saplingRequired => sapling ?? false;
  bool get transparentRequired => transparent ?? false;
  bool get orchardAllowed => orchard ?? true;
  bool get saplingAllowed => sapling ?? true;
  bool get transparentAllowed => transparent ?? true;
}

class ZCashAccount {
  final Zip32Sapling? sapling;
  final Zip32Orchard? orchard;
  final Bip32Slip10Secp256k1? transparent;
  final ZCashAccountConfig config;
  final ZCryptoContext context;
  const ZCashAccount._({
    required this.sapling,
    required this.orchard,
    required this.transparent,
    required this.config,
    required this.context,
  });
  factory ZCashAccount({
    final Zip32Sapling? sapling,
    final Zip32Orchard? orchard,
    final Bip32Slip10Secp256k1? transparent,
    required ZCashAccountConfig config,
    required ZCryptoContext context,
  }) {
    return ZCashAccount._(
      sapling: sapling,
      orchard: orchard,
      transparent: transparent,
      config: config,
      context: context,
    );
  }
  factory ZCashAccount.fromSeed({
    required List<int> seedBytes,
    required ZCashAccountConfig config,
    required ZCryptoContext context,
    Bip32KeyIndex? accountIndex,
  }) {
    List<Bip32KeyIndex> accountIndexes = [];
    if (accountIndex != null) {
      accountIndexes.add(accountIndex);
    } else {
      accountIndexes = Bip32PathParser.parse(config.coinConfig.defPath).elems;
    }
    //  ...
    // accountIndex ??= Bip32KeyIndex.unhardenIndex(index);
    final zip32Path =
        Bip32Path(
          elems: [
            Bip32KeyIndex.hardenIndex(32),
            Bip32KeyIndex.hardenIndex(config.coinConfig.coinIdx),
            ...accountIndexes,
          ],
        ).toPath();
    Bip32Slip10Secp256k1? transparent;
    if (config.transparentAllowed) {
      final tPath = Bip32Path(
        elems: [
          Bip44Const.purpose,
          Bip32KeyIndex.hardenIndex(config.coinConfig.coinIdx),
          ...accountIndexes,
        ],
      );
      transparent = Bip32Slip10Secp256k1.fromSeed(seedBytes);
      transparent = transparent.derivePath(tPath.toPath());
    }
    Zip32Sapling? sapling;
    if (config.saplingAllowed) {
      sapling = Zip32Sapling.fromSeed(seedBytes).derivePath(zip32Path, context);
    }
    Zip32Orchard? orchard;
    if (config.saplingAllowed) {
      orchard = Zip32Orchard.fromSeed(seedBytes).derivePath(zip32Path, context);
    }
    return ZCashAccount._(
      sapling: sapling,
      orchard: orchard,
      transparent: transparent,
      context: context,
      config: config,
    );
  }
  factory ZCashAccount.fromUnifiedSpendKeyBytes({
    required List<int> uskBytes,
    required ZCashAccountConfig config,
    required ZCryptoContext context,
  }) {
    final decode = ZCashEncodingUtils.decodeUnifiedSpendKey(uskBytes);
    return ZCashAccount._(
      config: config,
      context: context,
      sapling: Zip32Sapling.fromExtendedSpendingKeyBytes(
        decode.firstWhere((e) => e.type == Typecode.sapling).data,
      ),
      orchard: Zip32Orchard.fromSpendKey(
        context: context,
        sk: decode.firstWhere((e) => e.type == Typecode.orchard).data,
      ),
      transparent: Bip32Slip10Secp256k1.fromExtendedKeyBytes(
        decode.firstWhere((e) => e.type == Typecode.p2pkh).data,
      ),
    );
  }
  factory ZCashAccount.fromSaplingExtendedFullViewKey({
    required String uskBytes,
    required ZCashAccountConfig config,
    required ZCryptoContext context,
  }) {
    final key = ZCashEncodingUtils.decodeSaplingExtendedFullViewKey(
      uskBytes,
      config.coinConfig.hrpSaplingExtendedSpendingKey,
    );
    return ZCashAccount._(
      config: config,
      context: context,
      sapling: Zip32Sapling.fromExtendedFullViewKey(key),
      orchard: null,
      transparent: null,
    );
  }
  factory ZCashAccount.fromSaplingExtendedSpendingKey({
    required String extendedKey,
    required ZCashAccountConfig config,
    required ZCryptoContext context,
  }) {
    final key = ZCashEncodingUtils.decodeSaplingExtendedSpendingKey(
      extendedKey,
      config.coinConfig.hrpSaplingExtendedSpendingKey,
    );
    return ZCashAccount._(
      config: config,
      context: context,
      sapling: Zip32Sapling.fromExtendedSpendingKeyBytes(key),
      orchard: null,
      transparent: null,
    );
  }
  factory ZCashAccount.fromOrchardFullViewKey({
    required List<int> fullViewKeyBytes,
    required ZCashAccountConfig config,
    required ZCryptoContext context,
  }) {
    return ZCashAccount._(
      config: config,
      sapling: null,
      context: context,
      orchard: Zip32Orchard.fromFullViewKey(
        fvk: fullViewKeyBytes,
        context: context,
      ),
      transparent: null,
    );
  }

  factory ZCashAccount.fromUnifiedFullViewKey({
    required String ufvk,
    required ZCashAccountConfig config,
    required ZCryptoContext context,
  }) {
    final key = ZCashEncodingUtils.decodeUnifiedObject(
      address: ufvk,
      mode: UnifiedReceiverMode.fvk,
      expectedHrp: config.coinConfig.hrpUnifiedFvk,
    );
    if (key == null) {
      throw ArgumentException.invalidOperationArguments(
        "fromUnifiedFullViewKey",
        reason: "Invalid UFVK encoded string.",
      );
    }
    final r = key.$1;
    final sapling = r.firstWhereNullable((e) => e.type == Typecode.sapling);
    final orchard = r.firstWhereNullable((e) => e.type == Typecode.orchard);
    final transparent = r.firstWhereNullable((e) => e.type == Typecode.p2pkh);
    return ZCashAccount._(
      config: config,
      context: context,
      sapling:
          sapling == null
              ? null
              : Zip32Sapling.fromExtendedFullViewKey(sapling.data),
      orchard:
          orchard == null
              ? null
              : Zip32Orchard.fromFullViewKey(
                fvk: orchard.data,
                context: context,
              ),
      transparent:
          transparent == null
              ? null
              : ZCashEncodingUtils.decodeBip44Fvk(transparent.data),
    );
  }

  Zip32Orchard _getOrchard() {
    final orchard = this.orchard;
    if (orchard == null) throw ZcashKeyError("Missing Orchard key.");
    return orchard;
  }

  Zip32Sapling _getSapling() {
    final sapling = this.sapling;
    if (sapling == null) throw ZcashKeyError("Missing Sapling key.");
    return sapling;
  }

  Bip32Base _getTransparent() {
    final transparent = this.transparent;
    if (transparent == null) throw ZcashKeyError("Missing transaparent key.");
    return transparent;
  }

  List<int> encodeOrchardFullViewKey() {
    final orchard = _getOrchard();
    return orchard.publicKey.fvk.toBytes();
  }

  String encodeSaplingExtendedSpendKey() {
    final sapling = _getSapling();
    return ZCashEncodingUtils.encodeBech32Address(
      bytes: sapling.privateKey.toBytes(),
      encoding: Bech32Encodings.bech32,
      hrp: config.coinConfig.hrpSaplingExtendedSpendingKey,
    );
  }

  String encodeSaplingExtendedFullViewKey() {
    final sapling = _getSapling();
    return ZCashEncodingUtils.encodeBech32Address(
      bytes: sapling.publicKey.toBytes(),
      encoding: Bech32Encodings.bech32,
      hrp: config.coinConfig.hrpSaplingExtendedFullViewingKey,
    );
  }

  String encodeTransparentFullViewKey() {
    final transparent = _getTransparent();
    return transparent.publicKey.toExtended;
  }

  List<int> encodeUnifiedSpeningKeyBytes() {
    final sapling = _getSapling();
    final orchard = _getOrchard();
    final transparent = _getTransparent();
    return ZCashEncodingUtils.encodeUnifiedSpendKey([
      ReceiverP2pkh(
        data: transparent.privateKey.toExtendedBytes,
        mode: UnifiedReceiverMode.sk,
      ),
      ReceiverSapling(
        data: sapling.privateKey.spendKeyBytes(),
        mode: UnifiedReceiverMode.sk,
      ),
      ReceiverOrchard(
        data: orchard.privateKey.spendKeyBytes(),
        mode: UnifiedReceiverMode.sk,
      ),
    ]);
  }

  String encodeUnifiedFullViewKey() {
    final sapling = this.sapling;
    final orchard = this.orchard;
    final transparent = this.transparent;
    return ZCashEncodingUtils.encodeUnifiedObject(
      hrp: config.coinConfig.hrpUnifiedFvk,
      mode: UnifiedReceiverMode.fvk,
      receivers: [
        if (sapling != null)
          ReceiverSapling(
            data: sapling.publicKey.toBytes(),
            mode: UnifiedReceiverMode.fvk,
          ),
        if (orchard != null)
          ReceiverOrchard(
            data: orchard.publicKey.fvk.toBytes(),
            mode: UnifiedReceiverMode.fvk,
          ),
        if (transparent != null)
          ReceiverP2pkh(
            data: ZCashEncodingUtils.encodeBip44Fvk(transparent),
            mode: UnifiedReceiverMode.fvk,
          ),
      ],
    );
  }

  String encodeUnifiedIncomingViewKey() {
    final sapling = this.sapling?.publicKey.incomingViewingKey(context);
    final orchard = this.orchard?.publicKey.incomingViewingKey(context);
    final transparent = this.transparent;
    return ZCashEncodingUtils.encodeUnifiedObject(
      hrp: config.coinConfig.hrpUnifiedIvk,
      mode: UnifiedReceiverMode.fvk,
      receivers: [
        if (sapling != null)
          ReceiverSapling(
            data: sapling.toBytes(),
            mode: UnifiedReceiverMode.ivk,
          ),
        if (orchard != null)
          ReceiverOrchard(
            data: orchard.toBytes(),
            mode: UnifiedReceiverMode.ivk,
          ),
        if (transparent != null)
          ReceiverP2pkh(
            data: ZCashEncodingUtils.encodeBip44Fvk(transparent),
            mode: UnifiedReceiverMode.ivk,
          ),
      ],
    );
  }

  String p2pkhAddress({PubKeyModes pubKeyMode = PubKeyModes.compressed}) {
    final transparet = _getTransparent();
    return P2PKHAddrEncoder().encodeKey(
      transparet.publicKey.compressed,
      pubKeyMode: pubKeyMode,
      netVersion: config.coinConfig.b58PubkeyAddressPrefix,
    );
  }

  String p2shAddress() {
    final transparet = _getTransparent();
    return P2SHAddrEncoder().encodeKey(
      transparet.publicKey.compressed,
      netVersion: config.coinConfig.b58ScriptAddressPrefix,
    );
  }

  String saplingAddressAt(
    DiversifierIndex index, {
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    final sapling = _getSapling();
    final viewKey = sapling.publicKey.incomingViewingKey(context, scope: scope);
    final addressBytes = viewKey.addressAt(index).toBytes();
    return ZCashAddrEncoder().encodeKey(
      addressBytes,
      addrType: ZCashAddressType.sapling,
      network: config.coinConfig.network,
    );
  }

  String? findSaplingAddressFromIndex({
    DiversifierIndex? from,
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    final sapling = _getSapling();
    final viewKey = sapling.publicKey.incomingViewingKey(context, scope: scope);
    final address = viewKey.findAddress(from ?? DiversifierIndex.zero())?.$1;
    if (address == null) return null;
    return ZCashAddrEncoder().encodeKey(
      address.toBytes(),
      addrType: ZCashAddressType.sapling,
      network: config.coinConfig.network,
    );
  }

  String getSaplingDefaultAddress() {
    return saplingAddressAt(
      DiversifierIndex.zero(),
      scope: Bip44Changes.chainExt,
    );
  }

  String orchardAddressAt(
    DiversifierIndex index, {
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    final sapling = _getOrchard();
    final viewKey = sapling.publicKey.incomingViewingKey(context, scope: scope);
    final addressBytes = viewKey.addressAt(index).toBytes();
    return ZCashUnifiedAddrEncoder().encodeUnifiedReceivers([
      ReceiverOrchard(data: addressBytes, mode: UnifiedReceiverMode.address),
    ], network: config.coinConfig.network);
  }

  // Bip32KeyIndex _toBip32KeyIndex(DiversifierIndex index) {
  //   final indexBytes = index.toBip32Index();
  // }

  String getOrchardDefaultAddress() {
    return orchardAddressAt(
      DiversifierIndex.zero(),
      scope: Bip44Changes.chainExt,
    );
  }

  UnifiedSpendingKey toUnifiedSpendKey() {
    final sapling = this.sapling;
    final orchard = this.orchard;
    final transparent = this.transparent;
    if (sapling == null || orchard == null || transparent == null) {
      throw ZcashKeyError(
        "Unified spending key is incomplete: Sapling, Orchard, and Transparent keys are required.",
      );
    }
    return UnifiedSpendingKey(sapling, orchard, transparent, config.coinConfig);
  }
}
