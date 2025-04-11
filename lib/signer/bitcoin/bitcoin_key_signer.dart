import 'package:blockchain_utils/bip/address/p2tr_addr.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/signer.dart';
import 'package:blockchain_utils/signer/types/types.dart';
import 'package:blockchain_utils/utils/utils.dart';

class BitcoinKeySigner {
  final ECDSASigningKey _signingKey;
  final BitcoinSignatureVerifier verifierKey;
  const BitcoinKeySigner._(this._signingKey, this.verifierKey);

  /// Factory constructor for creating a [BitcoinKeySigner] from private key bytes.
  factory BitcoinKeySigner.fromKeyBytes(List<int> privateKeyBytes) {
    if (!IPrivateKey.isValidBytes(
        privateKeyBytes, EllipticCurveTypes.secp256k1)) {
      throw CryptoSignException("Invalid secp256k1 private key.");
    }
    final privateKey = ECDSAPrivateKey.fromBytes(
        privateKeyBytes, BitcoinSignerUtils.generator);
    final verifyKey =
        BitcoinSignatureVerifier._(ECDSAVerifyKey(privateKey.publicKey));
    return BitcoinKeySigner._(ECDSASigningKey(privateKey), verifyKey);
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
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw CryptoSignException(
          "The digest must be a ${BitcoinSignerUtils.baselen}-byte array.");
    }
    if (aux != null && aux.length != 32) {
      throw CryptoSignException("The aux must be a 32-byte array.");
    }

    List<int> byteKey = <int>[];
    if (tapTweakHash != null) {
      byteKey = BitcoinSignerUtils.calculatePrivateTweek(
          _signingKey.privateKey.toBytes(), tapTweakHash);
    } else {
      byteKey = _signingKey.privateKey.toBytes();
    }
    aux ??= QuickCrypto.sha256Hash(<int>[...digest, ...byteKey]);
    final d0 = BigintUtils.fromBytes(byteKey);

    if (!(BigInt.one <= d0 && d0 <= BitcoinSignerUtils.order - BigInt.one)) {
      throw const CryptoSignException(
          "The secret key must be an integer in the range 1..n-1.");
    }
    final P = BitcoinSignerUtils.generator * d0;
    BigInt d = d0;
    if (P.y.isOdd) {
      d = BitcoinSignerUtils.order - d;
    }

    final t = BytesUtils.xor(
        BigintUtils.toBytes(d, length: BitcoinSignerUtils.baselen),
        P2TRUtils.taggedHash("BIP0340/aux", aux));

    final kHash = P2TRUtils.taggedHash(
      "BIP0340/nonce",
      <int>[
        ...t,
        ...BigintUtils.toBytes(P.x, length: BitcoinSignerUtils.baselen),
        ...digest
      ],
    );
    final k0 = BigintUtils.fromBytes(kHash) % BitcoinSignerUtils.order;

    if (k0 == BigInt.zero) {
      throw const CryptoSignException(
          'Failure. This happens only with negligible probability.');
    }
    final R = (BitcoinSignerUtils.generator * k0);
    BigInt k = k0;
    if (R.y.isOdd) {
      k = BitcoinSignerUtils.order - k;
    }

    final eHash = P2TRUtils.taggedHash(
      "BIP0340/challenge",
      List<int>.from([...R.toXonly(), ...P.toXonly(), ...digest]),
    );

    final e = BigintUtils.fromBytes(eHash) % BitcoinSignerUtils.order;

    final eKey = (k + e * d) % BitcoinSignerUtils.order;
    final signature = [
      ...R.toXonly(),
      ...BigintUtils.toBytes(eKey, length: BitcoinSignerUtils.baselen)
    ];
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
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw CryptoSignException(
          "The digest must be a ${BitcoinSignerUtils.baselen}-byte array.");
    }
    BigInt d = _signingKey.privateKey.secretMultiplier;
    final BigInt order = CryptoSignerConst.generatorSecp256k1.order!;

    if (!(BigInt.one <= d && d <= order - BigInt.one)) {
      throw const CryptoSignException(
          "The secret key must be an integer in the range 1..n-1.");
    }
    extraEntropy ??= CryptoSignerConst.bchSchnorrRfc6979ExtraData;
    BigInt k = RFC6979.generateK(
        order: order,
        secexp: _signingKey.privateKey.secretMultiplier,
        hashFunc: () => SHA256(),
        data: digest,
        extraEntropy: extraEntropy);
    final R = (CryptoSignerConst.generatorSecp256k1 * k);
    if (ECDSAUtils.jacobi(R.y, CryptoSignerConst.curveSecp256k1.p).isNegative) {
      k = order - k;
    }

    // Step 4: Compute e = SHA256(R || pubkey || digest)
    final eHash = QuickCrypto.sha256Hash([
      ...R.toXonly(),
      ...verifierKey._verifyKey.publicKey.toBytes(),
      ...digest
    ]);
    final BigInt e = BigintUtils.fromBytes(eHash) % order;

    // Step 5: Compute Schnorr Signature: s = k + e * d (mod n)
    final BigInt s = (k + e * d) % order;
    final signature = BitcoinSchnorrSignature(r: R.x, s: s).toBytes();

    final verify = verifierKey.verifySchnorrSignature(
        digest: digest, signature: signature);
    if (!verify) {
      throw const CryptoSignException(
          'The created signature does not pass verification.');
    }
    // Step 6: Return Signature (64 bytes: R.x || s)
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
  List<int> signMessage({
    required List<int> message,
    bool hashMessage = true,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
    List<int> extraEntropy = const [],
  }) {
    List<int> messgaeHash = message;
    if (hashMessage) {
      messgaeHash = QuickCrypto.sha256Hash(
          BitcoinSignerUtils.magicMessage(message, messagePrefix));
    }
    if (messgaeHash.length != BitcoinSignerUtils.baselen) {
      throw CryptoSignException(
          "The message must be a ${BitcoinSignerUtils.baselen}-byte array.");
    }

    final ECDSASignature ecdsaSign = _signingKey.signDigestDeterminstic(
        digest: messgaeHash,
        hashFunc: () => SHA256(),
        extraEntropy: extraEntropy);
    BigInt newS;
    if (ecdsaSign.s.compareTo(CryptoSignerConst.secp256k1OrderHalf) > 0) {
      newS = BitcoinSignerUtils.order - ecdsaSign.s;
    } else {
      newS = ecdsaSign.s;
    }
    final newSignature = ECDSASignature(ecdsaSign.r, newS);
    final recId = newSignature.recoverId(
        hash: messgaeHash, publicKey: verifierKey._verifyKey.publicKey);
    if (recId == null) {
      throw const CryptoSignException(
          'The created signature does not pass verification.');
    }
    return [27 + recId, ...newSignature.toBytes(BitcoinSignerUtils.baselen)];
  }

  /// Signs the given transaction digest using ECDSA (DER-encoded).
  ///
  /// - [digest]: The transaction digest (message) to sign.
  List<int> signECDSADer(List<int> digest,
      {List<int> extraEntropy = const []}) {
    ECDSASignature ecdsaSign = _signingKey.signDigestDeterminstic(
        digest: digest, hashFunc: () => SHA256(), extraEntropy: extraEntropy);
    List<int> signature =
        CryptoSignatureUtils.toDer([ecdsaSign.r, ecdsaSign.s]);
    BigInt attempt = BigInt.one;
    int lengthR = signature[3];
    while (lengthR == 33) {
      ecdsaSign = _signingKey.signDigestDeterminstic(
          digest: digest,
          hashFunc: () => SHA256(),
          extraEntropy: [
            ...extraEntropy,
            ...BigintUtils.toBytes(attempt, length: 32)
          ]);
      signature = CryptoSignatureUtils.toDer([ecdsaSign.r, ecdsaSign.s]);
      attempt += BigInt.one;
      lengthR = signature[3];
    }
    final int derPrefix = signature[0];
    int lengthTotal = signature[1];
    final int derTypeInt = signature[2];
    final List<int> R = signature.sublist(4, 4 + lengthR);
    int lengthS = signature[5 + lengthR];
    final List<int> S = signature.sublist(5 + lengthR + 1);
    BigInt sAsBigint = BigintUtils.fromBytes(S);
    List<int> newS;
    if (lengthS == 33) {
      sAsBigint = BitcoinSignerUtils.order - sAsBigint;
      newS = BigintUtils.toBytes(sAsBigint, length: BitcoinSignerUtils.baselen);
      lengthS -= 1;
      lengthTotal -= 1;
    } else {
      newS = S;
    }
    return [
      derPrefix,
      lengthTotal,
      derTypeInt,
      lengthR,
      ...R,
      derTypeInt,
      lengthS,
      ...newS
    ];
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
