import 'package:blockchain_utils/bip/address/encoders.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_secp256k1.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/types/types.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/config.dart';
import 'package:blockchain_utils/bip/bip/zip32/conf/zcash.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/keys.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/exception.dart';
import 'package:blockchain_utils/bip/bip/zip32/sapling/keys.dart';
import 'package:blockchain_utils/bip/bip/zip32/zip32/types.dart';
import 'package:blockchain_utils/bip/zcash/src/encoding/encoding.dart';
import 'package:blockchain_utils/bip/zcash/src/exception.dart';
import 'package:blockchain_utils/bip/zcash/src/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

enum TransparentAddressRequestType { p2pkh, p2sh }

class UnifiedAddressRequest {
  final bool? transparent;
  final bool? sapling;
  final bool? orchard;
  final PubKeyModes transparentPubKeyMode;
  final List<int>? transparentScriptHash;
  final TransparentAddressRequestType transparentAddressType;

  const UnifiedAddressRequest.defaultRequest()
    : transparent = null,
      sapling = null,
      orchard = null,
      transparentPubKeyMode = PubKeyModes.compressed,
      transparentScriptHash = null,
      transparentAddressType = TransparentAddressRequestType.p2pkh;

  UnifiedAddressRequest._({
    this.transparent,
    this.sapling,
    this.orchard,
    this.transparentPubKeyMode = PubKeyModes.compressed,
    this.transparentAddressType = TransparentAddressRequestType.p2pkh,
    List<int>? transparentScriptHash,
  }) : transparentScriptHash =
           transparentScriptHash
               ?.exc(
                 length: QuickCrypto.hash160DigestSize,
                 operation: "UnifiedAddressRequest",
                 name: "transparentScriptHash",
                 reason: "Invalid transparent P2SH script bytes length.",
               )
               .asImmutableBytes;
  factory UnifiedAddressRequest({
    bool? transparent,
    bool? sapling,
    bool? orchard,
    PubKeyModes? transparentPubKeyMode,
    List<int>? transparentScriptHash,
    TransparentAddressRequestType transparentAddressType =
        TransparentAddressRequestType.p2pkh,
  }) {
    switch (transparentAddressType) {
      case TransparentAddressRequestType.p2pkh:
        if (transparentScriptHash != null) {
          throw ArgumentException.invalidOperationArguments(
            "UnifiedAddressRequest",
            reason: "P2PKH addresses cannot include a script hash.",
          );
        }
        break;
      case TransparentAddressRequestType.p2sh:
        if (transparentPubKeyMode != null &&
            transparentPubKeyMode != PubKeyModes.compressed) {
          throw ArgumentException.invalidOperationArguments(
            "UnifiedAddressRequest",
            reason: "P2SH addresses require a compressed public key mode.",
          );
        }
        break;
    }
    return UnifiedAddressRequest._(
      transparent: transparent,
      sapling: sapling,
      orchard: orchard,
      transparentAddressType: transparentAddressType,
      transparentScriptHash: transparentScriptHash,
      transparentPubKeyMode: transparentPubKeyMode ?? PubKeyModes.compressed,
    );
  }

  bool get orchardRequired => orchard ?? false;
  bool get saplingRequired => sapling ?? false;
  bool get transparentRequired => transparent ?? false;
  bool get orchardAllowed => orchard ?? true;
  bool get saplingAllowed => sapling ?? true;
  bool get transparentAllowed => transparent ?? true;
}

class UnifiedDerivedAddress {
  final ReceiverOrchard? orchard;
  final ReceiverSapling? sapling;
  final ZUnifiedReceiver? transparent;
  final DiversifierIndex index;
  final String address;
  const UnifiedDerivedAddress({
    this.orchard,
    this.sapling,
    this.transparent,
    required this.index,
    required this.address,
  });
}

class UnifiedIncomingViewingKey {
  final Bip32Slip10Secp256k1? transparent;
  final SaplingIncomingViewingKey? sapling;
  final OrchardIncomingViewingKey? orchard;
  final ReceiverUnknown? unknown;
  final ZIP32CoinConfig config;
  const UnifiedIncomingViewingKey._({
    this.transparent,
    this.orchard,
    this.sapling,
    this.unknown,
    required this.config,
  });
  factory UnifiedIncomingViewingKey.fromUnifiedFullViewKey({
    required String ifvk,
    required ZcashNetwork network,
  }) {
    final config = ZcashConf().fromNetwork(network);
    final key = ZCashEncodingUtils.decodeUnifiedObject(
      address: ifvk,
      mode: UnifiedReceiverMode.ivk,
      expectedHrp: config.hrpUnifiedFvk,
    );
    if (key == null) {
      throw ArgumentException.invalidOperationArguments(
        "UnifiedIncomingViewingKey",
        reason: "Invalid UIVK encoded string.",
      );
    }
    final r = key.$1;
    final sapling = r.firstWhereNullable((e) => e.type == Typecode.sapling);
    final orchard = r.firstWhereNullable((e) => e.type == Typecode.orchard);
    final transparent = r.firstWhereNullable((e) => e.type == Typecode.p2pkh);
    final unknown = r.firstWhereNullable((e) => e.type == Typecode.unknown);
    return UnifiedIncomingViewingKey._(
      config: config,
      sapling:
          sapling == null
              ? null
              : SaplingIncomingViewingKey.fromBytes(sapling.data),
      orchard:
          orchard == null
              ? null
              : OrchardIncomingViewingKey.fromBytes(orchard.data),
      transparent:
          transparent == null
              ? null
              : ZCashEncodingUtils.decodeBip44Fvk(transparent.data),
      unknown: unknown?.cast<ReceiverUnknown>().copyWith(
        mode: UnifiedReceiverMode.ivk,
      ),
    );
  }

  factory UnifiedIncomingViewingKey({
    Bip32Slip10Secp256k1? transparent,
    SaplingIncomingViewingKey? sapling,
    OrchardIncomingViewingKey? orchard,
    ReceiverUnknown? unknown,
    required ZcashNetwork network,
  }) {
    final config = ZcashConf().fromNetwork(network);
    return UnifiedIncomingViewingKey._(
      config: config,
      orchard: orchard,
      sapling: sapling,
      transparent: transparent,
      unknown: unknown?.copyWith(mode: UnifiedReceiverMode.ivk),
    );
  }
  String encode() {
    final sapling = this.sapling;
    final orchard = this.orchard;
    final transparent = this.transparent;
    final unknown = this.unknown;
    return ZCashEncodingUtils.encodeUnifiedObject(
      hrp: config.hrpUnifiedFvk,
      mode: UnifiedReceiverMode.ivk,
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
        if (unknown != null) unknown,
      ],
    );
  }

  SaplingIncomingViewingKey _getSapling() {
    final sapling = this.sapling;
    if (sapling == null) throw ZcashKeyError("Missing Sapling key.");
    return sapling;
  }

  Bip32Slip10Secp256k1 _getTransparent() {
    final transparent = this.transparent;
    if (transparent == null) throw ZcashKeyError("Missing transaparent key.");
    return transparent;
  }

  String saplingAddressAt(DiversifierIndex index) {
    try {
      final sapling = _getSapling();
      final addressBytes = sapling.addressAt(index).toBytes();
      return ZCashAddrEncoder().encodeKey(
        addressBytes,
        addrType: ZCashAddressType.sapling,
        network: config.network,
      );
    } catch (_) {
      throw ZcashKeyError("Invalid sapling Diversifier index.");
    }
  }

  (String, DiversifierIndex)? findSaplingAddressFrom(
    DiversifierIndex from, {
    Bip44Changes scope = Bip44Changes.chainExt,
  }) {
    final sapling = _getSapling();
    final addr = sapling.findAddress(from);
    if (addr == null) return null;
    final addrString = ZCashAddrEncoder().encodeKey(
      addr.$1.toBytes(),
      addrType: ZCashAddressType.sapling,
      network: config.network,
    );
    return (addrString, addr.$2);
  }

  ReceiverSapling? _getSaplingReceiver({
    required DiversifierIndex index,
    required UnifiedAddressRequest request,
  }) {
    if (!request.saplingAllowed) return null;

    final sapling = this.sapling;
    final saplingRequired = request.saplingRequired;
    if (sapling == null && !saplingRequired) return null;
    if (sapling == null) {
      throw ZcashKeyError("Sapling key required but missing.");
    }
    try {
      final addr = sapling.addressAt(index);
      return ReceiverSapling(
        data: addr.toBytes(),
        mode: UnifiedReceiverMode.address,
      );
    } on SaplingKeyError {
      rethrow;
    } catch (_) {
      if (!saplingRequired) return null;
      throw ZcashKeyError("Invalid sapling Diversifier index.");
    }
  }

  ReceiverOrchard? _getOrchardReceiver({
    required DiversifierIndex index,
    required UnifiedAddressRequest request,
  }) {
    if (!request.orchardAllowed) return null;

    final orchard = this.orchard;
    final orchardRequired = request.orchardRequired;
    if (orchard == null && !orchardRequired) return null;
    if (orchard == null) {
      throw ZcashKeyError("Orchard key required but missing.");
    }
    final addr = orchard.addressAt(index);
    return ReceiverOrchard(
      data: addr.toBytes(),
      mode: UnifiedReceiverMode.address,
    );
  }

  ZUnifiedReceiver? _getTransparentReceiver({
    required DiversifierIndex index,
    required UnifiedAddressRequest request,
  }) {
    if (!request.transparentAllowed) return null;

    final transparent = this.transparent;
    final transparentRequired = request.transparentRequired;
    if (transparent == null && !transparentRequired) return null;
    if (transparent == null) {
      throw ZcashKeyError("Transparent key required but missing.");
    }
    final bipIndex = index.toBip32Index();
    if (bipIndex == null) {
      if (!transparentRequired) return null;
      throw ZcashKeyError("Invalid transparent child index.");
    }
    final child = transparent.childKey(bipIndex);
    return switch (request.transparentAddressType) {
      TransparentAddressRequestType.p2pkh => ReceiverP2pkh(
        data: P2PKHAddrEncoder().validateAndHashKey(
          child.publicKey.compressed,
          pubKeyMode: request.transparentPubKeyMode,
        ),
        mode: UnifiedReceiverMode.address,
      ),
      TransparentAddressRequestType.p2sh => ReceiverP2sh(
        request.transparentScriptHash ??
            P2SHAddrEncoder().validateAndHashKey(child.publicKey.compressed),
      ),
    };
  }

  void _validateUnifiedRequest(UnifiedAddressRequest request) {
    final hasSapling = sapling != null;
    final hasOrchard = orchard != null;
    final hasTransparent = transparent != null;

    // Must have at least one shielded key
    if (!hasSapling && !hasOrchard) {
      throw ZcashKeyError("Unified address requires Sapling or Orchard key.");
    }

    // Request must allow at least one shielded type
    if (!request.orchardAllowed && !request.saplingAllowed) {
      throw ZcashKeyError("Request disallows all shielded receivers.");
    }

    // Required receiver checks
    if (request.saplingRequired && !hasSapling) {
      throw ZcashKeyError("Sapling key required but missing.");
    }

    if (request.orchardRequired && !hasOrchard) {
      throw ZcashKeyError("Orchard key required but missing.");
    }

    if (request.transparentRequired && !hasTransparent) {
      throw ZcashKeyError("Transparent key required but missing.");
    }
  }

  UnifiedDerivedAddress _address({
    required DiversifierIndex index,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
  }) {
    _validateUnifiedRequest(request);
    final sapling = _getSaplingReceiver(index: index, request: request);
    final orchard = _getOrchardReceiver(index: index, request: request);
    final transparent = _getTransparentReceiver(index: index, request: request);
    final addr = ZCashEncodingUtils.encodeUnifiedObject(
      hrp: config.hrpUnifiedAddress,
      mode: UnifiedReceiverMode.address,
      receivers: [
        if (sapling != null) sapling,
        if (orchard != null) orchard,
        if (transparent != null) transparent,
      ],
    );
    return UnifiedDerivedAddress(
      index: index,
      address: addr,
      orchard: orchard,
      sapling: sapling,
      transparent: transparent,
    );
  }

  String transparentAddress(
    DiversifierIndex index, {
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
    List<int>? transparentScriptHash,
    TransparentAddressRequestType transparentAddressType =
        TransparentAddressRequestType.p2pkh,
  }) {
    final transparent = _getTransparent();
    switch (transparentAddressType) {
      case TransparentAddressRequestType.p2pkh:
        if (transparentScriptHash != null) {
          throw ArgumentException.invalidOperationArguments(
            "transparentAddress",
            name: "transparentScriptHash",
            reason: "P2PKH addresses cannot include a script hash.",
          );
        }
        break;
      case TransparentAddressRequestType.p2sh:
        if (pubKeyMode != PubKeyModes.compressed) {
          throw ArgumentException.invalidOperationArguments(
            "transparentAddress",
            name: "pubKeyMode",
            reason: "P2SH addresses require a compressed public key mode.",
          );
        }
        break;
    }
    final bipIndex = index.toBip32Index();
    if (bipIndex == null) {
      throw ZcashKeyError("Invalid transparent child index.");
    }
    final child = transparent.childKey(bipIndex);
    return P2PKHAddrEncoder().encodeKey(
      child.publicKey.compressed,
      pubKeyMode: pubKeyMode,
      netVersion: config.b58PubkeyAddressPrefix,
    );
  }

  UnifiedDerivedAddress address({
    required DiversifierIndex index,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
  }) {
    try {
      return _address(index: index, request: request);
    } on SaplingKeyError {
      throw ZcashKeyError("Invalid sapling Diversifier index.");
    }
  }

  UnifiedDerivedAddress findAddress({
    required DiversifierIndex from,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
  }) {
    DiversifierIndex? j = from;
    while (j != null) {
      try {
        return _address(index: j, request: request);
      } on SaplingKeyError {
        j = j.tryIncrement();
      }
    }
    throw ZcashKeyError("Diversifier index space exhausted.");
  }

  UnifiedDerivedAddress defaultAddress({
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
  }) {
    return findAddress(from: DiversifierIndex.zero(), request: request);
  }

  String defaultTransparentAddress({
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
    List<int>? transparentScriptHash,
    TransparentAddressRequestType transparentAddressType =
        TransparentAddressRequestType.p2pkh,
  }) {
    return transparentAddress(
      DiversifierIndex.zero(),
      pubKeyMode: pubKeyMode,
      transparentAddressType: transparentAddressType,
      transparentScriptHash: transparentScriptHash,
    );
  }
}
