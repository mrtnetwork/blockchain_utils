import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/zip32/base/context.dart';
import 'package:blockchain_utils/protocol/zip32/conf/config.dart';
import 'package:blockchain_utils/protocol/zip32/conf/zcash.dart';
import 'package:blockchain_utils/protocol/zip32/orchard/keys.dart';
import 'package:blockchain_utils/protocol/zip32/sapling/keys.dart';
import 'package:blockchain_utils/protocol/zip32/sapling/zip32.dart';
import 'package:blockchain_utils/protocol/zip32/zip32/types.dart';
import 'package:blockchain_utils/protocol/zcash/src/encoding/encoding.dart';
import 'package:blockchain_utils/protocol/zcash/src/types.dart';
import 'package:blockchain_utils/protocol/zcash/src/uivk.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Represents a unified full viewing key (UFVK) for transparent, Sapling, and Orchard components.
class UnifiedFullViewingKey {
  /// Transparent component of the UFVK (BIP32/SLIP-10 secp256k1).
  final Bip32Slip10Secp256k1? transparent;

  /// Sapling diversifiable full viewing key component.
  final SaplingDiversifiableFullViewingKey? sapling;

  /// Orchard full viewing key component.
  final OrchardFullViewingKey? orchard;

  /// Placeholder for unknown or unsupported components.
  final ReceiverUnknown? unknown;

  /// ZIP32 coin configuration used for key derivation.
  final ZIP32CoinConfig config;

  final Map<Bip44Changes, UnifiedIncomingViewingKey> _cachedIvk = {};

  UnifiedFullViewingKey._({
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
    final key = ZcashEncodingUtils.decodeSaplingExtendedFullViewKey(
      uskBytes,
      hrp: config.hrpSaplingExtendedFullViewingKey,
    );
    final zip32 = Zip32Sapling.fromExtendedFullViewKeyBytes(key);
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
    final key = ZcashEncodingUtils.decodeUnifiedObject(
      address: ufvk,
      mode: UnifiedReceiverMode.fvk,
      expectedHrp: config.hrpUnifiedFvk,
    );
    if (key == null) {
      throw CoreErrors.invalidOperationArguments(
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
              : ZcashEncodingUtils.decodeBip44Fvk(transparent.data),
      unknown: unknown?.cast<ReceiverUnknown>().copyWith(
        mode: UnifiedReceiverMode.fvk,
      ),
    );
  }

  /// Encodes this unified full viewing key (UFVK) into a Zcash-compatible unified string.
  String encode() {
    final sapling = this.sapling;
    final orchard = this.orchard;
    final transparent = this.transparent;
    final unknown = this.unknown;
    return ZcashEncodingUtils.encodeUnifiedObject(
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
            data: ZcashEncodingUtils.encodeBip44Fvk(transparent),
            mode: UnifiedReceiverMode.fvk,
          ),
        if (unknown != null) unknown,
      ],
    );
  }

  /// Converts this UFVK into a unified incoming viewing key (UIVK) for the specified derivation scope.
  UnifiedIncomingViewingKey toUnifiedIncomingViewingKey(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    return _cachedIvk[scope] ??= UnifiedIncomingViewingKey(
      network: config.network,
      orchard: orchard?.toIvk(scope, context: context),
      sapling: sapling?.toIvk(scope),
      transparent: transparent?.childKey(Bip32KeyIndex(scope.value)),
    );
  }

  /// Returns the unified address derived from this UFVK at the given index, context, scope, and request configuration.
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

  /// Finds the first unified address from the given index using this UFVK, context, scope, and request configuration.
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

  /// Returns the default unified address for this UFVK using the specified context, scope, and request.
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

  /// Returns the default transparent-derived address for this UFVK using the specified context, scope, and address parameters.
  TransparentDerivedAddress defaultTransparentAddress(
    ZCryptoContext context, {
    Bip44Changes scope = Bip44Changes.chainExt,
    CryptoKeyEncoding pubKeyMode = CryptoKeyEncoding.base,
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

  /// Returns the transparent component of this UFVK, or throws if missing.
  Bip32Slip10Secp256k1 getTransparent() {
    final transparent = this.transparent;
    if (transparent == null) {
      throw BuError(DefaultErrorType.invalidArgument,"Transparent key missing.");
    }
    return transparent;
  }

  /// Returns the Sapling component of this UFVK, or throws if missing.
  SaplingDiversifiableFullViewingKey getSapling() {
    final sapling = this.sapling;
    if (sapling == null) {
      throw BuError(DefaultErrorType.invalidArgument,"Sapling key missing.");
    }
    return sapling;
  }

  /// Returns the Orchard component of this UFVK, or throws if missing.
  OrchardFullViewingKey getOrchard() {
    final orchard = this.orchard;
    if (orchard == null) {
      throw BuError(DefaultErrorType.invalidArgument,"Orchard key missing.");
    }
    return orchard;
  }
}
