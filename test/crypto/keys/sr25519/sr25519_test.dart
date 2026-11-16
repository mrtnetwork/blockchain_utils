import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/sr25519.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

List<int> _bytes(int base, int len) =>
    List<int>.generate(len, (i) => (base + i) & 0xFF);

// Mini secrets are little-endian scalars: keep the value below L with the
// top bit of the last byte clear so `toCanonical` accepts them.
List<int> _miniSecret() => List<int>.filled(32, 0)..[0] = 0x11;
List<int> _sk() => [..._miniSecret(), ..._bytes(0x22, 32)];

void sr25519KeysTest() {
  group('sr25519 keys', () {
    test('private fromBytes/toBytes + public base encoding', () {
      final sk = _sk();
      final priv = SR25519PrivateKey.fromBytes(sk);
      expect(priv.type, CryptoKeyType.sr25519);
      expect(BytesUtils.bytesEqual(priv.toBytes(), sk), isTrue);
      final pub = priv.publicKey;
      expect(pub.type, CryptoKeyType.sr25519);
      // keyBytes must be the canonical 32-byte base encoding.
      expect(pub.keyBytes.length, SchnorrkelKeyCost.publickeyLength);
      expect(pub.toBytes(), pub.keyBytes);
      expect(pub.toBytes(mode: CryptoKeyEncoding.base), pub.keyBytes);
      expect(
        SR25519PublicKey.isValidKeyEncoding(
          pub.keyBytes,
          CryptoKeyEncoding.base,
        ),
        isTrue,
      );
      expect(
        SR25519PublicKey.isValidKeyEncoding(
          pub.keyBytes,
          CryptoKeyEncoding.uncompressed,
        ),
        isFalse,
      );
      expect(
        IPublicKey.isValidKeyEncoding(
          pub.keyBytes,
          CryptoKeyType.sr25519,
          CryptoKeyEncoding.base,
        ),
        isTrue,
      );
      expect(IPublicKey.isValidBytes(pub.keyBytes, CryptoKeyType.sr25519), isTrue);
      expect(SR25519PublicKey.isValidBytes(pub.keyBytes), isTrue);
      expect(IPublicKey.fromBytes(pub.keyBytes, CryptoKeyType.sr25519), pub);
      // Public fromBytes round trip.
      expect(SR25519PublicKey.fromBytes(pub.keyBytes), pub);
      // Private dispatch through IPrivateKey + round trip through toBytes.
      final viaIface = IPrivateKey.fromBytes(sk, CryptoKeyType.sr25519);
      expect(viaIface, isA<SR25519PrivateKey>());
      expect(
        (viaIface as SR25519PrivateKey).publicKey,
        priv.publicKey,
      );
      expect(SR25519PrivateKey.isValidBytes(sk), isTrue);
      final back = SR25519PrivateKey.fromBytes(priv.toBytes());
      expect(back.publicKey, priv.publicKey);
    });

    test('invalid encodings', () {
      expect(SR25519PrivateKey.isValidBytes(List.filled(63, 1)), isFalse);
      expect(
        () => SR25519PrivateKey.fromBytes(List.filled(63, 1)),
        throwsA(isA<BuError>()),
      );
      expect(SR25519PublicKey.isValidBytes(List.filled(32, 0)), isFalse);
      expect(
        () => SR25519PublicKey.fromBytes(List.filled(32, 0)),
        throwsA(isA<BuError>()),
      );
      expect(
        SR25519PublicKey.isValidKeyEncoding(
          List.filled(31, 1),
          CryptoKeyEncoding.base,
        ),
        isFalse,
      );
      expect(
        IPrivateKey.isValidBytes(List.filled(63, 1), CryptoKeyType.sr25519),
        isFalse,
      );
    });

    test('sign/verify round trip', () {
      final sk = _sk();
      final priv = SR25519PrivateKey.fromBytes(sk);
      final context = _bytes(0xC0, 8);
      final message = _bytes(0xA0, 48);
      final params = SR25519SigningParams(
        context: context,
        message: message,
      );
      final sig = priv.sign(params);
      expect(
        priv.publicKey.verify(
          SR25519VerifyingParams(signingParams: params, signature: sig),
        ),
        isTrue,
      );
      // Signature bytes round trip.
      final sigBack = SR25519Signature.fromBytes(sig.toBytes());
      expect(
        priv.publicKey.verify(
          SR25519VerifyingParams(signingParams: params, signature: sigBack),
        ),
        isTrue,
      );
      // Wrong message fails verification.
      final bad = SR25519SigningParams(
        context: context,
        message: _bytes(0xB0, 48),
      );
      expect(
        priv.publicKey.verify(
          SR25519VerifyingParams(signingParams: bad, signature: sig),
        ),
        isFalse,
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(sr25519KeysTest, 'sr25519 keys');
}
