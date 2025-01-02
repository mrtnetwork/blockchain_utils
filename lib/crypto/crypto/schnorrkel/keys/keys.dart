import 'dart:typed_data';
import 'package:blockchain_utils/utils/utils.dart';

import 'package:blockchain_utils/crypto/crypto/cdsa/utils/ed25519_utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ristretto_point.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/prng/fortuna.dart';
import 'package:blockchain_utils/crypto/crypto/schnorrkel/merlin/transcript.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// The `SchnorrkelKeyCost` class defines various constants related to the sizes and lengths of Schnorrkel keys and components.
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
  /// - `bytes`: The list of bytes to check.
  /// - `expected`: The expected length of the bytes.
  /// - `name`: A descriptive name for the byte data, used in error messages.
  static void _checkKeysBytes(List<int> bytes, int expected, String name) {
    if (bytes.length != expected) {
      throw ArgumentException(
          "invalid $name bytes length expected $expected but ${bytes.length}");
    }
  }

  /// Divides a scalar value represented by a byte array by the cofactor of the curve.
  ///
  /// Parameters:
  /// - `s`: A byte array representing the scalar value.
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
  /// - `scalar`: A byte array representing the scalar value.
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
  /// In Ed25519, canonical values must have their highest bit unset and should be the result of scalar reduction.
  ///
  /// Parameters:
  /// - `bytes`: A byte array to be checked for canonical representation.
  ///
  /// Returns:
  /// A boolean indicating whether the byte array is a canonical representation in Ed25519 cryptography.
  ///
  /// This method checks if the highest bit of the last byte is unset (bitwise AND with 127) and if the byte array
  /// is equal to the result of scalar reduction. If both conditions are met, the value is considered canonical.
  static List<int>? toCanonical(List<int> bytes) {
    final cloneBytes = List<int>.from(bytes);
    cloneBytes[31] &= 127;
    final bool highBitUnset = (bytes[31] >> 7 & 0) == 0;
    final bool isCanonical = BytesUtils.bytesEqual(
        cloneBytes, Ed25519Utils.scalarReduce(cloneBytes));
    if (highBitUnset && isCanonical) {
      return cloneBytes;
    }
    return null;
  }
}

/// The `ExpansionMode` enum defines different expansion modes used in Schnorr signatures (Schnorrkel).
///
/// Schnorr signatures are a cryptographic signature scheme, and the choice of expansion mode can impact key generation and signing.
///
/// - `uniform`: A mode for generating keys and signatures with uniform randomness.
/// - `ed25519`: A mode that follows the Ed25519 specification for key generation and signing.
enum ExpansionMode {
  uniform,
  ed25519,
}

class VRFPreOut {
  VRFPreOut._({required List<int> output})
      : _output = BytesUtils.toBytes(output, unmodifiable: true);
  factory VRFPreOut(List<int> bytes) {
    if (bytes.length != SchnorrkelKeyCost.vrfPreOutLength) {
      throw ArgumentException(
          "Invalid VRFPreOut bytes length. excepted: ${SchnorrkelKeyCost.vrfPreOutLength} got: ${bytes.length}");
    }
    return VRFPreOut._(output: bytes);
  }
  final List<int> _output;
  List<int> toBytes() {
    return List<int>.from(_output);
  }
}

/// The `VRFInOut` class represents the input and output data of a Verifiable Random Function (VRF) computation.
///
/// VRF is a cryptographic construction used to generate a verifiable proof of a random value.
///
/// Members:
/// - `_input`: A `List<int>` containing the input data for the VRF computation.
/// - `_output`: A `List<int>` containing the output data of the VRF computation.
///
/// This class provides methods and properties to access and manipulate the input and output data.
class VRFInOut {
  /// Private constructor to create a `VRFInOut` instance with input and output data.
  VRFInOut._(this._input, this._output);
  final List<int> _input;
  final List<int> _output;

  /// Gets a copy of the input data as a `List<int>`.
  List<int> get input => List<int>.from(_input);

  /// Gets a copy of the output data as a `List<int>`.
  List<int> get output => List<int>.from(_output);

  /// Converts the output data into a RistrettoPoint point.
  RistrettoPoint get outputPoint => RistrettoPoint.fromBytes(output);

  /// Converts the input data into a RistrettoPoint point.
  RistrettoPoint get inputPoint => RistrettoPoint.fromBytes(input);

  /// Converts the `VRFInOut` instance into a `List<int>` by concatenating the input and output data.
  List<int> toBytes() {
    return List<int>.from([..._input, ..._output]);
  }

  VRFPreOut toVRFPreOut() => VRFPreOut(output);
}

/// The `VRFProof` class represents a Verifiable Random Function (VRF) proof, consisting of two components 'c' and 's'.
///
/// VRF is a cryptographic construction used to generate a verifiable proof of a random value.
///
/// Members:
/// - `_c`: A `List<int>` containing the 'c' component of the VRF proof.
/// - `_s`: A `List<int>` containing the 's' component of the VRF proof.
///
/// This class provides methods and properties to access and manipulate the components of the VRF proof.
class VRFProof {
  /// Private constructor to create a `VRFProof` instance with 'c' and 's' components.
  VRFProof._(this._c, this._s);

  /// Creates a `VRFProof` instance from a byte representation.
  /// The input bytes are expected to be properly formatted for a VRF proof.
  factory VRFProof.fromBytes(List<int> bytes) {
    _KeyUtils._checkKeysBytes(
        bytes, SchnorrkelKeyCost.vrfProofLength, "VRF proof");
    final c = _KeyUtils.toCanonical(bytes.sublist(0, 32));
    final s = _KeyUtils.toCanonical(bytes.sublist(32));
    if (c == null || s == null) {
      throw const ArgumentException("invalid VRF proof bytes");
    }
    return VRFProof._(c, s);
  }
  final List<int> _c;
  final List<int> _s;

  /// Gets a copy of the 'c' component as a `List<int>`.
  List<int> get c => List<int>.from(_c);

  /// Gets a copy of the 's' component as a `List<int>`.
  List<int> get s => List<int>.from(_s);

  /// Converts the 'c' component into a `BigInt`.
  BigInt get cBigint => BigintUtils.fromBytes(c, byteOrder: Endian.little);

  /// Converts the 's' component into a `BigInt`.
  BigInt get sBigint => BigintUtils.fromBytes(s, byteOrder: Endian.little);

  /// Converts the `VRFProof` instance into a `List<int>` by concatenating the 'c' and 's' components.
  List<int> toBytes() {
    return List<int>.from([..._c, ..._s]);
  }
}

/// The `SchnorrkelMiniSecretKey` class represents a mini-secret key used for generating Schnorr key pairs.
///
/// In the Schnorrkel signature scheme, a mini-secret key is used to generate Schnorr key pairs,
/// which consist of a public key and a corresponding secret key.
///
/// Members:
/// - `_bytes`: A `List<int>` containing the bytes of the mini-secret key.
///
/// This class provides methods for creating, converting, and validating mini-secret keys used in
/// the generation of Schnorr key pairs.
class SchnorrkelMiniSecretKey {
  /// Private constructor to create a `SchnorrkelMiniSecretKey` instance with bytes.
  SchnorrkelMiniSecretKey._(this._bytes);
  final List<int> _bytes;

  /// Converts the mini-secret key to a `List<int>`.
  List<int> toBytes() => List<int>.from(_bytes);

  /// Creates a `SchnorrkelMiniSecretKey` instance from a byte representation.
  /// The input bytes are expected to have the correct length for a mini-secret key.
  ///
  /// Parameters:
  /// - `keyBytes`: A byte array representing the mini-secret key.
  ///
  /// Returns:
  /// A `SchnorrkelMiniSecretKey` instance.
  factory SchnorrkelMiniSecretKey.fromBytes(List<int> keyBytes) {
    final bytes = BytesUtils.toBytes(keyBytes, unmodifiable: true);
    _KeyUtils._checkKeysBytes(
        keyBytes, SchnorrkelKeyCost.miniSecretLength, "mini secret key");
    return SchnorrkelMiniSecretKey._(bytes);
  }

  /// The `_expandEd25519` method expands the mini-secret key into a Schnorrkel secret key
  /// following the Ed25519 method for expansion.
  ///
  /// In Ed25519 expansion, the mini-secret key is hashed using SHA-512, and the result is
  /// then manipulated to create a Schnorrkel secret key.
  ///
  /// Returns:
  /// A `SchnorrkelSecretKey` instance derived from the mini-secret key expansion.
  SchnorrkelSecretKey _expandEd25519() {
    final toHash = SHA512.hash(toBytes());
    final key = toHash.sublist(0, 32);
    key[0] &= 248;
    key[31] &= 63;
    key[31] |= 64;
    final r = _KeyUtils.divideScalarByCofactor(key);
    return SchnorrkelSecretKey(r, toHash.sublist(32));
  }

  /// The `_expandUniform` method expands the mini-secret key into a Schnorrkel secret key
  /// following a uniform expansion method.
  ///
  /// In uniform expansion, a cryptographic transcript is used to create the Schnorrkel secret key.
  /// The transcript incorporates the mini-secret key to ensure uniform randomness.
  ///
  /// Returns:
  /// A `SchnorrkelSecretKey` instance derived from the mini-secret key expansion using uniform expansion.
  SchnorrkelSecretKey _expandUniform() {
    final script = MerlinTranscript("ExpandSecretKeys");
    script.additionalData("mini".codeUnits, toBytes());

    final key = script.toBytesWithReduceScalar("sk".codeUnits, 64);

    final nonce = script.toBytes("no".codeUnits, 32);
    return SchnorrkelSecretKey(key.sublist(0, 32), nonce.sublist(0, 32));
  }

  /// Converts the `SchnorrkelSecretKey` into a full secret key using a specified expansion mode.
  ///
  /// The expansion mode determines how the mini-secret key is expanded into a Schnorrkel secret key.
  ///
  /// Parameters:
  /// - `mode` (optional): The expansion mode for converting the mini-secret key. Default is `ExpansionMode.ed25519`.
  ///
  /// Returns:
  /// A `SchnorrkelSecretKey` instance representing the full secret key.
  ///
  /// Example Usage:
  /// ```dart
  /// SchnorrkelSecretKey miniSecretKey = ...;
  /// SchnorrkelSecretKey secretKey = miniSecretKey.toSecretKey(ExpansionMode.ed25519);
  /// ```
  ///
  /// The `toSecretKey` method allows the conversion of a mini-secret key into a full Schnorrkel secret key using
  /// the specified expansion mode, which can be either `ExpansionMode.ed25519` or `ExpansionMode.uniform`.
  /// Depending on the mode chosen, a different expansion method is applied.
  SchnorrkelSecretKey toSecretKey(
      [ExpansionMode mode = ExpansionMode.ed25519]) {
    if (mode == ExpansionMode.ed25519) {
      return _expandEd25519();
    }
    return _expandUniform();
  }
}

/// The `SchnorrkelSecretKey` class represents a Schnorrkel secret key used for cryptographic operations.
///
/// A Schnorrkel secret key consists of two components: a secret key and a nonce.
///
/// Members:
/// - `_key`: A `List<int>` containing the secret key component.
/// - `_nonce`: A `List<int>` containing the nonce component.
///
/// This class provides a constructor for creating Schnorrkel secret keys, validating the input components,
/// and ensuring the canonical form of the key.
class SchnorrkelSecretKey {
  /// Private constructor to create a `SchnorrkelSecretKey` instance with secret key and nonce components.
  SchnorrkelSecretKey._(this._key, this._nonce);

  /// Creates a `SchnorrkelSecretKey` instance from provided secret key and nonce components.
  ///
  /// Parameters:
  /// - `key`: A byte array representing the secret key.
  /// - `nonce`: A byte array representing the nonce.
  ///
  /// Returns:
  /// A `SchnorrkelSecretKey` instance if the input components are valid and in canonical form.
  ///
  /// Throws:
  /// - An `ArgumentException` if the input components are invalid or not in canonical form.
  factory SchnorrkelSecretKey(List<int> key, List<int> nonce) {
    _KeyUtils._checkKeysBytes(
        key, SchnorrkelKeyCost.miniSecretLength, "mini secret key");
    _KeyUtils._checkKeysBytes(nonce, SchnorrkelKeyCost.nonceLength, "nonce");
    final canonicalKey = _KeyUtils.toCanonical(key);
    if (canonicalKey != null) {
      return SchnorrkelSecretKey._(
          BytesUtils.toBytes(canonicalKey, unmodifiable: true),
          BytesUtils.toBytes(nonce, unmodifiable: true));
    }
    throw const ArgumentException("invalid key");
  }

  /// Creates a `SchnorrkelSecretKey` instance from a byte representation of a secret key.
  ///
  /// Parameters:
  /// - `secretKeyBytes`: A byte array representing the secret key.
  ///
  /// Returns:
  /// A `SchnorrkelSecretKey` instance derived from the provided byte representation.
  ///
  /// Throws:
  /// - An `ArgumentException` if the byte array does not have the correct length for a secret key.
  factory SchnorrkelSecretKey.fromBytes(List<int> secretKeyBytes) {
    _KeyUtils._checkKeysBytes(
        secretKeyBytes, SchnorrkelKeyCost.secretKeyLength, "secret key");
    final keyBytes =
        secretKeyBytes.sublist(0, SchnorrkelKeyCost.miniSecretLength);
    final nonceBytes = secretKeyBytes.sublist(
        SchnorrkelKeyCost.miniSecretLength, SchnorrkelKeyCost.secretKeyLength);
    return SchnorrkelSecretKey(BytesUtils.toBytes(keyBytes, unmodifiable: true),
        BytesUtils.toBytes(nonceBytes, unmodifiable: true));
  }

  /// Creates a `SchnorrkelSecretKey` instance from a byte representation of an Ed25519 secret key.
  ///
  /// Parameters:
  /// - `secretKeyBytes`: A byte array representing an Ed25519 secret key.
  ///
  /// Returns:
  /// A `SchnorrkelSecretKey` instance derived from the provided Ed25519 secret key representation.
  ///
  /// Throws:
  /// - An `ArgumentException` if the byte array does not have the correct length for a secret key.
  factory SchnorrkelSecretKey.fromEd25519(List<int> secretKeyBytes) {
    _KeyUtils._checkKeysBytes(
        secretKeyBytes, SchnorrkelKeyCost.secretKeyLength, "secret key");
    final newKey = List<int>.from(
        secretKeyBytes.sublist(0, SchnorrkelKeyCost.miniSecretLength));
    _KeyUtils.divideScalarByCofactor(newKey);
    return SchnorrkelSecretKey(
        BytesUtils.toBytes(newKey, unmodifiable: true),
        BytesUtils.toBytes(
            secretKeyBytes.sublist(SchnorrkelKeyCost.miniSecretLength,
                SchnorrkelKeyCost.secretKeyLength),
            unmodifiable: true));
  }
  final List<int> _key;
  final List<int> _nonce;

  /// The `toBytes` method converts the Schnorrkel secret key into a byte representation.
  ///
  /// Returns:
  /// A `List<int>` containing the byte representation of the Schnorrkel secret key, including both the secret key
  /// and the nonce components.
  List<int> toBytes() {
    return List<int>.from([..._key, ..._nonce]);
  }

  /// The `key` method returns the secret key component of the Schnorrkel secret key.
  ///
  /// Returns:
  /// A `List<int>` containing the secret key component.
  List<int> key() => List<int>.from(_key);

  /// The `nonce` method returns the nonce component of the Schnorrkel secret key.
  ///
  /// Returns:
  /// A `List<int>` containing the nonce component.
  List<int> nonce() => List<int>.from(_nonce);

  /// The `publicKey` method derives the corresponding public key from the Schnorrkel secret key.
  ///
  /// This method follows the process of computing the public key by first converting the secret key to a big integer,
  /// performing scalar multiplication with the Ed25519 generator point, and converting the resulting point
  /// to a RistrettoPoint format. Finally, the public key is returned as a `SchnorrkelPublicKey` instance.
  ///
  /// Returns:
  /// A `SchnorrkelPublicKey` representing the derived public key associated with this Schnorrkel secret key.
  SchnorrkelPublicKey publicKey() {
    /// Convert the secret key to a big integer in little-endian byte order.
    final tobig = BigintUtils.fromBytes(key(), byteOrder: Endian.little);

    /// Perform scalar multiplication with the Ed25519 generator point.
    final gn = Curves.generatorED25519 * tobig;

    /// Convert the result to a RistrettoPoint format.
    final pubPoint = RistrettoPoint.fromEdwardsPoint(gn);

    /// Convert the RistrettoPoint point to bytes and create a Schnorrkel public key.
    final pubBytes = pubPoint.toBytes();
    return SchnorrkelPublicKey(pubBytes);
  }

  /// The `toEd25519Bytes` method converts the Schnorrkel secret key into a byte representation
  /// following the Ed25519 format, suitable for use in Ed25519 operations.
  ///
  /// This method modifies the secret key by multiplying it by the cofactor and then combines it with the nonce
  /// to create a byte array in the Ed25519 format.
  ///
  /// Returns:
  /// A `List<int>` containing the byte representation of the Schnorrkel secret key in Ed25519 format.
  ///
  /// This byte representation is suitable for compatibility with Ed25519 operations.
  List<int> toEd25519Bytes() {
    final k = key();

    /// Multiply the secret key by the cofactor.
    _KeyUtils.multiplyScalarBytesByCofactor(k);
    return List<int>.from([...k, ...nonce()]);
  }

  /// Derives a new Schnorrkel secret key and chain code from the current secret key, chain code, and an optional message.
  ///
  /// This method performs a hard derivation following the Schnorrkel RistrettoPoint Hierarchical Deterministic Key Derivation (HDKD) scheme.
  ///
  /// Parameters:
  /// - `chainCode`: A chain code used in the derivation.
  /// - `message` (optional): An optional byte array message used in the derivation. Default is an empty byte array.
  /// - `mode` (optional): The expansion mode for converting the mini-secret key. Default is `ExpansionMode.ed25519`.
  ///
  /// Returns:
  /// A tuple containing a new Schnorrkel secret key and a new chain code, derived from the current secret key, chain code, and message.
  ///
  /// Example Usage:
  /// ```dart
  /// List<int> chainCode = ...;
  /// SchnorrkelSecretKey currentSecretKey = ...;
  /// List<int> message = ...;
  /// var (newSecretKey, newChainCode) = currentSecretKey.hardDerive(chainCode, message);
  /// ```
  ///
  /// The `hardDerive` method follows the Schnorrkel RistrettoPoint HDKD scheme to derive a new Schnorrkel secret key and chain code.
  /// It combines the current secret key, chain code, and an optional message to compute the new secret key and chain code.
  /// The `mode` parameter allows specifying the expansion mode for converting the mini-secret key.
  Tuple<SchnorrkelSecretKey, List<int>> hardDerive(List<int> chainCode,
      {List<int>? message, ExpansionMode mode = ExpansionMode.ed25519}) {
    final script = MerlinTranscript("SchnorrRistrettoHDKD");
    script.additionalData('sign-bytes'.codeUnits, message ?? List.empty());
    script.additionalData("chain-code".codeUnits, chainCode);
    script.additionalData("secret-key".codeUnits, key());
    final newSecret = script.toBytes("HDKD-hard".codeUnits, 32);
    final newChainCode = script.toBytes("HDKD-chaincode".codeUnits, 32);
    return Tuple(SchnorrkelMiniSecretKey.fromBytes(newSecret).toSecretKey(mode),
        newChainCode);
  }

  /// Derives a new Schnorrkel secret key and chain code from the current secret key, chain code, and an optional message.
  ///
  /// This method performs a soft derivation following the Schnorrkel RistrettoPoint Hierarchical Deterministic Key Derivation (HDKD) scheme.
  ///
  /// Parameters:
  /// - `chainCode`: A chain code used in the derivation.
  /// - `message` (optional): An optional byte array message used in the derivation. Default is an empty byte array.
  /// - `nonceGenerator` (optional): A function that generates a nonce. Default is a function that generates a random 32-byte nonce.
  ///
  /// Returns:
  /// A tuple containing a new Schnorrkel secret key and a new chain code, derived from the current secret key, chain code, and message.
  ///
  /// Example Usage:
  /// ```dart
  /// List<int> chainCode = ...;
  /// SchnorrkelSecretKey currentSecretKey = ...;
  /// List<int> message = ...;
  /// GenerateRandom? customNonceGenerator = (length) => ...;
  /// var (newSecretKey, newChainCode) = currentSecretKey.softDerive(chainCode, message, customNonceGenerator);
  /// ```
  ///
  /// The `softDerive` method follows the Schnorrkel RistrettoPoint HDKD scheme to derive a new Schnorrkel secret key and chain code.
  /// It combines the current secret key, chain code, and an optional message to compute the new secret key and chain code.
  /// The `nonceGenerator` parameter allows specifying a custom function to generate a nonce.
  Tuple<SchnorrkelSecretKey, List<int>> softDerive(List<int> chainCode,
      {List<int>? message, GenerateRandom? nonceGenerator}) {
    final derivePub = publicKey()._deriveScalarAndChainCode(chainCode, message);
    final nonce = nonceGenerator?.call(32) ?? QuickCrypto.generateRandom(32);
    if (nonce.length != 32) {
      throw const ArgumentException("invalid random bytes length");
    }
    final newKey = Ed25519Utils.add(key(), derivePub.item1);
    final combine = List<int>.from([...newKey, ...nonce]);
    return Tuple(SchnorrkelSecretKey.fromBytes(combine), derivePub.item2);
  }

  /// Signs a message using the Schnorrkel secret key and a specified signing context script.
  ///
  /// This method generates a Schnorrkel signature for a given message by appending context-specific information
  /// to the signing context script and combining it with a nonce.
  ///
  /// Parameters:
  /// - `signingContextScript`: A transcript containing context-specific information for the signature.
  /// - `nonceGenerator` (optional): A function that generates a nonce. Default is a function that generates a random 64-byte nonce.
  ///
  /// Returns:
  /// A `SchnorrkelSignature` representing the generated signature.
  ///
  /// Example Usage:
  /// ```dart
  /// MerlinTranscript signingContextScript = ...;
  /// SchnorrkelSecretKey secretKey = ...;
  /// GenerateRandom? customNonceGenerator = (length) => ...;
  /// SchnorrkelSignature signature = secretKey.sign(signingContextScript, customNonceGenerator);
  /// ```
  ///
  /// The `sign` method generates a Schnorrkel signature for a message by incorporating context-specific information
  /// from the signing context script, a nonce, and the secret key. It returns a `SchnorrkelSignature` instance.
  SchnorrkelSignature sign(MerlinTranscript signingContextScript,
      {GenerateRandom? nonceGenerator}) {
    signingContextScript.additionalData(
        "proto-name".codeUnits, "Schnorr-sig".codeUnits);
    signingContextScript.additionalData(
        "sign:pk".codeUnits, publicKey().toBytes());
    final nonceRand =
        nonceGenerator?.call(64) ?? QuickCrypto.generateRandom(64);
    if (nonceRand.length != 64) {
      throw const ArgumentException("invalid random bytes length");
    }
    final nonceBytes = Ed25519Utils.scalarReduce(nonceRand);
    final nonceBigint =
        BigintUtils.fromBytes(nonceBytes, byteOrder: Endian.little);
    final r =
        RistrettoPoint.fromEdwardsPoint(Curves.generatorED25519 * nonceBigint);
    signingContextScript.additionalData("sign:R".codeUnits, r.toBytes());
    final k =
        signingContextScript.toBytesWithReduceScalar("sign:c".codeUnits, 64);
    final km = Ed25519Utils.mul(key(), k);
    final s = Ed25519Utils.add(km, nonceBytes);
    final sig = SchnorrkelSignature._(s, r.toBytes());
    return sig;
  }

  /// Generates a Verifiable Random Function (VRF) output and its proof for a given transcript.
  ///
  /// This method generates a VRF output and its corresponding proof for a provided transcript by performing
  /// VRF computations using the secret key and the transcript's context-specific information.
  ///
  /// Parameters:
  /// - `script`: A transcript containing context-specific information for VRF signing.
  ///
  /// Returns:
  /// A tuple containing a `VRFInOut` representing the VRF output and a `VRFProof` as its proof.
  ///
  /// Example Usage:
  /// ```dart
  /// MerlinTranscript script = ...;
  /// SchnorrkelSecretKey secretKey = ...;
  /// var (vrfOutput, vrfProof) = secretKey.vrfSign(script);
  /// ```
  ///
  /// The `vrfSign` method generates a VRF output and its proof for a given transcript using the secret key and context-specific information.
  /// It returns a tuple with the VRF output and its proof.
  Tuple<VRFInOut, VRFProof> vrfSign(MerlinTranscript script,
      {GenerateRandom? nonceGenerator,
      bool kusamaVRF = true,
      MerlinTranscript? verifyScript}) {
    final publicHashPoint = publicKey().vrfHash(script);
    final keyBig = BigintUtils.fromBytes(key(), byteOrder: Endian.little);
    final mul = publicHashPoint * keyBig;
    final vrf = VRFInOut._(publicHashPoint.toBytes(), mul.toBytes());
    return Tuple(
        vrf,
        dleqProve(vrf,
            nonceGenerator: nonceGenerator,
            kusamaVRF: kusamaVRF,
            verifyScript: verifyScript));
  }

  /// Generates a Discrete Logarithm Equality Proof (DLEQ) for a Verifiable Random Function (VRF) output.
  ///
  /// This method generates a DLEQ proof for a given VRF output, ensuring the equality of discrete logarithms of
  /// specific points in the VRF computation.
  ///
  /// Parameters:
  /// - `out`: A `VRFInOut` containing the VRF output to prove.
  /// - `kusamaVRF` (optional): A boolean indicating whether to include the public key in the DLEQ proof.
  ///   Default is `true` for Kusama VRF compatibility.
  /// - `nonceGenerator` (optional): A function that generates a nonce. Default is a function that generates a random 64-byte nonce.
  ///
  /// Returns:
  /// A `VRFProof` representing the DLEQ proof.
  ///
  /// Example Usage:
  /// ```dart
  /// VRFInOut vrfOutput = ...;
  /// SchnorrkelSecretKey secretKey = ...;
  /// var dleqProof = secretKey.dleqProve(vrfOutput);
  /// ```
  ///
  /// The `dleqProve` method generates a DLEQ proof for a VRF output, ensuring the equality of discrete logarithms between
  /// specific points in the VRF computation. It returns a `VRFProof` instance.
  VRFProof dleqProve(VRFInOut out,
      {bool kusamaVRF = true,
      GenerateRandom? nonceGenerator,
      MerlinTranscript? verifyScript}) {
    final script = verifyScript ?? MerlinTranscript("VRF");
    script.additionalData("proto-name".codeUnits, "DLEQProof".codeUnits);
    script.additionalData("vrf:h".codeUnits, out.input);
    if (!kusamaVRF) {
      script.additionalData("vrf:pk".codeUnits, publicKey().toBytes());
    }
    final nonce = nonceGenerator?.call(64) ?? QuickCrypto.generateRandom(64);
    if (nonce.length != 64) {
      throw const ArgumentException("invalid random bytes length");
    }
    final n = Ed25519Utils.scalarReduce(nonce);
    final scalar = BigintUtils.fromBytes(n, byteOrder: Endian.little);
    final mult =
        RistrettoPoint.fromEdwardsPoint(Curves.generatorED25519 * scalar);
    script.additionalData("vrf:R=g^r".codeUnits, mult.toBytes());
    final inputPoint = RistrettoPoint.fromBytes(out.input);
    final hr = inputPoint * scalar;
    script.additionalData("vrf:h^r".codeUnits, hr.toBytes());
    if (kusamaVRF) {
      script.additionalData("vrf:pk".codeUnits, publicKey().toBytes());
    }
    script.additionalData("vrf:h^sk".codeUnits, out.output);
    final c = script.toBytesWithReduceScalar("prove".codeUnits, 64);
    final multiply = Ed25519Utils.mul(c, key());
    final s = Ed25519Utils.sub(n, multiply);

    return VRFProof._(c, s);
  }

  @override
  operator ==(other) {
    if (other is! SchnorrkelSecretKey) return false;
    return BytesUtils.bytesEqual(_key, other._key);
  }

  @override
  int get hashCode => _key.fold<int>(0, (c, p) => p ^ c).hashCode;
}

/// Represents a Schnorrkel public key used for verifying signatures.
///
/// A Schnorrkel public key is a cryptographic key used for signature verification. This class encapsulates the
/// functionality to create and work with Schnorrkel public keys.
///
/// Usage:
/// ```dart
/// // Create a Schnorrkel public key from bytes.
/// List<int> publicKeyBytes = ...;
/// SchnorrkelPublicKey publicKey = SchnorrkelPublicKey(publicKeyBytes);
/// ```
///
/// The `SchnorrkelPublicKey` class allows you to create a Schnorrkel public key from bytes and provides methods for
/// key validation.
class SchnorrkelPublicKey {
  /// Private constructor for creating a `SchnorrkelPublicKey` instance.
  SchnorrkelPublicKey._(this._publicKey);

  /// Creates a `SchnorrkelPublicKey` from the given byte representation.
  ///
  /// Parameters:
  /// - `keyBytes`: A byte array representing the Schnorrkel public key.
  ///
  /// Returns:
  /// A `SchnorrkelPublicKey` instance created from the provided byte array.
  factory SchnorrkelPublicKey(List<int> keyBytes) {
    _KeyUtils._checkKeysBytes(
        keyBytes, SchnorrkelKeyCost.publickeyLength, "public key");
    RistrettoPoint.fromBytes(keyBytes);
    return SchnorrkelPublicKey._(
        BytesUtils.toBytes(keyBytes, unmodifiable: true));
  }
  final List<int> _publicKey;

  /// Converts the Schnorrkel public key to a byte representation.
  ///
  /// This method returns a byte array representing the Schnorrkel public key.
  ///
  /// Returns:
  /// A `List<int>` containing the byte representation of the Schnorrkel public key.
  ///
  /// Example Usage:
  /// ```dart
  /// SchnorrkelPublicKey publicKey = ...;
  /// List<int> publicKeyBytes = publicKey.toBytes();
  /// ```
  List<int> toBytes() {
    return List<int>.from(_publicKey);
  }

  /// This method derives a scalar and chain code from the Schnorrkel public key, an optional message, and a provided chain code.
  /// It is used in hierarchical deterministic key derivation scenarios.
  ///
  /// Parameters:
  /// - `chainCode`: A chain code used in the derivation.
  /// - `message` (optional): An optional byte array message used in the derivation. Default is an empty byte array.
  ///
  /// Returns:
  /// A tuple containing the derived scalar and chain code.
  ///
  /// Example Usage:
  /// ```dart
  /// SchnorrkelPublicKey publicKey = ...;
  /// List<int> chainCode = ...;
  /// List<int> message = ...;
  /// var (scalar, derivedChainCode) = publicKey._deriveScalarAndChainCode(chainCode, message);
  /// ```
  ///
  /// The `_deriveScalarAndChainCode` method is used for hierarchical deterministic key derivation (HDKD)
  /// and returns a tuple with the derived scalar and chain code.
  Tuple<List<int>, List<int>> _deriveScalarAndChainCode(List<int> chainCode,
      [List<int>? message]) {
    final script = MerlinTranscript("SchnorrRistrettoHDKD");
    script.additionalData('sign-bytes'.codeUnits, message ?? List.empty());
    script.additionalData("chain-code".codeUnits, chainCode);
    script.additionalData("public-key".codeUnits, toBytes());
    final newKey = script.toBytesWithReduceScalar("HDKD-scalar".codeUnits, 64);
    final newChainCode = script.toBytes("HDKD-chaincode".codeUnits, 32);
    return Tuple(newKey, newChainCode);
  }

  /// Derives a new Schnorrkel public key and chain code using hierarchical deterministic key derivation (HDKD).
  ///
  /// This method derives a new Schnorrkel public key and chain code from the current public key, an optional message,
  /// and a provided chain code. It is used for hierarchical deterministic key derivation scenarios.
  ///
  /// Parameters:
  /// - `chainCode`: A chain code used in the derivation.
  /// - `message` (optional): An optional byte array message used in the derivation. Default is an empty byte array.
  ///
  /// Returns:
  /// A tuple containing the derived Schnorrkel public key and chain code.
  ///
  /// Example Usage:
  /// ```dart
  /// SchnorrkelPublicKey currentPublicKey = ...;
  /// List<int> chainCode = ...;
  /// List<int> message = ...;
  /// var (derivedPublicKey, derivedChainCode) = currentPublicKey.derive(chainCode, message);
  /// ```
  ///
  /// The `derive` method is used for hierarchical deterministic key derivation (HDKD)
  /// and returns a tuple with the derived Schnorrkel public key and chain code.
  Tuple<SchnorrkelPublicKey, List<int>> derive(List<int> chainCode,
      [List<int>? message]) {
    final derive = _deriveScalarAndChainCode(chainCode, message);
    final newKeyBigint =
        BigintUtils.fromBytes(derive.item1, byteOrder: Endian.little);
    final p = toPoint() + (Curves.generatorED25519 * newKeyBigint);
    return Tuple(SchnorrkelPublicKey(p.toBytes()), derive.item2);
  }

  /// Converts the Schnorrkel public key to a RistrettoPoint point.
  ///
  /// This method converts the Schnorrkel public key to a RistrettoPoint point, allowing further cryptographic operations.
  ///
  /// Returns:
  /// A `RistrettoPoint` point representation of the Schnorrkel public key.
  ///
  /// Example Usage:
  /// ```dart
  /// SchnorrkelPublicKey publicKey = ...;
  /// RistrettoPoint ristrettoPoint = publicKey.toPoint();
  /// ```
  ///
  /// The `toPoint` method is used to convert a Schnorrkel public key to a RistrettoPoint point for cryptographic operations
  RistrettoPoint toPoint() {
    return RistrettoPoint.fromBytes(toBytes());
  }

  /// Verifies a Schnorrkel signature using the public key and a transcript.
  ///
  /// This method verifies a Schnorrkel signature by appending context-specific information from the signing context
  /// script and performing the necessary cryptographic operations. It checks the validity of the provided signature.
  ///
  /// Parameters:
  /// - `signature`: The Schnorrkel signature to be verified.
  /// - `signingContextScript`: A transcript containing context-specific information for signature verification.
  ///
  /// Returns:
  /// A boolean indicating whether the signature is valid (true) or not (false).
  ///
  /// Example Usage:
  /// ```dart
  /// SchnorrkelPublicKey publicKey = ...;
  /// SchnorrkelSignature signature = ...;
  /// MerlinTranscript signingContextScript = ...;
  /// bool isSignatureValid = publicKey.verify(signature, signingContextScript);
  /// ```
  ///
  /// The `verify` method is used to verify a Schnorrkel signature using the public key and context-specific information.
  /// It returns `true` if the signature is valid, and `false` otherwise
  bool verify(
      SchnorrkelSignature signature, MerlinTranscript signingContextScript) {
    signingContextScript.additionalData(
        "proto-name".codeUnits, "Schnorr-sig".codeUnits);
    signingContextScript.additionalData("sign:pk".codeUnits, toBytes());
    signingContextScript.additionalData("sign:R".codeUnits, signature.r);
    final kBigint = signingContextScript.toBigint("sign:c".codeUnits, 64);
    final r = ((-toPoint()) * kBigint) +
        (Curves.generatorED25519 * signature.sBigint);
    return BytesUtils.bytesEqual(r.toBytes(), signature.r);
  }

  /// Verifies a Verifiable Random Function (VRF) output and its proof.
  ///
  /// This method verifies the validity of a VRF output and its corresponding proof by comparing it to a transcript and the provided proof.
  ///
  /// Parameters:
  /// - `script`: A transcript containing context-specific information used for VRF verification.
  /// - `output`: The VRF output to be verified.
  /// - `proof`: The proof associated with the VRF output.
  ///
  /// Returns:
  /// A boolean indicating whether the VRF output and its proof are valid (true) or not (false).
  ///
  /// Example Usage:
  /// ```dart
  /// MerlinTranscript script = ...;
  /// List<int> vrfOutput = ...;
  /// VRFProof proof = ...;
  /// bool isVRFValid = vrfVerify(script, vrfOutput, proof);
  /// ```
  ///
  /// The `vrfVerify` method is used to verify the validity of a Verifiable Random Function (VRF) output and its proof
  /// by comparing it to a transcript and the provided proof. It returns `true` if the output and proof are valid,
  /// and `false` otherwise.
  bool vrfVerify(MerlinTranscript script, VRFPreOut output, VRFProof proof,
      {MerlinTranscript? verifyScript}) {
    final publicPointHash = vrfHash(script);
    final vrf = VRFInOut._(publicPointHash.toBytes(), output.toBytes());
    final vrifyScript = verifyScript ?? MerlinTranscript("VRF");
    return dleqVerify(vrifyScript, vrf, proof);
  }

  /// Verifies a Discrete Logarithm Equality (DLEQ) proof for a Verifiable Random Function (VRF) output.
  ///
  /// This method verifies the validity of a DLEQ proof for a VRF output by comparing it to a transcript and the provided proof.
  ///
  /// Parameters:
  /// - `script`: A transcript containing context-specific information used for DLEQ proof verification.
  /// - `out`: The VRF input and output pair to be verified.
  /// - `proof`: The DLEQ proof associated with the VRF output.
  /// - `isKusamaVRF` (optional): A boolean indicating whether it's a Kusama VRF. Default is true.
  ///
  /// Returns:
  /// A boolean indicating whether the DLEQ proof for the VRF output is valid (true) or not (false).
  ///
  /// Example Usage:
  /// ```dart
  /// MerlinTranscript script = ...;
  /// VRFInOut vrfInOut = ...;
  /// VRFProof proof = ...;
  /// bool isDLEQProofValid = dleqVerify(script, vrfInOut, proof);
  /// ```
  ///
  /// The `dleqVerify` method is used to verify the validity of a Discrete Logarithm Equality (DLEQ)
  /// proof for a Verifiable Random Function (VRF) output by comparing it to a transcript and the provided proof.
  /// It returns `true` if the DLEQ proof is valid, and `false` otherwise.
  bool dleqVerify(MerlinTranscript script, VRFInOut out, VRFProof proof,
      {bool isKusamaVRF = true}) {
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
  /// This method computes a VRF hash by appending a Schnorrkel public key to the provided transcript, extracting 64 bytes, and converting it into a RistrettoPoint point.
  ///
  /// Parameters:
  /// - `script`: A transcript containing context-specific information for the VRF hash computation.
  ///
  /// Returns:
  /// A RistrettoPoint point representing the VRF hash.
  ///
  /// Example Usage:
  /// ```dart
  /// MerlinTranscript script = ...;
  /// SchnorrkelPublicKey publicKey = ...;
  /// RistrettoPoint vrfHashPoint = publicKey.vrfHash(script);
  /// ```
  ///
  /// The `vrfHash` method is used to compute a VRF hash by appending the public key to a transcript
  /// and extracting the resulting hash as a RistrettoPoint point.
  RistrettoPoint vrfHash(MerlinTranscript script) {
    script.additionalData("vrf-nm-pk".codeUnits, toBytes());
    final hashPoint =
        RistrettoPoint.fromUniform(script.toBytes("VRFHash".codeUnits, 64));
    return hashPoint;
  }

  static RistrettoPoint vrfHash2(MerlinTranscript script, List<int> keyBytes) {
    script.additionalData("vrf-nm-pk".codeUnits, keyBytes);
    final hashPoint =
        RistrettoPoint.fromUniform(script.toBytes("VRFHash".codeUnits, 64));
    return hashPoint;
  }

  @override
  operator ==(other) {
    if (other is! SchnorrkelPublicKey) return false;
    return BytesUtils.bytesEqual(_publicKey, other._publicKey);
  }

  @override
  int get hashCode => _publicKey.fold<int>(0, (c, p) => p ^ c).hashCode;
}

/// Represents a Schnorrkel key pair, consisting of a secret key and a public key.
///
/// A Schnorrkel key pair is used for various cryptographic operations, including signing and verification.
///
/// Constructors:
/// - `SchnorrkelKeypair.fromBytes(List<int> bytes)`: Creates a key pair from raw bytes.
/// - `SchnorrkelKeypair.fromEd25519(List<int> bytes)`: Creates a key pair from Ed25519 key bytes.
///
/// Example Usage:
/// ```dart
/// List<int> keyPairBytes = ...;
/// SchnorrkelKeypair keyPair = SchnorrkelKeypair.fromBytes(keyPairBytes);
/// SchnorrkelPublicKey publicKey = keyPair.publicKey();
/// SchnorrkelSecretKey secretKey = keyPair.secretKey();
/// ```
///
/// The `SchnorrkelKeypair` class represents a key pair used for Schnorrkel cryptographic operations.
/// It includes methods for obtaining the public and secret keys.
class SchnorrkelKeypair {
  SchnorrkelKeypair._(this._secretKey, this._publicKey);
  final List<int> _secretKey;
  final List<int> _publicKey;

  ///  Creates a key pair from raw bytes.
  factory SchnorrkelKeypair.fromBytes(List<int> bytes) {
    _KeyUtils._checkKeysBytes(
        bytes, SchnorrkelKeyCost.keypairLength, "keypair");
    final secret = SchnorrkelSecretKey.fromBytes(
        bytes.sublist(0, SchnorrkelKeyCost.secretKeyLength));
    final public = SchnorrkelPublicKey(bytes.sublist(
        SchnorrkelKeyCost.secretKeyLength, SchnorrkelKeyCost.keypairLength));
    return SchnorrkelKeypair._(List<int>.unmodifiable(secret.toBytes()),
        List<int>.unmodifiable(public.toBytes()));
  }

  /// Creates a key pair from Ed25519 key bytes.
  factory SchnorrkelKeypair.fromEd25519(List<int> bytes) {
    _KeyUtils._checkKeysBytes(
        bytes, SchnorrkelKeyCost.keypairLength, "keypair");
    final secret = SchnorrkelSecretKey.fromEd25519(
        bytes.sublist(0, SchnorrkelKeyCost.secretKeyLength));
    final public = SchnorrkelPublicKey(bytes.sublist(
        SchnorrkelKeyCost.secretKeyLength, SchnorrkelKeyCost.keypairLength));
    return SchnorrkelKeypair._(secret.toBytes(), public.toBytes());
  }

  /// public key
  SchnorrkelPublicKey publicKey() {
    return SchnorrkelPublicKey(List<int>.from(_publicKey));
  }

  /// secret key
  SchnorrkelSecretKey secretKey() {
    return SchnorrkelSecretKey.fromBytes(List<int>.from(_secretKey));
  }
}

/// Represents a Schnorrkel digital signature.
///
/// A Schnorrkel digital signature is used to verify the authenticity and integrity of data in various cryptographic applications.
///
/// Constructors:
/// - `SchnorrkelSignature.fromBytes(List<int> signatureBytes)`: Creates a signature from raw bytes.
///
/// Example Usage:
/// ```dart
/// List<int> signatureBytes = ...;
/// SchnorrkelSignature signature = SchnorrkelSignature.fromBytes(signatureBytes);
/// ```
///
/// The `SchnorrkelSignature` class represents a Schnorrkel digital signature and provides a constructor for creating a signature from raw bytes.

class SchnorrkelSignature {
  /// Creates a signature from raw bytes.
  factory SchnorrkelSignature.fromBytes(List<int> signatureBytes) {
    _KeyUtils._checkKeysBytes(
        signatureBytes, SchnorrkelKeyCost.signatureLength, "signature");
    final r = signatureBytes.sublist(0, 32);
    final s = signatureBytes.sublist(32, SchnorrkelKeyCost.signatureLength);
    if (s[31] & 128 == 0) {
      throw const ArgumentException(
          "Signature not marked as schnorrkel, maybe try ed25519 instead.");
    }
    final canonicalS = _KeyUtils.toCanonical(s);
    if (canonicalS != null) {
      return SchnorrkelSignature._(
          BytesUtils.toBytes(canonicalS, unmodifiable: true),
          BytesUtils.toBytes(r, unmodifiable: true));
    }
    throw const ArgumentException("invalid schnorrkel signature");
  }

  /// private constructor
  SchnorrkelSignature._(this._s, this._r);
  final List<int> _s;
  final List<int> _r;

  /// Converts the signature to raw bytes with a schnorrkel marker.
  List<int> toBytes() {
    final inBytes = List<int>.from([..._r, ..._s]);
    inBytes[63] |= 128;
    return inBytes;
  }

  /// Returns the 'r' component of the signature.
  List<int> get r => List<int>.from(_r);

  /// Returns the 's' component of the signature.
  List<int> get s => List<int>.from(_s);

  /// Converts the 'r' component to a BigInt.
  BigInt get rBigint => BigintUtils.fromBytes(r, byteOrder: Endian.little);

  /// Converts the 's' component to a BigInt.
  BigInt get sBigint => BigintUtils.fromBytes(s, byteOrder: Endian.little);
}
