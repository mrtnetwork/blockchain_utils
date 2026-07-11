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
import 'package:blockchain_utils/bip/zcash/src/types.dart';
import 'package:blockchain_utils/bip/zcash/src/ufvk.dart';
import 'package:blockchain_utils/bip/zcash/src/uivk.dart';

/// Represents a unified spending key (USK) containing transparent, Sapling, and Orchard components.
class UnifiedSpendingKey {
  /// Transparent BIP32/SLIP-10 secp256k1 spending key component.
  final Bip32Slip10Secp256k1 transparent;

  /// Sapling ZIP32 spending key component.
  final Zip32Sapling sapling;

  /// Orchard ZIP32 spending key component.
  final Zip32Orchard orchard;

  /// ZIP32 coin configuration for key derivation.
  final ZIP32CoinConfig config;
  final ZCryptoContext context;
  UnifiedFullViewingKey? _cachedFvk;
  UnifiedSpendingKey._({
    required this.sapling,
    required this.orchard,
    required this.transparent,
    required this.config,
    required this.context,
  });
  factory UnifiedSpendingKey({
    required Zip32Sapling sapling,
    required Zip32Orchard orchard,
    required Bip32Slip10Secp256k1 transparent,
    required ZIP32CoinConfig config,
    required ZCryptoContext context,
  }) {
    return UnifiedSpendingKey._(
      sapling: sapling,
      orchard: orchard,
      transparent: transparent,

      config: config,
      context: context,
    );
  }
  factory UnifiedSpendingKey.fromSeed({
    required List<int> seedBytes,
    required ZcashNetwork network,
    required ZCryptoContext context,
    Bip32KeyIndex? accountIndex,
  }) {
    final config = ZcashConf().fromNetwork(network);

    List<Bip32KeyIndex> accountIndexes = [];
    if (accountIndex != null) {
      accountIndexes.add(accountIndex);
    } else {
      accountIndexes = Bip32PathParser.parse(config.defPath).elems;
    }
    final zip32Path =
        Bip32Path(
          elems: [
            Bip32KeyIndex.hardenIndex(32),
            Bip32KeyIndex.hardenIndex(config.coinIdx),
            ...accountIndexes,
          ],
        ).toPath();
    final tPath = Bip32Path(
      elems: [
        Bip44Const.purpose,
        Bip32KeyIndex.hardenIndex(config.coinIdx),
        ...accountIndexes,
      ],
    );
    Bip32Slip10Secp256k1 transparent = Bip32Slip10Secp256k1.fromSeed(seedBytes);
    transparent = transparent.derivePath(tPath.toPath());
    Zip32Sapling sapling = Zip32Sapling.fromSeed(
      seedBytes,
    ).derivePath(zip32Path, context: context);
    Zip32Orchard orchard = Zip32Orchard.fromSeed(
      seedBytes,
    ).derivePath(zip32Path, context: context);
    return UnifiedSpendingKey._(
      sapling: sapling,
      orchard: orchard,
      transparent: transparent,
      context: context,
      config: config,
    );
  }
  factory UnifiedSpendingKey.fromUnifiedSpendKeyBytes({
    required List<int> uskBytes,
    required ZcashNetwork network,
    required ZCryptoContext context,
  }) {
    final decode = ZcashEncodingUtils.decodeUnifiedSpendKey(uskBytes);
    final config = ZcashConf().fromNetwork(network);
    return UnifiedSpendingKey._(
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

  /// Encodes this unified spending key (USK) into Zcash-compatible unified bytes.
  List<int> encodeUnifiedSpeningKeyBytes() {
    return ZcashEncodingUtils.encodeUnifiedSpendKey([
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

  /// Converts this USK into its corresponding unified full viewing key (UFVK).
  UnifiedFullViewingKey toUnifiedFullViewingKey() {
    return _cachedFvk ??= (() {
      final transparent = Bip32Slip10Secp256k1.fromPublicKey(
        this.transparent.publicKey.compressed,
        keyData: this.transparent.publicKey.keyData,
        keyNetVer: this.transparent.keyNetVersions,
      );
      return UnifiedFullViewingKey(
        network: config.network,
        orchard: orchard.publicKey.fvk,
        sapling: sapling.publicKey.toDiversifiableFullViewingKey(),
        transparent: transparent,
      );
    }());
  }

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
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return toUnifiedIncomingViewingKey(
      scope: scope,
    ).address(index: index, request: request);
  }

  /// Finds the first unified address starting from the given index that matches the specified request.
  UnifiedDerivedAddress findAddress({
    required DiversifierIndex from,
    Bip44Changes scope = Bip44Changes.chainExt,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
  }) {
    return toUnifiedIncomingViewingKey(
      scope: scope,
    ).findAddress(from: from, request: request);
  }

  /// Returns the default unified address for this account using the specified request configuration.
  UnifiedDerivedAddress defaultAddress({
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return toUnifiedIncomingViewingKey(
      scope: scope,
    ).defaultAddress(request: request);
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
