import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/signature/rfc6979/rfc6979.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Curve-agnostic ECDSA key helpers.
class EcdsaKeysUtils {
  /// Normalizes a BIP-137 header byte (27-42, encoding recovery id +
  /// compression/segwit format) down to a plain 0/1 recovery id.
  static int getBip137Header(int header) {
    if (header < 27 || header > 42) {
      throw CoreErrors.invalidOperationArguments(
        "verifyMessageSignature",
        name: "signature",
        reason: "Invalid signature recovery id.",
      );
    }
    if (header >= 39) {
      header -= 12;
    } else if (header >= 35) {
      header -= 8;
    } else if (header >= 31) {
      header -= 4;
    }
    header -= 27;
    if (header > 1) {
      header -= 2;
    }
    return header;
  }
}

/// secp256k1 ECDSA recovery and signing/verification on [Secp256k1Point].
///
/// All scalar math runs in [Secp256k1Fr]; no BigInt modular arithmetic.
class Secp256k1EcdsaUtils {
  static final Secp256k1Fr _b256 = Secp256k1Fr.from(Uint64(256));

  static Secp256k1Fr _fr(List<int> s) => Secp256k1Fr.fromBytes(s);

  /// Big-endian integer value of arbitrary-length [bytes] mod n.
  static Secp256k1Fr _frHash(List<int> bytes) {
    var acc = Secp256k1Fr.zero;
    for (final b in bytes) {
      acc = acc * _b256 + Secp256k1Fr.from(Uint64(b));
    }
    return acc;
  }

  static void _checkRange(Secp256k1Fr r, Secp256k1Fr s) {
    if (r.isZero() || s.isZero()) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256k1EcdsaUtils",
        reason: "Invalid signature scalar range.",
      );
    }
  }

  static Secp256k1Fr _frSig(List<int> s) {
    try {
      final f = Secp256k1Fr.fromBytes(s);
      if (f.isZero()) throw const FormatException();
      return f;
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256k1EcdsaUtils",
        reason: "Invalid signature scalar range.",
      );
    }
  }

  /// Returns the (at most) two candidate public key points for a signature,
  /// given only the message hash - one for each possible y-parity.
  static List<Secp256k1Point> recoverPublicKeys({
    required List<int> hash,
    required IECDSASignature signature,
  }) {
    final r = _frSig(signature.r);
    final s = _frSig(signature.s);
    _checkRange(r, s);
    final e = _frHash(hash);
    final even = Secp256k1AffinePoint.liftX(r.toBytes()).toCurve();
    final odd = -even;
    final invR = r.invert()!;
    Secp256k1Point q(Secp256k1Point rPt) =>
        (rPt * s + Secp256k1Point.generator_ * (-e)) * invR;
    return [q(even), q(odd)];
  }

  /// Recovers the single public key point matching a signature's stored
  /// recovery id.
  static Secp256k1Point recoverPublicKey({
    required List<int> hash,
    required IECDSASignature signature,
  }) {
    int? header = signature.recoveryId;
    if (header == null) {
      throw CoreErrors.cryptoFailed(
        "Secp256k1EcdsaUtils.recoverPublicKey",
        reason: "Missing signature recovery id.",
      );
    }
    if (header > 3) {
      header = EcdsaKeysUtils.getBip137Header(header);
    }
    if (header > 1) {
      header -= 2;
    }
    final r = _frSig(signature.r);
    final s = _frSig(signature.s);
    _checkRange(r, s);
    final e = _frHash(hash);
    final even = Secp256k1AffinePoint.liftX(r.toBytes()).toCurve();
    final rPt = header > 0 ? -even : even;
    return (rPt * s + Secp256k1Point.generator_ * (-e)) * r.invert()!;
  }

  /// Finds which of the two candidate points equals [pubKeyPoint], and
  /// returns its index (0 or 1) as the recovery id, or null if neither matches.
  static int? recoverId({
    required List<int> hash,
    required IECDSASignature signature,
    required List<int> pubKey,
  }) {
    final keys = recoverPublicKeys(hash: hash, signature: signature);
    for (var i = 0; i < keys.length; i++) {
      if (BytesUtils.bytesEqual(keys[i].toBytes(), pubKey)) {
        return i;
      }
    }
    return null;
  }

  /// Signs [hashBytes] with the 32-byte big-endian [secret], returning
  /// r/s + recovery id.
  static IECDSASignature ecdsaSign({
    required List<int> hashBytes,
    required List<int> secret,
    required List<int> pubKey,
    List<int>? extraEntropy,
  }) {
    final kBytes = RFC6979.generateSecp256k1KBytes(
      secexp: secret,
      hashFunc: QuickCrypto.sha256Instance,
      data: hashBytes,
      extraEntropy: extraEntropy,
    );
    final k = _fr(kBytes);
    final h = _frHash(hashBytes);
    final sk = _fr(secret);

    final rPt = Secp256k1Point.generator_ * k;
    final r = Secp256k1Fr.fromBytesUnchecked(rPt.toXOnly());
    if (r.isZero()) {
      throw CoreErrors.cryptoFailed(
        "Secp256k1EcdsaUtils.ecdsaSign",
        reason: "Signing produced an invalid zero scalar.",
      );
    }
    final s = (h + sk * r) * k.invert()!;
    if (s.isZero()) {
      throw CoreErrors.cryptoFailed(
        "Secp256k1EcdsaUtils.ecdsaSign",
        reason: "Signing produced an invalid zero scalar.",
      );
    }
    final signature = IECDSASignature(r: r.toBytes(), s: s.toBytes());
    final recoverId = Secp256k1EcdsaUtils.recoverId(
      hash: hashBytes,
      signature: signature,
      pubKey: pubKey,
    );
    if (recoverId == null) {
      throw CoreErrors.cryptoFailed(
        "Secp256k1EcdsaUtils.ecdsaSign",
        reason: "Signature verification failed.",
      );
    }
    return IECDSASignature(
      r: signature.r,
      s: signature.s,
      recoveryId: recoverId,
    );
  }

  /// Verifies an ECDSA signature against [pubKeyPoint].
  static bool ecdsaVerifySignature({
    required List<int> hashBytes,
    required IECDSASignature signature,
    required Secp256k1Point pubKeyPoint,
  }) {
    final Secp256k1Fr r;
    final Secp256k1Fr s;
    try {
      r = _fr(signature.r);
      s = _fr(signature.s);
    } catch (_) {
      return false;
    }
    if (r.isZero() || s.isZero()) return false;
    final h = _frHash(hashBytes);
    final c = s.invert()!;
    final u1 = h * c;
    final u2 = r * c;
    final xy = Secp256k1Point.generator_ * u1 + pubKeyPoint * u2;
    if (xy.isZero()) return false;
    return BytesUtils.bytesEqual(xy.toXOnly(), r.toBytes());
  }
}

/// secp256r1 ECDSA recovery and signing/verification on [Secp256r1Point].
///
/// All scalar math runs in [Secp256r1Fr]; no BigInt modular arithmetic.
class Secp256r1EcdsaUtils {
  static final Secp256r1Fr _b256 = Secp256r1Fr.from(Uint64(256));

  static Secp256r1Fr _fr(List<int> s) => Secp256r1Fr.fromBytes(s);

  /// Big-endian integer value of arbitrary-length [bytes] mod n.
  static Secp256r1Fr _frHash(List<int> bytes) {
    var acc = Secp256r1Fr.zero;
    for (final b in bytes) {
      acc = acc * _b256 + Secp256r1Fr.from(Uint64(b));
    }
    return acc;
  }

  static void _checkRange(Secp256r1Fr r, Secp256r1Fr s) {
    if (r.isZero() || s.isZero()) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256r1EcdsaUtils",
        reason: "Invalid signature scalar range.",
      );
    }
  }

  static Secp256r1Fr _frSig(List<int> s) {
    try {
      final f = Secp256r1Fr.fromBytes(s);
      if (f.isZero()) throw const FormatException();
      return f;
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "Secp256r1EcdsaUtils",
        reason: "Invalid signature scalar range.",
      );
    }
  }

  /// Returns the (at most) two candidate public key points for a signature,
  /// given only the message hash - one for each possible y-parity.
  static List<Secp256r1Point> recoverPublicKeys({
    required List<int> hash,
    required IECDSASignature signature,
  }) {
    final r = _frSig(signature.r);
    final s = _frSig(signature.s);
    _checkRange(r, s);
    final e = _frHash(hash);
    final even = Secp256r1AffinePoint.liftX(r.toBytes()).toCurve();
    final odd = -even;
    final invR = r.invert()!;
    Secp256r1Point q(Secp256r1Point rPt) =>
        (rPt * s + Secp256r1Point.generator_ * (-e)) * invR;
    return [q(even), q(odd)];
  }

  /// Recovers the single public key point matching a signature's stored
  /// recovery id.
  static Secp256r1Point recoverPublicKey({
    required List<int> hash,
    required IECDSASignature signature,
  }) {
    int? header = signature.recoveryId;
    if (header == null) {
      throw CoreErrors.cryptoFailed(
        "Secp256r1EcdsaUtils.recoverPublicKey",
        reason: "Missing signature recovery id.",
      );
    }
    if (header > 3) {
      header = EcdsaKeysUtils.getBip137Header(header);
    }
    if (header > 1) {
      header -= 2;
    }
    final r = _frSig(signature.r);
    final s = _frSig(signature.s);
    _checkRange(r, s);
    final e = _frHash(hash);
    final even = Secp256r1AffinePoint.liftX(r.toBytes()).toCurve();
    final rPt = header > 0 ? -even : even;
    return (rPt * s + Secp256r1Point.generator_ * (-e)) * r.invert()!;
  }

  /// Finds which of the two candidate points equals [pubKeyPoint], and
  /// returns its index (0 or 1) as the recovery id, or null if neither matches.
  static int? recoverId({
    required List<int> hash,
    required IECDSASignature signature,
    required List<int> pubKey,
  }) {
    final keys = recoverPublicKeys(hash: hash, signature: signature);
    for (var i = 0; i < keys.length; i++) {
      if (BytesUtils.bytesEqual(keys[i].toBytes(), pubKey)) {
        return i;
      }
    }
    return null;
  }

  /// Signs [hashBytes] with the 32-byte big-endian [secret], returning
  /// r/s + recovery id.
  static IECDSASignature ecdsaSign({
    required List<int> hashBytes,
    required List<int> secret,
    required List<int> pubKey,
    List<int>? extraEntropy,
  }) {
    final kBytes = RFC6979.generateSecp256r1KBytes(
      secexp: secret,
      hashFunc: QuickCrypto.sha256Instance,
      data: hashBytes,
      extraEntropy: extraEntropy,
    );
    final k = _fr(kBytes);
    final h = _frHash(hashBytes);
    final sk = _fr(secret);

    final rPt = Secp256r1Point.generator_ * k;
    final r = Secp256r1Fr.fromBytesUnchecked(rPt.toXOnly());
    if (r.isZero()) {
      throw CoreErrors.cryptoFailed(
        "Secp256r1EcdsaUtils.ecdsaSign",
        reason: "Signing produced an invalid zero scalar.",
      );
    }
    final s = (h + sk * r) * k.invert()!;
    if (s.isZero()) {
      throw CoreErrors.cryptoFailed(
        "Secp256r1EcdsaUtils.ecdsaSign",
        reason: "Signing produced an invalid zero scalar.",
      );
    }
    final signature = IECDSASignature(r: r.toBytes(), s: s.toBytes());
    final recoverId = Secp256r1EcdsaUtils.recoverId(
      hash: hashBytes,
      signature: signature,
      pubKey: pubKey,
    );
    if (recoverId == null) {
      throw CoreErrors.cryptoFailed(
        "Secp256r1EcdsaUtils.ecdsaSign",
        reason: "Signature verification failed.",
      );
    }
    return IECDSASignature(
      r: signature.r,
      s: signature.s,
      recoveryId: recoverId,
    );
  }

  /// Verifies an ECDSA signature against [pubKeyPoint].
  static bool ecdsaVerifySignature({
    required List<int> hashBytes,
    required IECDSASignature signature,
    required Secp256r1Point pubKeyPoint,
  }) {
    final Secp256r1Fr r;
    final Secp256r1Fr s;
    try {
      r = _fr(signature.r);
      s = _fr(signature.s);
    } catch (_) {
      return false;
    }
    if (r.isZero() || s.isZero()) return false;
    final h = _frHash(hashBytes);
    final c = s.invert()!;
    final u1 = h * c;
    final u2 = r * c;
    final xy = Secp256r1Point.generator_ * u1 + pubKeyPoint * u2;
    if (xy.isZero()) return false;
    return BytesUtils.bytesEqual(xy.toXOnly(), r.toBytes());
  }
}

/// Shared key-encoding helpers.
class CryptoKeysUtils {
  /// Calls [onModeBytes] and throws a clear error if [mode] isn't supported
  /// for [type].
  static BuBytes ensureSupportPubKeyMode({
    required CryptoKeyEncoding mode,
    required BuBytes? Function(CryptoKeyEncoding mode) onModeBytes,
    required CryptoKeyType type,
  }) {
    final keyBytes = onModeBytes(mode);
    if (keyBytes == null) {
      throw CoreErrors.cryptoFailed(
        "CryptoKeysUtils.ensureSupportedPubKeyMode",
        reason:
            "${type.name} does not support the ${mode.name} public key encoding.",
      );
    }
    return keyBytes;
  }
}
