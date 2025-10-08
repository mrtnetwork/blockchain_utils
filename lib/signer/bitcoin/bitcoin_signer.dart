import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/signer/utils/utils.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/address/p2tr_addr.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/private_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/public_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/signature.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';

/// The [BitcoinSignerUtils] class provides utility methods related to Bitcoin signing operations.

class BitcoinSignerUtils {
  static const String signMessagePrefix = '\x18Bitcoin Signed Message:\n';

  /// The projective ECC (Elliptic Curve Cryptography) point generator for the Secp256k1 curve.
  static ProjectiveECCPoint get generator => Curves.generatorSecp256k1;

  /// The order of the generator point on the Secp256k1 curve.
  static BigInt get order => generator.order!;

  /// The base length of the curve associated with the generator.
  static int get baselen => generator.curve.baselen;

  /// Calculates a private tweak for a given secret and tweak value.
  ///
  /// The tweak is applied to the negation of the secret key, and the result is adjusted based on
  /// the parity of the corresponding public key.
  static List<int> calculatePrivateTweek(
      List<int> secret, List<int> tapTweakHash) {
    if (tapTweakHash.length != 32) {
      throw const CryptoSignException(
          "The tap tweak hash must be 32-byte array.");
    }
    final tweakBig = BigintUtils.fromBytes(tapTweakHash);
    BigInt negatedKey = BigintUtils.fromBytes(secret);
    final publicBytes =
        (generator * negatedKey).toBytes(EncodeType.uncompressed);
    final yBig = BigintUtils.fromBytes(
        publicBytes.sublist(EcdsaKeysConst.pubKeyCompressedByteLen));
    if (yBig.isOdd) {
      negatedKey = order - negatedKey;
    }
    final tw = (negatedKey + tweakBig) % order;
    return BigintUtils.toBytes(tw, length: baselen);
  }

  /// Adds a magic prefix to a message for Bitcoin signing.
  ///
  /// The magic prefix includes the message prefix and the length of the message.
  static List<int> _magicPrefix(List<int> message, List<int> messagePrefix) {
    final encodeLength = IntUtils.encodeVarint(message.length);

    return [...messagePrefix, ...encodeLength, ...message];
  }

  /// Applies the magic prefix and calculates the SHA-256 hash of the message for Bitcoin signing.
  ///
  /// The message prefix is expected to start with the safe Bitcoin message prefix (0x18).
  static List<int> magicMessage(List<int> message, String messagePrefix) {
    final prefixBytes = StringUtils.encode(messagePrefix);
    final magic = _magicPrefix(message, prefixBytes);
    return QuickCrypto.sha256Hash(magic);
  }
}

/// The [BitcoinSigner] class encapsulates functionality for signing Bitcoin messages, transactions,
/// and Schnorr-based transactions using ECDSA (Elliptic Curve Digital Signature Algorithm) and
/// related cryptographic operations.
@Deprecated(
    "Use BitcoinKeySigner instead. This will be removed in future versions.")
class BitcoinSigner {
  /// The ECDSA signing key associated with this Bitcoin signer.
  final ECDSASigningKey signingKey;

  /// Constructs a [BitcoinSigner] instance with the given ECDSA signing key.
  BitcoinSigner._(this.signingKey);

  /// Factory constructor for creating a [BitcoinSigner] from private key bytes.
  factory BitcoinSigner.fromKeyBytes(List<int> privateKeyBytes) {
    final privateKey = ECDSAPrivateKey.fromBytes(
        privateKeyBytes, BitcoinSignerUtils.generator);
    return BitcoinSigner._(ECDSASigningKey(privateKey));
  }

  /// Signs a given message using the ECDSA deterministic signature scheme.
  /// The message is first hashed and then signed using the private key.
  List<int> signMessage(List<int> message, String messagePrefix) {
    final messgaeHash = QuickCrypto.sha256Hash(
        BitcoinSignerUtils.magicMessage(message, messagePrefix));
    final ECDSASignature ecdsaSign = signingKey.signDigestDeterminstic(
        digest: messgaeHash, hashFunc: () => SHA256());
    final n = BitcoinSignerUtils.order >> 1;
    BigInt newS;
    if (ecdsaSign.s.compareTo(n) > 0) {
      newS = BitcoinSignerUtils.order - ecdsaSign.s;
    } else {
      newS = ecdsaSign.s;
    }
    final newSignature = ECDSASignature(ecdsaSign.r, newS);
    final verify = verifyKey.verifyMessage(message, messagePrefix,
        newSignature.toBytes(BitcoinSignerUtils.baselen));
    if (!verify) {
      throw const CryptoSignException(
          'The created signature does not pass verification.');
    }
    return newSignature.toBytes(BitcoinSignerUtils.baselen);
  }

  /// Signs a given transaction digest using the ECDSA deterministic signature scheme.
  /// The signature is adjusted for low-S encoding and verified against the public key.
  List<int> signBcHTransaction(List<int> digest) {
    ECDSASignature ecdsaSign = signingKey.signDigestDeterminstic(
        digest: digest, hashFunc: () => SHA256());
    if (ecdsaSign.s > CryptoSignerConst.orderHalf) {
      ecdsaSign = ECDSASignature(
          ecdsaSign.r, CryptoSignerConst.secp256k1Order - ecdsaSign.s);
    }
    final List<int> signature =
        CryptoSignatureUtils.toDer([ecdsaSign.r, ecdsaSign.s]);
    return signature;
  }

  /// Signs a given transaction digest using the ECDSA deterministic signature scheme.
  /// The signature is adjusted for low-S encoding and verified against the public key.
  List<int> signTransaction(List<int> digest) {
    ECDSASignature ecdsaSign = signingKey.signDigestDeterminstic(
        digest: digest, hashFunc: () => SHA256());
    List<int> signature =
        CryptoSignatureUtils.toDer([ecdsaSign.r, ecdsaSign.s]);

    int attempt = 1;
    int lengthR = signature[3];

    while (lengthR == 33) {
      final List<int> extraEntropy = List<int>.filled(32, 0);
      final attemptBytes =
          IntUtils.toBytes(attempt, length: IntUtils.bitlengthInBytes(attempt));
      extraEntropy.setAll(
          extraEntropy.length - attemptBytes.length, attemptBytes);
      ecdsaSign = signingKey.signDigestDeterminstic(
          digest: digest, hashFunc: () => SHA256(), extraEntropy: extraEntropy);

      signature = CryptoSignatureUtils.toDer([ecdsaSign.r, ecdsaSign.s]);
      attempt += 1;
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
    signature = List<int>.from([
      derPrefix,
      lengthTotal,
      derTypeInt,
      lengthR,
      ...R,
      derTypeInt,
      lengthS,
      ...newS,
    ]);

    final verify = verifyKey.verifyTransaction(digest, signature);
    if (!verify) {
      throw const CryptoSignException(
          'The created signature does not pass verification.');
    }
    return signature;
  }

  /// Signs a given Schnorr-based transaction digest using the Schnorr signature scheme.
  List<int> signSchnorrTransaction(List<int> digest,
      {required List<dynamic> tapScripts,
      required bool tweak,
      List<int>? auxRand}) {
    if (digest.length != 32) {
      throw const CryptoSignException("The message must be a 32-byte array.");
    }
    List<int> byteKey = <int>[];
    if (tweak) {
      final t = P2TRUtils.calculateTweek(verifyKey.verifyKey.publicKey.point,
          script: tapScripts);

      byteKey = BitcoinSignerUtils.calculatePrivateTweek(
          signingKey.privateKey.toBytes(), t);
    } else {
      byteKey = signingKey.privateKey.toBytes();
    }
    final List<int> aux =
        auxRand ?? QuickCrypto.sha256Hash(<int>[...digest, ...byteKey]);
    final d0 = BigintUtils.fromBytes(byteKey);

    if (!(BigInt.one <= d0 && d0 <= BitcoinSignerUtils.order - BigInt.one)) {
      throw const CryptoSignException(
          "The secret key must be an integer in the range 1..n-1.");
    }
    final P = Curves.generatorSecp256k1 * d0;
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
    final R = (Curves.generatorSecp256k1 * k0);
    BigInt k = k0;
    if (R.y.isOdd) {
      k = BitcoinSignerUtils.order - k;
    }

    final eHash = P2TRUtils.taggedHash(
      "BIP0340/challenge",
      List<int>.from([
        ...BigintUtils.toBytes(R.x, length: BitcoinSignerUtils.baselen),
        ...BigintUtils.toBytes(P.x, length: BitcoinSignerUtils.baselen),
        ...digest
      ]),
    );

    final e = BigintUtils.fromBytes(eHash) % BitcoinSignerUtils.order;

    final eKey = (k + e * d) % BitcoinSignerUtils.order;
    final sig = List<int>.from([
      ...BigintUtils.toBytes(R.x, length: BitcoinSignerUtils.baselen),
      ...BigintUtils.toBytes(eKey, length: BitcoinSignerUtils.baselen)
    ]);
    final verify = verifyKey.verifySchnorr(digest, sig,
        tapleafScripts: tapScripts, isTweak: tweak);

    if (!verify) {
      throw const CryptoSignException(
          'The created signature does not pass verification.');
    }
    return sig;
  }

  /// Signs a given Schnorr-based transaction digest using the Schnorr signature scheme.
  List<int> signSchnorrTx(List<int> digest,
      {List<int>? tweak, List<int>? auxRand}) {
    if (digest.length != 32) {
      throw const CryptoSignException("The message must be a 32-byte array.");
    }
    if (tweak != null && tweak.length != 32) {
      throw const CryptoSignException("The message must be a 32-byte array.");
    }
    List<int> byteKey = <int>[];
    if (tweak != null) {
      byteKey = BitcoinSignerUtils.calculatePrivateTweek(
          signingKey.privateKey.toBytes(), tweak);
    } else {
      byteKey = signingKey.privateKey.toBytes();
    }
    final List<int> aux =
        auxRand ?? QuickCrypto.sha256Hash(<int>[...digest, ...byteKey]);
    final d0 = BigintUtils.fromBytes(byteKey);

    if (!(BigInt.one <= d0 && d0 <= BitcoinSignerUtils.order - BigInt.one)) {
      throw const CryptoSignException(
          "The secret key must be an integer in the range 1..n-1.");
    }
    final P = Curves.generatorSecp256k1 * d0;
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
    final R = (Curves.generatorSecp256k1 * k0);
    BigInt k = k0;
    if (R.y.isOdd) {
      k = BitcoinSignerUtils.order - k;
    }

    final eHash = P2TRUtils.taggedHash(
      "BIP0340/challenge",
      List<int>.from([
        ...BigintUtils.toBytes(R.x, length: BitcoinSignerUtils.baselen),
        ...BigintUtils.toBytes(P.x, length: BitcoinSignerUtils.baselen),
        ...digest
      ]),
    );

    final e = BigintUtils.fromBytes(eHash) % BitcoinSignerUtils.order;

    final eKey = (k + e * d) % BitcoinSignerUtils.order;
    final sig = List<int>.from([
      ...BigintUtils.toBytes(R.x, length: BitcoinSignerUtils.baselen),
      ...BigintUtils.toBytes(eKey, length: BitcoinSignerUtils.baselen)
    ]);
    final verify = verifyKey.verifySchnorrSig(digest, sig, tweak: tweak);
    if (!verify) {
      throw const CryptoSignException(
          'The created signature does not pass verification.');
    }
    return sig;
  }

  /// Returns a [BitcoinVerifier] instance associated with the verification key derived from the signer's private key.
  BitcoinVerifier get verifyKey {
    return BitcoinVerifier._(ECDSAVerifyKey(signingKey.privateKey.publicKey));
  }
}

/// The [BitcoinVerifier] class encapsulates functionality for verifying Bitcoin transactions,
/// Schnorr-based transactions, and messages using ECDSA (Elliptic Curve Digital Signature Algorithm)
/// and related cryptographic operations.
@Deprecated(
    "Use BitcoinSignatureVerifier instead. This will be removed in future versions.")
class BitcoinVerifier {
  /// The ECDSA verification key associated with this Bitcoin verifier.
  final ECDSAVerifyKey verifyKey;

  /// Constructs a [BitcoinVerifier] instance with the given ECDSA verification key.
  BitcoinVerifier._(this.verifyKey);

  /// Factory constructor for creating a [BitcoinVerifier] from public key bytes.
  factory BitcoinVerifier.fromKeyBytes(List<int> publicKey) {
    final point = ProjectiveECCPoint.fromBytes(
        curve: Curves.curveSecp256k1, data: publicKey, order: null);
    final pub = ECDSAPublicKey(Curves.generatorSecp256k1, point);
    return BitcoinVerifier._(ECDSAVerifyKey(pub));
  }

  /// Verifies an ECDSA signature against a given transaction digest.
  bool verifyTransaction(List<int> digest, List<int> derSignature) {
    if (derSignature.length < 9 || derSignature.length > 73) {
      return false;
    }

    if (derSignature[0] != 0x30) {
      return false;
    }
    final int lengthR = derSignature[3];
    final int lengthS = derSignature[5 + lengthR];
    final List<int> rBytes = derSignature.sublist(4, 4 + lengthR);
    final int sIndex = 4 + lengthR + 2;
    final List<int> sBytes = derSignature.sublist(sIndex, sIndex + lengthS);
    final signature = ECDSASignature(
        BigintUtils.fromBytes(rBytes), BigintUtils.fromBytes(sBytes));
    return verifyKey.verify(signature, digest);
  }

  /// Verifies a Schnorr-based signature against a given message, considering optional Taproot scripts.
  bool verifySchnorr(List<int> message, List<int> signature,
      {List<dynamic>? tapleafScripts, required bool isTweak}) {
    if (message.length != 32) {
      throw const CryptoSignException("The message must be a 32-byte array.");
    }

    if (signature.length != 64 && signature.length != 65) {
      throw const CryptoSignException(
          "The signature must be a 64-byte array or 65-bytes with sighash");
    }

    final P = isTweak
        ? P2TRUtils.tweakPublicKey(verifyKey.publicKey.point,
            script: tapleafScripts)
        : P2TRUtils.liftX(verifyKey.publicKey.point.x);

    final r = BigintUtils.fromBytes(signature.sublist(0, 32));

    final s = BigintUtils.fromBytes(signature.sublist(32, 64));

    final ProjectiveECCPoint generator = verifyKey.publicKey.generator;
    final BigInt prime = BitcoinSignerUtils.generator.curve.p;

    if (r >= prime || s >= BitcoinSignerUtils.order) {
      return false;
    }
    final eHash = P2TRUtils.taggedHash(
      "BIP0340/challenge",
      List<int>.from([
        ...signature.sublist(0, 32),
        ...BigintUtils.toBytes(P.x, length: BitcoinSignerUtils.baselen),
        ...message
      ]),
    );
    BigInt e = BigintUtils.fromBytes(eHash) % BitcoinSignerUtils.order;
    final sp = generator * s;

    if (P.y.isEven) {
      e = BitcoinSignerUtils.order - e;
    }
    final ProjectiveECCPoint eP = P * e;

    final R = sp + eP;

    if (R.y.isOdd || R.x != r) {
      return false;
    }

    return true;
  }

  static bool verifySchnorrSignature(
      {required List<int> xOnly,
      required List<int> message,
      required List<int> signature,
      List<int>? tweak}) {
    if (message.length != 32) {
      throw const CryptoSignException("The message must be a 32-byte array.");
    }

    if (signature.length != 64 && signature.length != 65) {
      throw const CryptoSignException(
          "The signature must be a 64-byte array or 65-bytes with sighash");
    }
    final x = BigintUtils.fromBytes(xOnly);
    final P =
        tweak != null ? tweakKey(xBig: x, tweak: tweak) : P2TRUtils.liftX(x);

    final r = BigintUtils.fromBytes(signature.sublist(0, 32));

    final s = BigintUtils.fromBytes(signature.sublist(32, 64));

    final ProjectiveECCPoint generator = BitcoinSignerUtils.generator;
    final BigInt prime = BitcoinSignerUtils.generator.curve.p;

    if (r >= prime || s >= BitcoinSignerUtils.order) {
      return false;
    }
    final eHash = P2TRUtils.taggedHash(
      "BIP0340/challenge",
      List<int>.from([
        ...signature.sublist(0, 32),
        ...BigintUtils.toBytes(P.x, length: BitcoinSignerUtils.baselen),
        ...message
      ]),
    );
    BigInt e = BigintUtils.fromBytes(eHash) % BitcoinSignerUtils.order;
    final sp = generator * s;

    if (P.y.isEven) {
      e = BitcoinSignerUtils.order - e;
    }
    final ProjectiveECCPoint eP = P * e;

    final R = sp + eP;

    if (R.y.isOdd || R.x != r) {
      return false;
    }

    return true;
  }

  bool verifySchnorrSig(List<int> message, List<int> signature,
      {List<int>? tweak}) {
    return verifySchnorrSignature(
        xOnly: verifyKey.publicKey.point.toXonly(),
        message: message,
        signature: signature,
        tweak: tweak);
  }

  /// Verifies an ECDSA signature against a given message, considering the message prefix.
  bool verifyMessage(
      List<int> message, String messagePrefix, List<int> signature) {
    if (signature.length != 64 && signature.length != 65) {
      throw const CryptoSignException(
          "bitcoin signature must be 64 bytes without recover-id or 65 bytes with recover-id");
    }
    final List<int> messgaeHash = QuickCrypto.sha256Hash(
        BitcoinSignerUtils.magicMessage(message, messagePrefix));
    final List<int> correctSignature =
        signature.length == 65 ? signature.sublist(1) : List.from(signature);
    final List<int> rBytes = correctSignature.sublist(0, 32);
    final List<int> sBytes = correctSignature.sublist(32);
    final ecdsaSignature = ECDSASignature(
        BigintUtils.fromBytes(rBytes), BigintUtils.fromBytes(sBytes));

    return verifyKey.verify(ecdsaSignature, messgaeHash);
  }

  static ProjectiveECCPoint tweakKey(
      {required BigInt xBig, required List<int> tweak}) {
    final n = Curves.generatorSecp256k1 * BigintUtils.fromBytes(tweak);
    final outPoint = P2TRUtils.liftX(xBig) + n;
    return outPoint as ProjectiveECCPoint;
  }
}
