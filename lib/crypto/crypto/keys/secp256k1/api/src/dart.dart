import 'package:blockchain_utils/chain/address/protocol/p2tr_addr.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/signer/bitcoin/bitcoin_key_signer.dart';
import 'package:blockchain_utils/chain/signer/const/constants.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/signature/rfc6979/rfc6979.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Pure-Dart secp256k1 signing/verification on [Secp256k1Point].
class DartSecp256k1SigningApi implements Secp256k1SigningApi {
  const DartSecp256k1SigningApi();
  static Secp256k1Fr _fr(List<int> s) => Secp256k1Fr.fromBytes(s);
  static Secp256k1Point _pt(List<int> p) => Secp256k1Point.fromBytes(p);

  /// Low-S normalization without any order constant: the smaller of `s`
  /// and `-s` (lexicographic big-endian compare) is the canonical low-S form.
  static List<int> _lowS(Secp256k1Fr s) {
    final a = s.toBytes();
    final b = (-s).toBytes();
    return BytesUtils.compareBytes(a, b) <= 0 ? a : b;
  }

  static Secp256k1Fr _scCheckFr(List<int> s, String op, String what) {
    try {
      final f = _fr(s);
      if (f.isZero()) throw const FormatException();
      return f;
    } catch (_) {
      throw CoreErrors.cryptoFailed(
        op,
        reason: "Signing produced an invalid $what.",
      );
    }
  }

  @override
  IECDSASignature signSchnorr({
    required List<int> digest,
    required List<int> sk,
    required List<int> publicKey,
    List<int>? extraEntropy,
  }) {
    if (digest.length != EcdsaKeysConst.pointCoordByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256k1Signing.signSchnorrConst",
        name: "digest",
        reason: "Invalid digest bytes length.",
      );
    }
    extraEntropy ??= BuBytes.unsafe(
      CryptoSignerConst.bchSchnorrRfc6979ExtraData,
    );
    List<int> k = RFC6979.generateSecp256k1KBytes(
      secexp: sk,
      hashFunc: QuickCrypto.sha256Instance,
      data: digest,
      extraEntropy: extraEntropy,
    );

    var kFr = _scCheckFr(k, "Secp256k1Signing.signSchnorr", "zero scalar");
    final rPt = Secp256k1Point.generator_ * kFr;
    final nonce32 = rPt.toXOnly();
    final eHash = QuickCrypto.sha256Hash([
      ...nonce32,
      ..._pt(publicKey).toBytes(),
      ...digest,
    ]);

    final skFr = _scCheckFr(sk, "Secp256k1Signing.signSchnorr", "scalar");
    final eFr = _scCheckFr(eHash, "Secp256k1Signing.signSchnorr", "scalar");
    var n = eFr * skFr;
    if (!rPt.toAffine().y.sqrt().isSquare) {
      kFr = -kFr;
    }
    final sigs = kFr + n;
    if (sigs.isZero()) {
      throw CoreErrors.cryptoFailed(
        "Secp256k1Signing.signSchnorr",
        reason: "Signing produced an invalid scalar.",
      );
    }
    return IECDSASignature(r: nonce32, s: sigs.toBytes());
  }

  static IECDSASignature _signInternal({
    required List<int> kBytes,
    required List<int> privateKey,
    required List<int> digest,
    required List<int> pubKey,
  }) {
    final k = _scCheckFr(kBytes, "Secp256k1Signing.sign", "random scalar");
    final sk = _scCheckFr(privateKey, "Secp256k1Signing.sign", "secret key");
    final msg = Secp256k1Fr.fromBytes(digest);

    final rPt = Secp256k1Point.generator_ * k;
    final nonce32 = rPt.toXOnly();
    final sigr = Secp256k1Fr.fromBytesUnchecked(nonce32);

    final n = sigr * sk + msg;
    final sigs = n * k.invert()!;
    if (sigs.isZero() || sigr.isZero()) {
      throw CoreErrors.cryptoFailed(
        "Secp256k1Signing.sign",
        reason: "Signing produced an invalid scalar.",
      );
    }
    final sBytes = _lowS(sigs);

    final signature = IECDSASignature(r: nonce32, s: sBytes);
    final recoverId = Secp256k1EcdsaUtils.recoverId(
      hash: digest,
      signature: signature,
      pubKey: pubKey,
    );
    if (recoverId == null) {
      throw CoreErrors.cryptoFailed(
        "Secp256k1Signing.sign",
        reason: "Signature verification failed.",
      );
    }
    return IECDSASignature(
      r: signature.r,
      s: signature.s,
      recoveryId: recoverId,
    );
  }

  @override
  IECDSASignature sign({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? extraEntropy,
  }) {
    List<int> k = RFC6979.generateSecp256k1KBytes(
      secexp: sk,
      hashFunc: QuickCrypto.sha256Instance,
      data: digest,
      extraEntropy: extraEntropy,
    );
    return _signInternal(
      kBytes: k,
      privateKey: sk,
      digest: digest,
      pubKey: publicKey,
    );
  }

  static Secp256k1Fr _tweakConst(
    List<int> privateKey, {
    List<int>? tapTweakHash,
  }) {
    final a = Secp256k1Fr.fromBytes(privateKey);
    if (tapTweakHash == null) return a;
    final p = Secp256k1Point.generator_ * a;
    var t = a;
    if (p.isOdd) {
      t = -t;
    }
    try {
      t = t + Secp256k1Fr.fromBytes(tapTweakHash);
    } catch (_) {
      throw CoreErrors.cryptoFailed(
        "Secp256k1Signing.tweak",
        reason: "Tweak produced an invalid scalar.",
      );
    }
    return t;
  }

  @override
  IECDSASignature signBip340({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? aux,
    List<int>? tapTweakHash,
  }) {
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256k1Signing.signBip340Const",
        name: "digest",
        reason: "Invalid digest bytes length.",
      );
    }

    if (aux != null && aux.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256k1Signing.signBip340Const",
        name: "aux",
        reason: "Invalid aux bytes length.",
      );
    }

    final tKey = _tweakConst(sk, tapTweakHash: tapTweakHash);

    /// Default aux is fresh randomness
    /// (BIP-340): never derived from the secret. Explicit aux stays
    /// deterministic for test vectors.
    aux ??= QuickCrypto.generateRandom(length: 32);

    final mid = Secp256k1Point.generator_ * tKey;
    var tKeyN = tKey;
    if (mid.isOdd) {
      tKeyN = -tKeyN;
    }
    final d = tKeyN.toBytes();
    final t = BytesUtils.xor(d, P2TRUtils.taggedHash("BIP0340/aux", aux));
    final xBytes = mid.toXOnly();

    final kHash = P2TRUtils.taggedHash("BIP0340/nonce", [
      ...t,
      ...xBytes,
      ...digest,
    ]);
    var k0 = _scCheckFr(kHash, "Secp256k1Signing.signBip340", "scalar");
    final midR = Secp256k1Point.generator_ * k0;
    if (midR.isOdd) {
      k0 = -k0;
    }
    final rBytes = midR.toXOnly();
    final eHash = P2TRUtils.taggedHash("BIP0340/challenge", [
      ...rBytes,
      ...xBytes,
      ...digest,
    ]);
    final e = _scCheckFr(eHash, "Secp256k1Signing.signBip340", "scalar");
    final sigs = k0 + e * tKeyN;
    if (sigs.isZero()) {
      throw CoreErrors.cryptoFailed(
        "Secp256k1Signing.signBip340",
        reason: "Signing produced an invalid scalar.",
      );
    }

    return IECDSASignature(r: rBytes, s: sigs.toBytes());
  }

  static Secp256k1Point tweakKey({
    required BigInt xBig,
    required List<int> tapTweakHash,
  }) {
    if (tapTweakHash.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        "tweakKey",
        name: "signature",
        reason: "Invalid Tap-tweak hash bytes length.",
      );
    }
    final t = Secp256k1Fr.fromBytesUnchecked(tapTweakHash);
    final n = Secp256k1Point.generator_ * t;
    final outPoint =
        Secp256k1AffinePoint.liftX(xBig.toBeBytes(length: 32)).toCurve() + n;
    return outPoint;
  }

  @override
  bool verifyBip340SignatureUsingXOnly({
    required List<int> xOnly,
    required List<int> digest,
    required IECDSASignature signature,
    List<int>? tapTweakHash,
  }) {
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw CoreErrors.invalidOperationArguments(
        "verifyBip340SignatureUsingXOnly",
        name: "digest",
        reason: "Invalid digest bytes length.",
      );
    }
    if (xOnly.length != EcdsaKeysConst.pointCoordByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "verifyBip340SignatureUsingXOnly",
        name: "xOnly",
        reason: "Invalid xOnlyPublicKey bytes length.",
      );
    }
    final r = signature.r;
    final Secp256k1Fr s;
    try {
      // r only needs the field-prime range (BIP-340 verifies r < p);
      // s needs the scalar range.
      Secp256k1Fp.fromBytes(r);
      s = Secp256k1Fr.fromBytes(signature.s);
    } catch (_) {
      return false;
    }

    final Secp256k1Point p;
    try {
      p =
          tapTweakHash != null
              ? tweakKey(
                xBig: BigintUtils.fromBytes(xOnly),
                tapTweakHash: tapTweakHash,
              )
              : Secp256k1AffinePoint.liftX(xOnly).toCurve();
    } catch (_) {
      return false;
    }

    final eHash = P2TRUtils.taggedHash("BIP0340/challenge", [
      ...r,
      ...p.toXOnly(),
      ...digest,
    ]);
    var e = Secp256k1Fr.fromBytesUnchecked(eHash);
    final sp = Secp256k1Point.generator_ * s;

    if (p.isEven) {
      e = -e;
    }
    final eP = p * e;

    final rPt = sp + eP;
    if (rPt.isZero()) return false;
    if (rPt.isOdd || !BytesUtils.bytesEqual(rPt.toXOnly(), r)) {
      return false;
    }

    return true;
  }

  @override
  bool verifySchnorr({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  }) {
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw CoreErrors.invalidOperationArguments(
        "verifySchnorrSignature",
        name: "digest",
        reason: "Invalid digest bytes length.",
      );
    }

    final Secp256k1Point p;
    try {
      p = _pt(publicKey);
    } catch (_) {
      return false;
    }
    final eHash = QuickCrypto.sha256Hash([
      ...signature.r,
      ...p.toBytes(),
      ...digest,
    ]);
    final e = Secp256k1Fr.fromBytesUnchecked(eHash);
    final sG =
        Secp256k1Point.generator_ * Secp256k1Fr.fromBytesUnchecked(signature.s);
    final eP = -(p * e);
    final rPt = sG + eP;
    if (rPt.isZero() || !rPt.toAffine().y.sqrt().isSquare) {
      return false;
    }
    return BigintUtils.fromBytes(rPt.toXOnly()) == signature.rInt();
  }

  @override
  bool verifyMessageSignature({
    required List<int> message,
    required IECDSASignature signature,
    required List<int> publicKey,
    required String messagePrefix,
  }) {
    final BuBytes messageHash = QuickCrypto.sha256Hash(
      BitcoinSignerUtils.magicMessage(message, messagePrefix),
    );
    final Secp256k1Point pk;
    try {
      pk = _pt(publicKey);
    } catch (_) {
      return false;
    }
    int? header = signature.recoveryId;
    if (header == null) {
      return verify(
        digest: messageHash,
        publicKey: publicKey,
        signature: signature,
      );
    }
    Secp256k1Point pubPoint;
    try {
      pubPoint = Secp256k1EcdsaUtils.recoverPublicKey(
        hash: messageHash,
        signature: signature,
      );
    } catch (_) {
      return false;
    }
    return pubPoint == pk;
  }

  @override
  bool verify({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  }) {
    final Secp256k1Point pubKeyPoint;
    try {
      pubKeyPoint = _pt(publicKey);
    } catch (_) {
      return false;
    }
    return Secp256k1EcdsaUtils.ecdsaVerifySignature(
      signature: signature,
      hashBytes: digest,
      pubKeyPoint: pubKeyPoint,
    );
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    try {
      final point = Secp256k1Point.fromBytes(publicKey);
      if (point.isZero()) return null;
      return BuBytes.immutable(point.toBytes());
    } catch (_) {
      return null;
    }
  }
}
