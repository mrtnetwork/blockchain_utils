import 'package:blockchain_utils/chain/address/protocol/p2tr_addr.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';
import 'package:blockchain_utils/api/api/api.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants backing [MuSig2Utils] for the blinded signing path.
class MuSig2UtilsConst {
  static Secp256k1Fr _frUnchecked(List<int> s) =>
      Secp256k1Fr.fromBytesUnchecked(s);

  static List<int> zeroPk() =>
      List.filled(EcdsaKeysConst.pubKeyCompressedByteLen, 0);

  /// Partial signatures are plain 32-byte scalars; length + range check
  /// through the curve API (replaces the deleted `MuSig2Utils` helper).
  static bool isValidPartialSignature(List<int> signature) {
    return blockchainUtils.api.secp256k1.scCheck(signature);
  }

  static List<BuBytes> sortPublicKeys(List<BuBytes> keys) {
    for (final i in keys) {
      if (i.length != EcdsaKeysConst.pubKeyCompressedByteLen) {
        throw CoreErrors.invalidOperationArguments(
          "sortPublicKeys",
          name: "keys",
          reason: "Invalid public key bytes length.",
        );
      }
    }
    final sortKeys = List<BuBytes>.from(keys)..sort(BytesUtils.compareBytes);
    return sortKeys;
  }

  static Secp256k1Point encodePoint(List<int> bytes) {
    try {
      return Secp256k1Point.fromBytes(bytes);
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "encodePoint",
        name: "keys",
        reason: "Invalid public key.",
      );
    }
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

  static Secp256k1Fr getSessionKeyAggCoeffConst({
    required MuSig2Session session,
    required List<int> pkBytes,
  }) {
    final signerPk = session.publicKeys.any(
      (e) => BytesUtils.bytesEqualConst(e, pkBytes),
    );
    if (!signerPk) {
      throw CoreErrors.invalidOperationArguments(
        "getSessionKeyAggCoeff",
        name: "pk",
        reason: "The signer pubkey does not exists in pubkey list.",
      );
    }
    if (_isSecondUniqueKey(keys: session.publicKeys, key: pkBytes)) {
      return Secp256k1Fr.one;
    }
    final hashKeys = P2TRUtils.taggedHash(
      MuSig2Constants.keyAggListDomain,
      session.publicKeys.expand((e) => e).toList(),
    );
    final hash = P2TRUtils.taggedHash(MuSig2Constants.keyAggCoeffDomain, [
      ...hashKeys,
      ...pkBytes,
    ]);

    return _frUnchecked(hash);
  }

  static Secp256k1Fr _keyAggCoeffConst({
    required List<List<int>> keys,
    required List<int> key,
  }) {
    if (_isSecondUniqueKey(keys: keys, key: key)) {
      return Secp256k1Fr.one;
    }
    final hashKeys = P2TRUtils.taggedHash(
      MuSig2Constants.keyAggListDomain,
      keys.expand((e) => e).toList(),
    );
    final hash = P2TRUtils.taggedHash(MuSig2Constants.keyAggCoeffDomain, [
      ...hashKeys,
      ...key,
    ]);
    return _frUnchecked(hash);
  }

  static Secp256k1Point encodePointAsEvenConst(
    List<int> keys, {
    bool allowInfitity = false,
  }) {
    try {
      if (keys.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
        if (_isZeroX(keys)) {
          if (allowInfitity) return Secp256k1Point.identity_;
        } else {
          if (keys[0] != 0x02 && keys[0] != 0x03) {
            throw const FormatException('bad prefix');
          }
          final even = Secp256k1AffinePoint.liftX(keys.sublist(1)).toCurve();
          return keys[0] == 0x03 ? -even : even;
        }
      }
    } catch (_) {}
    throw CoreErrors.invalidOperationArguments(
      "encodePointAsEven",
      name: "keys",
      reason: "Invalid public key.",
    );
  }

  static bool _isZeroX(List<int> keys) {
    // Strict infinity encoding: all 33 bytes must be zero (BIP-327 nonce_agg).
    for (var i = 0; i < keys.length; i++) {
      if (keys[i] != 0) return false;
    }
    return true;
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
    final b = _frUnchecked(hash);
    Secp256k1Point r1 = encodePointAsEvenConst(
      session.aggnonce.sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen),
      allowInfitity: true,
    );
    Secp256k1Point r2 = encodePointAsEvenConst(
      session.aggnonce.sublist(
        EcdsaKeysConst.pubKeyCompressedByteLen,
        EcdsaKeysConst.pubKeyCompressedByteLen * 2,
      ),
      allowInfitity: true,
    );
    final r = () {
      final agg = r1 + r2 * b;
      // BIP-327 session fallback (mirrors `MuSig2Utils.decodeSession`):
      // an infinity aggregate nonce stands in for the generator.
      if (agg.isZero()) return MuSig2Constants.generator;
      return agg;
    }();
    final rBytes = r.toXOnly();
    final eHash = P2TRUtils.taggedHash(MuSig2Constants.challengeDomain, [
      ...rBytes,
      ...tweak.xOnly(),
      ...session.msg,
    ]);
    final sc = _frUnchecked(eHash);
    return MuSig2SessionValues(
      publicKey: tweak.publicKey,
      gacc: tweak.gacc,
      tacc: tweak.tacc,
      b: b.toBytes(),
      r: r,
      e: sc.toBytes(),
    );
  }

  static MuSig2KeyAggContext _applyTweakConst({
    required MuSig2KeyAggContext context,
    required MuSig2Tweak tweak,
  }) {
    if (tweak.tweak.length != MuSig2Constants.xOnlyBytesLength) {
      throw CoreErrors.invalidOperationArguments(
        "applyTweak",
        name: "tweak",
        reason: "Invalid tweak bytes length.",
      );
    }
    final cPublicKey = Secp256k1Point.fromBytes(context.publicKey.toBytes());
    var g = Secp256k1Fr.one;
    if (tweak.isXOnly && cPublicKey.isOdd) {
      g = -g;
    }
    final t = Secp256k1Fr.fromBytes(tweak.tweak);
    final q = cPublicKey * g + MuSig2Constants.generator * t;
    if (q.isZero()) {
      throw CoreErrors.invalidOperationArguments(
        "applyTweak",
        name: "tweak",
        reason: "Invalid tweak bytes.",
      );
    }
    final gacc = Secp256k1Fr.fromBytes(context.gacc);
    final tacc = Secp256k1Fr.fromBytes(context.tacc);
    final pkBytes = q.toCompressed().toList();
    final nGacc = gacc * g;
    final nTacc = tacc * g + t;
    return MuSig2KeyAggContext(
      publicKey: Secp256k1Point.fromBytes(pkBytes),
      gacc: nGacc.toBytes(),
      tacc: nTacc.toBytes(),
    );
  }

  static MuSig2KeyAggContext aggPublicKeys({required List<List<int>> keys}) {
    Secp256k1Point? aggKey;
    for (final k in keys) {
      final coeff = _keyAggCoeffConst(keys: keys, key: k);
      final c = encodePointAsEvenConst(k);
      final key = c * coeff;
      aggKey = aggKey == null ? key : aggKey + key;
    }
    if (aggKey == null) {
      throw CoreErrors.invalidOperationArguments(
        "aggPublicKeys",
        name: "aggPublicKeys",
        reason:
            "At least ${MuSig2Constants.minimumRequiredKey} public keys require.",
      );
    }
    final keyBytes = aggKey.toCompressed().toList();
    return MuSig2KeyAggContext(
      publicKey: Secp256k1Point.fromBytes(keyBytes),
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
      keyAgg = _applyTweakConst(context: keyAgg, tweak: tweak);
    }
    return keyAgg;
  }

  static Secp256k1Fr nonceHash({
    required List<int> rand,
    required List<int> publicKey,
    required List<int> aggPk,
    required int i,
    required List<int> messagePrefix,
    required List<int> extraIn,
  }) {
    final bytes = BuBytes.empty();
    bytes.addAll(rand);
    bytes.addAll([publicKey.length]);
    bytes.addAll(publicKey);
    bytes.addAll([aggPk.length]);
    bytes.addAll(aggPk);
    bytes.addAll(messagePrefix);
    bytes.addAll(extraIn.length.toU32BeBytes());
    bytes.addAll(extraIn);
    bytes.addAll(i.toBeBytes(length: 1));
    return _frUnchecked(
      P2TRUtils.taggedHash(MuSig2Constants.nonceDomain, bytes),
    );
  }

  static Secp256k1Fr deterministicNonceHash({
    required List<int> sk,
    required List<int> aggotherNonce,
    required List<int> aggPk,
    required int i,
    required List<int> msg,
  }) {
    final bytes = BuBytes.empty();
    bytes.addAll(sk);
    bytes.addAll(aggotherNonce);
    bytes.addAll(aggPk);
    bytes.addAll(msg.length.toBeBytes(length: 8));
    bytes.addAll(msg);
    bytes.addAll(i.toBeBytes(length: 1));
    return _frUnchecked(
      P2TRUtils.taggedHash(
        MuSig2Constants.deterministicNonceDomain,
        bytes,
      ),
    );
  }
}
