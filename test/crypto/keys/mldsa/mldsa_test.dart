import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

List<int> _seed(int base) =>
    List<int>.generate(32, (i) => (base + i) & 0xFF);

void _checkPubBase(
  BaseMLDSAPublicKey pub,
  bool Function(List<int>, CryptoKeyEncoding) isValidEncoding,
  CryptoKeyType type,
) {
  // The public bytes must be the canonical base encoding.
  expect(pub.toBytes(), pub.bytes);
  expect(pub.toBytes(mode: CryptoKeyEncoding.base), pub.bytes);
  expect(isValidEncoding(pub.bytes, CryptoKeyEncoding.base), isTrue);
  expect(
    IPublicKey.isValidKeyEncoding(pub.bytes, type, CryptoKeyEncoding.base),
    isTrue,
  );
  expect(
    IPublicKey.isValidKeyEncoding(
      pub.bytes,
      type,
      CryptoKeyEncoding.uncompressed,
    ),
    isFalse,
  );
  expect(IPublicKey.isValidBytes(pub.bytes, type), isTrue);
  expect(IPublicKey.fromBytes(pub.bytes, type), pub);
}

void mldsaKeysTest() {
  group('mldsa keys', () {
    test('44: generate/fromBytes/toBytes + base encoding', () {
      final priv = MLDSA44PrivateKey.generate(seed: _seed(0x11));
      expect(priv.type, CryptoKeyType.mldsa44);
      expect(MLDSA44PrivateKey.isValidBytes(priv.toBytes()), isTrue);
      _checkPubBase(
        priv.publicKey,
        MLDSA44PublicKey.isValidKeyEncoding,
        CryptoKeyType.mldsa44,
      );
      expect(
        MLDSA44PublicKey.fromBytes(priv.publicKey.bytes),
        priv.publicKey,
      );
      final viaPriv = IPrivateKey.fromBytes(
        priv.toBytes(),
        CryptoKeyType.mldsa44,
      );
      expect(viaPriv, isA<MLDSA44PrivateKey>());
      expect(
        (viaPriv as MLDSA44PrivateKey).publicKey,
        priv.publicKey,
      );
      final back = MLDSA44PrivateKey.fromBytes(priv.toBytes());
      expect(back.publicKey, priv.publicKey);
      // Length dispatch through the base factories.
      expect(
        BaseMLDSAPublicKey.fromBytes(priv.publicKey.bytes),
        priv.publicKey,
      );
      expect(BaseMLDSAPrivateKey.fromBytes(priv.toBytes()), back);
    });

    test('65: generate/fromBytes/toBytes + base encoding', () {
      final priv = MLDSA65PrivateKey.generate(seed: _seed(0x22));
      expect(priv.type, CryptoKeyType.mldsa65);
      expect(MLDSA65PrivateKey.isValidBytes(priv.toBytes()), isTrue);
      _checkPubBase(
        priv.publicKey,
        MLDSA65PublicKey.isValidKeyEncoding,
        CryptoKeyType.mldsa65,
      );
      final viaPriv = IPrivateKey.fromBytes(
        priv.toBytes(),
        CryptoKeyType.mldsa65,
      );
      expect(
        (viaPriv as MLDSA65PrivateKey).publicKey,
        priv.publicKey,
      );
      expect(
        MLDSA65PublicKey.fromBytes(priv.publicKey.bytes),
        priv.publicKey,
      );
      expect(
        IPrivateKey.isValidBytes(priv.toBytes(), CryptoKeyType.mldsa65),
        isTrue,
      );
    });

    test('87: generate/fromBytes/toBytes + base encoding', () {
      final priv = MLDSA87PrivateKey.generate(seed: _seed(0x33));
      expect(priv.type, CryptoKeyType.mldsa87);
      expect(MLDSA87PrivateKey.isValidBytes(priv.toBytes()), isTrue);
      _checkPubBase(
        priv.publicKey,
        MLDSA87PublicKey.isValidKeyEncoding,
        CryptoKeyType.mldsa87,
      );
      final viaPriv = IPrivateKey.fromBytes(
        priv.toBytes(),
        CryptoKeyType.mldsa87,
      );
      expect(
        (viaPriv as MLDSA87PrivateKey).publicKey,
        priv.publicKey,
      );
      expect(
        MLDSA87PublicKey.fromBytes(priv.publicKey.bytes),
        priv.publicKey,
      );
    });

    test('invalid encodings', () {
      expect(MLDSA44PrivateKey.isValidBytes(List.filled(32, 1)), isFalse);
      expect(
        () => MLDSA44PrivateKey.fromBytes(List.filled(32, 1)),
        throwsA(anyOf(isA<BuError>(), isA<BuError>())),
      );
      expect(
        MLDSA44PublicKey.isValidKeyEncoding(
          List.filled(32, 1),
          CryptoKeyEncoding.base,
        ),
        isFalse,
      );
      // Wrong-level bytes are rejected by the level factories.
      final priv65 = MLDSA65PrivateKey.generate(seed: _seed(0x44));
      expect(
        () => MLDSA44PublicKey.fromBytes(priv65.publicKey.bytes),
        throwsA(isA<BuError>()),
      );
    });

    test('44 sign/verify round trip', () {
      final priv = MLDSA44PrivateKey.generate(seed: _seed(0x55));
      final message = 'mldsa-44'.codeUnits;
      final sig = priv.sign(MLDSASigningParams(message));
      expect(
        priv.publicKey.verify(MLDSAVerifyingParams(message, sig)),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          MLDSAVerifyingParams(message, MLDSASignature(sig.toBytes())),
        ),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          MLDSAVerifyingParams('tampered'.codeUnits, sig),
        ),
        isFalse,
      );
    });

    test('65 sign/verify round trip', () {
      final priv = MLDSA65PrivateKey.generate(seed: _seed(0x66));
      final message = 'mldsa-65'.codeUnits;
      final sig = priv.sign(MLDSASigningParams(message));
      expect(
        priv.publicKey.verify(MLDSAVerifyingParams(message, sig)),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          MLDSAVerifyingParams('tampered'.codeUnits, sig),
        ),
        isFalse,
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(mldsaKeysTest, 'mldsa keys');
}
