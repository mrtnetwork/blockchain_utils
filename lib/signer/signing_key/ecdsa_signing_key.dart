import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/cdsa.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/bitcoin/bitcoin_signer.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/signer/types/types.dart';
import 'package:blockchain_utils/signer/utils/utils.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// The [ECDSASigningKey] class represents a key pair for ECDSA (Elliptic Curve Digital Signature Algorithm) signing.
/// It encapsulates the private key and provides methods for signing digests and generating deterministic signatures.
class ECDSASigningKey {
  /// The ECDSA private key associated with this signing key.
  final ECDSAPrivateKey privateKey;

  /// Constructs an [ECDSASigningKey] instance with the given private key.
  ECDSASigningKey(this.privateKey) : generator = privateKey.publicKey.generator;

  /// The projective ECC (Elliptic Curve Cryptography) point generator associated with the key.
  final ProjectiveECCPoint generator;

  /// Truncates and converts a digest into a BigInt, based on the provided [generator].
  ///
  /// Throws an [CryptoSignException] if the digest length exceeds the curve's base length when [truncate] is false.
  static BigInt _truncateAndConvertDigest(
      List<int> digest, ProjectiveECCPoint generator,
      {bool truncate = false}) {
    List<int> digestBytes = List.from(digest);
    if (!truncate) {
      if (digest.length > generator.curve.baselen) {
        throw const CryptoSignException(
            "this curve is too short for digest length");
      }
    } else {
      digestBytes = digest.sublist(0, generator.curve.baselen);
    }

    BigInt toBig = BigintUtils.fromBytes(digest);
    if (truncate) {
      final int maxLength = toBig.bitLength;
      final int digestLen = digestBytes.length * 8;

      toBig >>= IntUtils.max(0, digestLen - maxLength);
    }
    return toBig;
  }

  /// Signs a given digest using the private key and a specified value of 'k'.
  ECDSASignature signDigest(
      {required List<int> digest,
      List<int>? entropy,
      required BigInt k,
      bool truncate = false}) {
    final digestInt =
        _truncateAndConvertDigest(digest, generator, truncate: truncate);
    final sign = privateKey.sign(digestInt, k);
    return sign;
  }

  /// Generates a deterministic signature for a given digest using the private key.
  ///
  /// Uses RFC 6979 for 'k' value generation to mitigate certain vulnerabilities associated with random 'k' generation.
  ECDSASignature signDigestDeterminstic(
      {required List<int> digest,
      required HashFunc hashFunc,
      List<int>? extraEntropy,
      bool truncate = false,
      int retry = 0}) {
    final k = RFC6979.generateK(
        order: generator.order!,
        secexp: privateKey.secretMultiplier,
        hashFunc: hashFunc,
        data: digest,
        extraEntropy: extraEntropy,
        retryGn: retry);
    return signDigest(digest: digest, k: k, truncate: truncate);
  }
}

/// The [ECDSAVerifyKey] class represents a key for ECDSA (Elliptic Curve Digital Signature Algorithm) verification.
/// It encapsulates the public key and provides a method for verifying ECDSA signatures against a given digest.
class ECDSAVerifyKey {
  /// The ECDSA public key associated with this verification key.
  final ECDSAPublicKey publicKey;

  /// Constructs an [ECDSAVerifyKey] instance with the given public key.
  ECDSAVerifyKey(this.publicKey);

  /// Verifies a given ECDSA signature against a digest using the associated public key.
  ///
  /// It internally converts the digest into a BigInt using the truncate-and-convert method,
  /// and then calls the 'verifies' method of the associated public key.
  ///
  /// Returns true if the signature is valid for the provided digest, false otherwise.
  bool verify(ECDSASignature signature, List<int> digest) {
    final digestNumber =
        ECDSASigningKey._truncateAndConvertDigest(digest, publicKey.generator);
    return publicKey.verifies(digestNumber, signature);
  }
}

/// The [ECDSASigningKey] class represents a key pair for ECDSA (Elliptic Curve Digital Signature Algorithm) signing.
/// It encapsulates the private key and provides methods for signing digests and generating deterministic signatures.
class Secp256k1SigningKey extends ECDSASigningKey {
  final Secp256k1ECmultGenContext ecMultContext;
  ECDSAVerifyKey toVerifyKey() {
    return ECDSAVerifyKey(ECDSAPublicKey(Curves.generatorSecp256k1,
        privateKey.publicKey.point.cast<ProjectiveECCPoint>()));
  }

  factory Secp256k1SigningKey.fromBytes(
      {required List<int> keyBytes, Secp256k1ECmultGenContext? ecMultContext}) {
    //CryptoSignException
    try {
      return Secp256k1SigningKey(
        ecMultContext:
            ecMultContext ?? Secp256k1Utils.initalizeBlindEcMultContext(),
        privateKey: ECDSAPrivateKey.fromBytesConst(
            bytes: keyBytes, type: EllipticCurveTypes.secp256k1),
      );
    } catch (e) {
      throw CryptoSignException("Invalid secp256k1 private key.");
    }
  }

  /// Constructs an [ECDSASigningKey] instance with the given private key.
  Secp256k1SigningKey(
      {required this.ecMultContext, required ECDSAPrivateKey privateKey})
      : super(privateKey);

  Tuple<ECDSASignature, int> _signEcdsaConst(
      {required List<int> digest, List<int>? extraEntropy}) {
    if (digest.length != CryptoSignerConst.digestLength) {
      throw CryptoSignException(
          "invalid digest. digest length must be ${CryptoSignerConst.digestLength} got ${digest.length}");
    }
    final keyBytes = privateKey.toBytes();
    List<int> k = RFC6979.generateSecp256k1KBytes(
        secexp: keyBytes,
        hashFunc: () => SHA256(),
        data: digest,
        extraEntropy: extraEntropy);
    final ecdsaSign = _signInternal(
        kBytes: k,
        privateKey: keyBytes,
        message: digest,
        context: ecMultContext);
    final verifyKey = toVerifyKey();
    if (verifyKey.verify(ecdsaSign, digest)) {
      final recover = ecdsaSign.recoverPublicKeys(
          digest, CryptoSignerConst.generatorSecp256k1);
      for (int i = 0; i < recover.length; i++) {
        if (recover[i].point == verifyKey.publicKey.point) {
          return Tuple(ecdsaSign, i);
        }
      }
    }

    throw const CryptoSignException(
        'The created signature does not pass verification.');
  }

  Tuple<ECDSASignature, int> _signEcdsa(
      {required List<int> digest, List<int>? extraEntropy}) {
    ECDSASignature ecdsaSign = signDigestDeterminstic(
        digest: digest, hashFunc: () => SHA256(), extraEntropy: extraEntropy);
    if (ecdsaSign.s > CryptoSignerConst.secp256k1OrderHalf) {
      ecdsaSign = ECDSASignature(
          ecdsaSign.r, CryptoSignerConst.secp256k1Order - ecdsaSign.s);
    }
    final verifyKey = toVerifyKey();
    if (verifyKey.verify(ecdsaSign, digest)) {
      final recover = ecdsaSign.recoverPublicKeys(
          digest, CryptoSignerConst.generatorSecp256k1);
      for (int i = 0; i < recover.length; i++) {
        if (recover[i].point == verifyKey.publicKey.point) {
          return Tuple(ecdsaSign, i);
        }
      }
    }

    throw const CryptoSignException(
        'The created signature does not pass verification.');
  }

  Tuple<ECDSASignature, int> signConst(
      {required List<int> digest, List<int>? extraEntropy}) {
    return _signEcdsaConst(digest: digest, extraEntropy: extraEntropy);
  }

  List<int> signConstDer({required List<int> digest, List<int>? extraEntropy}) {
    final signature =
        signConst(digest: digest, extraEntropy: extraEntropy).item1;
    return CryptoSignatureUtils.toDer([signature.r, signature.s]);
  }

  Tuple<ECDSASignature, int> sign(
      {required List<int> digest, List<int>? extraEntropy}) {
    return _signEcdsa(digest: digest, extraEntropy: extraEntropy);
  }

  List<int> signDer({required List<int> digest, List<int>? extraEntropy}) {
    final signature = sign(digest: digest, extraEntropy: extraEntropy).item1;
    return CryptoSignatureUtils.toDer([signature.r, signature.s]);
  }

  static ECDSASignature _signInternal(
      {required List<int> kBytes,
      required List<int> privateKey,
      required List<int> message,
      required Secp256k1ECmultGenContext context}) {
    Secp256k1Gej R = Secp256k1Gej();
    Secp256k1Ge rg = Secp256k1Ge();
    Secp256k1Scalar k = Secp256k1Utils.scalarFromBytes(kBytes);
    Secp256k1Scalar msg = Secp256k1Utils.scalarFromBytes(message);
    Secp256k1Scalar sk = Secp256k1Utils.scalarFromBytes(privateKey);

    if (!Secp256k1Utils.isValidScalar(k) || !Secp256k1Utils.isValidScalar(sk)) {
      throw const CryptoSignException(
          'Signing failed due to an unexpected error.');
    }
    Secp256k1Scalar sigs = Secp256k1Scalar();
    Secp256k1Scalar sigr = Secp256k1Scalar();
    Secp256k1Scalar n = Secp256k1Scalar();

    Secp256k1.secp256k1ECmultGen(context, R, k);
    Secp256k1.secp256k1GeSetGej(rg, R);
    List<int> nonce32 = List<int>.filled(32, 0);
    Secp256k1.secp256k1FeNormalize(rg.x);
    Secp256k1.secp256k1FeNormalize(rg.y);
    Secp256k1.secp256k1FeGetB32(nonce32, rg.x);
    Secp256k1.secp256k1ScalarSetB32(sigr, nonce32);

    Secp256k1.secp256k1ScalarMul(n, sigr, sk);
    Secp256k1.secp256k1ScalarAdd(n, n, msg);
    Secp256k1.secp256k1ScalarInverse(sigs, k);
    Secp256k1.secp256k1ScalarMul(sigs, sigs, n);
    int high = Secp256k1.secp256k1ScalarIsHigh(sigs);
    Secp256k1.secp256k1ScalarCondNegate(sigs, high);
    List<int> rBytes = List<int>.filled(32, 0);
    List<int> sBytes = List<int>.filled(32, 0);
    if (!Secp256k1Utils.isValidScalar(sigr) ||
        !Secp256k1Utils.isValidScalar(sigs)) {
      throw const CryptoSignException(
          'Signing failed due to an unexpected error.');
    }
    Secp256k1.secp256k1ScalarGetB32(rBytes, sigr);
    Secp256k1.secp256k1ScalarGetB32(sBytes, sigs);

    return ECDSASignature(
        BigintUtils.fromBytes(rBytes), BigintUtils.fromBytes(sBytes));
  }

  List<int> signSchnorrConst(
      {required List<int> digest, List<int>? extraEntropy}) {
    if (digest.length != Curves.curveSecp256k1.baselen) {
      throw CryptoSignException(
          "The digest must be a ${Curves.curveSecp256k1.baselen}-byte array.");
    }
    final sec = privateKey.toBytes();
    List<int> k = RFC6979.generateSecp256k1KBytes(
        secexp: sec,
        hashFunc: () => SHA256(),
        data: digest,
        extraEntropy: extraEntropy);
    final kScalar = Secp256k1Utils.scalarFromBytes(k);
    if (!Secp256k1Utils.isValidScalar(kScalar)) {
      throw const CryptoSignException(
          'Schnorr signing failed due to an unexpected error.');
    }
    Secp256k1Gej R = Secp256k1Gej();
    Secp256k1.secp256k1ECmultGen(ecMultContext, R, kScalar);
    Secp256k1Ge rg = Secp256k1Ge();
    Secp256k1.secp256k1GeSetGej(rg, R);
    Secp256k1.secp256k1FeNormalize(rg.x);
    Secp256k1.secp256k1FeNormalize(rg.y);
    List<int> nonce32 = List<int>.filled(32, 0);
    Secp256k1.secp256k1FeGetB32(nonce32, rg.x);
    final eHash = QuickCrypto.sha256Hash(
        [...nonce32, ...privateKey.publicKey.toBytes(), ...digest]);

    final sk = Secp256k1Utils.scalarFromBytes(sec);
    final eSclar = Secp256k1Utils.scalarFromBytes(eHash);
    if (!Secp256k1Utils.isValidScalar(sk) ||
        !Secp256k1Utils.isValidScalar(eSclar)) {
      throw const CryptoSignException(
          'Schnorr signing failed due to an unexpected error.');
    }
    Secp256k1Scalar n = Secp256k1Scalar();
    Secp256k1Scalar sigs = Secp256k1Scalar();
    Secp256k1.secp256k1ScalarMul(n, eSclar, sk);

    if (Secp256k1.secp256k1FeIsQuad(R.y) == 0) {
      Secp256k1.secp256k1ScalarNegate(kScalar, kScalar);
    }
    Secp256k1.secp256k1ScalarAdd(sigs, kScalar, n);
    if (!Secp256k1Utils.isValidScalar(sigs)) {
      throw const CryptoSignException(
          'Schnorr signing failed due to an unexpected error.');
    }
    List<int> sBytes = List<int>.filled(32, 0);
    Secp256k1.secp256k1ScalarGetB32(sBytes, sigs);
    return [...nonce32, ...sBytes];
  }

  List<int> signBip340Const(
      {required List<int> digest, List<int>? tapTweakHash, List<int>? aux}) {
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw CryptoSignException(
          "The digest must be a ${BitcoinSignerUtils.baselen}-byte array.");
    }
    if (aux != null && aux.length != 32) {
      throw CryptoSignException("The aux must be a 32-byte array.");
    }

    final tKey = _tweakConst(privateKey.toBytes(), ecMultContext,
        tapTweakHash: tapTweakHash);
    aux ??= QuickCrypto.sha256Hash(
        [...digest, ...Secp256k1Utils.scalarToBytes(tKey)]);

    Secp256k1Ge mid = Secp256k1Ge();
    Secp256k1Gej res = Secp256k1Gej();
    Secp256k1.secp256k1ECmultGen(ecMultContext, res, tKey);
    Secp256k1.secp256k1GeSetGej(mid, res);
    if (Secp256k1.secp256k1FeIsOdd(mid.y) == 1) {
      Secp256k1.secp256k1ScalarNegate(tKey, tKey);
    }
    final d = Secp256k1Utils.scalarToBytes(tKey);
    final t = BytesUtils.xor(d, P2TRUtils.taggedHash("BIP0340/aux", aux));
    Secp256k1.secp256k1FeNormalize(mid.x);
    final xBytes = Secp256k1Utils.feToBytes(mid.x);

    final kHash =
        P2TRUtils.taggedHash("BIP0340/nonce", [...t, ...xBytes, ...digest]);
    final k0 = Secp256k1Utils.scalarFromBytes(kHash);

    if (!Secp256k1Utils.isValidScalar(k0)) {
      throw const CryptoSignException(
          'Schnorr signing failed due to an unexpected error.');
    }
    Secp256k1Ge midR = Secp256k1Ge();
    Secp256k1Gej resR = Secp256k1Gej();
    Secp256k1.secp256k1ECmultGen(ecMultContext, resR, k0);
    Secp256k1.secp256k1GeSetGej(midR, resR);

    if (Secp256k1.secp256k1FeIsOdd(midR.y) == 1) {
      Secp256k1.secp256k1ScalarNegate(k0, k0);
    }
    Secp256k1.secp256k1FeNormalize(midR.x);
    final rBytes = Secp256k1Utils.feToBytes(midR.x);
    final eHash = P2TRUtils.taggedHash(
        "BIP0340/challenge", [...rBytes, ...xBytes, ...digest]);
    final eSclar = Secp256k1Utils.scalarFromBytes(eHash);
    if (!Secp256k1Utils.isValidScalar(eSclar)) {
      throw const CryptoSignException(
          'Schnorr signing failed due to an unexpected error.');
    }
    Secp256k1Scalar n = Secp256k1Scalar();
    Secp256k1Scalar sigs = Secp256k1Scalar();
    Secp256k1.secp256k1ScalarMul(n, eSclar, tKey);
    Secp256k1.secp256k1ScalarAdd(sigs, k0, n);
    if (!Secp256k1Utils.isValidScalar(sigs)) {
      throw const CryptoSignException(
          'Schnorr signing failed due to an unexpected error.');
    }
    List<int> sBytes = List<int>.filled(32, 0);
    Secp256k1.secp256k1ScalarGetB32(sBytes, sigs);

    return [...rBytes, ...sBytes];
  }

  List<int> signSchnorr(List<int> digest, {List<int>? extraEntropy}) {
    if (digest.length != BitcoinSignerUtils.baselen) {
      throw CryptoSignException(
          "The digest must be a ${BitcoinSignerUtils.baselen}-byte array.");
    }
    BigInt d = privateKey.secretMultiplier;
    final BigInt order = CryptoSignerConst.generatorSecp256k1.order!;

    if (!(BigInt.one <= d && d <= order - BigInt.one)) {
      throw const CryptoSignException(
          "The secret key must be an integer in the range 1..n-1.");
    }
    extraEntropy ??= CryptoSignerConst.bchSchnorrRfc6979ExtraData;
    BigInt k = RFC6979.generateK(
        order: order,
        secexp: privateKey.secretMultiplier,
        hashFunc: () => SHA256(),
        data: digest,
        extraEntropy: extraEntropy);

    final R = (CryptoSignerConst.generatorSecp256k1 * k);
    if (ECDSAUtils.jacobi(R.y, CryptoSignerConst.curveSecp256k1.p).isNegative) {
      k = order - k;
    }
    final eHash = QuickCrypto.sha256Hash(
        [...R.toXonly(), ...privateKey.publicKey.toBytes(), ...digest]);
    final BigInt e = BigintUtils.fromBytes(eHash) % order;

    // Step 5: Compute Schnorr Signature: s = k + e * d (mod n)
    final BigInt s = (k + e * d) % order;
    final signature = BitcoinSchnorrSignature(r: R.x, s: s).toBytes();

    // Step 6: Return Signature (64 bytes: R.x || s)
    return signature;
  }

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
          privateKey.toBytes(), tapTweakHash);
    } else {
      byteKey = privateKey.toBytes();
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
    return [
      ...R.toXonly(),
      ...BigintUtils.toBytes(eKey, length: BitcoinSignerUtils.baselen)
    ];
  }

  static Secp256k1Scalar _tweakConst(
      List<int> privateKey, Secp256k1ECmultGenContext context,
      {List<int>? tapTweakHash}) {
    Secp256k1Scalar a = Secp256k1Utils.scalarFromBytes(privateKey);
    if (tapTweakHash == null) return a;

    Secp256k1Gej res1 = Secp256k1Gej();
    Secp256k1.secp256k1ECmultGen(context, res1, a);
    Secp256k1Ge mid1 = Secp256k1Ge();
    Secp256k1.secp256k1GeSetGej(mid1, res1);
    Secp256k1.secp256k1FeNormalizeVar(mid1.x);
    Secp256k1.secp256k1FeNormalizeVar(mid1.y);
    if (Secp256k1.secp256k1FeIsOdd(mid1.y) == 1) {
      Secp256k1.secp256k1ScalarNegate(a, a);
    }
    Secp256k1Scalar tweakScalar = Secp256k1Utils.scalarFromBytes(tapTweakHash);
    if (!Secp256k1Utils.isValidScalar(tweakScalar)) {
      throw CryptoSignException("Invalid tweak bytes.");
    }
    Secp256k1.secp256k1ScalarAdd(a, a, tweakScalar);
    if (!Secp256k1Utils.isValidScalar(a)) {
      throw CryptoSignException("Invalid tweak bytes.");
    }
    return a;
  }
}
