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

class UnifiedSpendingKey {
  final Zip32Sapling sapling;
  final Zip32Orchard orchard;
  final Bip32Slip10Secp256k1 transparent;
  final ZIP32CoinConfig config;
  const UnifiedSpendingKey._({
    required this.sapling,
    required this.orchard,
    required this.transparent,
    required this.config,
  });
  factory UnifiedSpendingKey(
    Zip32Sapling sapling,
    Zip32Orchard orchard,
    Bip32Slip10Secp256k1 transparent,
    ZIP32CoinConfig config,
  ) {
    return UnifiedSpendingKey._(
      sapling: sapling,
      orchard: orchard,
      transparent: transparent,
      config: config,
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
    ).derivePath(zip32Path, context);
    Zip32Orchard orchard = Zip32Orchard.fromSeed(
      seedBytes,
    ).derivePath(zip32Path, context);
    return UnifiedSpendingKey._(
      sapling: sapling,
      orchard: orchard,
      transparent: transparent,
      config: config,
    );
  }
  factory UnifiedSpendingKey.fromUnifiedSpendKeyBytes({
    required List<int> uskBytes,
    required ZcashNetwork network,
    required ZCryptoContext context,
  }) {
    final decode = ZCashEncodingUtils.decodeUnifiedSpendKey(uskBytes);
    final config = ZcashConf().fromNetwork(network);
    return UnifiedSpendingKey._(
      config: config,
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

  List<int> encodeUnifiedSpeningKeyBytes() {
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

  UnifiedFullViewingKey toUnifiedFullViewingKey() {
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
  }

  UnifiedDerivedAddress address({
    required ZCryptoContext context,

    required DiversifierIndex index,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),

    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return toUnifiedFullViewingKey().address(
      scope: scope,
      index: index,
      request: request,
      context: context,
    );
  }

  UnifiedDerivedAddress findAddress({
    required ZCryptoContext context,

    required DiversifierIndex from,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return toUnifiedFullViewingKey().findAddress(
      scope: scope,
      from: from,
      request: request,
      context: context,
    );
  }

  UnifiedDerivedAddress defaultAddress(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainExt,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
  }) {
    return toUnifiedFullViewingKey().defaultAddress(
      scope: scope,
      request: request,
      context: context,
    );
  }

  String defaultTransparentAddress(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainExt,
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
    List<int>? transparentScriptHash,
    TransparentAddressRequestType transparentAddressType =
        TransparentAddressRequestType.p2pkh,
  }) {
    return toUnifiedFullViewingKey().defaultTransparentAddress(
      context,
      pubKeyMode: pubKeyMode,
      scope: scope,
      transparentAddressType: transparentAddressType,
      transparentScriptHash: transparentScriptHash,
    );
  }
}
