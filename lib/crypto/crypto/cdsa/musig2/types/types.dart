import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

class MuSig2DeterministicSignature {
  final List<int> pubnonce;
  final List<int> signature;
  MuSig2DeterministicSignature._(
      {required List<int> pubnonce, required List<int> signature})
      : pubnonce = pubnonce.asImmutableBytes,
        signature = signature.asImmutableBytes;
  factory MuSig2DeterministicSignature(
      {required List<int> signature, required List<int> pubnonce}) {
    if (pubnonce.length != MuSig2Const.pubnonceLength) {
      throw MuSig2Exception("Invalid public nonce length.", details: {
        "expected": MuSig2Const.pubnonceLength,
        "length": signature.length
      });
    }
    return MuSig2DeterministicSignature._(
        signature: signature, pubnonce: pubnonce);
  }
}

class MuSig2Nonce {
  final List<int> secnonce;
  final List<int> pubnonce;
  final ProjectiveECCPoint publicKey;
  MuSig2Nonce._(
      {required List<int> secnonce,
      required List<int> pubnonce,
      required this.publicKey})
      : secnonce = secnonce.asImmutableBytes,
        pubnonce = pubnonce.asImmutableBytes;
  factory MuSig2Nonce(
      {required List<int> pubnonce, required List<int> secnonce}) {
    if (pubnonce.length != MuSig2Const.pubnonceLength) {
      throw MuSig2Exception("Invalid public nonce length.", details: {
        "excpected": MuSig2Const.pubnonceLength,
        "length": pubnonce.length
      });
    }
    if (secnonce.length != MuSig2Const.secnoncelength) {
      throw MuSig2Exception("Invalid secrent nonce length.", details: {
        "excpected": MuSig2Const.secnoncelength,
        "length": pubnonce.length
      });
    }
    ProjectiveECCPoint pubKey;
    try {
      pubKey = ProjectiveECCPoint.fromBytes(
          curve: MuSig2Const.curve,
          data: secnonce.sublist(
              secnonce.length - EcdsaKeysConst.pubKeyCompressedByteLen));
      if (pubKey.isInfinity) {
        throw MuSig2Exception(
            "Invalid secret nonce public key. infinity key not allowed.");
      }
    } on MuSig2Exception {
      rethrow;
    } catch (_) {
      throw MuSig2Exception("Invalid secret nonce public key.");
    }
    try {
      final r1 = ProjectiveECCPoint.fromBytes(
          curve: MuSig2Const.curve,
          data: pubnonce.sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen));
      final r2 = ProjectiveECCPoint.fromBytes(
          curve: MuSig2Const.curve,
          data: pubnonce.sublist(EcdsaKeysConst.pubKeyCompressedByteLen));
      if (r1.isInfinity || r2.isInfinity) {
        throw MuSig2Exception(
            "Invalid public nonce. infinity key not allowed.");
      }
    } on MuSig2Exception {
      rethrow;
    } catch (_) {
      throw MuSig2Exception("Invalid public nonce.");
    }
    return MuSig2Nonce._(
        secnonce: secnonce, pubnonce: pubnonce, publicKey: pubKey);
  }
}

class MuSig2Session {
  final List<int> aggnonce;
  final List<List<int>> publicKeys;
  final List<MuSig2Tweak> tweaks;
  final List<int> msg;
  MuSig2Session._(
      {required List<int> aggnonce,
      required List<List<int>> publicKeys,
      required List<MuSig2Tweak> tweaks,
      required List<int> msg})
      : aggnonce = aggnonce.asImmutableBytes,
        publicKeys = publicKeys.map((e) => e.asImmutableBytes).toImutableList,
        tweaks = tweaks.immutable,
        msg = msg.asImmutableBytes;

  factory MuSig2Session(
      {required List<int> aggnonce,
      required List<List<int>> publicKeys,
      List<MuSig2Tweak> tweaks = const [],
      required List<int> msg}) {
    List<ProjectiveECCPoint> pubKeys = [];
    try {
      pubKeys = publicKeys
          .map((e) => ProjectiveECCPoint.fromBytes(
              curve: Curves.curveSecp256k1, data: e))
          .toList();
    } catch (_) {
      throw MuSig2Exception("Invalid public key.");
    }
    if (publicKeys.toSet().length != pubKeys.length) {
      throw MuSig2Exception(
          "Multiple keys not allowed. Duplicate key detected.");
    }
    if (pubKeys.length < MuSig2Const.minimumRequiredKey) {
      throw MuSig2Exception(
          "At least ${MuSig2Const.minimumRequiredKey} public keys required.");
    }
    return MuSig2Session._(
        aggnonce: aggnonce, publicKeys: publicKeys, tweaks: tweaks, msg: msg);
  }
}

class MuSig2Tweak {
  final List<int> tweak;
  final bool isXOnly;
  MuSig2Tweak({required List<int> tweak, this.isXOnly = true})
      : tweak = tweak.asImmutableBytes;
}

class MuSig2KeyAggContext {
  final ProjectiveECCPoint publicKey;
  final BigInt gacc;
  final BigInt tacc;
  const MuSig2KeyAggContext._(
      {required this.publicKey, required this.gacc, required this.tacc});
  factory MuSig2KeyAggContext(
      {required ProjectiveECCPoint publicKey,
      required BigInt gacc,
      required BigInt tacc}) {
    if (publicKey.isInfinity) {
      throw MuSig2Exception(
          "The aggregated public key cannot be the point at infinity.");
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
}

class MuSig2SessionValues {
  final ProjectiveECCPoint publicKey;
  final BigInt gacc;
  final BigInt tacc;
  final BigInt b;
  final ProjectiveECCPoint r;
  final BigInt e;
  const MuSig2SessionValues(
      {required this.publicKey,
      required this.gacc,
      required this.tacc,
      required this.b,
      required this.r,
      required this.e});
}
