import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

List<int> _bytes(int base, int len) =>
    List<int>.generate(len, (i) => (base + i) & 0xFF);

void _checkPubBase(
  BaseSecp256r1PublicKey pub,
  bool Function(List<int>) isValidBytes,
  bool Function(List<int>, CryptoKeyEncoding) isValidEncoding,
  CryptoKeyType type,
) {
  expect(pub.keyBytes.length, EcdsaKeysConst.pubKeyCompressedByteLen);
  expect(pub.toBytes(), pub.keyBytes);
  expect(pub.toBytes(mode: CryptoKeyEncoding.base), pub.keyBytes);
  expect(isValidEncoding(pub.keyBytes, CryptoKeyEncoding.base), isTrue);
  expect(
    IPublicKey.isValidKeyEncoding(pub.keyBytes, type, CryptoKeyEncoding.base),
    isTrue,
  );
  expect(IPublicKey.isValidBytes(pub.keyBytes, type), isTrue);
  expect(isValidBytes(pub.keyBytes), isTrue);
  expect(IPublicKey.fromBytes(pub.keyBytes, type), pub);
  final uncompressed = pub.toBytes(mode: CryptoKeyEncoding.uncompressed);
  expect(uncompressed.length, EcdsaKeysConst.pubKeyUncompressedByteLen);
  expect(isValidEncoding(uncompressed, CryptoKeyEncoding.uncompressed), isTrue);
  // Uncompressed input decodes to the same key; storage stays compressed.
  expect(IPublicKey.fromBytes(uncompressed, type), pub);
  expect(IPublicKey.isValidBytes(uncompressed, type), isTrue);
}

void secp256r1KeysTest() {
  group('secp256r1 keys', () {
    test('private fromBytes/toBytes + public base encoding', () {
      final sk = _bytes(0x11, 32);
      final priv = Secp256r1PrivateKey.fromBytes(sk);
      expect(priv.type, CryptoKeyType.nist256p1);
      expect(BytesUtils.bytesEqual(priv.toBytes(), sk), isTrue);
      _checkPubBase(
        priv.publicKey,
        Secp256r1PublicKey.isValidBytes,
        Secp256r1PublicKey.isValidKeyEncoding,
        CryptoKeyType.nist256p1,
      );
      final pub = Secp256r1PublicKey.fromBytes(priv.publicKey.keyBytes);
      expect(pub, priv.publicKey);
      final viaIface = IPrivateKey.fromBytes(sk, CryptoKeyType.nist256p1);
      expect(viaIface, isA<Secp256r1PrivateKey>());
      expect((viaIface as Secp256r1PrivateKey).publicKey, priv.publicKey);
      final back = Secp256r1PrivateKey.fromBytes(priv.toBytes());
      expect(back.publicKey, priv.publicKey);
      expect(Secp256r1PrivateKey.isValidBytes(sk), isTrue);
    });

    test('sui hybrid private/public base encoding', () {
      final sk = _bytes(0x33, 32);
      final priv = SuiHybridSecp256r1PrivateKey.fromBytes(sk);
      expect(priv.type, CryptoKeyType.nist256p1Hybrid);
      expect(BytesUtils.bytesEqual(priv.toBytes(), sk), isTrue);
      _checkPubBase(
        priv.publicKey,
        SuiHybridSecp256r1PublicKey.isValidBytes,
        SuiHybridSecp256r1PublicKey.isValidKeyEncoding,
        CryptoKeyType.nist256p1Hybrid,
      );
      final viaIface = IPrivateKey.fromBytes(sk, CryptoKeyType.nist256p1Hybrid);
      expect(viaIface, isA<SuiHybridSecp256r1PrivateKey>());
      expect(
        (viaIface as SuiHybridSecp256r1PrivateKey).publicKey,
        priv.publicKey,
      );
    });

    test('invalid private scalars', () {
      // Order n rejected; moved from the old fragmented file.
      expect(
        Secp256r1PrivateKey.isValidBytes(
          BytesUtils.fromHexString(
            'FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551',
          ),
        ),
        isFalse,
      );
      expect(
        () => Secp256r1PrivateKey.fromBytes(
          BytesUtils.fromHexString(
            'FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551',
          ),
        ),
        throwsA(isA<BuError>()),
      );
      expect(Secp256r1PrivateKey.isValidBytes(List.filled(32, 0)), isFalse);
      expect(
        () => Secp256r1PrivateKey.fromBytes(List.filled(32, 0)),
        throwsA(isA<BuError>()),
      );
      expect(Secp256r1PrivateKey.isValidBytes(List.filled(31, 1)), isFalse);
    });

    test('invalid public encodings', () {
      expect(Secp256r1PublicKey.isValidBytes(List.filled(33, 0)), isFalse);
      expect(
        () => Secp256r1PublicKey.fromBytes(List.filled(33, 0)),
        throwsA(isA<BuError>()),
      );
      expect(
        Secp256r1PublicKey.isValidKeyEncoding(
          List.filled(32, 1),
          CryptoKeyEncoding.base,
        ),
        isFalse,
      );
    });

    test('sign/verify round trip', () {
      final priv = Secp256r1PrivateKey.fromBytes(_bytes(0x11, 32));
      final digest = _bytes(0xA0, 32);
      final params = Secp256r1SigningParams(digest: digest);
      final sig = priv.sign(params);
      expect(
        priv.publicKey.verify(Secp256r1VerifyingParams(params, sig)),
        isTrue,
      );
      final sigBack = IECDSASignature.fromBytes(sig.toBytes());
      expect(
        priv.publicKey.verify(Secp256r1VerifyingParams(params, sigBack)),
        isTrue,
      );
      final bad = Secp256r1SigningParams(digest: _bytes(0xB0, 32));
      expect(
        priv.publicKey.verify(Secp256r1VerifyingParams(bad, sig)),
        isFalse,
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(secp256r1KeysTest, 'secp256r1 keys');
}
