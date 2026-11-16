import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/ristretto/point/ristretto.dart';
import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/keys/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/keys/utils.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/merlin/transcript.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Common base for sr25519's two signature shapes (plain + VRF).
abstract class BaseSR25519Signature extends ISignature {
  const BaseSR25519Signature();
}

/// A plain sr25519 (Schnorrkel) signature.
class SR25519Signature extends BaseSR25519Signature {
  factory SR25519Signature.fromBytes(List<int> signatureBytes) {
    signatureBytes.exc(
      length: SchnorrkelKeyCost.signatureLength,
      operation: "SR25519Signature.fromBytes",
      reason: "Invalid signature bytes length.",
    );
    final r = signatureBytes.sublist(0, 32);
    final s = signatureBytes.sublist(32, 64);
    if (s[31] & 128 == 0) {
      throw CoreErrors.cryptoFailed(
        "SR25519Signature.fromBytes",
        reason: "Invalid signature bytes.",
      );
    }
    // toCanonical validates the pure scalar value, so strip the wire-format
    // marker bit first (toCanonical itself is shared with secret/VRF parsing
    // and must keep requiring canonical input).
    final strippedS = List<int>.from(s)..[31] &= 127;
    final canonicalS = SchnorrKeyUtils.toCanonical(strippedS);
    if (canonicalS == null) {
      throw CoreErrors.cryptoFailed(
        "SR25519Signature.fromBytes",
        reason: "Invalid signature bytes.",
      );
    }
    return SR25519Signature._(canonicalS, r);
  }

  SR25519Signature._(List<int> s, List<int> r)
    : s = BuBytes.immutable(s),
      r = BuBytes.immutable(r);

  final BuBytes r;
  final BuBytes s;

  BigInt get rBigint => BigintUtils.fromBytes(r, byteOrder: Endian.little);
  BigInt get sBigint => BigintUtils.fromBytes(s, byteOrder: Endian.little);

  @override
  BuBytes toBytes() {
    final inBytes = [...r, ...s];
    inBytes[63] |= 128;
    return BuBytes(inBytes);
  }

  @override
  List<dynamic> get variables => [r, s];
}

/// An sr25519 VRF signature: output + proof (+ optional input).
class SR25519VRFSignature extends BaseSR25519Signature {
  final VRFPreOut output;
  final VRFProof proof;
  final BuBytes? input;
  SR25519VRFSignature({
    required this.output,
    required this.proof,
    List<int>? input,
  }) : input = input?.asImmutableBytes;

  factory SR25519VRFSignature.fromBytes(List<int> bytes) {
    const int vrfResultLength =
        SchnorrkelKeyCost.vrfPreOutLength + SchnorrkelKeyCost.vrfProofLength;
    if (bytes.length != vrfResultLength) {
      throw CoreErrors.invalidOperationArguments(
        "SR25519VRFSignature.fromBytes",
        name: "bytes",
        reason: "Invalid vrf signature bytes length.",
      );
    }
    final VRFPreOut output = VRFPreOut(
      bytes.sublist(0, SchnorrkelKeyCost.vrfPreOutLength),
    );
    final VRFProof proof = VRFProof.fromBytes(
      bytes.sublist(SchnorrkelKeyCost.vrfPreOutLength),
    );
    return SR25519VRFSignature(output: output, proof: proof);
  }

  @override
  BuBytes toBytes() {
    return BuBytes.unsafeMutable([...output.toBytes(), ...proof.toBytes()]);
  }

  @override
  List<dynamic> get variables => [output, proof];
}

/// Parameters for a plain sr25519 sign operation.
class SR25519SigningParams implements ISigningParams {
  final BuBytes message;
  final BuBytes? context;
  final BuBytes? nonce;
  SR25519SigningParams({
    required List<int> context,
    required List<int> message,
    List<int>? nonce,
  }) : nonce =
           nonce
               ?.exc(
                 length: SchnorrkelKeyCost.signatureNonceLength,
                 operation: "SR25519SigningParams",
                 reason: "Invalid nonce bytes length.",
                 name: "nonce",
               )
               .asImmutableBytes,
       message = message.asImmutableBytes,
       context = context.asImmutableBytes;
}

/// Parameters for an sr25519 VRF sign operation.
class SR25519VrfSigningParams implements ISigningParams {
  final BuBytes message;
  final BuBytes? context;
  final BuBytes? nonce;
  final BuBytes? vrfScriptadditionalData;
  final bool kusamaVRF;

  SR25519VrfSigningParams({
    required List<int> context,
    required List<int> message,
    List<int>? vrfScriptadditionalData,
    List<int>? nonce,
    this.kusamaVRF = true,
  }) : nonce =
           nonce
               ?.exc(
                 length: SchnorrkelKeyCost.signatureNonceLength,
                 operation: "SR25519VrfSigningParams",
                 reason: "Invalid nonce bytes length.",
               )
               .asImmutableBytes,
       message = message.asImmutableBytes,
       context = context.asImmutableBytes,
       vrfScriptadditionalData = vrfScriptadditionalData?.asImmutableBytes;
}

/// Parameters for a plain sr25519 verify operation.
class SR25519VerifyingParams implements IVerifiyingParams {
  final SR25519SigningParams signingParams;
  final SR25519Signature signature;
  SR25519VerifyingParams({
    required this.signingParams,
    required this.signature,
  });
}

/// Parameters for an sr25519 VRF verify operation.
class SR25519VRFVerifyingParams implements IVerifiyingParams {
  final SR25519VrfSigningParams signingParams;
  final SR25519VRFSignature signature;
  SR25519VRFVerifyingParams({
    required this.signingParams,
    required this.signature,
  });
}

/// Common interface every sr25519 public key implements.
abstract class ISR25519VerificationKey
    implements IVerifiyingKey<SR25519VerifyingParams> {
  BuBytes get keyBytes;
  const ISR25519VerificationKey();
  bool vrfVerify(SR25519VRFVerifyingParams params) {
    return blockchainUtils.api.signing.sr25519.vrfVerify(
      publicKey: keyBytes,
      message: params.signingParams.message,
      context: params.signingParams.context,
      kusamaVrf: params.signingParams.kusamaVRF,
      preOut32: params.signature.output.toBytes(),
      proof64: params.signature.proof.toBytes(),
      extra: params.signingParams.vrfScriptadditionalData,
    );
  }

  bool vrfVerifyScript(
    MerlinTranscript script,
    SR25519VRFSignature signature, {
    MerlinTranscript? verifyScript,
    bool isKusamaVRF = true,
  }) {
    final api = DartSr25519SigningApi();
    return api.vrfVerifyScript(
      publicKey: keyBytes,
      script: script,
      verifyScript: verifyScript,
      kusamaVrf: isKusamaVRF,
      preOut32: signature.output.toBytes(),
      proof64: signature.proof.toBytes(),
    );
  }

  bool dleqVerifyScript({
    required VRFInOut out,
    required VRFProof proof,
    List<int>? extra,
    bool isKusamaVRF = true,
  }) {
    return blockchainUtils.api.signing.sr25519.dleqVerify(
      publicKey: keyBytes,
      inout64: out.toBytes(),
      proof64: proof.toBytes(),
      extra: extra,
      kusamaVrf: isKusamaVRF,
    );
  }

  bool dleqVerify({
    required VRFInOut out,
    required VRFProof proof,
    List<int>? extra,
    bool isKusamaVRF = true,
  }) {
    return blockchainUtils.api.signing.sr25519.dleqVerify(
      publicKey: keyBytes,
      inout64: out.toBytes(),
      proof64: proof.toBytes(),
      extra: extra,
      kusamaVrf: isKusamaVRF,
    );
  }

  RistrettoPoint vrfHash(List<int> message, {List<int>? context}) {
    final result = blockchainUtils.api.signing.sr25519.vrfHash(
      publicKey: keyBytes,
      message: message,
      context: context,
    );
    return RistrettoPoint.fromBytes(result);
  }

  RistrettoPoint vrfHashScript(MerlinTranscript script) {
    final api = DartSr25519SigningApi();
    final pk = api.vrfHashScript(publicKey: keyBytes, script: script);
    return RistrettoPoint.fromBytes(pk);
  }

  @override
  bool verify(SR25519VerifyingParams verifyParams) {
    return blockchainUtils.api.signing.sr25519.verify(
      publicKey: keyBytes,
      message: verifyParams.signingParams.message,
      signature: verifyParams.signature.toBytes(),
      context: verifyParams.signingParams.context,
    );
  }
}

/// Common interface every sr25519 private key implements.
abstract class ISR25519SigningKey<P extends ISR25519VerificationKey>
    implements ISigningKey<SR25519Signature, SR25519SigningParams, P> {
  const ISR25519SigningKey();
  SR25519VRFSignature vrfSign(SR25519VrfSigningParams params) {
    return takeSecretKey().useValue((sk) {
      final proof = blockchainUtils.api.signing.sr25519.vrfSign(
        seedOrSk: sk,
        message: params.message,
        nonce64:
            params.nonce ??
            QuickCrypto.generateRandom(
              length: SchnorrkelKeyCost.signatureLength,
            ),
        kusamaVrf: params.kusamaVRF,
        context: params.context,
        fromSeed: false,
        uniform: false,
        extra: params.vrfScriptadditionalData,
      );
      return SR25519VRFSignature.fromBytes(proof);
    });
  }

  VRFInOut vrfInOutScript(MerlinTranscript script) {
    return takeSecretKey().useValue((sk) {
      final api = DartSr25519SigningApi();
      final result = api.vrfInOutScript(
        seedOrSk: sk,
        uniform: false,
        script: script,
        fromSeed: false,
      );
      return VRFInOut.fromBytes(result);
    });
  }

  VRFProof dleqProveScript(
    VRFInOut out, {
    bool kusamaVRF = true,
    List<int>? nonce,
    MerlinTranscript? verifyScript,
  }) {
    return takeSecretKey().useValue((sk) {
      final api = DartSr25519SigningApi();
      final proof = api.dleqProveScript(
        seedOrSk: sk,
        inout64: out.toBytes(),
        nonce64:
            nonce ??
            QuickCrypto.generateRandom(
              length: SchnorrkelKeyCost.signatureNonceLength,
            ),
        script: verifyScript,
        fromSeed: false,
        uniform: false,
        kusamaVrf: kusamaVRF,
      );
      return VRFProof.fromBytes(proof);
    });
  }

  @override
  SR25519Signature sign(SR25519SigningParams params) {
    return takeSecretKey().useValue((sk) {
      final signature = blockchainUtils.api.signing.sr25519.sign(
        seedOrSk: sk,
        message: params.message,
        fromSeed: false,
        uniform: false,
        context: params.context,
        nonce64:
            params.nonce ??
            QuickCrypto.generateRandom(
              length: SchnorrkelKeyCost.signatureNonceLength,
            ),
      );
      return SR25519Signature.fromBytes(signature);
    });
  }
}
