import 'package:blockchain_utils/bip/address/p2tr_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/exception/exception.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/native/native.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/ec/utils/secp256k1.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class MuSig2UtilsConst {
  static bool _isSecondUniqueKey({
    required List<List<int>> keys,
    required List<int> key,
  }) {
    for (final k in keys) {
      if (!BytesUtils.bytesEqualConst(k, keys[0])) {
        if (BytesUtils.bytesEqualConst(k, key)) {
          return true;
        }
        return false;
      }
    }
    return false;
  }

  static Secp256k1Scalar getSessionKeyAggCoeffConst({
    required MuSig2Session session,
    required List<int> pkBytes,
  }) {
    final signerPk = session.publicKeys.any(
      (e) => BytesUtils.bytesEqualConst(e, pkBytes),
    );
    if (!signerPk) {
      throw ArgumentException.invalidOperationArguments(
        "getSessionKeyAggCoeff",
        name: "pk",
        reason: "The signer pubkey does not exists in pubkey list.",
      );
    }
    if (_isSecondUniqueKey(keys: session.publicKeys, key: pkBytes)) {
      return Secp256k1Const.secp256k1ScalarOne;
    }
    final hashKeys = P2TRUtils.taggedHash(
      MuSig2Constants.keyAggListDomain,
      session.publicKeys.expand((e) => e).toList(),
    );
    final hash = P2TRUtils.taggedHash(MuSig2Constants.keyAggCoeffDomain, [
      ...hashKeys,
      ...pkBytes,
    ]);
    return Secp256k1Utils.scalarFromBytes(hash);
  }

  static Secp256k1Scalar _keyAggCoeffConst({
    required List<List<int>> keys,
    required List<int> key,
  }) {
    if (_isSecondUniqueKey(keys: keys, key: key)) {
      return Secp256k1Const.secp256k1ScalarOne;
    }
    final hashKeys = P2TRUtils.taggedHash(
      MuSig2Constants.keyAggListDomain,
      keys.expand((e) => e).toList(),
    );
    final hash = P2TRUtils.taggedHash(MuSig2Constants.keyAggCoeffDomain, [
      ...hashKeys,
      ...key,
    ]);
    return Secp256k1Utils.scalarFromBytes(hash);
  }

  static Secp256k1Ge encodePointAsEvenConst(
    List<int> keys, {
    bool allowInfitity = false,
  }) {
    try {
      if (keys.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
        Secp256k1Fe x = Secp256k1Fe();
        if (Secp256k1.secp256k1FeImplSetB32Limit(x, keys.sublist(1)).toBool) {
          if (Secp256k1.secp256k1FeIsZero(x).toBool) {
            if (allowInfitity) return Secp256k1Ge.infinity();
          } else {
            final r = liftX(
              x,
              keys[0] == Secp256k1Const.secp256k1TagPubkeyOdd ? 1 : 0,
            );
            if (r != null) return r;
          }
        }
      }
    } catch (_) {}
    throw ArgumentException.invalidOperationArguments(
      "encodePointAsEven",
      name: "keys",
      reason: "Invalid public key.",
    );
  }

  static Secp256k1Ge? liftX(Secp256k1Fe x, int odd) {
    Secp256k1Ge r = Secp256k1Ge();
    if (Secp256k1.secp256k1GeSetXoVar(r, x, odd) == 1) {
      return r;
    }
    return null;
  }

  static MuSig2SessionValues decodeSessionConst(MuSig2Session session) {
    final tweak = keyAggAndTweak(
      publicKeys: session.publicKeys,
      tweaks: session.tweaks,
    );
    final hash = P2TRUtils.taggedHash(MuSig2Constants.noncecoefDomain, [
      ...session.aggnonce,
      ...tweak.xOnly(),
      ...session.msg,
    ]);
    final b = Secp256k1Utils.scalarFromBytes(hash);
    Secp256k1Ge r1 = encodePointAsEvenConst(
      session.aggnonce.sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen),
      allowInfitity: true,
    );
    Secp256k1Ge r2 = encodePointAsEvenConst(
      session.aggnonce.sublist(
        EcdsaKeysConst.pubKeyCompressedByteLen,
        EcdsaKeysConst.pubKeyCompressedByteLen * 2,
      ),
      allowInfitity: true,
    );
    Secp256k1Ge r = Secp256k1Ge();

    if (!r2.infinity.toBool) {
      Secp256k1Gej e = Secp256k1Utils.secp256k1Mult(scalar: b, point: r2);
      Secp256k1.secp256k1GejAddGe(e, e, r1);
      Secp256k1.secp256k1GeSetGej(r, e);
    } else {
      r = Secp256k1Const.G.clone();
    }
    final List<int> rBytes = List<int>.filled(MuSig2Constants.baselen, 0);
    Secp256k1.secp256k1FeGetB32(rBytes, r.x);
    final eHash = P2TRUtils.taggedHash(MuSig2Constants.challengeDomain, [
      ...rBytes,
      ...tweak.xOnly(),
      ...session.msg,
    ]);
    final sc = Secp256k1Utils.scalarFromBytes(eHash);
    return MuSig2SessionValues(
      publicKey: tweak.publicKey,
      gacc: tweak.gacc,
      tacc: tweak.tacc,
      b: Secp256k1Utils.scalarToBytes(b, clean: true),
      r: Secp256k1Utils.geToEcPoint(r),
      e: Secp256k1Utils.scalarToBytes(sc, clean: true),
    );
  }

  static MuSig2KeyAggContext _applyTweakConst({
    required MuSig2KeyAggContext context,
    required MuSig2Tweak tweak,
    Secp256k1ECmultGenContext? c,
  }) {
    if (tweak.tweak.length != MuSig2Constants.xOnlyBytesLength) {
      throw ArgumentException.invalidOperationArguments(
        "applyTweak",
        name: "tweak",
        reason: "Invalid tweak bytes length.",
      );
    }
    final cPublicKey = Secp256k1Utils.loadPublicKey(
      context.publicKey.toBytes(),
    );
    if (cPublicKey == null) {
      throw ArgumentException.invalidOperationArguments(
        "applyTweak",
        name: "tweak",
        reason: "Invalid public key.",
      );
    }
    final isOdd = Secp256k1.secp256k1FeIsOdd(cPublicKey.y);
    Secp256k1Scalar g = Secp256k1Const.secp256k1ScalarOne.clone();

    if (tweak.isXOnly && isOdd.toBool) {
      Secp256k1.secp256k1ScalarNegate(g, g);
    }
    final t = Secp256k1Utils.scalarFromBytes(tweak.tweak);
    if (!Secp256k1Utils.scCheck(t)) {
      throw ArgumentException.invalidOperationArguments(
        "applyTweak",
        name: "tweak",
        reason: "Invalid tweak bytes.",
      );
    }
    final m1 = Secp256k1Utils.secp256k1Mult(
      scalar: g,
      checkScalar: false,
      point: cPublicKey,
    );
    final m2 = Secp256k1Utils.secp256k1MultBase(scalar: t, context: c);
    Secp256k1.secp256k1GejAddGe(m1, m1, m2);
    Secp256k1Ge q = Secp256k1Ge();
    Secp256k1.secp256k1GeSetGej(q, m1);
    if (Secp256k1.secp256k1FeIsZero(q.x).toBool ||
        Secp256k1.secp256k1FeIsZero(q.y).toBool) {
      throw ArgumentException.invalidOperationArguments(
        "applyTweak",
        name: "tweak",
        reason: "Invalid tweak bytes.",
      );
    }
    Secp256k1.secp256k1FeNormalize(q.x);
    Secp256k1.secp256k1FeNormalize(q.y);
    final gacc = Secp256k1Utils.scalarFromBytes(context.gacc);
    final tacc = Secp256k1Utils.scalarFromBytes(context.tacc, validate: false);
    final pkBytes = Secp256k1Utils.secp256k1ECkeyPubkeySerialize(q, true);
    if (pkBytes == null) {
      throw MuSig2Exception("Failed to generate tweak public key.");
    }
    Secp256k1.secp256k1ScalarMul(gacc, gacc, g);
    Secp256k1.secp256k1ScalarMul(tacc, tacc, g);
    Secp256k1.secp256k1ScalarAdd(tacc, tacc, t);
    return MuSig2KeyAggContext(
      publicKey: ProjectiveECCPoint.fromBytes(
        curve: MuSig2Constants.curve,
        data: pkBytes,
      ),
      gacc: Secp256k1Utils.scalarToBytes(gacc, clean: true),
      tacc: Secp256k1Utils.scalarToBytes(tacc, clean: true),
    );
  }

  static MuSig2KeyAggContext aggPublicKeys({required List<List<int>> keys}) {
    Secp256k1Gej? aggKey;
    for (final k in keys) {
      final coeff = _keyAggCoeffConst(keys: keys, key: k);
      Secp256k1Ge c = encodePointAsEvenConst(k);
      final key = Secp256k1Utils.secp256k1Mult(
        scalar: coeff,
        point: c,
        checkScalar: false,
      );
      if (aggKey != null) {
        Secp256k1Ge mid1 = Secp256k1Ge();
        Secp256k1.secp256k1GeSetGej(mid1, key);
        Secp256k1.secp256k1GejAddGe(aggKey, aggKey, mid1);
      } else {
        aggKey = key;
      }
    }
    if (aggKey == null) {
      throw ArgumentException.invalidOperationArguments(
        "MuSig2Session",
        name: "aggPublicKeys",
        reason:
            "At least ${MuSig2Constants.minimumRequiredKey} public keys require.",
      );
    }
    Secp256k1Ge mid1 = Secp256k1Ge();
    Secp256k1.secp256k1GeSetGej(mid1, aggKey);
    final keyBytes = Secp256k1Utils.secp256k1ECkeyPubkeySerialize(mid1, true);
    if (keyBytes == null) {
      throw MuSig2Exception("Failed to generate agg publuc key.");
    }
    return MuSig2KeyAggContext(
      publicKey: ProjectiveECCPoint.fromBytes(
        curve: MuSig2Constants.curve,
        data: keyBytes,
      ),
      gacc: BigintUtils.toBytes(BigInt.one, length: MuSig2Constants.baselen),
      tacc: BigintUtils.toBytes(BigInt.zero, length: MuSig2Constants.baselen),
    );
  }

  static MuSig2KeyAggContext keyAggAndTweak({
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
  }) {
    MuSig2KeyAggContext keyAgg = aggPublicKeys(keys: publicKeys);
    for (int i = 0; i < tweaks.length; i++) {
      final tweak = tweaks[i];
      keyAgg = _applyTweakConst(context: keyAgg, tweak: tweak);
    }
    return keyAgg;
  }

  static Secp256k1Scalar nonceHash({
    required List<int> rand,
    required List<int> publicKey,
    required List<int> aggPk,
    required int i,
    required List<int> messagePrefix,
    required List<int> extraIn,
  }) {
    return Secp256k1Utils.scalarFromBytes(
      MuSig2Utils.nonceHash(
        rand: rand,
        publicKey: publicKey,
        aggPk: aggPk,
        i: i,
        messagePrefix: messagePrefix,
        extraIn: extraIn,
      ),
    );
  }

  static Secp256k1Scalar deterministicNonceHash({
    required List<int> sk,
    required List<int> aggotherNonce,
    required List<int> aggPk,
    required int i,
    required List<int> msg,
  }) {
    return Secp256k1Utils.scalarFromBytes(
      MuSig2Utils.deterministicNonceHash(
        sk: sk,
        aggotherNonce: aggotherNonce,
        aggPk: aggPk,
        i: i,
        msg: msg,
      ),
    );
  }
}
