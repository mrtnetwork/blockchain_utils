import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_path.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_secp256k1.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/bip44/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/types/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/zip32.dart';
import 'package:blockchain_utils/bip/zcash/src/encoding/encoding.dart';
import 'package:blockchain_utils/bip/zcash/src/exception.dart';
import 'package:blockchain_utils/bip/zcash/src/types.dart';
import 'package:blockchain_utils/bip/zcash/src/ufsk.dart';
import 'package:blockchain_utils/bip/zcash/src/ufvk.dart';
import 'package:blockchain_utils/bip/zcash/src/uivk.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// Configuration for a ZCash account, including enabled key types and network info.
class ZCashAccountConfig {
  /// Whether Orchard keys are enabled/required.
  final bool? orchard;

  /// Whether Sapling keys are enabled/required.
  final bool? sapling;

  /// Whether Transparent keys are enabled/required.
  final bool? transparent;

  /// Coin-specific configuration for ZIP32 derivation and HRPs.
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
    required ZCashNetwork network,
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
  factory ZCashAccountConfig.shield(ZCashNetwork network) {
    return ZCashAccountConfig(
      network: network,
      orchard: true,
      sapling: true,
      transparent: false,
    );
  }
  factory ZCashAccountConfig.transparent(ZCashNetwork network) {
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

  UnifiedAddressRequest toUnifiedAddressRequest() => UnifiedAddressRequest(
    orchard: orchard,
    sapling: sapling,
    transparent: transparent,
  );
}

/// Represents a ZCash account, optionally holding Sapling, Orchard, and Transparent keys.
class ZCashAccount {
  /// Sapling extended key.
  final Zip32Sapling? sapling;

  /// Orchard extended key.
  final Zip32Orchard? orchard;

  /// Transparent extended key.
  final Bip32Slip10Secp256k1? transparent;

  /// Configuration specifying which key types are enabled/required.
  final ZCashAccountConfig config;

  /// Crypto context used for derivations and encoding.
  final ZCryptoContext context;

  /// Cached unified full viewing key.
  UnifiedFullViewingKey? _cachedFvk;
  ZCashAccount._({
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
    if (config.orchardAllowed) {
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
      transparent: Bip32Slip10Secp256k1.fromExtendedPrivateKeyBytes(
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

  /// Returns the Orchard ZIP32 component, or throws if missing.
  Zip32Orchard getOrchard() {
    final orchard = this.orchard;
    if (orchard == null) throw ZCashKeyError("Missing Orchard key.");
    return orchard;
  }

  /// Returns the Sapling ZIP32 component, or throws if missing.
  Zip32Sapling getSapling() {
    final sapling = this.sapling;
    if (sapling == null) throw ZCashKeyError("Missing Sapling key.");
    return sapling;
  }

  /// Returns the Transparent BIP32 component, or throws if missing.
  Bip32Base getTransparent() {
    final transparent = this.transparent;
    if (transparent == null) throw ZCashKeyError("Missing transaparent key.");
    return transparent;
  }

  /// Encodes the Orchard full viewing key as raw bytes.
  List<int> encodeOrchardFullViewKey() {
    final orchard = getOrchard();
    return orchard.publicKey.fvk.toBytes();
  }

  /// Encodes the Sapling extended spending key as a Bech32 string.
  String encodeSaplingExtendedSpendKey() {
    final sapling = getSapling();
    return ZCashEncodingUtils.encodeBech32Address(
      bytes: sapling.privateKey.toBytes(),
      encoding: Bech32Encodings.bech32,
      hrp: config.coinConfig.hrpSaplingExtendedSpendingKey,
    );
  }

  /// Encodes the Sapling extended full viewing key as a Bech32 string.
  String encodeSaplingExtendedFullViewKey() {
    final sapling = getSapling();
    return ZCashEncodingUtils.encodeBech32Address(
      bytes: sapling.publicKey.toBytes(),
      encoding: Bech32Encodings.bech32,
      hrp: config.coinConfig.hrpSaplingExtendedFullViewingKey,
    );
  }

  /// Encodes the Transparent full viewing key as a string.
  String encodeTransparentFullViewKey() {
    final transparent = getTransparent();
    return transparent.publicKey.toExtended;
  }

  /// Encodes this unified spending key (USK) into unified bytes.
  List<int> encodeUnifiedSpeningKeyBytes() {
    final sapling = getSapling();
    final orchard = getOrchard();
    final transparent = getTransparent();
    return ZCashEncodingUtils.encodeUnifiedSpendKey([
      ReceiverP2pkh(
        data: transparent.privateKey.toExtendedBytes(withPrefix: false),
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

  /// Encodes this unified full viewing key (UFVK) as a unified string.
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

  /// Encodes this unified incoming viewing key (UIVK) as a unified string.
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

  /// Converts this object into a unified spending key (USK), requires all components.
  UnifiedSpendingKey toUnifiedSpendKey() {
    final sapling = this.sapling;
    final orchard = this.orchard;
    final transparent = this.transparent;
    if (sapling == null || orchard == null || transparent == null) {
      throw ZCashKeyError(
        "Unified spending key is incomplete: Sapling, Orchard, and Transparent keys are required.",
      );
    }
    return UnifiedSpendingKey(
      sapling: sapling,
      orchard: orchard,
      transparent: transparent,
      config: config.coinConfig,
      context: context,
    );
  }

  /// Converts this object into a unified full viewing key (UFVK), caches the result.
  UnifiedFullViewingKey toUnifiedFullViewingKey() {
    return _cachedFvk ??= (() {
      final transparent = (() {
        final t = this.transparent;
        if (t == null) return null;
        return Bip32Slip10Secp256k1.fromPublicKey(
          t.publicKey.compressed,
          keyData: t.publicKey.keyData,
          keyNetVer: t.keyNetVersions,
        );
      }());
      return UnifiedFullViewingKey(
        network: config.coinConfig.network,
        orchard: orchard?.publicKey.fvk,
        sapling: sapling?.publicKey.toDiversifiableFullViewingKey(),
        transparent: transparent,
      );
    }());
  }

  /// Converts this object into a unified incoming viewing key (UIVK).
  UnifiedIncomingViewingKey toUnifiedIncomingViewingKey({
    Bip44Changes scope = Bip44Changes.chainExt,
  }) => toUnifiedFullViewingKey().toUnifiedIncomingViewingKey(
    context,
    scope: scope,
  );

  /// Returns the Sapling-derived address at the given diversifier index.
  SaplingDerivedAddress saplingAddressAt(
    DiversifierIndex index, {
    Bip44Changes scope = Bip44Changes.chainExt,
  }) => toUnifiedIncomingViewingKey(scope: scope).saplingAddressAt(index);

  /// Finds the first Sapling-derived address starting from the given diversifier index within the specified scope.
  SaplingDerivedAddress? findSaplingAddressFrom(
    DiversifierIndex from, {
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return toUnifiedIncomingViewingKey(
      scope: scope,
    ).findSaplingAddressFrom(from);
  }

  /// Returns the transparent-derived address at the given index with specified pubkey mode and address type.
  TransparentDerivedAddress transparentAddress(
    DiversifierIndex index, {
    Bip44Changes scope = Bip44Changes.chainExt,
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
    List<int>? transparentScriptHash,
    TransparentAddressRequestType transparentAddressType =
        TransparentAddressRequestType.p2pkh,
  }) {
    return toUnifiedIncomingViewingKey(scope: scope).transparentAddress(
      index,
      pubKeyMode: pubKeyMode,
      transparentAddressType: transparentAddressType,
      transparentScriptHash: transparentScriptHash,
    );
  }

  /// Returns the unified address at the given index, using the specified address request configuration.
  UnifiedDerivedAddress address({
    required DiversifierIndex index,
    UnifiedAddressRequest? request,
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return toUnifiedIncomingViewingKey(scope: scope).address(
      index: index,
      request: request ?? config.toUnifiedAddressRequest(),
    );
  }

  /// Finds the first unified address starting from the given index that matches the specified request.
  UnifiedDerivedAddress findAddress({
    required DiversifierIndex from,
    Bip44Changes scope = Bip44Changes.chainExt,
    UnifiedAddressRequest? request,
  }) {
    return toUnifiedIncomingViewingKey(scope: scope).findAddress(
      from: from,
      request: request ?? config.toUnifiedAddressRequest(),
    );
  }

  /// Returns the default unified address for this account using the specified request configuration.
  UnifiedDerivedAddress defaultAddress({
    UnifiedAddressRequest? request,
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return toUnifiedIncomingViewingKey(
      scope: scope,
    ).defaultAddress(request: request ?? config.toUnifiedAddressRequest());
  }

  /// Returns the default transparent-derived address with the specified pubkey mode and address type.
  TransparentDerivedAddress defaultTransparentAddress({
    Bip44Changes scope = Bip44Changes.chainExt,
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
    List<int>? transparentScriptHash,
    TransparentAddressRequestType transparentAddressType =
        TransparentAddressRequestType.p2pkh,
  }) {
    return toUnifiedIncomingViewingKey(scope: scope).defaultTransparentAddress(
      pubKeyMode: pubKeyMode,
      transparentAddressType: transparentAddressType,
      transparentScriptHash: transparentScriptHash,
    );
  }
}
