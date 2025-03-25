import 'package:blockchain_utils/bip/address/p2tr_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/musig2/exception/exception.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/utils/utils.dart';

class MuSig2Utils {
  static List<int> scToPk(List<int> sk) {
    final sBig = BigintUtils.fromBytes(sk);
    if (sBig < BigInt.one || sBig >= MuSig2Const.order) {
      throw MuSig2Exception('Invalid secret key.');
    }
    return (MuSig2Const.generator * sBig).toBytes();
  }

  static bool isValidPartialSignature(List<int> signature) {
    if (signature.length != MuSig2Const.partialSignatureLength) return false;
    final sBig = BigintUtils.fromBytes(signature);
    if (sBig >= MuSig2Const.order) return false;
    return true;
  }

  static bool _isSecondUniqueKey(
      {required List<List<int>> keys, required List<int> key}) {
    for (final k in keys) {
      if (!BytesUtils.bytesEqual(k, keys[0])) {
        if (BytesUtils.bytesEqual(k, key)) {
          return true;
        }
        return false;
      }
    }
    return false;
  }

  static BigInt getSessionKeyAggCoeff(
      {required MuSig2Session session, required ProjectiveECCPoint pk}) {
    final pkBytes = pk.toBytes();
    final signerPk =
        session.publicKeys.any((e) => BytesUtils.bytesEqual(e, pkBytes));
    if (!signerPk) {
      throw MuSig2Exception(
          "The signer pubkey does not exists in pubkey list.");
    }
    return _keyAggCoeff(keys: session.publicKeys, key: pkBytes);
  }

  static List<List<int>> sortPublicKeys(List<List<int>> keys) {
    for (final i in keys) {
      if (i.length != EcdsaKeysConst.pubKeyCompressedByteLen) {
        throw MuSig2Exception("Invalid public key length.", details: {
          "excpected": EcdsaKeysConst.pubKeyCompressedByteLen,
          "length": i.length,
          "key": BytesUtils.toHexString(i)
        });
      }
    }
    final sortKeys = List<List<int>>.from(keys)..sort(BytesUtils.compareBytes);
    return sortKeys;
  }

  static BigInt _keyAggCoeff(
      {required List<List<int>> keys, required List<int> key}) {
    if (_isSecondUniqueKey(keys: keys, key: key)) return BigInt.one;
    final hashKeys = P2TRUtils.taggedHash(
        MuSig2Const.keyAggListDomain, keys.expand((e) => e).toList());
    final hash = P2TRUtils.taggedHash(
        MuSig2Const.keyAggCoeffDomain, [...hashKeys, ...key]);
    return BigintUtils.fromBytes(hash) % MuSig2Const.order;
  }

  static ProjectiveECCPoint encodePoint(List<int> bytes) {
    try {
      return ProjectiveECCPoint.fromBytes(
          curve: MuSig2Const.curve, data: bytes);
    } catch (e) {
      throw MuSig2Exception("Invalid point.",
          details: {"message": e.toString()});
    }
  }

  static ProjectiveECCPoint encodePointAsEven(List<int> keyBytes) {
    try {
      final point = encodePoint(keyBytes);
      final p = P2TRUtils.liftX(point.x);
      if (keyBytes[0] == 2) {
        return p;
      } else if (keyBytes[0] == 3) {
        return -p;
      }
    } catch (_) {}
    throw MuSig2Exception("Invalid comprossed point");
  }

  static ProjectiveECCPoint encodeOrInfinityPoint(List<int> keyBytes) {
    if (BytesUtils.bytesEqual(keyBytes, MuSig2Const.zero)) {
      return ProjectiveECCPoint.infinity(MuSig2Const.curve);
    }
    final point = encodePoint(keyBytes);
    try {
      final p = P2TRUtils.liftX(point.x);
      if (keyBytes[0] == 2) {
        return p;
      } else if (keyBytes[0] == 3) {
        return -p;
      }
    } catch (_) {}
    throw MuSig2Exception("Invalid comprossed point");
  }

  static MuSig2SessionValues decodeSession(MuSig2Session session) {
    final tweak =
        keyAggAndTweak(publicKeys: session.publicKeys, tweaks: session.tweaks);
    final hash = P2TRUtils.taggedHash(MuSig2Const.noncecoefDomain,
        [...session.aggnonce, ...tweak.xOnly(), ...session.msg]);
    final b = BigintUtils.fromBytes(hash) % MuSig2Const.order;
    ProjectiveECCPoint r1 = MuSig2Utils.encodeOrInfinityPoint(
        session.aggnonce.sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen));
    ProjectiveECCPoint r2 = MuSig2Utils.encodeOrInfinityPoint(session.aggnonce
        .sublist(EcdsaKeysConst.pubKeyCompressedByteLen,
            EcdsaKeysConst.pubKeyCompressedByteLen * 2));
    ProjectiveECCPoint r = (r1 + (r2 * b)).cast();
    if (r.isInfinity) {
      r = MuSig2Const.generator;
    }
    final eHash = P2TRUtils.taggedHash(MuSig2Const.challengeDomain,
        [...r.toXonly(), ...tweak.xOnly(), ...session.msg]);
    final e = BigintUtils.fromBytes(eHash) % MuSig2Const.order;
    return MuSig2SessionValues(
        publicKey: tweak.publicKey,
        gacc: tweak.gacc,
        tacc: tweak.tacc,
        b: b,
        r: r,
        e: e);
  }

  static MuSig2KeyAggContext _applyTweak(
      {required MuSig2KeyAggContext context, required MuSig2Tweak tweak}) {
    if (tweak.tweak.length != MuSig2Const.xOnlyBytesLength) {
      throw MuSig2Exception("Invalid tweak length.", details: {
        "excpected": MuSig2Const.xOnlyBytesLength,
        "length": tweak.tweak.length,
      });
    }
    final BigInt order = MuSig2Const.order;
    BigInt g = BigInt.one;
    if (tweak.isXOnly && context.publicKey.isOdd) {
      g = order - BigInt.one;
    }
    BigInt t = BigintUtils.fromBytes(tweak.tweak);
    if (t >= order) {
      throw MuSig2Exception("Invalid tweak. tweak must be less than order.");
    }
    final q = (context.publicKey * g) + (MuSig2Const.generator * t);
    if (q.isInfinity) {
      throw MuSig2Exception("tweaking cannot be infinity.");
    }
    final gacc = (g * context.gacc) % order;
    final tacc = (t + g * context.tacc) % order;
    return MuSig2KeyAggContext(publicKey: q.cast(), gacc: gacc, tacc: tacc);
  }

  static MuSig2KeyAggContext aggPublicKeys({required List<List<int>> keys}) {
    ProjectiveECCPoint? aggKey;
    for (final k in keys) {
      final coeff = _keyAggCoeff(keys: keys, key: k);
      ProjectiveECCPoint key = MuSig2Utils.encodePointAsEven(k);
      key = key * coeff;
      if (aggKey != null) {
        aggKey = (aggKey + key).cast();
      } else {
        aggKey = key;
      }
    }
    return MuSig2KeyAggContext(
        publicKey: aggKey!, gacc: BigInt.one, tacc: BigInt.zero);
  }

  static MuSig2KeyAggContext keyAggAndTweak(
      {required List<List<int>> publicKeys,
      required List<MuSig2Tweak> tweaks}) {
    MuSig2KeyAggContext keyAgg = aggPublicKeys(keys: publicKeys);
    for (int i = 0; i < tweaks.length; i++) {
      final tweak = tweaks[i];
      keyAgg = _applyTweak(context: keyAgg, tweak: tweak);
    }
    return keyAgg;
  }

  static BigInt nonceHash(
      {required List<int> rand,
      required List<int> publicKey,
      required List<int> aggPk,
      required int i,
      required List<int> messagePrefix,
      required List<int> extraIn}) {
    assert(publicKey.length == EcdsaKeysConst.pubKeyCompressedByteLen,
        "invalid public key length");
    assert(aggPk.length <= MuSig2Const.xOnlyBytesLength,
        "Invalid xonly agg key bytes.");
    final bytes = DynamicByteTracker();
    bytes.add(rand);
    bytes.add([publicKey.length]);
    bytes.add(publicKey);
    bytes.add([aggPk.length]);
    bytes.add(aggPk);
    bytes.add(messagePrefix);
    bytes.add(IntUtils.toBytes(extraIn.length, length: 4));
    bytes.add(extraIn);
    bytes.add(IntUtils.toBytes(i, length: 1));
    return BigintUtils.fromBytes(
        P2TRUtils.taggedHash(MuSig2Const.nonceDomain, bytes.toBytes()));
  }

  static BigInt deterministicNonceHash(
      {required List<int> sk,
      required List<int> aggotherNonce,
      required List<int> aggPk,
      required int i,
      required List<int> msg}) {
    final bytes = DynamicByteTracker();
    bytes.add(sk);
    bytes.add(aggotherNonce);
    bytes.add(aggPk);
    bytes.add(BigintUtils.toBytes(BigInt.from(msg.length), length: 8));
    bytes.add(msg);
    bytes.add(IntUtils.toBytes(i, length: 1));
    return BigintUtils.fromBytes(P2TRUtils.taggedHash(
        MuSig2Const.deterministicNonceDomain, bytes.toBytes()));
  }
}
