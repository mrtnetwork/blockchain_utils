import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/constants/const.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// A MuSig2 partial signature produced deterministically, with the
/// public nonce that accompanies it.
class MuSig2DeterministicSignature {
  final BuBytes pubnonce;
  final BuBytes signature;
  MuSig2DeterministicSignature._({
    required List<int> pubnonce,
    required List<int> signature,
  }) : pubnonce = pubnonce.asImmutableBytes,
       signature = signature.asImmutableBytes;
  factory MuSig2DeterministicSignature({
    required List<int> signature,
    required List<int> pubnonce,
  }) {
    if (pubnonce.length != MuSig2Constants.pubnonceLength) {
      throw CoreErrors.invalidOperationArguments(
        "MuSig2DeterministicSignature",
        name: "pubnonce",
        reason: "Invalid pubnonce length.",
      );
    }
    return MuSig2DeterministicSignature._(
      signature: signature,
      pubnonce: pubnonce,
    );
  }
}

/// A MuSig2 nonce pair: the secret nonce and its public counterpart.
class MuSig2Nonce with Equality {
  final BuBytes secnonce;
  final BuBytes pubnonce;

  /// Signer public key: validated once at construction, stored as bytes.
  final BuBytes publicKey;
  MuSig2Nonce._({
    required List<int> secnonce,
    required List<int> pubnonce,
    required List<int> publicKey,
  }) : secnonce = secnonce.asImmutableBytes,
       pubnonce = pubnonce.asImmutableBytes,
       publicKey = publicKey.asImmutableBytes;
  factory MuSig2Nonce({
    required List<int> pubnonce,
    required List<int> secnonce,
  }) {
    if (pubnonce.length != MuSig2Constants.pubnonceLength) {
      throw CoreErrors.invalidOperationArguments(
        "MuSig2Nonce",
        name: "pubnonce",
        reason: "Invalid pubnonce length.",
      );
    }
    if (secnonce.length != MuSig2Constants.secnoncelength) {
      throw CoreErrors.invalidOperationArguments(
        "MuSig2Nonce",
        name: "secnonce",
        reason: "Invalid secret nonce length.",
      );
    }
    final signerKey = secnonce.sublist(
      secnonce.length - EcdsaKeysConst.pubKeyCompressedByteLen,
    );
    try {
      final pubKey = Secp256k1Point.fromBytes(signerKey);
      if (pubKey.isZero()) {
        throw CoreErrors.invalidOperationArguments(
          "MuSig2Nonce",
          name: "secnonce",
          reason: "Invalid secret nonce key.",
        );
      }
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "MuSig2Nonce",
        name: "secnonce",
        reason: "Invalid secret nonce key.",
      );
    }
    try {
      final r1 = Secp256k1Point.fromBytes(
        pubnonce.sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen),
      );
      final r2 = Secp256k1Point.fromBytes(
        pubnonce.sublist(EcdsaKeysConst.pubKeyCompressedByteLen),
      );
      if (r1.isZero() || r2.isZero()) {
        throw CoreErrors.invalidOperationArguments(
          "MuSig2Nonce",
          name: "pubnonce",
          reason: "Invalid public nonce key.",
        );
      }
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "MuSig2Nonce",
        name: "pubnonce",
        reason: "Invalid public nonce key.",
      );
    }
    return MuSig2Nonce._(
      secnonce: secnonce,
      pubnonce: pubnonce,
      publicKey: signerKey,
    );
  }

  @override
  List<dynamic> get variables => [secnonce, pubnonce, publicKey];
}

/// Per-signer state for one MuSig2 signing session.
class MuSig2Session with Equality {
  final BuBytes aggnonce;
  final List<BuBytes> publicKeys;
  final List<MuSig2Tweak> tweaks;
  final BuBytes msg;
  MuSig2Session._({
    required List<int> aggnonce,
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
    required List<int> msg,
  }) : aggnonce = aggnonce.asImmutableBytes,
       publicKeys = publicKeys.map((e) => e.asImmutableBytes).toImutableList,
       tweaks = tweaks.immutable,
       msg = msg.asImmutableBytes;

  factory MuSig2Session({
    required List<int> aggnonce,
    required List<List<int>> publicKeys,
    List<MuSig2Tweak> tweaks = const [],
    required List<int> msg,
  }) {
    List<Secp256k1Point> pubKeys = [];
    try {
      pubKeys = publicKeys.map((e) => Secp256k1Point.fromBytes(e)).toList();
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "MuSig2Session",
        name: "pubKeys",
        reason: "Invalid public keys.",
      );
    }
    if (publicKeys.toSet().length != pubKeys.length) {
      throw CoreErrors.invalidOperationArguments(
        "MuSig2Session",
        name: "pubKeys",
        reason: "Duplicate public key not allowed.",
      );
    }
    if (pubKeys.length < MuSig2Constants.minimumRequiredKey) {
      throw CoreErrors.invalidOperationArguments(
        "MuSig2Session",
        name: "pubKeys",
        reason:
            "At least ${MuSig2Constants.minimumRequiredKey} public keys require.",
      );
    }
    return MuSig2Session._(
      aggnonce: aggnonce,
      publicKeys: publicKeys,
      tweaks: tweaks,
      msg: msg,
    );
  }

  @override
  List<dynamic> get variables => [aggnonce, publicKeys, tweaks, msg];
}

/// A tweak applied to an aggregated MuSig2 key (x-only or plain).
class MuSig2Tweak with Equality {
  final BuBytes tweak;
  final bool isXOnly;
  MuSig2Tweak({required List<int> tweak, this.isXOnly = true})
    : tweak =
          tweak
              .exc(
                length: MuSig2Constants.xOnlyBytesLength,
                operation: "MuSig2Tweak",
                reason: "Invalid tweak bytes length",
              )
              .asImmutableBytes;

  @override
  List<dynamic> get variables => [tweak, isXOnly];
}

/// The result of aggregating signer public keys, plus any applied tweaks.
class MuSig2KeyAggContext {
  final Secp256k1Point publicKey;
  final BuBytes gacc;
  final BuBytes tacc;
  MuSig2KeyAggContext._({
    required this.publicKey,
    required List<int> gacc,
    required List<int> tacc,
  }) : gacc = gacc.asImmutableBytes,
       tacc = tacc.asImmutableBytes;
  factory MuSig2KeyAggContext({
    required Secp256k1Point publicKey,
    required List<int> gacc,
    required List<int> tacc,
  }) {
    if (publicKey.isZero()) {
      throw CoreErrors.invalidOperationArguments(
        "MuSig2KeyAggContext",
        name: "pubKeys",
        reason: "Invalid aggregated public key.",
      );
    }
    return MuSig2KeyAggContext._(publicKey: publicKey, gacc: gacc, tacc: tacc);
  }

  Secp256k1Fr get gaccFr => Secp256k1Fr.fromBytes(gacc);
  Secp256k1Fr get taccFr => Secp256k1Fr.fromBytes(tacc);
  BuBytes xOnly() {
    return publicKey.toXOnly();
  }

  BuBytes toBytes() {
    return publicKey.toBytes();
  }
}

/// Values derived once per session and reused across partial signatures.
class MuSig2SessionValues {
  final Secp256k1Point publicKey;
  final BuBytes gacc;
  final BuBytes tacc;
  final BuBytes b;
  final Secp256k1Point r;
  final BuBytes e;

  Secp256k1Fr get gaccFr => Secp256k1Fr.fromBytes(gacc);
  Secp256k1Fr get taccFr => Secp256k1Fr.fromBytes(tacc);
  Secp256k1Fr get bFr => Secp256k1Fr.fromBytes(b);
  Secp256k1Fr get eFr => Secp256k1Fr.fromBytes(e);
  MuSig2SessionValues({
    required this.publicKey,
    required List<int> gacc,
    required List<int> tacc,
    required List<int> b,
    required this.r,
    required List<int> e,
  }) : gacc = gacc.asImmutableBytes,
       tacc = tacc.asImmutableBytes,
       b = b.asImmutableBytes,
       e = e.asImmutableBytes;
}
