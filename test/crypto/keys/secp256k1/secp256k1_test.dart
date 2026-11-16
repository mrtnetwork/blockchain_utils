import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

List<int> _bytes(int base, int len) =>
    List<int>.generate(len, (i) => (base + i) & 0xFF);

void _checkPubBase(Secp256k1PublicKey pub) {
  // keyBytes must be the canonical base (compressed) encoding.
  expect(pub.keyBytes.length, EcdsaKeysConst.pubKeyCompressedByteLen);
  expect(pub.toBytes(), pub.keyBytes);
  expect(pub.toBytes(mode: CryptoKeyEncoding.base), pub.keyBytes);
  expect(
    Secp256k1PublicKey.isValidKeyEncoding(
      pub.keyBytes,
      CryptoKeyEncoding.base,
    ),
    isTrue,
  );
  expect(
    IPublicKey.isValidKeyEncoding(
      pub.keyBytes,
      CryptoKeyType.secp256k1,
      CryptoKeyEncoding.base,
    ),
    isTrue,
  );
  expect(
    IPublicKey.isValidBytes(pub.keyBytes, CryptoKeyType.secp256k1),
    isTrue,
  );
  expect(IPublicKey.fromBytes(pub.keyBytes, CryptoKeyType.secp256k1), pub);
  final uncompressed = pub.toBytes(mode: CryptoKeyEncoding.uncompressed);
  expect(uncompressed.length, EcdsaKeysConst.pubKeyUncompressedByteLen);
  expect(
    Secp256k1PublicKey.isValidKeyEncoding(
      uncompressed,
      CryptoKeyEncoding.uncompressed,
    ),
    isTrue,
  );
  // Uncompressed input decodes to the same key; storage stays compressed.
  expect(Secp256k1PublicKey.fromBytes(uncompressed), pub);
  expect(Secp256k1PublicKey.fromBytes(uncompressed).keyBytes, pub.keyBytes);
  expect(Secp256k1PublicKey.isValidBytes(uncompressed), isTrue);
}

void secp256k1KeysTest() {
  group('secp256k1 keys', () {
    test('private fromBytes/toBytes + public base encoding', () {
      final sk = _bytes(0x11, 32);
      final priv = Secp256k1PrivateKey.fromBytes(sk);
      expect(priv.type, CryptoKeyType.secp256k1);
      expect(BytesUtils.bytesEqual(priv.toBytes(), sk), isTrue);
      expect(priv.publicKey.type, CryptoKeyType.secp256k1);
      _checkPubBase(priv.publicKey);
      // Public fromBytes round trip.
      final pub = Secp256k1PublicKey.fromBytes(priv.publicKey.keyBytes);
      expect(pub, priv.publicKey);
      expect(Secp256k1PublicKey.isValidBytes(priv.publicKey.keyBytes), isTrue);
      // Private dispatch through IPrivateKey.
      final viaIface = IPrivateKey.fromBytes(sk, CryptoKeyType.secp256k1);
      expect(viaIface, isA<Secp256k1PrivateKey>());
      expect(
        (viaIface as Secp256k1PrivateKey).publicKey,
        priv.publicKey,
      );
      // Private round trip through toBytes.
      final back = Secp256k1PrivateKey.fromBytes(priv.toBytes());
      expect(back.publicKey, priv.publicKey);
      expect(Secp256k1PrivateKey.isValidBytes(sk), isTrue);
    });

    test('invalid private scalars', () {
      // Order n and n+1 are rejected; moved from the old fragmented file.
      expect(
        Secp256k1PrivateKey.isValidBytes(
          BytesUtils.fromHexString(
            'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
          ),
        ),
        isFalse,
      );
      expect(
        () => Secp256k1PrivateKey.fromBytes(
          BytesUtils.fromHexString(
            'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
          ),
        ),
        throwsA(isA<BuError>()),
      );
      expect(Secp256k1PrivateKey.isValidBytes(List.filled(32, 0)), isFalse);
      expect(
        () => Secp256k1PrivateKey.fromBytes(List.filled(32, 0)),
        throwsA(isA<BuError>()),
      );
      expect(Secp256k1PrivateKey.isValidBytes(List.filled(31, 1)), isFalse);
      expect(
        () => Secp256k1PrivateKey.fromBytes(List.filled(31, 1)),
        throwsA(isA<BuError>()),
      );
      expect(
        IPrivateKey.isValidBytes(List.filled(32, 0), CryptoKeyType.secp256k1),
        isFalse,
      );
    });

    test('invalid public encodings', () {
      expect(Secp256k1PublicKey.isValidBytes(List.filled(33, 0)), isFalse);
      expect(
        () => Secp256k1PublicKey.fromBytes(List.filled(33, 0)),
        throwsA(isA<BuError>()),
      );
      expect(
        Secp256k1PublicKey.isValidKeyEncoding(
          List.filled(32, 1),
          CryptoKeyEncoding.base,
        ),
        isFalse,
      );
      expect(
        IPublicKey.isValidBytes(List.filled(33, 0), CryptoKeyType.secp256k1),
        isFalse,
      );
    });

    test('sign/verify round trip', () {
      final priv = Secp256k1PrivateKey.fromBytes(_bytes(0x11, 32));
      final digest = _bytes(0xA0, 32);
      final params = Secp256k1SigningParams(digest: digest);
      final sig = priv.sign(params);
      final verifyParams = Secp256k1VerifyingParams(params, sig);
      expect(priv.publicKey.verify(verifyParams), isTrue);
      // Signature bytes round trip.
      final sigBack = IECDSASignature.fromBytes(sig.toBytes());
      expect(
        priv.publicKey.verify(Secp256k1VerifyingParams(params, sigBack)),
        isTrue,
      );
      // Wrong digest fails verification.
      final bad = Secp256k1SigningParams(digest: _bytes(0xB0, 32));
      expect(
        priv.publicKey.verify(Secp256k1VerifyingParams(bad, sig)),
        isFalse,
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(secp256k1KeysTest, 'secp256k1 keys');
}
