import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

List<int> _scalar(int last) => List<int>.filled(32, 0)..[31] = last;

void _checkPubBase32(
  BaseRedPallasPublicKey pub,
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

void redPallasKeysTest() {
  group('redpallas keys', () {
    test('binding: fromBytes/toBytes + base encoding + randomize', () {
      final sk = _scalar(7);
      final r = _scalar(11);
      final priv = RedPallasBindingPrivateKey.fromBytes(sk);
      expect(priv.type, CryptoKeyType.redPallasBinding);
      expect(BytesUtils.bytesEqual(priv.toBytes(), sk), isTrue);
      _checkPubBase32(
        priv.publicKey,
        RedPallasBindingPublicKey.isValidKeyEncoding,
        CryptoKeyType.redPallasBinding,
      );
      expect(
        RedPallasBindingPublicKey.isValidBytes(priv.publicKey.keyBytes),
        isTrue,
      );
      expect(
        RedPallasBindingPublicKey.fromBytes(priv.publicKey.keyBytes),
        priv.publicKey,
      );
      final viaPriv = IPrivateKey.fromBytes(sk, CryptoKeyType.redPallasBinding);
      expect(viaPriv, isA<RedPallasBindingPrivateKey>());
      expect((viaPriv as RedPallasBindingPrivateKey).publicKey, priv.publicKey);
      expect(RedPallasBindingPrivateKey.isValidBytes(sk), isTrue);
      final back = RedPallasBindingPrivateKey.fromBytes(priv.toBytes());
      expect(back.publicKey, priv.publicKey);
      expect(
        priv.randomize(r).publicKey,
        RedPallasBindingPublicKey.fromBytes(
          priv.publicKey.keyBytes,
        ).randomize(r),
      );
      expect(
        RedPallasBindingPrivateKey.fromScalar(sk).publicKey,
        priv.publicKey,
      );
    });

    test('spend: fromBytes/toBytes + base encoding + randomize', () {
      final sk = _scalar(7);
      final r = _scalar(11);
      final priv = RedPallasSpendPrivateKey.fromBytes(sk);
      expect(priv.type, CryptoKeyType.redPallasSpend);
      expect(BytesUtils.bytesEqual(priv.toBytes(), sk), isTrue);
      _checkPubBase32(
        priv.publicKey,
        RedPallasSpendPublicKey.isValidKeyEncoding,
        CryptoKeyType.redPallasSpend,
      );
      expect(
        RedPallasSpendPublicKey.isValidBytes(priv.publicKey.keyBytes),
        isTrue,
      );
      expect(
        RedPallasSpendPublicKey.fromBytes(priv.publicKey.keyBytes),
        priv.publicKey,
      );
      final viaPriv = IPrivateKey.fromBytes(sk, CryptoKeyType.redPallasSpend);
      expect(viaPriv, isA<RedPallasSpendPrivateKey>());
      expect((viaPriv as RedPallasSpendPrivateKey).publicKey, priv.publicKey);
      expect(RedPallasSpendPrivateKey.isValidBytes(sk), isTrue);
      expect(RedPallasSpendPrivateKey.fromScalar(sk).publicKey, priv.publicKey);
      expect(
        priv.randomize(r).publicKey,
        RedPallasSpendPublicKey.fromBytes(priv.publicKey.keyBytes).randomize(r),
      );
    });

    test('zero: spend rejects, binding allows', () {
      final zero = List<int>.filled(32, 0);
      final identity = blockchainUtils.api.pallas.identity();
      // spend private/public must reject zero.
      expect(
        () => RedPallasSpendPrivateKey.fromScalar(zero),
        throwsA(isA<BuError>()),
      );
      expect(RedPallasSpendPrivateKey.isValidBytes(zero), isFalse);
      expect(
        () => RedPallasSpendPublicKey.fromBytes(identity),
        throwsA(isA<BuError>()),
      );
      expect(RedPallasSpendPublicKey.isValidBytes(identity), isFalse);
      // binding allows zero on both ends, with round-trip.
      final bpriv = RedPallasBindingPrivateKey.fromScalar(zero);
      expect(RedPallasBindingPrivateKey.isValidBytes(zero), isTrue);
      expect(bpriv.publicKey.keyBytes, identity);
      expect(
        RedPallasBindingPublicKey.isValidBytes(bpriv.publicKey.keyBytes),
        isTrue,
      );
      expect(
        RedPallasBindingPublicKey.fromBytes(bpriv.publicKey.keyBytes),
        bpriv.publicKey,
      );
      expect(RedPallasBindingPublicKey.fromBytes(identity), bpriv.publicKey);
    });

    test('invalid encodings', () {
      expect(
        RedPallasBindingPrivateKey.isValidBytes(List.filled(31, 1)),
        isFalse,
      );
      expect(
        () => RedPallasBindingPrivateKey.fromBytes(List.filled(31, 1)),
        throwsA(isA<BuError>()),
      );
      expect(
        RedPallasSpendPrivateKey.isValidBytes(List.filled(31, 1)),
        isFalse,
      );
      // 0xFF-filled encoding is out of range, so invalid (the all-zero
      // identity encoding is accepted by fromBytes, matching backend
      // semantics).
      final badPoint = List<int>.filled(32, 0xFF);
      expect(RedPallasBindingPublicKey.isValidBytes(badPoint), isFalse);
      expect(
        () => RedPallasBindingPublicKey.fromBytes(badPoint),
        throwsA(isA<BuError>()),
      );
      expect(
        RedPallasSpendPublicKey.isValidKeyEncoding(
          List.filled(31, 1),
          CryptoKeyEncoding.base,
        ),
        isFalse,
      );
      expect(
        IPrivateKey.isValidBytes(
          List.filled(31, 1),
          CryptoKeyType.redPallasBinding,
        ),
        isFalse,
      );
    });

    test('binding sign/verify round trip', () {
      final priv = RedPallasBindingPrivateKey.fromBytes(_scalar(7));
      final message = 'redpallas-binding'.codeUnits;
      final sig = priv.sign(RedPallasSigningParams(message));
      expect(
        priv.publicKey.verify(RedPallasVerifyingParams(message, sig)),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          RedPallasVerifyingParams(
            message,
            ReddsaSignature.fromBytes(sig.toBytes()),
          ),
        ),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          RedPallasVerifyingParams('tampered'.codeUnits, sig),
        ),
        isFalse,
      );
    });

    test('spend sign/verify round trip', () {
      final priv = RedPallasSpendPrivateKey.fromBytes(_scalar(7));
      final message = 'redpallas-spend'.codeUnits;
      final sig = priv.sign(RedPallasSigningParams(message));
      expect(
        priv.publicKey.verify(RedPallasVerifyingParams(message, sig)),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          RedPallasVerifyingParams('tampered'.codeUnits, sig),
        ),
        isFalse,
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(redPallasKeysTest, 'redpallas keys');
}
