import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/ristretto/point/ristretto.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/sr25519.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/merlin/transcript.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Pure-Dart implementation of sr25519 (Schnorrkel) key derivation/signing/
/// verification/VRF operations.
class DartSr25519SigningApi implements Sr25519SigningApi {
  RistrettoCurveApi get curveApi => blockchainUtils.api.ristretto;
  const DartSr25519SigningApi();

  static MerlinTranscript signContext({
    List<int>? context,
    List<int>? message,
  }) {
    final script = MerlinTranscript("SigningContext");
    script.additionalData([], context ?? []);
    script.additionalData(StringUtils.encode("sign-bytes"), message ?? []);
    return script;
  }

  (BuBytes, BuBytes) _expandEd25519(List<int> seedBytes) {
    final toHash = QuickCrypto.sha512Hash(seedBytes);
    final key = toHash.sublist(0, 32);
    key[0] &= 248;
    key[31] &= 63;
    key[31] |= 64;
    final r = SchnorrKeyUtils.divideScalarByCofactor(key).asBytes;
    return (r, toHash.sublist(32));
  }

  (BuBytes, BuBytes) _expandUniform(List<int> seedBytes) {
    final script = MerlinTranscript("ExpandSecretKeys");
    script.additionalData(StringUtils.encode("mini"), seedBytes);
    final key = script.toBytesWithReduceScalar(StringUtils.encode("sk"), 64);
    final nonce = script.toBytes(StringUtils.encode("no"), 32);
    return (key.sublist(0, 32), nonce.sublist(0, 32));
  }

  (BuBytes, BuBytes) _toSecretKeyInner({
    required BuBytes seedBytes,
    required bool uniform,
    required bool isSeed,
  }) {
    if (!isSeed) {
      if (seedBytes.length != SchnorrkelKeyCost.secretKeyLength) {
        throw CoreErrors.invalidOperationArguments(
          "Sr25519Signing.toSecretKey",
          reason: "Invalid secret key bytes length.",
        );
      }
      return (
        seedBytes.sublist(0, SchnorrkelKeyCost.miniSecretLength),
        seedBytes.sublist(SchnorrkelKeyCost.miniSecretLength),
      );
    }
    if (seedBytes.length != SchnorrkelKeyCost.miniSecretLength) {
      throw CoreErrors.invalidOperationArguments(
        "Sr25519Signing.toSecretKey",
        reason: "Invalid seed bytes length.",
      );
    }
    if (uniform) {
      return _expandUniform(seedBytes);
    }
    return _expandEd25519(seedBytes);
  }

  (BuBytes, BuBytes, BuBytes) _toSecretKey({
    required BuBytes seedBytes,
    required bool uniform,
    required bool isSeed,
  }) {
    final (sk, nonce) = _toSecretKeyInner(
      seedBytes: seedBytes,
      uniform: uniform,
      isSeed: isSeed,
    );
    return (sk, nonce, BuBytes.concat([sk, nonce]));
  }

  (BuBytes, BuBytes) _deriveScalarAndChainCode(
    List<int> publicKey,
    List<int> chainCode, [
    List<int>? message,
  ]) {
    final script = MerlinTranscript("SchnorrRistrettoHDKD");
    script.additionalData(
      StringUtils.encode('sign-bytes'),
      message ?? List.empty(),
    );
    script.additionalData(StringUtils.encode("chain-code"), chainCode);
    script.additionalData(StringUtils.encode("public-key"), publicKey);
    final newKey = script.toBytesWithReduceScalar(
      StringUtils.encode("HDKD-scalar"),
      64,
    );
    final newChainCode = script.toBytes(
      StringUtils.encode("HDKD-chaincode"),
      32,
    );
    return (newKey, newChainCode);
  }

  @override
  (BuBytes, BuBytes) derivePublic({
    required List<int> publicKey,
    required List<int> chainCode32,
    List<int>? message,
  }) {
    final derive = _deriveScalarAndChainCode(publicKey, chainCode32, message);
    final mult = curveApi.multBase(derive.$1);
    final pAdd = curveApi.add(publicKey, mult);
    return (pAdd, derive.$2);
  }

  @override
  (BuBytes, BuBytes) hardDerive({
    required List<int> seedOrSk,
    required List<int> chainCode32,
    List<int>? message,
    bool fromSeed = true,
    bool uniform = false,
  }) {
    final (sk, nonce, f) = _toSecretKey(
      seedBytes: seedOrSk.asBytes,
      uniform: uniform,
      isSeed: fromSeed,
    );
    final script = MerlinTranscript("SchnorrRistrettoHDKD");
    script.additionalData(
      StringUtils.encode('sign-bytes'),
      message ?? List.empty(),
    );
    script.additionalData(StringUtils.encode("chain-code"), chainCode32);
    script.additionalData(StringUtils.encode("secret-key"), sk);
    final newSecret = script.toBytes(StringUtils.encode("HDKD-hard"), 32);
    final newChainCode = script.toBytes(
      StringUtils.encode("HDKD-chaincode"),
      32,
    );
    final (newSk, newNonce, newS) = _toSecretKey(
      seedBytes: newSecret,
      uniform: uniform,
      isSeed: true,
    );
    sk.forceZero();
    f.forceZero();
    newSk.forceZero();
    return (newS, newChainCode);
  }

  @override
  bool isValidPublicKey(List<int> pk32) {
    try {
      RistrettoPoint.fromBytes(pk32);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool isValidSecretKey(List<int> sk) {
    if (sk.length != SchnorrkelKeyCost.secretKeyLength) {
      return false;
    }
    final keyPart = sk.sublist(0, SchnorrkelKeyCost.miniSecretLength);
    try {
      final canonicalKey = SchnorrKeyUtils.toCanonical(keyPart);
      if (canonicalKey == null) return false;
      return true;
    } finally {
      keyPart.tryZero();
    }
  }

  @override
  BuBytes publicKeyFromSecret(List<int> sk64) {
    if (sk64.length == SchnorrkelKeyCost.secretKeyLength) {
      final keyPart = sk64.sublist(0, SchnorrkelKeyCost.miniSecretLength);
      try {
        final canonicalKey = SchnorrKeyUtils.toCanonical(keyPart);
        if (canonicalKey != null) {
          return curveApi.multBase(canonicalKey);
        }
      } finally {
        keyPart.tryZero();
      }
    }
    throw CoreErrors.invalidOperationArguments(
      "publicKeyFromSecret",
      reason: "Invalid SR25519 secret key bytes.",
    );
  }

  @override
  BuBytes publicKeyFromSeed(List<int> seed32, {bool uniform = false}) {
    final (sk, nonce, f) = _toSecretKey(
      seedBytes: seed32.asBytes,
      uniform: uniform,
      isSeed: true,
    );
    try {
      return publicKeyFromSecret(f);
    } finally {
      sk.forceZero();
      f.forceZero();
    }
  }

  BuBytes signScript({
    required List<int> seedOrSk,
    required List<int> nonce64,
    required MerlinTranscript script,
    bool fromSeed = true,
    bool uniform = false,
  }) {
    final (key, _, f) = _toSecretKey(
      seedBytes: seedOrSk.asBytes,
      uniform: uniform,
      isSeed: fromSeed,
    );
    try {
      final pubKey = publicKeyFromSecret(f);
      script.additionalData(
        StringUtils.encode("proto-name"),
        StringUtils.encode("Schnorr-sig"),
      );
      script.additionalData(StringUtils.encode("sign:pk"), pubKey);
      if (nonce64.length != SchnorrkelKeyCost.signatureNonceLength) {
        throw CoreErrors.cryptoFailed(
          "ISR25519SigningKey",
          reason: "Unexpected random bytes length.",
        );
      }
      final scNonce = curveApi.scReduce64(nonce64);
      final mult = curveApi.multBase(scNonce);
      script.additionalData(StringUtils.encode("sign:R"), mult);
      final k = script.toBytesWithReduceScalar(
        StringUtils.encode("sign:c"),
        64,
      );
      final sigS = curveApi.scMulAdd(key, k, scNonce);
      sigS[31] |= 128;

      return BuBytes.concat([mult, sigS]);
    } finally {
      f.forceZero();
      key.forceZero();
    }
  }

  @override
  BuBytes sign({
    required List<int> seedOrSk,
    required List<int> message,
    required List<int> nonce64,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
  }) {
    return signScript(
      seedOrSk: seedOrSk,
      nonce64: nonce64,
      script: signContext(context: context, message: message),
      fromSeed: fromSeed,
      uniform: uniform,
    );
  }

  @override
  (BuBytes, BuBytes) softDerive({
    required List<int> seedOrSk,
    required List<int> chainCode32,
    required List<int> newNonce32,
    List<int>? message,
    bool fromSeed = true,
    bool uniform = false,
  }) {
    final (key, nonce, f) = _toSecretKey(
      seedBytes: seedOrSk.asBytes,
      uniform: uniform,
      isSeed: fromSeed,
    );
    try {
      final pubKey = publicKeyFromSecret(f);
      final derivePub = _deriveScalarAndChainCode(pubKey, chainCode32, message);
      if (newNonce32.length != SchnorrkelKeyCost.nonceLength) {
        throw CoreErrors.cryptoFailed(
          "softDerive",
          reason: "Unexpected random bytes length.",
        );
      }
      final newKey = curveApi.scAdd(key, derivePub.$1);
      final combine = BuBytes.concat([newKey, newNonce32]);
      newKey.forceZero();
      return (combine, derivePub.$2);
    } finally {
      key.forceZero();
      f.forceZero();
    }
  }

  @override
  BuBytes toEd25519Bytes(List<int> sk64) {
    final k = sk64.sublist(0, SchnorrkelKeyCost.miniSecretLength);
    try {
      final nonce = sk64.sublist(SchnorrkelKeyCost.miniSecretLength);
      SchnorrKeyUtils.multiplyScalarBytesByCofactor(k);
      return BuBytes.concat([k, nonce]);
    } finally {
      k.tryZero();
    }
  }

  bool verifyScript({
    required MerlinTranscript script,
    required List<int> publicKey,
    required List<int> signature,
  }) {
    if (signature.length != SchnorrkelKeyCost.signatureLength) {
      return false;
    }
    final rBytes = signature.sublist(0, 32);
    final sBytes = signature.sublist(32);
    script.additionalData(
      StringUtils.encode("proto-name"),
      StringUtils.encode("Schnorr-sig"),
    );
    script.additionalData(StringUtils.encode("sign:pk"), publicKey);
    script.additionalData(StringUtils.encode("sign:R"), rBytes);
    final k = script.toBytesWithReduceScalar(StringUtils.encode("sign:c"), 64);
    final neg = curveApi.neg(publicKey);
    final mult = curveApi.mult(k, neg);
    // Strip the wire-format marker bit before canonical validation
    // (see SR25519Signature.fromBytes).
    final strippedS = List<int>.from(sBytes)..[31] &= 127;
    final cS = SchnorrKeyUtils.toCanonical(strippedS);
    if (cS == null) return false;
    final multBase = curveApi.multBase(cS);
    final r = curveApi.add(mult, multBase);
    return BytesUtils.bytesEqual(r, rBytes);
  }

  @override
  bool verify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> signature,
    List<int>? context,
  }) {
    return verifyScript(
      script: signContext(context: context, message: message),
      publicKey: publicKey,
      signature: signature,
    );
  }

  @override
  BuBytes vrfSign({
    required List<int> seedOrSk,
    required List<int> message,
    required List<int> nonce64,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
    List<int>? extra,
    bool kusamaVrf = true,
  }) {
    final inOutput = vrfInOut(
      message: message,
      seedOrSk: seedOrSk,
      context: context,
      fromSeed: fromSeed,
      uniform: uniform,
    );
    final proof = dleqProve(
      nonce64: nonce64,
      inout64: inOutput,
      seedOrSk: seedOrSk,
      fromSeed: fromSeed,
      kusamaVrf: kusamaVrf,
      uniform: uniform,
      extra: extra,
    );
    return BuBytes.concat([inOutput.sublist(32), proof]);
  }

  @override
  bool vrfVerify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> preOut32,
    required List<int> proof64,
    List<int>? context,
    List<int>? extra,
    bool kusamaVrf = true,
  }) {
    final publicHashPoint = vrfHash(
      message: message,
      publicKey: publicKey,
      context: context,
    );
    return dleqVerify(
      inout64: BuBytes.concat([publicHashPoint, preOut32]),
      proof64: proof64,
      extra: extra,
      publicKey: publicKey,
      kusamaVrf: kusamaVrf,
    );
  }

  bool vrfVerifyScript({
    required List<int> publicKey,
    required List<int> preOut32,
    required List<int> proof64,
    required MerlinTranscript script,
    MerlinTranscript? verifyScript,
    bool kusamaVrf = true,
  }) {
    final publicHashPoint = vrfHashScript(publicKey: publicKey, script: script);

    return dleqVerifyScript(
      inout64: BuBytes.concat([publicHashPoint, preOut32]),
      proof64: proof64,
      script: verifyScript,
      publicKey: publicKey,
      kusamaVrf: kusamaVrf,
    );
  }

  BuBytes dleqProveScript({
    required List<int> seedOrSk,
    required List<int> inout64,
    required List<int> nonce64,
    MerlinTranscript? script,
    bool fromSeed = true,
    bool uniform = false,
    bool kusamaVrf = true,
  }) {
    script ??= MerlinTranscript("VRF");
    if (inout64.length != SchnorrkelKeyCost.vrfPreOutLength * 2) {
      throw CoreErrors.invalidOperationArguments(
        "dleqProve",
        reason: "Invalid proof inout bytes length.",
      );
    }
    final input = inout64.sublist(0, 32);
    final output = inout64.sublist(32);
    final (sk, nonce, f) = _toSecretKey(
      seedBytes: seedOrSk.asBytes,
      uniform: uniform,
      isSeed: fromSeed,
    );
    try {
      final pkBytes = publicKeyFromSecret(f);
      const int nonceLength = SchnorrkelKeyCost.signatureNonceLength;
      script.additionalData(
        StringUtils.encode("proto-name"),
        StringUtils.encode("DLEQProof"),
      );
      script.additionalData(StringUtils.encode("vrf:h"), input);
      if (!kusamaVrf) {
        script.additionalData(StringUtils.encode("vrf:pk"), pkBytes);
      }
      if (nonce64.length != nonceLength) {
        throw const BuError(
          DefaultErrorType.invalidLength,
          "invalid nonce length.",
        );
      }
      final nScalar = curveApi.scReduce(nonce64);
      final mult = curveApi.multBase(nScalar);
      script.additionalData(StringUtils.encode("vrf:R=g^r"), mult);
      final inputPoint = curveApi.mult(nScalar, input);
      script.additionalData(StringUtils.encode("vrf:h^r"), inputPoint);
      if (kusamaVrf) {
        script.additionalData(StringUtils.encode("vrf:pk"), pkBytes);
      }
      script.additionalData(StringUtils.encode("vrf:h^sk"), output);
      final c = script.toBytesWithReduceScalar(
        StringUtils.encode("prove"),
        SchnorrkelKeyCost.vrfProofLength,
      );
      return BuBytes.concat([c, curveApi.scMulSub(c, sk, nScalar)]);
    } finally {
      sk.forceZero();
      f.forceZero();
    }
  }

  @override
  BuBytes dleqProve({
    required List<int> seedOrSk,
    required List<int> inout64,
    required List<int> nonce64,
    List<int>? extra,
    bool fromSeed = true,
    bool uniform = false,
    bool kusamaVrf = true,
  }) {
    final script = MerlinTranscript("VRF");
    if (extra != null) {
      script.additionalData([], extra);
    }
    return dleqProveScript(
      seedOrSk: seedOrSk,
      inout64: inout64,
      nonce64: nonce64,
      script: script,
      fromSeed: fromSeed,
      kusamaVrf: kusamaVrf,
      uniform: uniform,
    );
  }

  bool dleqVerifyScript({
    required List<int> publicKey,
    required List<int> inout64,
    required List<int> proof64,
    required MerlinTranscript? script,
    bool kusamaVrf = true,
  }) {
    if (inout64.length != SchnorrkelKeyCost.vrfPreOutLength * 2) {
      return false;
    }
    if (proof64.length != SchnorrkelKeyCost.vrfProofLength) {
      return false;
    }
    script ??= MerlinTranscript("VRF");
    final c = SchnorrKeyUtils.toCanonical(proof64.sublist(0, 32));
    final s = SchnorrKeyUtils.toCanonical(proof64.sublist(32));
    if (c == null || s == null) {
      return false;
    }
    final input = inout64.sublist(0, 32);
    final output = inout64.sublist(32);

    script.additionalData(
      StringUtils.encode("proto-name"),
      StringUtils.encode("DLEQProof"),
    );
    script.additionalData(StringUtils.encode("vrf:h"), input);
    if (!kusamaVrf) {
      script.additionalData(StringUtils.encode("vrf:pk"), publicKey);
    }
    final pr = curveApi.add(curveApi.mult(c, publicKey), curveApi.multBase(s));
    script.additionalData(StringUtils.encode("vrf:R=g^r"), pr);
    final hr = curveApi.add(curveApi.mult(c, output), curveApi.mult(s, input));
    script.additionalData(StringUtils.encode("vrf:h^r"), hr);
    if (kusamaVrf) {
      script.additionalData(StringUtils.encode("vrf:pk"), publicKey);
    }
    script.additionalData(StringUtils.encode("vrf:h^sk"), output);
    final gC = script.toBytesWithReduceScalar(StringUtils.encode("prove"), 64);
    return BytesUtils.bytesEqual(c, gC);
  }

  @override
  bool dleqVerify({
    required List<int> publicKey,
    required List<int> inout64,
    required List<int> proof64,
    List<int>? extra,
    bool kusamaVrf = true,
  }) {
    final script = MerlinTranscript("VRF");
    if (extra != null) {
      script.additionalData([], extra);
    }
    return dleqVerifyScript(
      publicKey: publicKey,
      inout64: inout64,
      proof64: proof64,
      script: script,
      kusamaVrf: kusamaVrf,
    );
  }

  BuBytes vrfHashScript({
    required List<int> publicKey,
    required MerlinTranscript script,
  }) {
    script.additionalData(StringUtils.encode("vrf-nm-pk"), publicKey);
    final scBytes = script.toBytes(StringUtils.encode("VRFHash"), 64);
    return RistrettoPoint.fromUniform(scBytes).toBytes();
  }

  @override
  BuBytes vrfHash({
    required List<int> publicKey,
    required List<int> message,
    List<int>? context,
  }) {
    return vrfHashScript(
      publicKey: publicKey,
      script: signContext(context: context, message: message),
    );
  }

  BuBytes vrfInOutScript({
    required List<int> seedOrSk,
    required MerlinTranscript script,
    bool fromSeed = true,
    bool uniform = false,
  }) {
    final (sk, nonce, f) = _toSecretKey(
      seedBytes: seedOrSk.asBytes,
      uniform: uniform,
      isSeed: fromSeed,
    );
    try {
      final publicHashPoint = vrfHashScript(
        publicKey: publicKeyFromSecret(f),
        script: script,
      );
      final p = curveApi.mult(sk, publicHashPoint);
      return BuBytes.concat([publicHashPoint, p]);
    } finally {
      sk.forceZero();
      f.forceZero();
    }
  }

  @override
  BuBytes vrfInOut({
    required List<int> seedOrSk,
    required List<int> message,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
  }) {
    final (sk, nonce, f) = _toSecretKey(
      seedBytes: seedOrSk.asBytes,
      uniform: uniform,
      isSeed: fromSeed,
    );
    try {
      final publicHashPoint = vrfHash(
        publicKey: publicKeyFromSecret(f),
        message: message,
        context: context,
      );
      final p = curveApi.mult(sk, publicHashPoint);
      return BuBytes.concat([publicHashPoint, p]);
    } finally {
      sk.forceZero();
      f.forceZero();
    }
  }

  @override
  BuBytes secretFromSeed(List<int> seed, {bool uniform = false}) {
    final (sk, nonce, f) = _toSecretKey(
      seedBytes: seed.asBytes,
      uniform: uniform,
      isSeed: true,
    );
    try {
      return f;
    } finally {
      sk.forceZero();
    }
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    try {
      final point = RistrettoPoint.fromBytes(publicKey);
      if (point.isZero()) return null;
      return BuBytes.immutable(point.toBytes());
    } catch (_) {
      return null;
    }
  }
}
