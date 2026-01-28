import 'package:blockchain_utils/bip/bip/bip32/bip32.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/types/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/config.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/zcash.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/keys.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/keys.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/zip32.dart';
import 'package:blockchain_utils/bip/bip/zip32/zip32/types.dart';
import 'package:blockchain_utils/bip/zcash/src/encoding/encoding.dart';
import 'package:blockchain_utils/bip/zcash/src/types.dart';
import 'package:blockchain_utils/bip/zcash/src/uivk.dart';
import 'package:blockchain_utils/exception/exception/exception.dart'
    show ArgumentException;
import 'package:blockchain_utils/helper/extensions/extensions.dart';

class UnifiedFullViewingKey {
  final Bip32Slip10Secp256k1? transparent;
  final SaplingDiversifiableFullViewingKey? sapling;
  final OrchardFullViewingKey? orchard;
  final ReceiverUnknown? unknown;
  final ZIP32CoinConfig config;
  const UnifiedFullViewingKey._({
    this.transparent,
    this.orchard,
    this.sapling,
    this.unknown,
    required this.config,
  });

  factory UnifiedFullViewingKey.fromSaplingExtendedFullViewKey({
    required String uskBytes,
    required ZcashNetwork network,
  }) {
    final config = ZcashConf().fromNetwork(network);
    final key = ZCashEncodingUtils.decodeSaplingExtendedFullViewKey(
      uskBytes,
      config.hrpSaplingExtendedFullViewingKey,
    );
    final zip32 = Zip32Sapling.fromExtendedFullViewKey(key);
    return UnifiedFullViewingKey._(
      config: config,
      sapling: SaplingDiversifiableFullViewingKey(
        fvk: zip32.publicKey.fvk,
        dk: zip32.publicKey.keyData.dk,
      ),
      orchard: null,
      transparent: null,
    );
  }
  factory UnifiedFullViewingKey({
    Bip32Slip10Secp256k1? transparent,
    SaplingDiversifiableFullViewingKey? sapling,
    OrchardFullViewingKey? orchard,
    ReceiverUnknown? unknown,
    required ZcashNetwork network,
  }) {
    final config = ZcashConf().fromNetwork(network);
    return UnifiedFullViewingKey._(
      config: config,
      orchard: orchard,
      sapling: sapling,
      transparent: transparent,
      unknown: unknown?.copyWith(mode: UnifiedReceiverMode.fvk),
    );
  }
  factory UnifiedFullViewingKey.fromUnifiedFullViewKey({
    required String ufvk,
    required ZcashNetwork network,
    required ZCryptoContext context,
  }) {
    final config = ZcashConf().fromNetwork(network);
    final key = ZCashEncodingUtils.decodeUnifiedObject(
      address: ufvk,
      mode: UnifiedReceiverMode.fvk,
      expectedHrp: config.hrpUnifiedFvk,
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
    final unknown = r.firstWhereNullable((e) => e.type == Typecode.unknown);
    return UnifiedFullViewingKey._(
      config: config,
      sapling:
          sapling == null
              ? null
              : SaplingDiversifiableFullViewingKey.fromBytes(sapling.data),
      orchard:
          orchard == null
              ? null
              : OrchardFullViewingKey.fromBytes(
                bytes: orchard.data,
                context: context,
              ),
      transparent:
          transparent == null
              ? null
              : ZCashEncodingUtils.decodeBip44Fvk(transparent.data),
      unknown: unknown?.cast<ReceiverUnknown>().copyWith(
        mode: UnifiedReceiverMode.fvk,
      ),
    );
  }

  String encode() {
    final sapling = this.sapling;
    final orchard = this.orchard;
    final transparent = this.transparent;
    final unknown = this.unknown;
    return ZCashEncodingUtils.encodeUnifiedObject(
      hrp: config.hrpUnifiedFvk,
      mode: UnifiedReceiverMode.fvk,
      receivers: [
        if (sapling != null)
          ReceiverSapling(
            data: sapling.toBytes(),
            mode: UnifiedReceiverMode.fvk,
          ),
        if (orchard != null)
          ReceiverOrchard(
            data: orchard.toBytes(),
            mode: UnifiedReceiverMode.fvk,
          ),
        if (transparent != null)
          ReceiverP2pkh(
            data: ZCashEncodingUtils.encodeBip44Fvk(transparent),
            mode: UnifiedReceiverMode.fvk,
          ),
        if (unknown != null) unknown,
      ],
    );
  }

  UnifiedIncomingViewingKey toUnifiedIncomingViewingKey(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return UnifiedIncomingViewingKey(
      network: config.network,
      orchard: orchard?.toIvk(scope: scope, context: context),
      sapling: sapling?.toIvk(scope),
      transparent: transparent?.childKey(Bip32KeyIndex(scope.value)),
    );
  }

  UnifiedDerivedAddress address({
    required DiversifierIndex index,
    required ZCryptoContext context,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return toUnifiedIncomingViewingKey(
      context,
      scope: scope,
    ).address(index: index, request: request);
  }

  UnifiedDerivedAddress findAddress({
    required DiversifierIndex from,
    required ZCryptoContext context,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return toUnifiedIncomingViewingKey(
      context,
      scope: scope,
    ).findAddress(from: from, request: request);
  }

  UnifiedDerivedAddress defaultAddress({
    required ZCryptoContext context,
    Bip44Changes scope = Bip44Changes.chainExt,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
  }) {
    return toUnifiedIncomingViewingKey(
      context,
      scope: scope,
    ).defaultAddress(request: request);
  }

  String defaultTransparentAddress(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainExt,
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
    List<int>? transparentScriptHash,
    TransparentAddressRequestType transparentAddressType =
        TransparentAddressRequestType.p2pkh,
  }) {
    return toUnifiedIncomingViewingKey(
      context,
      scope: scope,
    ).defaultTransparentAddress(
      pubKeyMode: pubKeyMode,
      transparentAddressType: transparentAddressType,
      transparentScriptHash: transparentScriptHash,
    );
  }
}
