import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class MuSig2DeterministicSignature {
  final List<int> pubnonce;
  final List<int> signature;
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
      throw ArgumentException.invalidOperationArguments(
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

class MuSig2Nonce {
  final List<int> secnonce;
  final List<int> pubnonce;
  final ProjectiveECCPoint publicKey;
  MuSig2Nonce._({
    required List<int> secnonce,
    required List<int> pubnonce,
    required this.publicKey,
  }) : secnonce = secnonce.asImmutableBytesConst,
       pubnonce = pubnonce.asImmutableBytes;
  factory MuSig2Nonce({
    required List<int> pubnonce,
    required List<int> secnonce,
  }) {
    if (pubnonce.length != MuSig2Constants.pubnonceLength) {
      throw ArgumentException.invalidOperationArguments(
        "MuSig2Nonce",
        name: "pubnonce",
        reason: "Invalid pubnonce length.",
      );
    }
    if (secnonce.length != MuSig2Constants.secnoncelength) {
      throw ArgumentException.invalidOperationArguments(
        "MuSig2Nonce",
        name: "secnonce",
        reason: "Invalid secret nonce length.",
      );
    }
    ProjectiveECCPoint pubKey;
    try {
      pubKey = ProjectiveECCPoint.fromBytes(
        curve: MuSig2Constants.curve,
        data: secnonce.sublist(
          secnonce.length - EcdsaKeysConst.pubKeyCompressedByteLen,
        ),
      );
      if (pubKey.isZero()) {
        throw ArgumentException.invalidOperationArguments(
          "MuSig2Nonce",
          name: "secnonce",
          reason: "Invalid secret nonce key.",
        );
      }
    } catch (_) {
      throw ArgumentException.invalidOperationArguments(
        "MuSig2Nonce",
        name: "secnonce",
        reason: "Invalid secret nonce key.",
      );
    }
    try {
      final r1 = ProjectiveECCPoint.fromBytes(
        curve: MuSig2Constants.curve,
        data: pubnonce.sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen),
      );
      final r2 = ProjectiveECCPoint.fromBytes(
        curve: MuSig2Constants.curve,
        data: pubnonce.sublist(EcdsaKeysConst.pubKeyCompressedByteLen),
      );
      if (r1.isZero() || r2.isZero()) {
        throw ArgumentException.invalidOperationArguments(
          "MuSig2Nonce",
          name: "pubnonce",
          reason: "Invalid public nonce key.",
        );
      }
    } catch (_) {
      throw ArgumentException.invalidOperationArguments(
        "MuSig2Nonce",
        name: "pubnonce",
        reason: "Invalid public nonce key.",
      );
    }
    return MuSig2Nonce._(
      secnonce: secnonce,
      pubnonce: pubnonce,
      publicKey: pubKey,
    );
  }
}

class MuSig2Session {
  final List<int> aggnonce;
  final List<List<int>> publicKeys;
  final List<MuSig2Tweak> tweaks;
  final List<int> msg;
  MuSig2Session._({
    required List<int> aggnonce,
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
    required List<int> msg,
  }) : aggnonce = aggnonce.asImmutableBytesConst,
       publicKeys =
           publicKeys.map((e) => e.asImmutableBytesConst).toImutableList,
       tweaks = tweaks.immutable,
       msg = msg.asImmutableBytesConst;

  factory MuSig2Session({
    required List<int> aggnonce,
    required List<List<int>> publicKeys,
    List<MuSig2Tweak> tweaks = const [],
    required List<int> msg,
  }) {
    List<ProjectiveECCPoint> pubKeys = [];
    try {
      pubKeys =
          publicKeys
              .map(
                (e) => ProjectiveECCPoint.fromBytes(
                  curve: Curves.curveSecp256k1,
                  data: e,
                ),
              )
              .toList();
    } catch (_) {
      throw ArgumentException.invalidOperationArguments(
        "MuSig2Session",
        name: "pubKeys",
        reason: "Invalid public keys.",
      );
    }
    if (publicKeys.toSet().length != pubKeys.length) {
      throw ArgumentException.invalidOperationArguments(
        "MuSig2Session",
        name: "pubKeys",
        reason: "Duplicate public key not allowed.",
      );
    }
    if (pubKeys.length < MuSig2Constants.minimumRequiredKey) {
      throw ArgumentException.invalidOperationArguments(
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
}

class MuSig2Tweak {
  final List<int> tweak;
  final bool isXOnly;
  MuSig2Tweak({required List<int> tweak, this.isXOnly = true})
    : tweak = tweak.asImmutableBytesConst;
}

class MuSig2KeyAggContext {
  final ProjectiveECCPoint publicKey;
  final List<int> gacc;
  final List<int> tacc;
  const MuSig2KeyAggContext._({
    required this.publicKey,
    required this.gacc,
    required this.tacc,
  });
  factory MuSig2KeyAggContext({
    required ProjectiveECCPoint publicKey,
    required List<int> gacc,
    required List<int> tacc,
  }) {
    if (publicKey.isZero()) {
      throw ArgumentException.invalidOperationArguments(
        "MuSig2KeyAggContext",
        name: "pubKeys",
        reason: "Invalid aggregated public key.",
      );
    }
    return MuSig2KeyAggContext._(publicKey: publicKey, gacc: gacc, tacc: tacc);
  }
  List<int> xOnly() {
    return publicKey.toXonly();
  }

  List<int> toBytes() {
    return publicKey.toBytes();
  }

  List<int> keyBytes() {
    return publicKey.toBytes();
  }

  String hex() {
    return publicKey.toHex();
  }

  BigInt get gaccAsInteger => BigintUtils.fromBytes(gacc);

  BigInt get taccAsInteger => BigintUtils.fromBytes(tacc);
}

class MuSig2SessionValues {
  final ProjectiveECCPoint publicKey;
  final List<int> gacc;
  final List<int> tacc;
  final List<int> b;
  final ProjectiveECCPoint r;
  final List<int> e;

  BigInt get gaccAsInteger => BigintUtils.fromBytes(gacc);

  BigInt get taccAsInteger => BigintUtils.fromBytes(tacc);
  BigInt get bAsInteger => BigintUtils.fromBytes(b);
  BigInt get eAsInteger => BigintUtils.fromBytes(e);
  const MuSig2SessionValues({
    required this.publicKey,
    required this.gacc,
    required this.tacc,
    required this.b,
    required this.r,
    required this.e,
  });
}
