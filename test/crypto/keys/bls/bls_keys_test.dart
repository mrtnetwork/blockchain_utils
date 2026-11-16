import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

List<int> _bytes(int base, int len) =>
    List<int>.generate(len, (i) => (base + i) & 0xFF);

final List<int> _dst = 'BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_'.codeUnits;

void blsKeysTest() {
  group('bls keys', () {
    test('G1: fromBytes/toBytes + base encoding + uncompressed', () {
      final sk = _bytes(0x11, 32);
      final priv = Bls12G1PrivateKey.fromBytes(sk);
      expect(priv.type, CryptoKeyType.bls12G1);
      expect(BytesUtils.bytesEqual(priv.toBytes(), sk), isTrue);
      final pub = priv.publicKey;
      // keyBytes must be the canonical 48-byte compressed base encoding.
      expect(pub.keyBytes.length, Bls12KeyConst.compressedPubKeyLength);
      expect(pub.toBytes(), pub.keyBytes);
      expect(pub.toBytes(mode: CryptoKeyEncoding.base), pub.keyBytes);
      expect(
        Bls12G1PublicKey.isValidKeyEncoding(
          pub.keyBytes,
          CryptoKeyEncoding.base,
        ),
        isTrue,
      );
      expect(
        IPublicKey.isValidKeyEncoding(
          pub.keyBytes,
          CryptoKeyType.bls12G1,
          CryptoKeyEncoding.base,
        ),
        isTrue,
      );
      expect(IPublicKey.isValidBytes(pub.keyBytes, CryptoKeyType.bls12G1), isTrue);
      expect(Bls12G1PublicKey.isValidBytes(pub.keyBytes), isTrue);
      expect(IPublicKey.fromBytes(pub.keyBytes, CryptoKeyType.bls12G1), pub);
      expect(Bls12G1PublicKey.fromBytes(pub.keyBytes), pub);
      // Uncompressed (96-byte) form: encodes, validates, and decodes back
      // to the same key while storage stays compressed.
      final uncompressed = pub.toBytes(mode: CryptoKeyEncoding.uncompressed);
      expect(uncompressed.length, Bls12KeyConst.uncompressedPubKeyLength);
      expect(
        Bls12G1PublicKey.isValidKeyEncoding(
          uncompressed,
          CryptoKeyEncoding.uncompressed,
        ),
        isTrue,
      );
      expect(Bls12G1PublicKey.isValidBytes(uncompressed), isTrue);
      expect(Bls12G1PublicKey.fromBytes(uncompressed), pub);
      expect(Bls12G1PublicKey.fromBytes(uncompressed).keyBytes, pub.keyBytes);
      // Private dispatch through IPrivateKey + round trip through toBytes.
      final viaIface = IPrivateKey.fromBytes(sk, CryptoKeyType.bls12G1);
      expect(viaIface, isA<Bls12G1PrivateKey>());
      expect((viaIface as Bls12G1PrivateKey).publicKey, pub);
      expect(Bls12G1PrivateKey.isValidBytes(sk), isTrue);
      expect(Bls12G1PrivateKey.fromBytes(priv.toBytes()).publicKey, pub);
    });

    test('G2: fromBytes/toBytes + base encoding + uncompressed', () {
      final sk = _bytes(0x22, 32);
      final priv = Bls12G2PrivateKey.fromBytes(sk);
      expect(priv.type, CryptoKeyType.bls12G2);
      expect(BytesUtils.bytesEqual(priv.toBytes(), sk), isTrue);
      final pub = priv.publicKey;
      // keyBytes must be the canonical 96-byte compressed base encoding.
      expect(pub.keyBytes.length, Bls12G2KeyConst.compressedPubKeyLength);
      expect(pub.toBytes(), pub.keyBytes);
      expect(pub.toBytes(mode: CryptoKeyEncoding.base), pub.keyBytes);
      expect(
        Bls12G2PublicKey.isValidKeyEncoding(
          pub.keyBytes,
          CryptoKeyEncoding.base,
        ),
        isTrue,
      );
      expect(
        IPublicKey.isValidKeyEncoding(
          pub.keyBytes,
          CryptoKeyType.bls12G2,
          CryptoKeyEncoding.base,
        ),
        isTrue,
      );
      expect(IPublicKey.isValidBytes(pub.keyBytes, CryptoKeyType.bls12G2), isTrue);
      expect(Bls12G2PublicKey.isValidBytes(pub.keyBytes), isTrue);
      expect(IPublicKey.fromBytes(pub.keyBytes, CryptoKeyType.bls12G2), pub);
      expect(Bls12G2PublicKey.fromBytes(pub.keyBytes), pub);
      // Uncompressed (192-byte) form round trip, storage stays compressed.
      final uncompressed = pub.toBytes(mode: CryptoKeyEncoding.uncompressed);
      expect(uncompressed.length, Bls12G2KeyConst.uncompressedPubKeyLength);
      expect(
        Bls12G2PublicKey.isValidKeyEncoding(
          uncompressed,
          CryptoKeyEncoding.uncompressed,
        ),
        isTrue,
      );
      expect(Bls12G2PublicKey.isValidBytes(uncompressed), isTrue);
      expect(Bls12G2PublicKey.fromBytes(uncompressed), pub);
      expect(Bls12G2PublicKey.fromBytes(uncompressed).keyBytes, pub.keyBytes);
      final viaIface = IPrivateKey.fromBytes(sk, CryptoKeyType.bls12G2);
      expect(viaIface, isA<Bls12G2PrivateKey>());
      expect((viaIface as Bls12G2PrivateKey).publicKey, pub);
      expect(Bls12G2PrivateKey.isValidBytes(sk), isTrue);
      expect(Bls12G2PrivateKey.fromBytes(priv.toBytes()).publicKey, pub);
    });

    test('invalid encodings', () {
      expect(Bls12G1PrivateKey.isValidBytes(List.filled(32, 0)), isFalse);
      expect(
        () => Bls12G1PrivateKey.fromBytes(List.filled(32, 0)),
        throwsA(isA<BuError>()),
      );
      expect(Bls12G1PrivateKey.isValidBytes(List.filled(31, 1)), isFalse);
      // Infinity (0xc0...) is rejected for plain public keys.
      final infG1 = Bls12G1PublicKey.isValidBytes(
        BytesUtils.fromHexString(
          'c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
        ),
      );
      expect(infG1, isFalse);
      expect(
        () => Bls12G1PublicKey.fromBytes(List.filled(48, 0)),
        throwsA(isA<BuError>()),
      );
      expect(
        Bls12G1PublicKey.isValidKeyEncoding(
          List.filled(47, 1),
          CryptoKeyEncoding.base,
        ),
        isFalse,
      );
      expect(
        Bls12G2PublicKey.isValidKeyEncoding(
          List.filled(95, 1),
          CryptoKeyEncoding.base,
        ),
        isFalse,
      );
      expect(
        IPrivateKey.isValidBytes(List.filled(32, 0), CryptoKeyType.bls12G1),
        isFalse,
      );
    });

    test('G1 sign/verify round trip', () {
      final priv = Bls12G1PrivateKey.fromBytes(_bytes(0x11, 32));
      final message = 'bls-g1'.codeUnits;
      final params = Bls12SigningParams(message: message, dst: _dst);
      final sig = priv.sign(params);
      expect(
        priv.publicKey.verify(
          Bls12G1VerifiyingParams(signature: sig, signingParams: params),
        ),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          Bls12G1VerifiyingParams(
            signature: Bls12G1Signature.fromBytes(sig.toBytes()),
            signingParams: params,
          ),
        ),
        isTrue,
      );
      final bad = Bls12SigningParams(message: 'tampered'.codeUnits, dst: _dst);
      expect(
        priv.publicKey.verify(
          Bls12G1VerifiyingParams(signature: sig, signingParams: bad),
        ),
        isFalse,
      );
    });

    test('G2 sign/verify round trip', () {
      final priv = Bls12G2PrivateKey.fromBytes(_bytes(0x22, 32));
      final message = 'bls-g2'.codeUnits;
      final params = Bls12SigningParams(message: message, dst: _dst);
      final sig = priv.sign(params);
      expect(
        priv.publicKey.verify(
          Bls12G2VerifiyingParams(signature: sig, signingParams: params),
        ),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          Bls12G2VerifiyingParams(
            signature: Bls12G2Signature.fromBytes(sig.toBytes()),
            signingParams: params,
          ),
        ),
        isTrue,
      );
      final bad = Bls12SigningParams(message: 'tampered'.codeUnits, dst: _dst);
      expect(
        priv.publicKey.verify(
          Bls12G2VerifiyingParams(signature: sig, signingParams: bad),
        ),
        isFalse,
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(blsKeysTest, 'bls keys');
}
