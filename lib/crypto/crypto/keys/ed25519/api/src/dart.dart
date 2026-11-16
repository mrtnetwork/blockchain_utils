import 'package:blockchain_utils/chain/signer/const/constants.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/fields.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/ops.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Pure-Dart implementation of ed25519-family signing/verification.
class DartED25519SigningApi implements ED25519SigningApi {
  const DartED25519SigningApi();
  ({List<int> extendedKey, List<int> secret}) _extractKeys({
    required List<int> secretKey,
    required CryptoKeyType type,
  }) {
    switch (type) {
      case CryptoKeyType.ed25519:
      case CryptoKeyType.ed25519Blake2b:
        if (secretKey.length != Ed25519KeysConst.privKeyByteLen) {
          throw CoreErrors.invalidOperationArguments(
            "sign",
            name: "secretKey",
            reason: "Invalid secret key bytes length.",
          );
        }
        final extendedKey = switch (type) {
          CryptoKeyType.ed25519Blake2b => QuickCrypto.blake2b512Hash(secretKey),
          _ => QuickCrypto.sha512Hash(secretKey),
        };
        final extendeKey = extendedKey.sublist(Ed25519KeysConst.privKeyByteLen);
        final secret = extendedKey.sublist(0, Ed25519KeysConst.privKeyByteLen);
        ED25519KeyUtils.keyPrune(secret);
        return (extendedKey: extendeKey, secret: secret);
      case CryptoKeyType.ed25519Monero:
      case CryptoKeyType.ed25519Kholaw:
        if (secretKey.length != Ed25519KeysConst.kholawPrivKeyLen) {
          throw CoreErrors.invalidOperationArguments(
            "sign",
            name: "secretKey",
            reason: "Invalid secret key bytes length.",
          );
        }
        final extendeKey = secretKey.sublist(Ed25519KeysConst.privKeyByteLen);
        final secret = secretKey.sublist(0, Ed25519KeysConst.privKeyByteLen);
        return (extendedKey: extendeKey, secret: secret);
      default:
        throw CoreErrors.cryptoFailed(
          "IEd25519SigningKey.sign",
          reason: "Invalid ED25519 key bytes.",
        );
    }
  }

  @override
  BuBytes sign({
    required List<int> sk,
    required List<int> message,
    required List<int> publicKey,
    CryptoKeyType type = CryptoKeyType.ed25519,
  }) {
    final keys = _extractKeys(secretKey: sk, type: type);
    final hash = QuickCrypto.sha512Hash([...keys.extendedKey, ...message]);
    final rScalar = EdwardsLimbOps.scReduce64(hash);
    final R = EdwardsLimbOps.multBase(rScalar);
    final kBytes = QuickCrypto.sha512Hash([...R, ...publicKey, ...message]);
    final s = EdwardsLimbOps.scReduce64(kBytes);
    // The secret scalar is clamped (ed25519) or raw (kholaw/monero) and may
    // exceed L: reduce (idempotent on canonical input) before combining.
    final sec = EdwardsLimbOps.scReduce32(keys.secret);
    final s2 = EdwardsLimbOps.scMulAdd(s, sec, rScalar);
    if (!EdwardsLimbOps.scIsNonZero(s) ||
        !EdwardsLimbOps.scIsNonZero(rScalar)) {
      throw CoreErrors.cryptoFailed(
        "DartED25519SigningApi.sign",
        reason: "Signing produced an invalid zero scalar.",
      );
    }
    return BuBytes.concat([R, s2]);
  }

  @override
  bool verify({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKey,
    CryptoKeyType type = CryptoKeyType.ed25519,
  }) {
    if (signature.length != CryptoSignerConst.ed25519SignatureLength) {
      return false;
    }
    final rBytes = signature.sublist(0, 32);
    final sBytes = signature.sublist(32);
    final EdwardsLimbPoint pk;
    final EdwardsLimbPoint rPoint;
    final Ed25519Fr sScalar;
    try {
      pk = EdwardsLimbPoint.fromBytes(publicKey);
      rPoint = EdwardsLimbPoint.fromBytes(rBytes);
      sScalar = Ed25519Fr.fromBytes(sBytes);
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "verify",
        name: "signature",
        reason: "Invalid signature bytes.",
      );
    }
    final digest = QuickCrypto.sha512Hash([
      ...rPoint.toBytes(),
      ...publicKey,
      ...message,
    ]);
    final k = Ed25519Fr.fromBytes64(digest);
    final s2 = EdwardsLimbPoint.generator_ * sScalar;
    if (s2.isIdentity()) return false;
    if (s2 != pk * k + rPoint) {
      return false;
    }
    return true;
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    try {
      final point = EdwardsLimbPoint.fromBytes(publicKey);
      if (point.isIdentity()) return null;
      return BuBytes.immutable(point.toBytes());
    } catch (_) {
      return null;
    }
  }
}
