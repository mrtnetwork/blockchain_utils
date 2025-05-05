import 'package:blockchain_utils/bip/address/p2tr_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/signer.dart';
import 'package:blockchain_utils/signer/types/types.dart';
import 'package:blockchain_utils/utils/utils.dart';

class BitcoinKeySigner {
  final Secp256k1SigningKey _signingKey;
  Secp256k1SigningKey get signingKey => _signingKey;
  final BitcoinSignatureVerifier verifierKey;
  const BitcoinKeySigner._(this._signingKey, this.verifierKey);

  /// Factory constructor for creating a [BitcoinKeySigner] from private key bytes.
  factory BitcoinKeySigner.fromKeyBytes(List<int> privateKeyBytes) {
    final privateKey = Secp256k1SigningKey.fromBytes(keyBytes: privateKeyBytes);
    final verifyKey = BitcoinSignatureVerifier._(
        ECDSAVerifyKey(privateKey.privateKey.publicKey));
    return BitcoinKeySigner._(
        Secp256k1SigningKey.fromBytes(keyBytes: privateKeyBytes), verifyKey);
  }

  /// Signs a given digest using the BIP-340 (Schnorr) signature scheme.
  ///
  /// This method follows the BIP-340 specification for creating Schnorr
  /// signatures. It ensures that the provided digest has the correct length
  /// and applies private key tweaking if a `tapTweakHash` is provided.
  ///
  /// - [digest]: The 32-byte message digest to be signed. It must be exactly
  ///   `BitcoinSignerUtils.baselen` bytes in length.
  /// - [tapTweakHash]: (Optional) A tweak applied to the private key for
  ///   Taproot-related signatures.
  /// - [aux]: (Optional) Auxiliary random data used to add entropy to the
  ///   signature for security against side-channel attacks.
  List<int> signBip340(
      {required List<int> digest, List<int>? tapTweakHash, List<int>? aux}) {
    final signature = _signingKey.signBip340(
        digest: digest, aux: aux, tapTweakHash: tapTweakHash);
    if (verifierKey.verifyBip340Signature(
        digest: digest, signature: signature, tapTweakHash: tapTweakHash)) {
      return signature;
    }
    throw const CryptoSignException(
        'The created signature does not pass verification.');
  }

  List<int> signBip340Const(
      {required List<int> digest, List<int>? tapTweakHash, List<int>? aux}) {
    final signature = _signingKey.signBip340Const(
        digest: digest, aux: aux, tapTweakHash: tapTweakHash);
    if (verifierKey.verifyBip340Signature(
        digest: digest, signature: signature, tapTweakHash: tapTweakHash)) {
      return signature;
    }
    throw const CryptoSignException(
        'The created signature does not pass verification.');
  }

  /// Signs the given transaction digest using Schnorr signature (old style).
  ///
  /// This method is primarily useful for networks like Bitcoin Cash (BCH) that
  /// support Schnorr signatures in a legacy format.
  ///
  /// - [digest]: The transaction digest (message) to sign.
  List<int> signSchnorr(List<int> digest, {List<int>? extraEntropy}) {
    final signature =
        _signingKey.signSchnorr(digest, extraEntropy: extraEntropy);

    final verify = verifierKey.verifySchnorrSignature(
        digest: digest, signature: signature);
    if (!verify) {
      throw const CryptoSignException(
          'The created signature does not pass verification.');
    }
    return signature;
  }

  List<int> signSchnorrConst(List<int> digest,
      {List<int>? extraEntropy, Secp256k1ECmultGenContext? context}) {
    final signature = _signingKey.signSchnorrConst(
        digest: digest,
        extraEntropy:
            extraEntropy ?? CryptoSignerConst.bchSchnorrRfc6979ExtraData);
    final verify = verifierKey.verifySchnorrSignature(
        digest: digest, signature: signature);
    if (!verify) {
      throw const CryptoSignException(
          'The created signature does not pass verification.');
    }
    return signature;
  }

  /// Signs a message using Bitcoin's message signing format.
  ///
  /// This method produces a compact ECDSA signature for a given message, following
  /// the Bitcoin Signed Message standard.
  ///
  /// - [message]: The raw message to be signed.
  /// - [messagePrefix]: The prefix used for Bitcoin's message signing.
  /// - [extraEntropy]: Optional extra entropy to modify the signature.
  List<int> signMessage(
      {required List<int> message,
      bool hashMessage = true,
      String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
      List<int> extraEntropy = const []}) {
    List<int> messgaeHash = message;
    if (hashMessage) {
      messgaeHash = QuickCrypto.sha256Hash(
          BitcoinSignerUtils.magicMessage(message, messagePrefix));
    }
    final signature =
        _signingKey.sign(digest: messgaeHash, extraEntropy: extraEntropy);
    return [
      signature.item2 + 27,
      ...signature.item1.toBytes(BitcoinSignerUtils.baselen)
    ];
  }

  List<int> signMessageConst(
      {required List<int> message,
      bool hashMessage = true,
      String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
      List<int> extraEntropy = const [],
      Secp256k1ECmultGenContext? context}) {
    List<int> messgaeHash = message;
    if (hashMessage) {
      messgaeHash = QuickCrypto.sha256Hash(
          BitcoinSignerUtils.magicMessage(message, messagePrefix));
    }
    final signature =
        _signingKey.signConst(digest: messgaeHash, extraEntropy: extraEntropy);
    return [
      signature.item2 + 27,
      ...signature.item1.toBytes(BitcoinSignerUtils.baselen)
    ];
  }

  /// Signs the given transaction digest using ECDSA (DER-encoded).
  ///
  /// - [digest]: The transaction digest (message) to sign.
  List<int> signECDSADer(List<int> digest, {List<int>? extraEntropy}) {
    List<int> signature =
        _signingKey.signDer(digest: digest, extraEntropy: extraEntropy);
    BigInt attempt = BigInt.one;
    int lengthR = signature[3];
    while (lengthR == 33) {
      signature = _signingKey.signDer(digest: digest, extraEntropy: [
        ...extraEntropy ?? [],
        ...BigintUtils.toBytes(attempt, length: 32)
      ]);
      attempt += BigInt.one;
      lengthR = signature[3];
    }
    return signature;
  }

  List<int> signECDSADerConst(List<int> digest, {List<int>? extraEntropy}) {
    List<int> signature =
        _signingKey.signConstDer(digest: digest, extraEntropy: extraEntropy);
    BigInt attempt = BigInt.one;
    int lengthR = signature[3];
    while (lengthR == 33) {
      signature = _signingKey.signConstDer(digest: digest, extraEntropy: [
        ...extraEntropy ?? [],
        ...BigintUtils.toBytes(attempt, length: 32)
      ]);
      attempt += BigInt.one;
      lengthR = signature[3];
    }
    return signature;
  }
}

class BitcoinSignatureVerifier {
  /// The ECDSA verification key associated with this Bitcoin verifier.
  final ECDSAVerifyKey _verifyKey;
  const BitcoinSignatureVerifier._(this._verifyKey);

  factory BitcoinSignatureVerifier.fromKeyBytes(List<int> publicKey) {
    final point = ProjectiveECCPoint.fromBytes(
        curve: CryptoSignerConst.curveSecp256k1, data: publicKey, order: null);
    final pub = ECDSAPublicKey(CryptoSignerConst.generatorSecp256k1, point);
    return BitcoinSignatureVerifier._(ECDSAVerifyKey(pub));
  }

  /// Verifies a BIP-340 Schnorr signature using an x-only public key.
  ///
  /// This method checks whether the given Schnorr signature is valid for the
  /// provided message digest and x-only public key. It optionally applies a
  /// tweak if `tapTweakHash` is provided.
  ///
  /// - [xOnly]: A 32-byte x-only public key (corresponding to the Taproot key).
  /// - [digest]: A 32-byte message digest that was signed.
  /// - [signature]: A 64-byte Schnorr signature (`R.x || s`).
  /// - [tapTweakHash] (optional): A 32-byte tweak hash used to modify the public key.
  static bool verifyBip340SignatureUsingXOnly(
      {required List<int> xOnly,
      required List<int> digest,
      required List<int> signature,
      List<int>? tapTweakHash}) {
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw CryptoSignException(
          "The digest must be a ${BitcoinSignerUtils.baselen}-byte array.");
    }
    if (xOnly.length != EcdsaKeysConst.pointCoordByteLen) {
      throw CryptoSignException("Invalid xOnly bytes length.");
    }

    final schnorrSignature = BitcoinSchnorrSignature.fromBytes(signature);
    final x = BigintUtils.fromBytes(xOnly);
    final P = tapTweakHash != null
        ? tweakKey(xBig: x, tapTweakHash: tapTweakHash)
        : P2TRUtils.liftX(x);
    final ProjectiveECCPoint generator = BitcoinSignerUtils.generator;
    final BigInt prime = BitcoinSignerUtils.generator.curve.p;

    if (schnorrSignature.r >= prime ||
        schnorrSignature.s >= BitcoinSignerUtils.order) {
      return false;
    }
    final eHash = P2TRUtils.taggedHash(
      "BIP0340/challenge",
      List<int>.from([...schnorrSignature.rBytes(), ...P.toXonly(), ...digest]),
    );
    BigInt e = BigintUtils.fromBytes(eHash) % BitcoinSignerUtils.order;
    final sp = generator * schnorrSignature.s;

    if (P.y.isEven) {
      e = BitcoinSignerUtils.order - e;
    }
    final ProjectiveECCPoint eP = P * e;

    final R = sp + eP;

    if (R.y.isOdd || R.x != schnorrSignature.r) {
      return false;
    }

    return true;
  }

  /// Verifies a BIP-340 Schnorr signature using a public key.
  ///
  /// This method checks whether the given Schnorr signature is valid for the
  /// provided message digest and x-only public key. It optionally applies a
  /// tweak if `tapTweakHash` is provided.
  ///
  /// - [digest]: A 32-byte message digest that was signed.
  /// - [signature]: A 64-byte Schnorr signature (`R.x || s`).
  /// - [tapTweakHash] (optional): A 32-byte tweak hash used to modify the public key.
  bool verifyBip340Signature(
      {required List<int> digest,
      required List<int> signature,
      List<int>? tapTweakHash}) {
    return verifyBip340SignatureUsingXOnly(
        xOnly: _verifyKey.publicKey.point.toXonly(),
        digest: digest,
        signature: signature,
        tapTweakHash: tapTweakHash);
  }

  /// Verifies a Schnorr(old style) signature for a given digest.
  ///
  /// This method checks whether the provided Schnorr signature is valid for
  /// the given digest using the public key.
  ///
  /// - [digest]: The hash or message digest that was signed.
  /// - [signature]: The Schnorr signature to verify.
  ///
  /// Returns `true` if the signature is valid for the given digest, otherwise `false`.
  bool verifySchnorrSignature(
      {required List<int> digest, required List<int> signature}) {
    final schnorrSignature = BitcoinSchnorrSignature.fromBytes(signature);
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw CryptoSignException(
          "The digest must be a ${BitcoinSignerUtils.baselen}-byte array.");
    }

    final P = _verifyKey.publicKey.point;
    final eHash = QuickCrypto.sha256Hash([
      ...schnorrSignature.rBytes(),
      ..._verifyKey.publicKey.toBytes(),
      ...digest
    ]);
    final e = BigintUtils.fromBytes(eHash) % CryptoSignerConst.secp256k1Order;
    final sG = CryptoSignerConst.generatorSecp256k1 * schnorrSignature.s;
    final ProjectiveECCPoint eP = -(P * e);
    final R = sG + eP;
    if (R.isInfinity ||
        ECDSAUtils.jacobi(R.y, CryptoSignerConst.curveSecp256k1.p) <= 0) {
      return false;
    }
    return R.x == schnorrSignature.r;
  }

  /// Recovers the ECDSA public key from a Bitcoin signed message.
  ///
  /// This method extracts the public key from a 65-byte compact ECDSA signature,
  /// which includes a recovery ID in the first byte. It is used to verify
  /// Bitcoin-signed messages (BIP-137).
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: A 65-byte Bitcoin signature (including the recovery ID).
  /// - [messagePrefix] (optional): A custom prefix for the signed message
  ///   (default is Bitcoin's standard prefix).
  ///
  static ECDSAPublicKey recoverPublicKey(
      {required List<int> message,
      required List<int> signature,
      String messagePrefix = BitcoinSignerUtils.signMessagePrefix}) {
    if (signature.length != 65) {
      throw const CryptoSignException(
          "bitcoin signature must be 65 bytes with recover-id");
    }
    final List<int> messgaeHash = QuickCrypto.sha256Hash(
        BitcoinSignerUtils.magicMessage(message, messagePrefix));
    int header = signature[0];
    signature = signature.sublist(1);
    final ecdsaSignature =
        ECDSASignature.fromBytes(signature, BitcoinSignerUtils.generator);

    if (header < 27 || header > 42) {
      throw CryptoSignException("Header byte out of range");
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
    return ecdsaSignature.recoverPublicKey(
        messgaeHash, BitcoinSignerUtils.generator, header);
  }

  /// Verifies a Bitcoin-signed message signature.
  ///
  /// This method checks if a given ECDSA signature is valid for the provided message.
  /// It supports both 64-byte and 65-byte signatures, where the latter includes a
  /// recovery ID for public key reconstruction.
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: The ECDSA signature (64 or 65 bytes).
  /// - [messagePrefix] (optional): A custom prefix for the signed message
  ///   (default is Bitcoin's standard prefix).
  ///
  bool verifyMessageSignature(
      {required List<int> message,
      required List<int> signature,
      String messagePrefix = BitcoinSignerUtils.signMessagePrefix}) {
    if (signature.length != 64 && signature.length != 65) {
      throw const CryptoSignException(
          "bitcoin signature must be 64 bytes without recover-id or 65 bytes with recover-id");
    }
    final List<int> messgaeHash = QuickCrypto.sha256Hash(
        BitcoinSignerUtils.magicMessage(message, messagePrefix));
    int? header;
    if (signature.length == 65) {
      header = signature[0] & 0xFF;
      signature = signature.sublist(1);
    }
    final ecdsaSignature =
        ECDSASignature.fromBytes(signature, BitcoinSignerUtils.generator);
    if (header == null) {
      return _verifyKey.verify(ecdsaSignature, messgaeHash);
    }
    if (header < 27 || header > 42) {
      throw CryptoSignException("Header byte out of range");
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
    final pubKey = ecdsaSignature.recoverPublicKey(
        messgaeHash, _verifyKey.publicKey.generator, header);
    return pubKey == _verifyKey.publicKey;
  }

  /// Verifies an ECDSA DER-encoded signature against a given digest.
  ///
  /// This method checks whether the provided DER-encoded signature is valid for
  /// the given digest using the public key.
  ///
  /// - [digest]: The hash or message digest that was signed.
  /// - [signature]: The DER-encoded ECDSA signature to verify.
  ///
  /// Returns `true` if the signature is valid for the given digest, otherwise `false`.
  bool verifyECDSADerSignature(
      {required List<int> digest, required List<int> signature}) {
    final secp256k1Signature = Secp256k1EcdsaSignature.fromDer(signature);
    final ecdsaSignature =
        ECDSASignature(secp256k1Signature.r, secp256k1Signature.s);
    return _verifyKey.verify(ecdsaSignature, digest);
  }

  /// Tweaks a public key for Taproot (BIP-341).
  ///
  /// This function performs a Taproot key tweak operation, modifying the given
  /// x-only public key coordinate using a tweak value derived from `tapTweakHash`.
  ///
  /// - [xBig]: The x-coordinate of the public key as a `BigInt`.
  /// - [tapTweakHash]: A 32-byte tweak hash used to modify the key.
  static ProjectiveECCPoint tweakKey(
      {required BigInt xBig, required List<int> tapTweakHash}) {
    if (tapTweakHash.length != 32) {
      throw const CryptoSignException(
          "The tap tweak hash must be 32-byte array.");
    }
    final n =
        BitcoinSignerUtils.generator * BigintUtils.fromBytes(tapTweakHash);
    final outPoint = P2TRUtils.liftX(xBig) + n;
    return outPoint as ProjectiveECCPoint;
  }

  ProjectiveECCPoint publicKeyPoint() {
    return _verifyKey.publicKey.point;
  }
}
