import 'package:blockchain_utils/bip/address/encoders.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/musig2/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';

import '../exception/exception.dart';

class MuSig2 {
  /// Aggregates public nonces for MuSig2
  static List<int> nonceAgg(List<List<int>> pubnonces) {
    if (pubnonces.length < MuSig2Const.minimumRequiredKey) {
      throw MuSig2Exception(
          "At least two public nonces are required for aggregation.");
    }
    for (final i in pubnonces) {
      if (i.length != MuSig2Const.pubnonceLength) {
        throw MuSig2Exception("Invalid public nonce length.", details: {
          "excpected": MuSig2Const.pubnonceLength,
          "length": i.length
        });
      }
    }
    final nonce = DynamicByteTracker();
    for (int i = 1; i < 3; i++) {
      ProjectiveECCPoint? rJ;
      for (final n in pubnonces) {
        final offset = (i - 1) * EcdsaKeysConst.pubKeyCompressedByteLen;
        final key = MuSig2Utils.encodePointAsEven(
            n.sublist(offset, offset + EcdsaKeysConst.pubKeyCompressedByteLen));
        if (rJ != null) {
          rJ = (rJ + key).cast();
        } else {
          rJ = key;
        }
      }
      if (rJ!.isInfinity) {
        nonce.add(MuSig2Const.zero);
      } else {
        nonce.add(rJ.toBytes());
      }
    }

    return nonce.toBytes();
  }

  /// Generates a MuSig2 nonce for signing
  static MuSig2Nonce nonceGenerate(
      {required List<int> publicKey,
      List<int>? rand,
      List<int>? sk,
      List<int>? aggPubKey,
      List<int>? msg,
      List<int>? extra}) {
    if (publicKey.length != EcdsaKeysConst.pubKeyCompressedByteLen) {
      throw MuSig2Exception("Invalid public key length.", details: {
        "expected": EcdsaKeysConst.pubKeyCompressedByteLen,
        "length": publicKey.length
      });
    }
    rand ??= QuickCrypto.generateRandom();
    if (sk != null) {
      rand = BytesUtils.xor(
          sk, P2TRUtils.taggedHash(MuSig2Const.musigAuxDomain, rand));
    }
    if (msg == null) {
      msg = [0];
    } else {
      msg = [
        1,
        ...BigintUtils.toBytes(BigInt.from(msg.length), length: 8),
        ...msg
      ];
    }
    extra ??= [];
    aggPubKey ??= [];
    final k1 = MuSig2Utils.nonceHash(
            rand: rand,
            publicKey: publicKey,
            aggPk: aggPubKey,
            i: 0,
            messagePrefix: msg,
            extraIn: extra) %
        MuSig2Const.order;
    final k2 = MuSig2Utils.nonceHash(
            rand: rand,
            publicKey: publicKey,
            aggPk: aggPubKey,
            i: 1,
            messagePrefix: msg,
            extraIn: extra) %
        MuSig2Const.order;
    final rs1 = MuSig2Const.generator * k1;
    final rs2 = MuSig2Const.generator * k2;
    final pubNonce = [...rs1.toBytes(), ...rs2.toBytes()];
    final secNonce = [
      ...BigintUtils.toBytes(k1, length: BigintUtils.bitlengthInBytes(k1)),
      ...BigintUtils.toBytes(k2, length: BigintUtils.bitlengthInBytes(k1)),
      ...publicKey
    ];
    return MuSig2Nonce(secnonce: secNonce, pubnonce: pubNonce);
  }

  /// sort public keys
  static List<List<int>> sortPublicKeys({required List<List<int>> keys}) {
    return MuSig2Utils.sortPublicKeys(keys);
  }

  /// Aggregates public keys for MuSig2
  static MuSig2KeyAggContext aggPublicKeys({required List<List<int>> keys}) {
    return MuSig2Utils.aggPublicKeys(keys: keys);
  }

  /// Verifies a MuSig2 partial signature
  static bool partialSigVerify(
      {required List<int> signature,
      required List<int> pubnonce,
      required List<int> pk,
      required MuSig2Session session}) {
    if (pubnonce.length != MuSig2Const.pubnonceLength) {
      throw MuSig2Exception("Invalid public nonce length.", details: {
        "expected": MuSig2Const.pubnonceLength,
        "length": pubnonce.length
      });
    }
    final values = MuSig2Utils.decodeSession(session);
    final sBig = BigintUtils.fromBytes(signature);
    if (sBig >= MuSig2Const.order) return false;
    final rS1 = MuSig2Utils.encodePointAsEven(
        pubnonce.sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen));
    final rS2 = MuSig2Utils.encodePointAsEven(pubnonce.sublist(
        EcdsaKeysConst.pubKeyCompressedByteLen,
        EcdsaKeysConst.pubKeyCompressedByteLen * 2));
    ProjectiveECCPoint reS =
        (rS1 + (rS2 * values.b)).cast<ProjectiveECCPoint>();
    if (values.r.isOdd) {
      reS = -reS;
    }
    final p = MuSig2Utils.encodePoint(pk);
    final a = MuSig2Utils.getSessionKeyAggCoeff(session: session, pk: p);
    BigInt g = BigInt.one;
    if (values.publicKey.isOdd) {
      g = MuSig2Const.order - BigInt.one;
    }
    g = g * values.gacc % MuSig2Const.order;
    final expected = MuSig2Const.generator * sBig;
    final r = (reS + (p * (values.e * a * g % MuSig2Const.order)))
        .cast<ProjectiveECCPoint>();

    return expected == r;
  }

  /// Generates a MuSig2 partial signature
  static List<int> sign(
      {required List<int> secnonce,
      required List<int> sk,
      required MuSig2Session session}) {
    if (secnonce.length != MuSig2Const.secnoncelength) {
      throw MuSig2Exception("Invalid secrent nonce length.", details: {
        "expected": MuSig2Const.secnoncelength,
        "length": secnonce.length
      });
    }
    final values = MuSig2Utils.decodeSession(session);
    BigInt k1 = BigintUtils.fromBytes(
        secnonce.sublist(0, MuSig2Const.xOnlyBytesLength));
    BigInt k2 = BigintUtils.fromBytes(secnonce.sublist(
        MuSig2Const.xOnlyBytesLength, MuSig2Const.xOnlyBytesLength * 2));
    if (k1 <= BigInt.zero || k1 >= MuSig2Const.order) {
      throw MuSig2Exception("Invalid secret nonce.");
    }
    if (k2 <= BigInt.zero || k2 >= MuSig2Const.order) {
      throw MuSig2Exception("Invalid secret nonce.");
    }
    BigInt kE1 = k1;
    BigInt kE2 = k2;
    if (values.r.isOdd) {
      kE1 = MuSig2Const.order - k1;
      kE2 = MuSig2Const.order - k2;
    }
    BigInt d = BigintUtils.fromBytes(sk);
    if (d <= BigInt.zero || d >= MuSig2Const.order) {
      throw MuSig2Exception("Second secnonce is invalid.");
    }
    final p = MuSig2Const.generator * d;
    final pkBytes = p.toBytes();
    final pkOffset = MuSig2Const.xOnlyBytesLength * 2;
    if (!BytesUtils.bytesEqual(
        secnonce.sublist(
            pkOffset, pkOffset + EcdsaKeysConst.pubKeyCompressedByteLen),
        pkBytes)) {
      throw MuSig2Exception(
          "invalid secret key. nonce public key does not match with secret pub key.");
    }
    final a = MuSig2Utils.getSessionKeyAggCoeff(session: session, pk: p);
    BigInt g = BigInt.one;
    if (values.publicKey.isOdd) {
      g = MuSig2Const.order - BigInt.one;
    }
    d = g * values.gacc * d % MuSig2Const.order;
    final s = (kE1 + values.b * kE2 + values.e * a * d) % MuSig2Const.order;
    final sig = BigintUtils.toBytes(s, length: BigintUtils.bitlengthInBytes(s))
        .toImutableBytes;
    final rS1 = MuSig2Const.generator * k1;
    final rS2 = MuSig2Const.generator * k2;
    final List<int> pubnonce = [...rS1.toBytes(), ...rS2.toBytes()];
    final verify = partialSigVerify(
        signature: sig, pubnonce: pubnonce, pk: pkBytes, session: session);
    if (!verify) {
      throw MuSig2Exception("Generated signature does not pass verification.");
    }
    return sig;
  }

  /// Generates a deterministic MuSig2 signature
  static MuSig2DeterministicSignature deterministicSign(
      {required List<int> sk,
      required List<int> aggotherNonce,
      required List<List<int>> publicKeys,
      List<MuSig2Tweak> tweaks = const [],
      required List<int> msg,
      List<int>? rand}) {
    if (rand != null) {
      rand = BytesUtils.xor(
          sk, P2TRUtils.taggedHash(MuSig2Const.musigAuxDomain, rand));
    } else {
      rand = List<int>.from(sk);
    }
    final aggPk =
        MuSig2Utils.keyAggAndTweak(publicKeys: publicKeys, tweaks: tweaks);
    final aggPkX = aggPk.xOnly().asImmutableBytes;
    final k1 = MuSig2Utils.deterministicNonceHash(
            sk: rand,
            aggotherNonce: aggotherNonce,
            aggPk: aggPkX,
            i: 0,
            msg: msg) %
        MuSig2Const.order;
    final k2 = MuSig2Utils.deterministicNonceHash(
            sk: rand,
            aggotherNonce: aggotherNonce,
            aggPk: aggPkX,
            i: 1,
            msg: msg) %
        MuSig2Const.order;

    if (k1 == BigInt.zero || k2 == BigInt.zero) {
      throw MuSig2Exception("derive nonce hash failed.");
    }
    final rs1 = MuSig2Const.generator * k1;
    final rs2 = MuSig2Const.generator * k2;
    final pk = MuSig2Utils.scToPk(sk);
    final pubnonce = [...rs1.toBytes(), ...rs2.toBytes()];
    final secnonce = [
      ...BigintUtils.toBytes(k1, length: BigintUtils.bitlengthInBytes(k1)),
      ...BigintUtils.toBytes(k2, length: BigintUtils.bitlengthInBytes(k2)),
      ...pk
    ].asImmutableBytes;
    final aggnonce = nonceAgg([pubnonce, aggotherNonce]);
    final session = MuSig2Session(
        aggnonce: aggnonce, publicKeys: publicKeys, tweaks: tweaks, msg: msg);
    final signature = sign(secnonce: secnonce, sk: sk, session: session);
    return MuSig2DeterministicSignature(
        pubnonce: pubnonce, signature: signature);
  }

  /// Aggregates MuSig2 partial signatures
  static List<int> partialSigAgg(
      {required List<List<int>> signatures, required MuSig2Session session}) {
    final values = MuSig2Utils.decodeSession(session);
    BigInt s = BigInt.zero;
    for (final i in signatures) {
      final sBig = BigintUtils.fromBytes(i);
      if (sBig >= MuSig2Const.order) {
        throw MuSig2Exception("Invalid schnorr signature.");
      }
      s = (s + sBig) % MuSig2Const.order;
    }
    BigInt g = BigInt.one;
    if (values.publicKey.isOdd) {
      g = MuSig2Const.order - BigInt.one;
    }
    s = (s + values.e * g * values.tacc) % MuSig2Const.order;
    return [
      ...values.r.toXonly(),
      ...BigintUtils.toBytes(s, length: BigintUtils.bitlengthInBytes(s))
    ];
  }
}
