import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

List<int> _bytes(int base, int len) =>
    List<int>.generate(len, (i) => (base + i) & 0xFF);

void _checkPubBase(
  IEd25519VerificationKey pub,
  bool Function(List<int>) isValidBytes,
  bool Function(List<int>, CryptoKeyEncoding) isValidEncoding,
  CryptoKeyType type,
) {
  // keyBytes must be the canonical 32-byte base encoding.
  expect(pub.keyBytes.length, Ed25519KeysConst.pubKeyByteLen);
  expect(pub.toBytes(), pub.keyBytes);
  expect(pub.toBytes(mode: CryptoKeyEncoding.base), pub.keyBytes);
  expect(isValidEncoding(pub.keyBytes, CryptoKeyEncoding.base), isTrue);
  expect(
    IPublicKey.isValidKeyEncoding(pub.keyBytes, type, CryptoKeyEncoding.base),
    isTrue,
  );
  expect(
    IPublicKey.isValidKeyEncoding(
      pub.keyBytes,
      type,
      CryptoKeyEncoding.uncompressed,
    ),
    isFalse,
  );
  expect(IPublicKey.isValidBytes(pub.keyBytes, type), isTrue);
  expect(isValidBytes(pub.keyBytes), isTrue);
  expect(IPublicKey.fromBytes(pub.keyBytes, type), pub);
}

void _checkSignVerify(
  IPrivateKey priv,
  IPublicKey pub,
  ED25519Signature Function(List<int>) sign,
  bool Function(ED25519Signature, List<int>) verify,
) {
  final message = _bytes(0xA0, 48);
  final sig = sign(message);
  expect(verify(sig, message), isTrue);
  expect(verify(ED25519Signature.fromBytes(sig.toBytes()), message), isTrue);
  expect(verify(sig, _bytes(0xB0, 48)), isFalse);
  final badSig = ED25519Signature.fromBytes(List.filled(64, 1));
  expect(verify(badSig, message), isFalse);
}

void ed25519KeysTest() {
  group('ed25519 keys', () {
    test('plain: fromBytes/toBytes + base encoding + sign/verify', () {
      final seed = _bytes(0x03, 32);
      final priv = ED25519PrivateKey.fromBytes(seed);
      expect(priv.type, CryptoKeyType.ed25519);
      expect(BytesUtils.bytesEqual(priv.toBytes(), seed), isTrue);
      _checkPubBase(
        priv.publicKey,
        ED25519PublicKey.isValidBytes,
        ED25519PublicKey.isValidKeyEncoding,
        CryptoKeyType.ed25519,
      );
      expect(
        ED25519PublicKey.fromBytes(priv.publicKey.keyBytes),
        priv.publicKey,
      );
      final viaIface = IPrivateKey.fromBytes(seed, CryptoKeyType.ed25519);
      expect(viaIface, isA<ED25519PrivateKey>());
      expect((viaIface as ED25519PrivateKey).publicKey, priv.publicKey);
      expect(ED25519PrivateKey.isValidBytes(seed), isTrue);
      final back = ED25519PrivateKey.fromBytes(priv.toBytes());
      expect(back.publicKey, priv.publicKey);
      _checkSignVerify(
        priv,
        priv.publicKey,
        (m) => priv.sign(Ed25519SigningParams(message: m)),
        (s, m) => priv.publicKey.verify(
          Ed25519VerifyingParams(Ed25519SigningParams(message: m), s),
        ),
      );
      // Expanded (seed||pub) form round trip.
      final expanded = priv.toExpandedBytes();
      final fromExpanded = ED25519PrivateKey.fromBytes(expanded);
      expect(fromExpanded.publicKey, priv.publicKey);
      expanded.zero();
    });

    test('blake2b: fromBytes/toBytes + base encoding + sign/verify', () {
      final seed = _bytes(0x05, 32);
      final priv = ED25519Blake2bPrivateKey.fromBytes(seed);
      expect(priv.type, CryptoKeyType.ed25519Blake2b);
      expect(BytesUtils.bytesEqual(priv.toBytes(), seed), isTrue);
      _checkPubBase(
        priv.publicKey,
        ED25519Blake2bPublicKey.isValidBytes,
        ED25519Blake2bPublicKey.isValidKeyEncoding,
        CryptoKeyType.ed25519Blake2b,
      );
      final viaIface = IPrivateKey.fromBytes(
        seed,
        CryptoKeyType.ed25519Blake2b,
      );
      expect(viaIface, isA<ED25519Blake2bPrivateKey>());
      expect((viaIface as ED25519Blake2bPrivateKey).publicKey, priv.publicKey);
      expect(ED25519Blake2bPrivateKey.isValidBytes(seed), isTrue);
      _checkSignVerify(
        priv,
        priv.publicKey,
        (m) => priv.sign(Ed25519SigningParams(message: m)),
        (s, m) => priv.publicKey.verify(
          Ed25519VerifyingParams(Ed25519SigningParams(message: m), s),
        ),
      );
    });

    test('kholaw: fromBytes/toBytes + base encoding + sign/verify', () {
      final seed = _bytes(0x07, 64);
      final priv = ED25519KholawPrivateKey.fromBytes(seed);
      expect(priv.type, CryptoKeyType.ed25519Kholaw);
      expect(BytesUtils.bytesEqual(priv.toBytes(), seed), isTrue);
      _checkPubBase(
        priv.publicKey,
        ED25519KholawPublicKey.isValidBytes,
        ED25519KholawPublicKey.isValidKeyEncoding,
        CryptoKeyType.ed25519Kholaw,
      );
      final viaIface = IPrivateKey.fromBytes(seed, CryptoKeyType.ed25519Kholaw);
      expect(viaIface, isA<ED25519KholawPrivateKey>());
      expect((viaIface as ED25519KholawPrivateKey).publicKey, priv.publicKey);
      expect(ED25519KholawPrivateKey.isValidBytes(seed), isTrue);
      expect(ED25519KholawPrivateKey.isValidBytes(_bytes(0x07, 32)), isFalse);
      _checkSignVerify(
        priv,
        priv.publicKey,
        (m) => priv.sign(Ed25519SigningParams(message: m)),
        (s, m) => priv.publicKey.verify(
          Ed25519VerifyingParams(Ed25519SigningParams(message: m), s),
        ),
      );
    });

    test('monero: fromBytes/toBytes + base encoding + sign/verify', () {
      // Monero secrets are little-endian scalars: keep the value small.
      final seed = List<int>.filled(32, 0)..[0] = 0x09;
      final priv = ED25519MoneroPrivateKey.fromBytes(seed);
      expect(priv.type, CryptoKeyType.ed25519Monero);
      expect(BytesUtils.bytesEqual(priv.toBytes(), seed), isTrue);
      _checkPubBase(
        priv.publicKey,
        ED25519MoneroPublicKey.isValidBytes,
        ED25519MoneroPublicKey.isValidKeyEncoding,
        CryptoKeyType.ed25519Monero,
      );
      final viaIface = IPrivateKey.fromBytes(seed, CryptoKeyType.ed25519Monero);
      expect(viaIface, isA<ED25519MoneroPrivateKey>());
      expect((viaIface as ED25519MoneroPrivateKey).publicKey, priv.publicKey);
      expect(ED25519MoneroPrivateKey.isValidBytes(seed), isTrue);
      // Zero secret maps to the identity key: strict fromBytes rejects it,
      // the lenient zero() constructor preserves it.
      expect(
        () => ED25519MoneroPrivateKey.fromBytes(List.filled(32, 0)),
        throwsA(isA<BuError>()),
      );
      expect(ED25519MoneroPrivateKey.zero().publicKey.keyBytes.length, 32);
      // NOTE: `sign` is not exercised here: the signing API contract takes
      // a 64-byte monero/kholaw secret while this key stores the 32-byte
      // scalar (monero keys are derivation-only in this repo). Verify path
      // is covered below: negative case plus a positive case with a
      // signature produced through the backend API from the 64-byte
      // `seed || zeros` expansion of the same secret.
      final message = _bytes(0xA0, 48);
      final sigBytes = blockchainUtils.api.signing.ed25519.sign(
        sk: [...seed, ...List<int>.filled(32, 0)],
        message: message,
        publicKey: priv.publicKey.keyBytes,
        type: CryptoKeyType.ed25519Monero,
      );
      expect(
        priv.publicKey.verify(
          Ed25519VerifyingParams(
            Ed25519SigningParams(message: message),
            ED25519Signature.fromBytes(sigBytes),
          ),
        ),
        isTrue,
      );
      expect(
        priv.publicKey.verify(
          Ed25519VerifyingParams(
            Ed25519SigningParams(message: message),
            ED25519Signature.fromBytes(List.filled(64, 1)),
          ),
        ),
        isFalse,
      );
    });

    test('invalid encodings', () {
      // 0xFF-filled y (2^255-1) is out of range, so invalid.
      final badPoint = List<int>.filled(32, 0xFF);
      expect(ED25519PublicKey.isValidBytes(badPoint), isFalse);
      expect(
        () => ED25519PublicKey.fromBytes(badPoint),
        throwsA(isA<BuError>()),
      );
      expect(
        ED25519PublicKey.isValidKeyEncoding(
          List.filled(31, 1),
          CryptoKeyEncoding.base,
        ),
        isFalse,
      );
      expect(ED25519PrivateKey.isValidBytes(List.filled(31, 1)), isFalse);
      expect(
        IPrivateKey.isValidBytes(List.filled(31, 1), CryptoKeyType.ed25519),
        isFalse,
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(ed25519KeysTest, 'ed25519 keys');
}
