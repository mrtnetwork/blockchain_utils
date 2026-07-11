import 'package:blockchain_utils/bip/address/p2tr_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/native/native.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/ec/utils/secp256k1.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/bytes_tracker.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class MuSig2Utils {
  static List<int> zeroPk() =>
      List.filled(EcdsaKeysConst.pubKeyCompressedByteLen, 0);
  static List<int> generatePublicKey(List<int> sk) {
    final sBig = BigintUtils.fromBytes(sk);
    if (sBig < BigInt.one || sBig >= MuSig2Constants.order) {
      throw ArgumentException.invalidOperationArguments(
        "generatePublicKey",
        name: "sk",
        reason: "Invalid secret key bytes length.",
      );
    }
    return (MuSig2Constants.generator * sBig).toBytes();
  }

  static bool isValidPartialSignature(List<int> signature) {
    if (signature.length != MuSig2Constants.partialSignatureLength) {
      return false;
    }
    final sBig = BigintUtils.fromBytes(signature);
    if (sBig >= MuSig2Constants.order) return false;
    return true;
  }

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

  static BigInt getSessionKeyAggCoeff({
    required MuSig2Session session,
    required ProjectiveECCPoint pk,
  }) {
    final pkBytes = pk.toBytes();
    final signerPk = session.publicKeys.any(
      (e) => BytesUtils.bytesEqual(e, pkBytes),
    );
    if (!signerPk) {
      throw ArgumentException.invalidOperationArguments(
        "getSessionKeyAggCoeff",
        name: "pk",
        reason: "The signer pubkey does not exists in pubkey list.",
      );
    }
    return _keyAggCoeff(keys: session.publicKeys, key: pkBytes);
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

  static List<List<int>> sortPublicKeys(List<List<int>> keys) {
    for (final i in keys) {
      if (i.length != EcdsaKeysConst.pubKeyCompressedByteLen) {
        throw ArgumentException.invalidOperationArguments(
          "sortPublicKeys",
          name: "keys",
          reason: "Invalid public key bytes length.",
        );
      }
    }
    final sortKeys = List<List<int>>.from(keys)..sort(BytesUtils.compareBytes);
    return sortKeys;
  }

  static BigInt _keyAggCoeff({
    required List<List<int>> keys,
    required List<int> key,
  }) {
    if (_isSecondUniqueKey(keys: keys, key: key)) return BigInt.one;
    final hashKeys = P2TRUtils.taggedHash(
      MuSig2Constants.keyAggListDomain,
      keys.expand((e) => e).toList(),
    );
    final hash = P2TRUtils.taggedHash(MuSig2Constants.keyAggCoeffDomain, [
      ...hashKeys,
      ...key,
    ]);
    return BigintUtils.fromBytes(hash) % MuSig2Constants.order;
  }

  static ProjectiveECCPoint encodePoint(List<int> bytes) {
    try {
      return ProjectiveECCPoint.fromBytes(
        curve: MuSig2Constants.curve,
        data: bytes,
      );
    } catch (_) {
      throw ArgumentException.invalidOperationArguments(
        "encodePoint",
        name: "keys",
        reason: "Invalid public key.",
      );
    }
  }

  static ProjectiveECCPoint encodePointAsEven(
    List<int> keys, {
    bool allowInfinity = false,
  }) {
    try {
      if (keys.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
        if (allowInfinity && BytesUtils.bytesEqual(keys, zeroPk())) {
          return ProjectiveECCPoint.infinity(MuSig2Constants.curve);
        }
        final point = encodePoint(keys);
        if (!point.isZero()) {
          final p = P2TRUtils.liftX(point.x);
          if (keys[0] == 2) {
            return p;
          } else if (keys[0] == 3) {
            return -p;
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

  static MuSig2SessionValues decodeSession(MuSig2Session session) {
    final tweak = keyAggAndTweak(
      publicKeys: session.publicKeys,
      tweaks: session.tweaks,
    );
    final hash = P2TRUtils.taggedHash(MuSig2Constants.noncecoefDomain, [
      ...session.aggnonce,
      ...tweak.xOnly(),
      ...session.msg,
    ]);
    final b = BigintUtils.fromBytes(hash) % MuSig2Constants.order;
    ProjectiveECCPoint r1 = MuSig2Utils.encodePointAsEven(
      session.aggnonce.sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen),
      allowInfinity: true,
    );
    ProjectiveECCPoint r2 = MuSig2Utils.encodePointAsEven(
      session.aggnonce.sublist(
        EcdsaKeysConst.pubKeyCompressedByteLen,
        EcdsaKeysConst.pubKeyCompressedByteLen * 2,
      ),
      allowInfinity: true,
    );
    ProjectiveECCPoint r = (r1 + (r2 * b)).cast();
    if (r.isZero()) {
      r = MuSig2Constants.generator;
    }
    final eHash = P2TRUtils.taggedHash(MuSig2Constants.challengeDomain, [
      ...r.toXonly(),
      ...tweak.xOnly(),
      ...session.msg,
    ]);
    final e = BigintUtils.fromBytes(eHash) % MuSig2Constants.order;
    return MuSig2SessionValues(
      publicKey: tweak.publicKey,
      gacc: tweak.gacc,
      tacc: tweak.tacc,
      b: b.toBeBytes(length: MuSig2Constants.baselen),
      r: r,
      e: e.toBeBytes(length: MuSig2Constants.baselen),
    );
  }

  static MuSig2KeyAggContext _applyTweak({
    required MuSig2KeyAggContext context,
    required MuSig2Tweak tweak,
  }) {
    if (tweak.tweak.length != MuSig2Constants.xOnlyBytesLength) {
      throw ArgumentException.invalidOperationArguments(
        "applyTweak",
        name: "tweak",
        reason: "Invalid tweak bytes length.",
      );
    }
    final BigInt order = MuSig2Constants.order;
    BigInt g = BigInt.one;
    if (tweak.isXOnly && context.publicKey.isOdd) {
      g = order - BigInt.one;
    }
    BigInt t = BigintUtils.fromBytes(tweak.tweak);
    if (t >= order) {
      throw ArgumentException.invalidOperationArguments(
        "applyTweak",
        name: "tweak",
        reason: "Invalid tweak bytes.",
      );
    }
    final q = (context.publicKey * g) + (MuSig2Constants.generator * t);
    if (q.isZero()) {
      throw ArgumentException.invalidOperationArguments(
        "applyTweak",
        name: "tweak",
        reason: "Invalid tweak bytes.",
      );
    }
    final gacc = (g * context.gaccAsInteger) % order;
    final tacc = (t + g * context.taccAsInteger) % order;
    return MuSig2KeyAggContext(
      publicKey: q.cast(),
      gacc: gacc.toBeBytes(length: MuSig2Constants.baselen),
      tacc: tacc.toBeBytes(length: MuSig2Constants.baselen),
    );
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
      publicKey: aggKey!,
      gacc: BigInt.one.toBeBytes(length: MuSig2Constants.baselen),
      tacc: BigInt.zero.toBeBytes(length: MuSig2Constants.baselen),
    );
  }

  static MuSig2KeyAggContext keyAggAndTweak({
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
  }) {
    MuSig2KeyAggContext keyAgg = aggPublicKeys(keys: publicKeys);
    for (int i = 0; i < tweaks.length; i++) {
      final tweak = tweaks[i];
      keyAgg = _applyTweak(context: keyAgg, tweak: tweak);
    }
    return keyAgg;
  }

  static List<int> nonceHash({
    required List<int> rand,
    required List<int> publicKey,
    required List<int> aggPk,
    required int i,
    required List<int> messagePrefix,
    required List<int> extraIn,
  }) {
    final bytes = DynamicByteTracker();
    bytes.add(rand);
    bytes.add([publicKey.length]);
    bytes.add(publicKey);
    bytes.add([aggPk.length]);
    bytes.add(aggPk);
    bytes.add(messagePrefix);
    bytes.add(extraIn.length.toU32BeBytes());
    bytes.add(extraIn);
    bytes.add(i.toBeBytes(length: 1));
    return P2TRUtils.taggedHash(MuSig2Constants.nonceDomain, bytes.toBytes());
  }

  static List<int> deterministicNonceHash({
    required List<int> sk,
    required List<int> aggotherNonce,
    required List<int> aggPk,
    required int i,
    required List<int> msg,
  }) {
    final bytes = DynamicByteTracker();
    bytes.add(sk);
    bytes.add(aggotherNonce);
    bytes.add(aggPk);
    bytes.add(msg.length.toBeBytes(length: 8));
    bytes.add(msg);
    bytes.add(i.toBeBytes(length: 1));
    return P2TRUtils.taggedHash(
      MuSig2Constants.deterministicNonceDomain,
      bytes.toBytes(),
    );
  }

  static BigInt toScalarBigInt(List<int> scalarBytes) {
    if (scalarBytes.length == MuSig2Constants.baselen) {
      final toBig = BigintUtils.fromBytes(scalarBytes) % MuSig2Constants.order;
      if (toBig != BigInt.zero) return toBig;
    }
    throw ArgumentException.invalidOperationArguments(
      "toScalarBigInt",
      name: "scalarBytes",
      reason: "Invalid scalar bytes",
    );
  }
}
