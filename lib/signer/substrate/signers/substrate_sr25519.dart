import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/signer/substrate/core/verifier.dart';

class _SubstrateSr25519SignerConst {
  static const int vrfResultLength =
      SchnorrkelKeyCost.vrfPreOutLength + SchnorrkelKeyCost.vrfProofLength;
}

class _SubstrateSr25519SignerUtils {
  static MerlinTranscript signingContext(List<int> message) {
    final signingScript = MerlinTranscript("SigningContext");
    signingScript.additionalData("".codeUnits, "substrate".codeUnits);
    signingScript.additionalData("sign-bytes".codeUnits, message);
    return signingScript;
  }

  static MerlinTranscript substrateVrfSignScript(
      List<int> message, List<int>? context) {
    final signingScript = MerlinTranscript("SigningContext");
    signingScript.additionalData("".codeUnits, context ?? <int>[]);
    signingScript.additionalData("sign-bytes".codeUnits, message);
    return signingScript;
  }

  static MerlinTranscript vrfScript({List<int>? extra}) {
    final script = MerlinTranscript("VRF");
    if (extra != null) {
      script.additionalData([], extra);
    }
    return script;
  }
}

/// Class for signing Substrate transactions using either SR25519 algorithm.
class SubstrateSr25519Signer implements BaseSubstrateSigner {
  /// Constructs a new SubstrateED25519Signer instance with the provided signing keys.
  const SubstrateSr25519Signer._(this._signer);

  /// The EDDSA private key for signing.
  final SchnorrkelSecretKey _signer;

  /// Factory method to create an SubstrateED25519Signer instance from key bytes.
  factory SubstrateSr25519Signer.fromKeyBytes(List<int> keyBytes) {
    return SubstrateSr25519Signer._(SchnorrkelSecretKey.fromBytes(keyBytes));
  }

  /// Returns an SubstrateED25519Signer instance based on the available signing key type.
  ///
  /// This method constructs and returns an SubstrateED25519Verifier instance for signature verification.
  ///
  /// returns An SubstrateED25519Verifier instance based on the available signing key type.
  SubstrateSr25519Verifier toVerifyKey() {
    return SubstrateSr25519Verifier._(_signer.publicKey());
  }

  List<int> signScript(MerlinTranscript signingScript) {
    final cloneScript = signingScript.clone();
    final verifier = toVerifyKey();
    final signature = _signer.sign(signingScript);
    if (!verifier.verifyScript(signature.toBytes(), cloneScript)) {
      throw const MessageException(
          'The created signature does not pass verification.');
    }
    return signature.toBytes();
  }

  @override
  List<int> sign(List<int> message) {
    return signScript(_SubstrateSr25519SignerUtils.signingContext(message));
  }

  @override
  List<int> vrfSign(List<int> message, {List<int>? context, List<int>? extra}) {
    final MerlinTranscript vrfScript =
        _SubstrateSr25519SignerUtils.vrfScript(extra: extra);
    final MerlinTranscript script =
        _SubstrateSr25519SignerUtils.substrateVrfSignScript(message, context);
    final sign =
        _signer.vrfSign(script, kusamaVRF: true, verifyScript: vrfScript);
    final List<int> vrfResult = [...sign.item1.output, ...sign.item2.toBytes()];
    final verifier = toVerifyKey();
    if (!verifier.vrfVerify(message, List<int>.from(vrfResult),
        context: context, extra: extra)) {
      throw const MessageException(
          'The created vrfSign does not pass verification.');
    }
    return vrfResult;
  }
}

/// Class representing an Substrate SR25519 Verifier for signature verification.
class SubstrateSr25519Verifier implements BaseSubstrateVerifier {
  final SchnorrkelPublicKey _verifier;

  /// Private constructor to create an SubstrateSr25519Verifier instance.
  const SubstrateSr25519Verifier._(this._verifier);

  /// Factory method to create an SolanaVerifier instance from key bytes.
  factory SubstrateSr25519Verifier.fromKeyBytes(List<int> keyBytes) {
    final verifier = SchnorrkelPublicKey(keyBytes);
    return SubstrateSr25519Verifier._(verifier);
  }

  /// Verifies the signature for the provided digest using the available key.
  ///
  /// This method verifies the signature of the provided script using either schnorrkel algorithms,
  bool verifyScript(List<int> signature, MerlinTranscript signingScript) {
    return _verifier.verify(
        SchnorrkelSignature.fromBytes(signature), signingScript);
  }

  /// Verifies the signature for the provided digest using the available key.
  ///
  /// This method verifies the signature of the provided message using either schnorrkel algorithms,
  @override
  bool verify(List<int> message, List<int> signature) {
    return verifyScript(
        signature, _SubstrateSr25519SignerUtils.signingContext(message));
  }

  @override
  bool vrfVerify(List<int> message, List<int> vrfSign,
      {List<int>? context, List<int>? extra}) {
    if (vrfSign.length != _SubstrateSr25519SignerConst.vrfResultLength) {
      throw ArgumentException(
          "Invalid VrfSign bytes length. excepted: ${_SubstrateSr25519SignerConst.vrfResultLength} got: ${vrfSign.length} ");
    }
    final MerlinTranscript vrfScript =
        _SubstrateSr25519SignerUtils.vrfScript(extra: extra);
    final MerlinTranscript script =
        _SubstrateSr25519SignerUtils.substrateVrfSignScript(message, context);
    final VRFPreOut output =
        VRFPreOut(vrfSign.sublist(0, SchnorrkelKeyCost.vrfPreOutLength));
    final VRFProof proof =
        VRFProof.fromBytes(vrfSign.sublist(SchnorrkelKeyCost.vrfPreOutLength));
    return _verifier.vrfVerify(script, output, proof, verifyScript: vrfScript);
  }
}
