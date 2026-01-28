import 'dart:typed_data';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/crypto/ec/cdsa.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/prng/fortuna.dart';
import 'package:blockchain_utils/crypto/crypto/schnorrkel/merlin/transcript.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// The [SchnorrkelKeyCost] class defines various constants related to the sizes and lengths of Schnorrkel keys and components.
///
/// Schnorrkel is a cryptographic signature scheme, and these constants help manage and understand the sizes of key components.
class SchnorrkelKeyCost {
  /// Length of a VRF (Verifiable Random Function) proof in bytes.
  static const int vrfProofLength = 64;

  /// Length of a mini-secret key in bytes.
  static const int miniSecretLength = 32;

  /// Length of a nonce in bytes.
  static const int nonceLength = 32;

  /// Length of a public key in bytes.
  static const int publickeyLength = 32;

  /// Length of a secret key in bytes.
  static const int secretKeyLength = 64;

  /// Length of a key pair (combined public and secret key) in bytes.
  static const int keypairLength = 96;

  /// Length of a Schnorrkel signature in bytes.
  static const int signatureLength = 64;

  static const int vrfPreOutLength = 32;
}

/// A collection of static utility methods for performing cryptographic operations.
class _KeyUtils {
  /// Checks if the length of the input bytes matches the expected length and throws an error if not.
  ///
  /// Parameters:
  /// - [bytes]: The list of bytes to check.
  /// - [expected]: The expected length of the bytes.
  /// - [name]: A descriptive name for the byte data, used in error messages.
  static void _checkKeysBytes(
    List<int> bytes,
    int expected,
    String name,
    String operaton,
  ) {
    if (bytes.length != expected) {
      throw ArgumentException.invalidOperationArguments(
        operaton,
        name: name,
        reason: "Incorrect $name bytes length.",
      );
    }
  }

  /// Divides a scalar value represented by a byte array by the cofactor of the curve.
  ///
  /// Parameters:
  /// - [s]: A byte array representing the scalar value.
  ///
  /// Returns:
  /// A new byte array with the scalar divided by the cofactor.
  static List<int> divideScalarByCofactor(List<int> s) {
    final int l = s.length - 1;
    int low = 0;
    for (int i = 0; i < s.length; i++) {
      final int r = s[l - i] & 0x07; // remainder
      s[l - i] >>= 3;
      s[l - i] += low;
      low = r << 5;
    }

    return s;
  }

  /// Multiplies a scalar value represented by a byte array by the cofactor of the curve.
  ///
  /// Parameters:
  /// - [scalar]: A byte array representing the scalar value.
  ///
  static void multiplyScalarBytesByCofactor(List<int> scalar) {
    int high = 0;
    for (int i = 0; i < scalar.length; i++) {
      final int r = scalar[i] & 0xE0; // carry bits (0xE0 is binary 11100000)
      scalar[i] <<= 3; // multiply by 8
      scalar[i] += high;
      high = r >> 5;
    }
  }

  /// Checks whether a given byte array represents a canonical value in the context of Ed25519 cryptography.
  ///
  /// Parameters:
  /// - [bytes]: A byte array to be checked for canonical representation.
  ///
  static List<int>? toCanonical(List<int> bytes) {
    final cloneBytes = bytes.clone();
    cloneBytes[31] &= 127;
    final bool highBitUnset = (bytes[31] >> 7 & 0) == 0;
    final bool isCanonical = BytesUtils.bytesEqual(
      cloneBytes,
      Ed25519Utils.scalarReduceVar(cloneBytes),
    );
    if (highBitUnset && isCanonical) {
      return cloneBytes;
    }
    return null;
  }
}

/// The [ExpansionMode] enum defines different expansion modes used in Schnorr signatures (Schnorrkel).
///
/// Schnorr signatures are a cryptographic signature scheme, and the choice of expansion mode can impact key generation and signing.
///
/// - [uniform]: A mode for generating keys and signatures with uniform randomness.
/// - [ed25519]: A mode that follows the Ed25519 specification for key generation and signing.
///
enum ExpansionMode { uniform, ed25519 }

class VRFPreOut {
  VRFPreOut._({required List<int> output}) : _output = output.asImmutableBytes;
  factory VRFPreOut(List<int> bytes) {
    if (bytes.length != SchnorrkelKeyCost.vrfPreOutLength) {
      throw ArgumentException.invalidOperationArguments(
        "VRFPreOut",
        reason: "Incorrect vrf length.",
        details: {
          "expected": SchnorrkelKeyCost.vrfPreOutLength,
          "length": bytes.length,
        },
      );
    }
    return VRFPreOut._(output: bytes);
  }
  final List<int> _output;
  List<int> toBytes() {
    return _output.clone();
  }
}

/// The [VRFInOut] class represents the input and output data of a Verifiable Random Function (VRF) computation.
///
/// VRF is a cryptographic construction used to generate a verifiable proof of a random value.
///
/// Members:
/// - [input]: A [List<int>] containing the input data for the VRF computation.
/// - [output]: A [List<int>] containing the output data of the VRF computation.
///
class VRFInOut {
  /// Private constructor to create a [VRFInOut] instance with input and output data.
  VRFInOut._(List<int> input, List<int> output)
    : _input = input.asImmutableBytes,
      _output = output.asImmutableBytes;
  final List<int> _input;
  final List<int> _output;

  /// Gets a copy of the input data as a [List<int>].
  List<int> get input => _input.clone();

  /// Gets a copy of the output data as a [List<int>].
  List<int> get output => _output.clone();

  /// Converts the output data into a RistrettoPoint point.
  RistrettoPoint get outputPoint => RistrettoPoint.fromBytes(output);

  /// Converts the input data into a RistrettoPoint point.
  RistrettoPoint get inputPoint => RistrettoPoint.fromBytes(input);

  /// Converts the [VRFInOut] instance into a [List<int>] by concatenating the input and output data.
  List<int> toBytes() {
    return [..._input, ..._output];
  }

  VRFPreOut toVRFPreOut() => VRFPreOut(output);
}

/// The [VRFProof] class represents a Verifiable Random Function (VRF) proof, consisting of two components 'c' and 's'.
///
/// Members:
/// - [c]: Containing the 'c' component of the VRF proof.
/// - [s]: Containing the 's' component of the VRF proof.
///
class VRFProof {
  /// Private constructor to create a [VRFProof] instance with 'c' and 's' components.
  VRFProof._(List<int> c, List<int> s)
    : _c = c.asImmutableBytes,
      _s = s.asImmutableBytes;

  /// Creates a [VRFProof] instance from a byte representation.
  /// The input bytes are expected to be properly formatted for a VRF proof.
  factory VRFProof.fromBytes(List<int> bytes) {
    _KeyUtils._checkKeysBytes(
      bytes,
      SchnorrkelKeyCost.vrfProofLength,
      "VRF proof",
      "VRFProof",
    );
    final c = _KeyUtils.toCanonical(bytes.sublist(0, 32));
    final s = _KeyUtils.toCanonical(bytes.sublist(32));
    if (c == null || s == null) {
      throw ArgumentException.invalidOperationArguments(
        "VRFProof",
        reason: "Invalid vrf proof bytes.",
      );
    }
    return VRFProof._(c, s);
  }
  final List<int> _c;
  final List<int> _s;

  /// Gets a copy of the 'c' component.
  List<int> get c => _c.clone();

  /// Gets a copy of the 's' component.
  List<int> get s => _s.clone();

  /// Converts the [c] component into a [BigInt].
  BigInt get cBigint => BigintUtils.fromBytes(c, byteOrder: Endian.little);

  /// Converts the [s] component into a [BigInt].
  BigInt get sBigint => BigintUtils.fromBytes(s, byteOrder: Endian.little);

  /// Converts the [VRFProof] instance into a [List<int>] by concatenating the 'c' and 's' components.
  List<int> toBytes() {
    return [..._c, ..._s];
  }
}

/// The [SchnorrkelMiniSecretKey] class represents a mini-secret key used for generating Schnorr key pairs.
///
/// Members:
/// - [_bytes]: A [List<int>] containing the bytes of the mini-secret key.
///
class SchnorrkelMiniSecretKey {
  /// Private constructor to create a [SchnorrkelMiniSecretKey] instance with bytes.
  SchnorrkelMiniSecretKey._(List<int> bytes) : _bytes = bytes.asImmutableBytes;
  final List<int> _bytes;

  /// mini-secret key as bytes.
  List<int> toBytes() => _bytes.clone();

  /// Creates a [SchnorrkelMiniSecretKey] instance from a byte representation.
  /// The input bytes are expected to have the correct length for a mini-secret key.
  ///
  /// Parameters:
  /// - [keyBytes]: A byte array representing the mini-secret key.
  ///
  factory SchnorrkelMiniSecretKey.fromBytes(List<int> keyBytes) {
    _KeyUtils._checkKeysBytes(
      keyBytes,
      SchnorrkelKeyCost.miniSecretLength,
      "mini secret key",
      "SchnorrkelMiniSecretKey",
    );
    return SchnorrkelMiniSecretKey._(keyBytes);
  }

  SchnorrkelSecretKey _expandEd25519() {
    final toHash = SHA512.hash(toBytes());
    final key = toHash.sublist(0, Ed25519KeysConst.privKeyByteLen);
    key[0] &= 248;
    key[31] &= 63;
    key[31] |= 64;
    final r = _KeyUtils.divideScalarByCofactor(key);
    return SchnorrkelSecretKey(
      r,
      toHash.sublist(Ed25519KeysConst.privKeyByteLen),
    );
  }

  /// The [_expandUniform] method expands the mini-secret key into a Schnorrkel secret key
  SchnorrkelSecretKey _expandUniform() {
    final script = MerlinTranscript("ExpandSecretKeys");
    script.additionalData("mini".codeUnits, toBytes());

    final key = script.toBytesWithReduceScalar("sk".codeUnits, 64);

    final nonce = script.toBytes("no".codeUnits, 32);
    return SchnorrkelSecretKey(key.sublist(0, 32), nonce.sublist(0, 32));
  }

  /// Converts the [SchnorrkelSecretKey] into a full secret key using a specified expansion mode.
  ///
  /// Parameters:
  /// - [mode] (optional): The expansion mode for converting the mini-secret key. Default is [ExpansionMode.ed25519].
  ///
  SchnorrkelSecretKey toSecretKey([
    ExpansionMode mode = ExpansionMode.ed25519,
  ]) {
    if (mode == ExpansionMode.ed25519) {
      return _expandEd25519();
    }
    return _expandUniform();
  }
}

/// The [SchnorrkelSecretKey] class represents a Schnorrkel secret key used for cryptographic operations.
///
/// Members:
/// - [key]: Containing the secret key component.
/// - [nonce]: Containing the nonce component.
///
class SchnorrkelSecretKey with ConstantEquality<SchnorrkelSecretKey> {
  /// Private constructor to create a [SchnorrkelSecretKey] instance with secret key and nonce components.
  SchnorrkelSecretKey._(List<int> key, List<int> nonce)
    : _key = key.asImmutableBytesConst,
      _nonce = nonce.asImmutableBytesConst;

  /// Creates a [SchnorrkelSecretKey] instance from provided secret key and nonce components.
  ///
  /// Parameters:
  /// - [key]: A byte array representing the secret key.
  /// - [nonce]: A byte array representing the nonce.
  ///
  /// Throws:
  /// - An [ArgumentException] if the input components are invalid or not in canonical form.
  factory SchnorrkelSecretKey(List<int> key, List<int> nonce) {
    _KeyUtils._checkKeysBytes(
      key,
      SchnorrkelKeyCost.miniSecretLength,
      "mini secret key",
      "SchnorrkelSecretKey",
    );
    _KeyUtils._checkKeysBytes(
      nonce,
      SchnorrkelKeyCost.nonceLength,
      "nonce",
      "SchnorrkelSecretKey",
    );
    final canonicalKey = _KeyUtils.toCanonical(key);
    if (canonicalKey != null) {
      return SchnorrkelSecretKey._(canonicalKey, nonce);
    }
    throw CryptoException.failed(
      "SchnorrkelSecretKey",
      reason: "invalid sr25519 private key.",
    );
  }

  /// Creates a [SchnorrkelSecretKey] instance from a byte representation of a secret key.
  ///
  /// Parameters:
  /// - [secretKeyBytes]: A byte array representing the secret key.
  ///
  /// Returns:
  /// A [SchnorrkelSecretKey] instance derived from the provided byte representation.
  ///
  /// Throws:
  /// - An [CryptoException] if the byte array does not have the correct length for a secret key.
  factory SchnorrkelSecretKey.fromBytes(List<int> secretKeyBytes) {
    _KeyUtils._checkKeysBytes(
      secretKeyBytes,
      SchnorrkelKeyCost.secretKeyLength,
      "secret key",
      "SchnorrkelSecretKey",
    );
    final keyBytes = secretKeyBytes.sublist(
      0,
      SchnorrkelKeyCost.miniSecretLength,
    );
    final nonceBytes = secretKeyBytes.sublist(
      SchnorrkelKeyCost.miniSecretLength,
      SchnorrkelKeyCost.secretKeyLength,
    );
    return SchnorrkelSecretKey(keyBytes, nonceBytes);
  }

  /// Creates a [SchnorrkelSecretKey] instance from a byte representation of an Ed25519 secret key.
  ///
  /// Parameters:
  /// - [secretKeyBytes]: A byte array representing an Ed25519 secret key.
  ///
  /// Returns:
  /// A [SchnorrkelSecretKey] instance derived from the provided Ed25519 secret key representation.
  ///
  /// Throws:
  /// - An [CryptoException] if the byte array does not have the correct length for a secret key.
  factory SchnorrkelSecretKey.fromEd25519(List<int> secretKeyBytes) {
    _KeyUtils._checkKeysBytes(
      secretKeyBytes,
      SchnorrkelKeyCost.secretKeyLength,
      "secret key",
      "SchnorrkelSecretKey",
    );
    final newKey = secretKeyBytes.sublist(
      0,
      SchnorrkelKeyCost.miniSecretLength,
    );
    _KeyUtils.divideScalarByCofactor(newKey);
    return SchnorrkelSecretKey(
      newKey,
      secretKeyBytes.sublist(
        SchnorrkelKeyCost.miniSecretLength,
        SchnorrkelKeyCost.secretKeyLength,
      ),
    );
  }
  final List<int> _key;
  final List<int> _nonce;

  /// The [toBytes] method converts the Schnorrkel secret key into a byte representation.
  List<int> toBytes() {
    return [..._key, ..._nonce];
  }

  /// The [key] method returns the secret key component of the Schnorrkel secret key.
  List<int> key() => _key.clone();

  /// The [nonce] method returns the nonce component of the Schnorrkel secret key.
  List<int> nonce() => _nonce.clone();

  /// The [publicKey] method derives the corresponding public key from the Schnorrkel secret key.
  SchnorrkelPublicKey publicKey() {
    final pubkey = Ed25519Utils.scalarMultBase(key());

    /// Convert the result to a RistrettoPoint format.
    final pubPoint = RistrettoPoint.fromEdwardBytes(pubkey);

    /// Convert the RistrettoPoint point to bytes and create a Schnorrkel public key.
    final pubBytes = pubPoint.toBytes();
    return SchnorrkelPublicKey(pubBytes);
  }

  /// The [toEd25519Bytes] method converts the Schnorrkel secret key into a byte representation
  /// following the Ed25519 format, suitable for use in Ed25519 operations.
  List<int> toEd25519Bytes() {
    final k = key();

    /// Multiply the secret key by the cofactor.
    _KeyUtils.multiplyScalarBytesByCofactor(k);
    return [...k, ...nonce()];
  }

  /// Derives a new Schnorrkel secret key and chain code from the current secret key, chain code, and an optional message.
  ///
  /// Parameters:
  /// - [chainCode]: A chain code used in the derivation.
  /// - [message] (optional): An optional byte array message used in the derivation. Default is an empty byte array.
  /// - [mode] (optional): The expansion mode for converting the mini-secret key. Default is [ExpansionMode.ed25519].
  ///
  (SchnorrkelSecretKey, List<int>) hardDerive(
    List<int> chainCode, {
    List<int>? message,
    ExpansionMode mode = ExpansionMode.ed25519,
  }) {
    final script = MerlinTranscript("SchnorrRistrettoHDKD");
    script.additionalData('sign-bytes'.codeUnits, message ?? List.empty());
    script.additionalData("chain-code".codeUnits, chainCode);
    script.additionalData("secret-key".codeUnits, key());
    final newSecret = script.toBytes("HDKD-hard".codeUnits, 32);
    final newChainCode = script.toBytes("HDKD-chaincode".codeUnits, 32);
    return (
      SchnorrkelMiniSecretKey.fromBytes(newSecret).toSecretKey(mode),
      newChainCode,
    );
  }

  /// Derives a new Schnorrkel secret key and chain code from the current secret key, chain code, and an optional message.
  ///
  /// Parameters:
  /// - [chainCode]: A chain code used in the derivation.
  /// - [message] (optional): An optional byte array message used in the derivation. Default is an empty byte array.
  /// - [nonceGenerator] (optional): A function that generates a nonce. Default is a function that generates a random 32-byte nonce.
  ///
  (SchnorrkelSecretKey, List<int>) softDerive(
    List<int> chainCode, {
    List<int>? message,
    GenerateRandom? nonceGenerator,
  }) {
    final derivePub = publicKey()._deriveScalarAndChainCode(chainCode, message);
    final nonce =
        nonceGenerator?.call(SchnorrkelKeyCost.nonceLength) ??
        QuickCrypto.generateRandom(SchnorrkelKeyCost.nonceLength);
    if (nonce.length != SchnorrkelKeyCost.nonceLength) {
      throw const CryptoException("invalid none length.");
    }
    final newKey = Ed25519Utils.add(key(), derivePub.$1);
    final combine = [...newKey, ...nonce];
    return (SchnorrkelSecretKey.fromBytes(combine), derivePub.$2);
  }

  /// Signs a message using the Schnorrkel secret key and a specified signing context script.
  ///
  /// Parameters:
  /// - [signingContextScript]: A transcript containing context-specific information for the signature.
  /// - [nonceGenerator] (optional): A function that generates a nonce. Default is a function that generates a random 64-byte nonce.
  ///
  SchnorrkelSignature sign(
    MerlinTranscript signingContextScript, {
    GenerateRandom? nonceGenerator,
  }) {
    const int nonceLength = SchnorrkelKeyCost.nonceLength * 2;
    signingContextScript.additionalData(
      "proto-name".codeUnits,
      "Schnorr-sig".codeUnits,
    );
    signingContextScript.additionalData(
      "sign:pk".codeUnits,
      publicKey().toBytes(),
    );
    final nonceRand =
        nonceGenerator?.call(nonceLength) ??
        QuickCrypto.generateRandom(nonceLength);
    if (nonceRand.length != nonceLength) {
      throw const CryptoException("invalid nonce bytes length.");
    }
    final scNonce = Ed25519Utils.scalarReduceConst(nonceRand);
    final mult = Ed25519Utils.scalarMultBase(scNonce);
    final r = RistrettoPoint.fromEdwardBytes(mult);
    signingContextScript.additionalData("sign:R".codeUnits, r.toBytes());
    final k = signingContextScript.toBytesWithReduceScalar(
      "sign:c".codeUnits,
      64,
    );
    final sigS = Ed25519Utils.mulAdd(key(), k, scNonce);
    final sig = SchnorrkelSignature._(sigS, r.toBytes());
    return sig;
  }

  /// Generates a Verifiable Random Function (VRF) output and its proof for a given transcript.
  ///
  /// Parameters:
  /// - [script]: A transcript containing context-specific information for VRF signing.
  ///
  (VRFInOut, VRFProof) vrfSign(
    MerlinTranscript script, {
    GenerateRandom? nonceGenerator,
    bool kusamaVRF = true,
    MerlinTranscript? verifyScript,
  }) {
    final vrf = vrfInOut(script);
    return (
      vrf,
      dleqProve(
        vrf,
        nonceGenerator: nonceGenerator,
        kusamaVRF: kusamaVRF,
        verifyScript: verifyScript,
      ),
    );
  }

  /// This function computes the VRF (Verifiable Random Function) input and output
  /// using the provided [MerlinTranscript] as the cryptographic context.
  ///
  VRFInOut vrfInOut(MerlinTranscript script) {
    final publicHashPoint = publicKey().vrfHash(script);
    final pM = Ed25519Utils.pointScalarMult(
      publicHashPoint.toEdwardBytes(),
      key(),
    );
    final p = RistrettoPoint.fromEdwardBytes(pM);
    return VRFInOut._(publicHashPoint.toBytes(), p.toBytes());
  }

  VRFInOut vrfInOut_(MerlinTranscript script) {
    final publicHashPoint = publicKey().vrfHash(script);
    final mul = Ed25519Utils.mul(
      Ed25519Utils.scalarReduceConst(key()),
      publicHashPoint.toBytes(),
    );
    final p = RistrettoPoint.fromEdwardBytes(mul);
    return VRFInOut._(publicHashPoint.toBytes(), p.toBytes());
  }

  /// Generates a Discrete Logarithm Equality Proof (DLEQ) for a Verifiable Random Function (VRF) output.
  ///
  /// Parameters:
  /// - [out]: A [VRFInOut] containing the VRF output to prove.
  /// - [kusamaVRF] (optional): A boolean indicating whether to include the public key in the DLEQ proof.
  ///   Default is [true] for Kusama VRF compatibility.
  /// - [nonceGenerator] (optional): A function that generates a nonce. Default is a function that generates a random 64-byte nonce.
  ///
  VRFProof dleqProve(
    VRFInOut out, {
    bool kusamaVRF = true,
    GenerateRandom? nonceGenerator,
    MerlinTranscript? verifyScript,
  }) {
    const int nonceLength = SchnorrkelKeyCost.nonceLength * 2;
    final script = verifyScript ?? MerlinTranscript("VRF");
    script.additionalData("proto-name".codeUnits, "DLEQProof".codeUnits);
    script.additionalData("vrf:h".codeUnits, out.input);
    if (!kusamaVRF) {
      script.additionalData("vrf:pk".codeUnits, publicKey().toBytes());
    }
    final nonce =
        nonceGenerator?.call(nonceLength) ??
        QuickCrypto.generateRandom(nonceLength);
    if (nonce.length != nonceLength) {
      throw const CryptoException("invalid nonce length.");
    }
    final nScalar = Ed25519Utils.scalarReduceConst(nonce);
    final mult = RistrettoPoint.fromEdwardBytes(
      Ed25519Utils.scalarMultBase(nScalar),
    );
    script.additionalData("vrf:R=g^r".codeUnits, mult.toBytes());
    RistrettoPoint inputPoint = RistrettoPoint.fromBytes(out.input);
    inputPoint = RistrettoPoint.fromEdwardBytes(
      Ed25519Utils.pointScalarMult(inputPoint.toEdwardBytes(), nScalar),
    );
    script.additionalData("vrf:h^r".codeUnits, inputPoint.toBytes());
    if (kusamaVRF) {
      script.additionalData("vrf:pk".codeUnits, publicKey().toBytes());
    }
    script.additionalData("vrf:h^sk".codeUnits, out.output);
    final c = script.toBytesWithReduceScalar(
      "prove".codeUnits,
      SchnorrkelKeyCost.vrfProofLength,
    );
    final multiply = Ed25519Utils.mulSub(c, key(), nScalar);
    return VRFProof._(c, multiply);
  }

  @override
  List<List<int>> get secretFields => [_key];
}

/// Represents a Schnorrkel public key used for verifying signatures.
class SchnorrkelPublicKey with Equality {
  /// Private constructor for creating a [SchnorrkelPublicKey] instance.
  SchnorrkelPublicKey._(List<int> publicKey)
    : _publicKey = publicKey.asImmutableBytes;

  /// Creates a [SchnorrkelPublicKey] from the given byte representation.
  ///
  /// Parameters:
  /// - [keyBytes]: A byte array representing the Schnorrkel public key.
  ///
  /// Returns:
  /// A [SchnorrkelPublicKey] instance created from the provided byte array.
  factory SchnorrkelPublicKey(List<int> keyBytes) {
    _KeyUtils._checkKeysBytes(
      keyBytes,
      SchnorrkelKeyCost.publickeyLength,
      "public key",
      "SchnorrkelPublicKey",
    );
    RistrettoPoint.fromBytes(keyBytes);
    return SchnorrkelPublicKey._(keyBytes);
  }
  final List<int> _publicKey;

  /// Converts the Schnorrkel public key to a byte representation.
  ///
  /// This method returns a byte array representing the Schnorrkel public key.
  ///
  List<int> toBytes() {
    return _publicKey.clone();
  }

  /// This method derives a scalar and chain code from the Schnorrkel public key, an optional message, and a provided chain code.
  ///
  /// Parameters:
  /// - [chainCode]: A chain code used in the derivation.
  /// - [message] (optional): An optional byte array message used in the derivation. Default is an empty byte array.
  ///
  (List<int>, List<int>) _deriveScalarAndChainCode(
    List<int> chainCode, [
    List<int>? message,
  ]) {
    final script = MerlinTranscript("SchnorrRistrettoHDKD");
    script.additionalData('sign-bytes'.codeUnits, message ?? List.empty());
    script.additionalData("chain-code".codeUnits, chainCode);
    script.additionalData("public-key".codeUnits, toBytes());
    final newKey = script.toBytesWithReduceScalar("HDKD-scalar".codeUnits, 64);
    final newChainCode = script.toBytes("HDKD-chaincode".codeUnits, 32);
    return (newKey, newChainCode);
  }

  /// Derives a new Schnorrkel public key and chain code using hierarchical deterministic key derivation (HDKD).
  ///
  /// Parameters:
  /// - [chainCode]: A chain code used in the derivation.
  /// - [message] (optional): An optional byte array message used in the derivation. Default is an empty byte array.
  ///
  (SchnorrkelPublicKey, List<int>) derive(
    List<int> chainCode, [
    List<int>? message,
  ]) {
    final derive = _deriveScalarAndChainCode(chainCode, message);
    final mult = Ed25519Utils.scalarMultBase(derive.$1);
    final pAdd = Ed25519Utils.pointAdd(toPoint().toEdwardBytes(), mult);
    final newPoint = RistrettoPoint.fromEdwardBytes(pAdd);
    return (SchnorrkelPublicKey(newPoint.toBytes()), derive.$2);
  }

  /// Converts the Schnorrkel public key to a RistrettoPoint point.
  RistrettoPoint toPoint() {
    return RistrettoPoint.fromBytes(toBytes());
  }

  /// Verifies a Schnorrkel signature using the public key and a transcript.
  ///
  /// Parameters:
  /// - [signature]: The Schnorrkel signature to be verified.
  /// - [signingContextScript]: A transcript containing context-specific information for signature verification.
  ///
  bool verify(
    SchnorrkelSignature signature,
    MerlinTranscript signingContextScript,
  ) {
    signingContextScript.additionalData(
      "proto-name".codeUnits,
      "Schnorr-sig".codeUnits,
    );
    signingContextScript.additionalData("sign:pk".codeUnits, toBytes());
    signingContextScript.additionalData("sign:R".codeUnits, signature.r);
    final kBigint = signingContextScript.toBigint("sign:c".codeUnits, 64);
    final r =
        ((-toPoint()) * kBigint) +
        (Curves.generatorED25519 * signature.sBigint);
    return BytesUtils.bytesEqual(r.toBytes(), signature.r);
  }

  /// Verifies a Verifiable Random Function (VRF) output and its proof.
  ///
  /// Parameters:
  /// - [script]: A transcript containing context-specific information used for VRF verification.
  /// - [output]: The VRF output to be verified.
  /// - [proof]: The proof associated with the VRF output.
  ///
  bool vrfVerify(
    MerlinTranscript script,
    VRFPreOut output,
    VRFProof proof, {
    MerlinTranscript? verifyScript,
  }) {
    final publicPointHash = vrfHash(script);
    final vrf = VRFInOut._(publicPointHash.toBytes(), output.toBytes());
    final vrifyScript = verifyScript ?? MerlinTranscript("VRF");
    return dleqVerify(vrifyScript, vrf, proof);
  }

  /// Verifies a Discrete Logarithm Equality (DLEQ) proof for a Verifiable Random Function (VRF) output.
  ///
  /// Parameters:
  /// - [script]: A transcript containing context-specific information used for DLEQ proof verification.
  /// - [out]: The VRF input and output pair to be verified.
  /// - [proof]: The DLEQ proof associated with the VRF output.
  /// - [isKusamaVRF] (optional): A boolean indicating whether it's a Kusama VRF. Default is true.
  ///
  bool dleqVerify(
    MerlinTranscript script,
    VRFInOut out,
    VRFProof proof, {
    bool isKusamaVRF = true,
  }) {
    script.additionalData("proto-name".codeUnits, "DLEQProof".codeUnits);
    script.additionalData("vrf:h".codeUnits, out.input);
    if (!isKusamaVRF) {
      script.additionalData("vrf:pk".codeUnits, toBytes());
    }
    final pr =
        (toPoint() * proof.cBigint) + (Curves.generatorED25519 * proof.sBigint);
    script.additionalData("vrf:R=g^r".codeUnits, pr.toBytes());
    final hr =
        (out.outputPoint * proof.cBigint) + (out.inputPoint * proof.sBigint);
    script.additionalData("vrf:h^r".codeUnits, hr.toBytes());
    if (isKusamaVRF) {
      script.additionalData("vrf:pk".codeUnits, toBytes());
    }
    script.additionalData("vrf:h^sk".codeUnits, out.output);
    final c = script.toBytesWithReduceScalar("prove".codeUnits, 64);
    return BytesUtils.bytesEqual(c, proof.c);
  }

  /// Computes a VRF (Verifiable Random Function) hash using a transcript.
  ///
  /// Parameters:
  /// - [script]: A transcript containing context-specific information for the VRF hash computation.
  RistrettoPoint vrfHash(MerlinTranscript script, {List<int>? keyBytes}) {
    script.additionalData("vrf-nm-pk".codeUnits, keyBytes ?? toBytes());
    final scBytes = script.toBytes("VRFHash".codeUnits, 64);
    final hashPoint = RistrettoPoint.fromUniform(scBytes);
    return hashPoint;
  }

  @override
  List<dynamic> get variables => [_publicKey];
}

/// Represents a Schnorrkel key pair, consisting of a secret key and a public key.
class SchnorrkelKeypair {
  SchnorrkelKeypair._(this._secretKey, this._publicKey);
  final List<int> _secretKey;
  final List<int> _publicKey;

  ///  Creates a key pair from raw bytes.
  factory SchnorrkelKeypair.fromBytes(List<int> bytes) {
    _KeyUtils._checkKeysBytes(
      bytes,
      SchnorrkelKeyCost.keypairLength,
      "keypair",
      "SchnorrkelKeypair",
    );
    final secret = SchnorrkelSecretKey.fromBytes(
      bytes.sublist(0, SchnorrkelKeyCost.secretKeyLength),
    );
    final public = SchnorrkelPublicKey(
      bytes.sublist(
        SchnorrkelKeyCost.secretKeyLength,
        SchnorrkelKeyCost.keypairLength,
      ),
    );
    return SchnorrkelKeypair._(
      List<int>.unmodifiable(secret.toBytes()),
      List<int>.unmodifiable(public.toBytes()),
    );
  }

  /// Creates a key pair from Ed25519 key bytes.
  factory SchnorrkelKeypair.fromEd25519(List<int> bytes) {
    _KeyUtils._checkKeysBytes(
      bytes,
      SchnorrkelKeyCost.keypairLength,
      "keypair",
      "SchnorrkelKeypair",
    );
    final secret = SchnorrkelSecretKey.fromEd25519(
      bytes.sublist(0, SchnorrkelKeyCost.secretKeyLength),
    );
    final public = SchnorrkelPublicKey(
      bytes.sublist(
        SchnorrkelKeyCost.secretKeyLength,
        SchnorrkelKeyCost.keypairLength,
      ),
    );
    return SchnorrkelKeypair._(secret.toBytes(), public.toBytes());
  }

  /// public key
  SchnorrkelPublicKey publicKey() {
    return SchnorrkelPublicKey(_publicKey);
  }

  /// secret key
  SchnorrkelSecretKey secretKey() {
    return SchnorrkelSecretKey.fromBytes(_secretKey);
  }
}

/// Represents a Schnorrkel digital signature.
class SchnorrkelSignature {
  /// Creates a signature from raw bytes.
  factory SchnorrkelSignature.fromBytes(List<int> signatureBytes) {
    _KeyUtils._checkKeysBytes(
      signatureBytes,
      SchnorrkelKeyCost.signatureLength,
      "signature",
      "SchnorrkelSignature",
    );
    final r = signatureBytes.sublist(0, 32);
    final s = signatureBytes.sublist(32, SchnorrkelKeyCost.signatureLength);
    if (s[31] & 128 == 0) {
      throw const CryptoException(
        "Signature not marked as schnorrkel, maybe try ed25519 instead.",
      );
    }
    final canonicalS = _KeyUtils.toCanonical(s);
    if (canonicalS != null) {
      return SchnorrkelSignature._(canonicalS, r);
    }
    throw const CryptoException("invalid schnorrkel signature");
  }

  /// private constructor
  SchnorrkelSignature._(List<int> s, List<int> r)
    : _s = s.asImmutableBytes,
      _r = r.asImmutableBytes;
  final List<int> _s;
  final List<int> _r;

  /// Converts the signature to raw bytes with a schnorrkel marker.
  List<int> toBytes() {
    final inBytes = [..._r, ..._s];
    inBytes[63] |= 128;
    return inBytes;
  }

  /// Returns the 'r' component of the signature.
  List<int> get r => _r.clone();

  /// Returns the 's' component of the signature.
  List<int> get s => _s.clone();

  /// Converts the 'r' component to a BigInt.
  BigInt get rBigint => BigintUtils.fromBytes(r, byteOrder: Endian.little);

  /// Converts the 's' component to a BigInt.
  BigInt get sBigint => BigintUtils.fromBytes(s, byteOrder: Endian.little);
}
