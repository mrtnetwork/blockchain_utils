import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

List<int> _scalar(int last) => List<int>.filled(32, 0)..[31] = last;

void _checkPubBase32(
  IRedJubJubVerificationKey pub,
  bool Function(List<int>, CryptoKeyEncoding) isValidEncoding,
  CryptoKeyType type,
) {
  // keyBytes must be the canonical 32-byte base encoding.
  expect(pub.keyBytes.length, 32);
  expect(pub.toBytes(), pub.keyBytes);
  expect(pub.toBytes(mode: CryptoKeyEncoding.base), pub.keyBytes);
  expect(isValidEncoding(pub.keyBytes, CryptoKeyEncoding.base), isTrue);
  expect(
    isValidEncoding(pub.keyBytes, CryptoKeyEncoding.uncompressed),
    isFalse,
  );
  expect(
    IPublicKey.isValidKeyEncoding(pub.keyBytes, type, CryptoKeyEncoding.base),
    isTrue,
  );
  expect(IPublicKey.isValidBytes(pub.keyBytes, type), isTrue);
  expect(IPublicKey.fromBytes(pub.keyBytes, type), pub);
}

void redJubJubKeysTest() {
  group('redjubjub keys', () {
    test('binding: fromBytes/toBytes + base encoding + randomize', () {
      final sk = _scalar(7);
      final r = _scalar(11);
      final priv = RedJubJubBindingPrivateKey.fromBytes(sk);
      expect(priv.type, CryptoKeyType.redJubJubBinding);
      expect(BytesUtils.bytesEqual(priv.toBytes(), sk), isTrue);
      _checkPubBase32(
        priv.publicKey,
        RedJubJubBindingPublicKey.isValidKeyEncoding,
        CryptoKeyType.redJubJubBinding,
      );
      expect(RedJubJubBindingPublicKey.isValidBytes(priv.publicKey.keyBytes), isTrue);
      expect(
        RedJubJubBindingPublicKey.fromBytes(priv.publicKey.keyBytes),
        priv.publicKey,
      );
      final viaPriv = IPrivateKey.fromBytes(
        sk,
        CryptoKeyType.redJubJubBinding,
      );
      expect(viaPriv, isA<RedJubJubBindingPrivateKey>());
      expect(
        (viaPriv as RedJubJubBindingPrivateKey).publicKey,
        priv.publicKey,
      );
      expect(RedJubJubBindingPrivateKey.isValidBytes(sk), isTrue);
      final back = RedJubJubBindingPrivateKey.fromBytes(priv.toBytes());
      expect(back.publicKey, priv.publicKey);
      // Randomize consistency: priv.randomize == pub.randomize.
      expect(
        priv.randomize(r).publicKey,
        RedJubJubBindingPublicKey.fromBytes(
          priv.publicKey.keyBytes,
        ).randomize(r),
      );
      // fromScalar takes bytes and matches fromBytes.
      expect(
        RedJubJubBindingPrivateKey.fromScalar(sk).publicKey,
        priv.publicKey,
      );
    });

    test('spend: fromBytes/toBytes + base encoding + randomize', () {
      final sk = _scalar(7);
      final r = _scalar(11);
      final priv = RedJubJubSpendPrivateKey.fromBytes(sk);
      expect(priv.type, CryptoKeyType.redJubJubSpend);
      expect(BytesUtils.bytesEqual(priv.toBytes(), sk), isTrue);
      _checkPubBase32(
        priv.publicKey,
        RedJubJubSpendPublicKey.isValidKeyEncoding,
        CryptoKeyType.redJubJubSpend,
      );
      expect(RedJubJubSpendPublicKey.isValidBytes(priv.publicKey.keyBytes), isTrue);
      expect(
        RedJubJubSpendPublicKey.fromBytes(priv.publicKey.keyBytes),
        priv.publicKey,
      );
      final viaPriv = IPrivateKey.fromBytes(sk, CryptoKeyType.redJubJubSpend);
      expect(viaPriv, isA<RedJubJubSpendPrivateKey>());
      expect(
        (viaPriv as RedJubJubSpendPrivateKey).publicKey,
        priv.publicKey,
      );
      expect(RedJubJubSpendPrivateKey.isValidBytes(sk), isTrue);
      expect(
        RedJubJubSpendPrivateKey.fromScalar(sk).publicKey,
        priv.publicKey,
      );
      expect(
        priv.randomize(r).publicKey,
        RedJubJubSpendPublicKey.fromBytes(
          priv.publicKey.keyBytes,
        ).randomize(r),
      );
    });

    test('zero: spend rejects, binding allows', () {
      final zero = List<int>.filled(32, 0);
      final identity = blockchainUtils.api.jubjub.identity();
      // spend private/public must reject zero.
      expect(
        () => RedJubJubSpendPrivateKey.fromScalar(zero),
        throwsA(isA<BuError>()),
      );
      expect(RedJubJubSpendPrivateKey.isValidBytes(zero), isFalse);
      expect(
        () => RedJubJubSpendPublicKey.fromBytes(identity),
        throwsA(isA<BuError>()),
      );
      expect(RedJubJubSpendPublicKey.isValidBytes(identity), isFalse);
      // binding allows zero on both ends, with round-trip.
      final bpriv = RedJubJubBindingPrivateKey.fromScalar(zero);
      expect(RedJubJubBindingPrivateKey.isValidBytes(zero), isTrue);
      expect(bpriv.publicKey.keyBytes, identity);
      expect(
        RedJubJubBindingPublicKey.isValidBytes(bpriv.publicKey.keyBytes),
        isTrue,
      );
      expect(
        RedJubJubBindingPublicKey.fromBytes(bpriv.publicKey.keyBytes),
        bpriv.publicKey,
      );
      expect(
        RedJubJubBindingPublicKey.fromBytes(identity),
        bpriv.publicKey,
      );
    });

    test('invalid encodings', () {
      expect(
        RedJubJubBindingPrivateKey.isValidBytes(List.filled(31, 1)),
        isFalse,
      );
      expect(
        () => RedJubJubBindingPrivateKey.fromBytes(List.filled(31, 1)),
        throwsA(isA<BuError>()),
      );
      expect(
        RedJubJubSpendPrivateKey.isValidBytes(List.filled(31, 1)),
        isFalse,
      );
      // 0xFF-filled u is out of range, so invalid (the canonical identity
      // encoding is accepted by binding fromBytes, covered in the zero test).
      final badPoint = List<int>.filled(32, 0xFF);
      expect(RedJubJubBindingPublicKey.isValidBytes(badPoint), isFalse);
      expect(
        () => RedJubJubBindingPublicKey.fromBytes(badPoint),
        throwsA(isA<BuError>()),
      );
      expect(
        RedJubJubSpendPublicKey.isValidKeyEncoding(
          List.filled(31, 1),
          CryptoKeyEncoding.base,
        ),
        isFalse,
      );
      expect(
        IPrivateKey.isValidBytes(
          List.filled(31, 1),
          CryptoKeyType.redJubJubBinding,
        ),
        isFalse,
      );
    });

    test('binding sign/verify round trip', () {
      final priv = RedJubJubBindingPrivateKey.fromBytes(_scalar(7));
      final message = 'redjubjub-binding'.codeUnits;
      final sig = priv.sign(RedJubJubSigningParams(message));
      expect(
        priv.publicKey.verify(RedJubJubVerifyingParams(message, sig)),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          RedJubJubVerifyingParams(
            message,
            ReddsaSignature.fromBytes(sig.toBytes()),
          ),
        ),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          RedJubJubVerifyingParams('tampered'.codeUnits, sig),
        ),
        isFalse,
      );
    });

    test('spend sign/verify round trip', () {
      final priv = RedJubJubSpendPrivateKey.fromBytes(_scalar(7));
      final message = 'redjubjub-spend'.codeUnits;
      final sig = priv.sign(RedJubJubSigningParams(message));
      expect(
        priv.publicKey.verify(RedJubJubVerifyingParams(message, sig)),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          RedJubJubVerifyingParams('tampered'.codeUnits, sig),
        ),
        isFalse,
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(redJubJubKeysTest, 'redjubjub keys');
}
