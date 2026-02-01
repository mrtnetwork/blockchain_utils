import 'package:blockchain_utils/bip/address/encoders.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/bip/bip32/slip10/bip32_slip10_secp256k1.dart';
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

/// Types of transparent addresses (P2PKH or P2SH).
enum TransparentAddressRequestType { p2pkh, p2sh }

/// Represents a request for generating a unified address with optional transparent, Sapling, and Orchard components.
class UnifiedAddressRequest {
  /// Whether a transparent component is requested.
  final bool? transparent;

  /// Whether a Sapling component is requested.
  final bool? sapling;

  /// Whether an Orchard component is requested.
  final bool? orchard;

  /// PubKey mode for the transparent component.
  final PubKeyModes transparentPubKeyMode;

  /// Optional transparent script hash for P2SH addresses.
  final List<int>? transparentScriptHash;

  /// Type of transparent address to generate.
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

/// Represents a derived transparent address and associated keys.
class TransparentDerivedAddress {
  final String address;
  final ZUnifiedReceiver receiver;
  final TransparentAddressRequestType type;
  final Bip32KeyIndex bip32Index;
  final Bip32PublicKey publicKey;
  final PubKeyModes pubKeyMode;
  const TransparentDerivedAddress({
    required this.address,
    required this.type,
    required this.bip32Index,
    required this.receiver,
    required this.publicKey,
    required this.pubKeyMode,
  });
}

/// Represents a derived Sapling address and associated payment info.
class SaplingDerivedAddress {
  final String address;
  final ZUnifiedReceiver receiver;
  final SaplingPaymentAddress paymentAddress;
  final DiversifierIndex index;
  const SaplingDerivedAddress({
    required this.address,
    required this.paymentAddress,
    required this.index,
    required this.receiver,
  });
}

/// Represents a unified address combining optional Orchard, Sapling, and transparent components.
class UnifiedDerivedAddress {
  final ReceiverOrchard? orchard;
  final ReceiverSapling? sapling;
  final TransparentDerivedAddress? transparent;
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

/// Represents the unified incoming viewing key (UIVK) for transparent, Sapling, and Orchard components.
class UnifiedIncomingViewingKey {
  /// Transparent component of the UIVK (BIP32/SLIP-10 secp256k1).
  final Bip32Slip10Secp256k1? transparent;

  /// Sapling incoming viewing key component.
  final SaplingIncomingViewingKey? sapling;

  /// Orchard incoming viewing key component.
  final OrchardIncomingViewingKey? orchard;

  /// Unknown or unsupported component placeholder.
  final ReceiverUnknown? unknown;

  /// ZIP32 coin configuration used for key derivation.
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
    required ZCashNetwork network,
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
    required ZCashNetwork network,
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

  /// Encodes this unified incoming viewing key (UIVK) into a Zcash-compatible unified string.
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

  /// Returns the Sapling-derived address at the given diversifier index.
  SaplingDerivedAddress saplingAddressAt(DiversifierIndex index) {
    try {
      final sapling = getSapling();
      final addressBytes = sapling.addressAt(index).toBytes();
      return SaplingDerivedAddress(
        address: ZCashAddrEncoder().encodeKey(
          addressBytes,
          addrType: ZCashAddressType.sapling,
          network: config.network,
        ),
        paymentAddress: SaplingPaymentAddress.fromBytes(addressBytes),
        index: index,
        receiver: ReceiverSapling(
          data: addressBytes,
          mode: UnifiedReceiverMode.address,
        ),
      );
      // return ;
    } catch (_) {
      throw ZCashKeyError("Invalid sapling Diversifier index.");
    }
  }

  /// Finds the first Sapling-derived address starting from the given diversifier index.
  SaplingDerivedAddress? findSaplingAddressFrom(DiversifierIndex from) {
    final sapling = getSapling();
    final addr = sapling.findAddress(from);
    if (addr == null) return null;
    final addressBytes = addr.$1.toBytes();
    final addrString = ZCashAddrEncoder().encodeKey(
      addressBytes,
      addrType: ZCashAddressType.sapling,
      network: config.network,
    );
    return SaplingDerivedAddress(
      address: addrString,
      paymentAddress: SaplingPaymentAddress.fromBytes(addressBytes),
      index: addr.$2,
      receiver: ReceiverSapling(
        data: addressBytes,
        mode: UnifiedReceiverMode.address,
      ),
    );
  }

  /// Returns the transparent-derived address at the given index with specified pubkey mode and address type.
  TransparentDerivedAddress transparentAddress(
    DiversifierIndex index, {
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
    List<int>? transparentScriptHash,
    TransparentAddressRequestType transparentAddressType =
        TransparentAddressRequestType.p2pkh,
  }) {
    final transparent = getTransparent();
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
      throw ZCashKeyError("Invalid transparent child index.");
    }
    final child = transparent.childKey(bipIndex);
    final receiver = switch (transparentAddressType) {
      TransparentAddressRequestType.p2pkh => ReceiverP2pkh(
        data: P2PKHAddrEncoder().validateAndHashKey(
          child.publicKey.compressed,
          pubKeyMode: pubKeyMode,
        ),
        mode: UnifiedReceiverMode.address,
      ),
      TransparentAddressRequestType.p2sh => ReceiverP2sh(
        transparentScriptHash ??
            P2SHAddrEncoder().validateAndHashKey(child.publicKey.compressed),
      ),
    };
    return TransparentDerivedAddress(
      address: P2PKHAddrEncoder().encodeKey(
        child.publicKey.compressed,
        pubKeyMode: pubKeyMode,
        netVersion: config.b58PubkeyAddressPrefix,
      ),
      type: transparentAddressType,
      bip32Index: bipIndex,
      pubKeyMode: pubKeyMode,
      publicKey: child.publicKey,
      receiver: receiver,
    );
  }

  /// Returns the unified address at the given index, using the specified address request configuration.
  UnifiedDerivedAddress address({
    required DiversifierIndex index,
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
  }) {
    try {
      return _address(index: index, request: request);
    } on SaplingKeyError {
      throw ZCashKeyError("Invalid sapling Diversifier index.");
    }
  }

  /// Finds the first unified address starting from the given index that matches the specified request.
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
    throw ZCashKeyError("Diversifier index space exhausted.");
  }

  /// Returns the default unified address for this account using the specified request configuration.
  UnifiedDerivedAddress defaultAddress({
    UnifiedAddressRequest request =
        const UnifiedAddressRequest.defaultRequest(),
  }) {
    return findAddress(from: DiversifierIndex.zero(), request: request);
  }

  /// Returns the default transparent-derived address with the specified pubkey mode and address type.
  TransparentDerivedAddress defaultTransparentAddress({
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

  /// Returns the transparent component of the UIVK, or throws if missing.
  Bip32Slip10Secp256k1 getTransparent() {
    final transparent = this.transparent;
    if (transparent == null) {
      throw ZCashKeyError("Transparent key missing.");
    }
    return transparent;
  }

  /// Returns the Sapling component of the UIVK, or throws if missing.
  SaplingIncomingViewingKey getSapling() {
    final sapling = this.sapling;
    if (sapling == null) {
      throw ZCashKeyError("Sapling key missing.");
    }
    return sapling;
  }

  /// Returns the Orchard component of the UIVK, or throws if missing.
  OrchardIncomingViewingKey getOrchard() {
    final orchard = this.orchard;
    if (orchard == null) {
      throw ZCashKeyError("Orchard key missing.");
    }
    return orchard;
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
      throw ZCashKeyError("Sapling key required but missing.");
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
      throw ZCashKeyError("Invalid sapling Diversifier index.");
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
      throw ZCashKeyError("Orchard key required but missing.");
    }
    final addr = orchard.addressAt(index);
    return ReceiverOrchard(
      data: addr.toBytes(),
      mode: UnifiedReceiverMode.address,
    );
  }

  TransparentDerivedAddress? _getTransparentReceiver({
    required DiversifierIndex index,
    required UnifiedAddressRequest request,
  }) {
    if (!request.transparentAllowed) return null;

    final transparent = this.transparent;
    final transparentRequired = request.transparentRequired;
    if (transparent == null && !transparentRequired) return null;
    if (transparent == null) {
      throw ZCashKeyError("Transparent key required but missing.");
    }
    final bipIndex = index.toBip32Index();
    if (bipIndex == null) {
      if (!transparentRequired) return null;
      throw ZCashKeyError("Invalid transparent child index.");
    }
    final child = transparent.childKey(bipIndex);
    final receiver = switch (request.transparentAddressType) {
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
    return TransparentDerivedAddress(
      address: P2PKHAddrEncoder().encodeKey(
        child.publicKey.compressed,
        pubKeyMode: PubKeyModes.compressed,
        netVersion: config.b58PubkeyAddressPrefix,
      ),
      pubKeyMode: PubKeyModes.compressed,
      type: request.transparentAddressType,
      bip32Index: bipIndex,
      publicKey: child.publicKey,
      receiver: receiver,
    );
  }

  void _validateUnifiedRequest(UnifiedAddressRequest request) {
    final hasSapling = sapling != null;
    final hasOrchard = orchard != null;
    final hasTransparent = transparent != null;

    // Must have at least one shielded key
    if (!hasSapling && !hasOrchard) {
      throw ZCashKeyError("Unified address requires Sapling or Orchard key.");
    }

    // Request must allow at least one shielded type
    if (!request.orchardAllowed && !request.saplingAllowed) {
      throw ZCashKeyError("Request disallows all shielded receivers.");
    }

    // Required receiver checks
    if (request.saplingRequired && !hasSapling) {
      throw ZCashKeyError("Sapling key required but missing.");
    }

    if (request.orchardRequired && !hasOrchard) {
      throw ZCashKeyError("Orchard key required but missing.");
    }

    if (request.transparentRequired && !hasTransparent) {
      throw ZCashKeyError("Transparent key required but missing.");
    }
  }

  UnifiedDerivedAddress _address({
    required DiversifierIndex index,
    required UnifiedAddressRequest request,
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
        if (transparent != null) transparent.receiver,
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
}
