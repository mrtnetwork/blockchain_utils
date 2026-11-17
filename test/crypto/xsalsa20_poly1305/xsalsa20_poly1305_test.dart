import 'dart:convert';

import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/aead/api/src/api.dart';

import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/salsa20.dart';
import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/salsa_box.dart';
import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/session_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/xsalsa20poly1305.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void xsalsa20Poly1305Test() {
  group("XSalsa20-Poly1305 secretbox", () {
    test("tweetnacl golden vector framing holds for secretbox half", () {
      // The box ciphertext (after the 24-byte nonce prefix) must open with
      // the raw XSalsa20-Poly1305 transport key (beforenm), proving the
      // secretbox layer matches NaCl exactly.
      final sealed = BytesUtils.fromHexString(tweetnaclVectorHex);
      final nonce = sealed.sublist(0, 24);
      final boxCt = sealed.sublist(24);
      final sessionKey = SalsaBox.beforenm(
        peerPublicKey: BytesUtils.fromHexString(bobPubHex),
        secretKey: BytesUtils.fromHexString(aliceSecretHex),
      );
      final box = XSalsa20Poly1305(sessionKey);
      final plain = box.decrypt(nonce, boxCt);
      expect(plain, isNotNull);
      expect(utf8.decode(plain!), tweetnaclPlaintext);
    });

    test("secretbox round-trips incl. empty message", () {
      final key = QuickCrypto.generateRandom(length: 32);
      final box = QuickCrypto.xsalsa20Poly1305Instance(key);
      for (final len in [0, 1, 15, 16, 17, 64, 200]) {
        final pt = QuickCrypto.generateRandom(length: len);
        final nonce = QuickCrypto.generateRandom(length: 24);
        final sealed = box.encrypt(nonce, pt);
        expect(sealed.length, pt.length + box.tagLength);
        expect(box.decrypt(nonce, sealed), pt);
      }
    });

    test("tampered ciphertext fails closed", () {
      final key = QuickCrypto.generateRandom(length: 32);
      final box = QuickCrypto.xsalsa20Poly1305Instance(key);
      final nonce = QuickCrypto.generateRandom(length: 24);
      final sealed = box.encrypt(nonce, [1, 2, 3, 4]).toList();
      sealed[sealed.length - 1] ^= 1;
      expect(box.decrypt(nonce, sealed), isNull);
      sealed[sealed.length - 1] ^= 1;
      sealed[0] ^= 1;
      expect(box.decrypt(nonce, sealed), isNull);
    });

    test("wrong key and truncated input fail closed", () {
      final box = QuickCrypto.xsalsa20Poly1305Instance(
        QuickCrypto.generateRandom(length: 32),
      );
      final other = QuickCrypto.xsalsa20Poly1305Instance(
        QuickCrypto.generateRandom(length: 32),
      );
      final nonce = QuickCrypto.generateRandom(length: 24);
      final sealed = box.encrypt(nonce, utf8.encode("hello"));
      expect(other.decrypt(nonce, sealed), isNull);
      expect(box.decrypt(nonce, sealed.sublist(0, 10)), isNull);
    });

    test("nonce is strict 24 bytes, associated data rejected", () {
      final box = QuickCrypto.xsalsa20Poly1305Instance(
        QuickCrypto.generateRandom(length: 32),
      );
      expect(() => box.encrypt(List.filled(12, 0), [1]), throwsA(anything));
      expect(() => box.decrypt(List.filled(12, 0), [1]), throwsA(anything));
      expect(
        () => box.encrypt(List.filled(24, 0), [1], associatedData: [2]),
        throwsA(anything),
      );
      expect(
        () => QuickCrypto.xsalsa20Poly1305Instance(List.filled(31, 0)),
        throwsA(anything),
      );
    });

    test("seal/open prefixed framing round-trips", () {
      final key = QuickCrypto.generateRandom(length: 32);
      final box = XSalsa20Poly1305(key);
      final sealed = box.seal([9, 8, 7]);
      expect(sealed.length, 24 + 3 + 16);
      expect(box.open(sealed), [9, 8, 7]);
      expect(box.open(sealed.sublist(0, 39)), isNull);
    });
  });

  group("Salsa20 stream cipher", () {
    test("encrypt/decrypt round-trip with 8-byte nonce and seek", () {
      final key = QuickCrypto.generateRandom(length: 32);
      final cipher = Salsa20(key);
      final nonce = QuickCrypto.generateRandom(length: 8).toList();
      final pt = QuickCrypto.generateRandom(length: 200).toList();
      final ct = cipher.process(pt, nonce: nonce).toList();
      expect(ct, isNot(equals(pt)));
      expect(cipher.process(ct, nonce: nonce).toList(), pt);
      // Seek consistency: split decryption matches one-shot.
      final a =
          cipher
              .process(ct.sublist(0, 100), nonce: nonce, seekBytes: 0)
              .toList();
      final b =
          cipher
              .process(ct.sublist(100), nonce: nonce, seekBytes: 100)
              .toList();
      expect([...a, ...b], pt);
    });

    test("rejects bad key/nonce lengths", () {
      expect(() => Salsa20(List.filled(16, 0)), throwsA(anything));
      final cipher = Salsa20(List.filled(32, 0));
      expect(
        () => cipher.process([1], nonce: List.filled(12, 0)),
        throwsA(anything),
      );
    });

    test("hsalsa20 is 32 bytes and nonce-sensitive", () {
      final key = QuickCrypto.generateRandom(length: 32).toList();
      final n1 = List<int>.filled(16, 1);
      final n2 = List<int>.filled(16, 2);
      final k1 = Salsa20.hsalsa20(key, n1);
      final k2 = Salsa20.hsalsa20(key, n2);
      expect(k1.length, 32);
      expect(k1, isNot(equals(k2.toList())));
    });
  });

  group("SalsaBox (NaCl crypto_box)", () {
    test("pubkeys derive to golden values", () {
      final alice = SessionCrypto.generate(
        secretKey: BytesUtils.fromHexString(aliceSecretHex),
      );
      final bob = SessionCrypto.generate(
        secretKey: BytesUtils.fromHexString(bobSecretHex),
      );
      expect(alice.sessionId, alicePubHex);
      expect(bob.sessionId, bobPubHex);
    });

    test("tweetnacl golden vector encrypts byte-exact", () {
      final aliceSk = BytesUtils.fromHexString(aliceSecretHex);
      final bobPk = BytesUtils.fromHexString(bobPubHex);
      final nonce = BytesUtils.fromHexString(testNonceHex);
      final sealed = SalsaBox.seal(
        utf8.encode(tweetnaclPlaintext),
        peerPublicKey: bobPk,
        secretKey: aliceSk,
        nonce: nonce,
      );
      expect(sealed.toHex(), tweetnaclVectorHex);
      final alicePk = BytesUtils.fromHexString(alicePubHex);
      final bobSk = BytesUtils.fromHexString(bobSecretHex);
      final open = SalsaBox.open(
        sealed,
        peerPublicKey: alicePk,
        secretKey: bobSk,
      );
      expect(open, isNotNull);
      expect(utf8.decode(open!), tweetnaclPlaintext);
    });

    test("pytonconnect golden vector decrypts and re-encrypts", () {
      final raw = base64.decode(pyTonVectorB64);
      expect(raw.toHex(), startsWith(testNonceHex));
      final alicePk = BytesUtils.fromHexString(alicePubHex);
      final bobSk = BytesUtils.fromHexString(bobSecretHex);
      final open = SalsaBox.open(raw, peerPublicKey: alicePk, secretKey: bobSk);
      expect(open, isNotNull);
      expect(utf8.decode(open!), pyTonPlaintext);
      final aliceSk = BytesUtils.fromHexString(aliceSecretHex);
      final bobPk = BytesUtils.fromHexString(bobPubHex);
      final nonce = BytesUtils.fromHexString(testNonceHex);
      final sealed = SalsaBox.seal(
        utf8.encode(pyTonPlaintext),
        peerPublicKey: bobPk,
        secretKey: aliceSk,
        nonce: nonce,
      );
      expect(base64.encode(sealed), pyTonVectorB64);
    });

    test("tampered box fails closed", () {
      final aliceSk = BytesUtils.fromHexString(aliceSecretHex);
      final bobPk = BytesUtils.fromHexString(bobPubHex);
      final sealed =
          SalsaBox.seal(
            utf8.encode("request"),
            peerPublicKey: bobPk,
            secretKey: aliceSk,
            nonce: BytesUtils.fromHexString(testNonceHex),
          ).toList();
      sealed[sealed.length - 1] ^= 1;
      expect(
        SalsaBox.open(
          sealed,
          peerPublicKey: BytesUtils.fromHexString(alicePubHex),
          secretKey: BytesUtils.fromHexString(bobSecretHex),
        ),
        isNull,
      );
    });
  });

  group("SessionCrypto (TON Connect)", () {
    test("string message round-trip with random nonces", () {
      final dapp = SessionCrypto.generate();
      final wallet = SessionCrypto.generate();
      expect(dapp.sessionId.length, 64);
      expect(dapp.sessionId, isNot(equals(wallet.sessionId)));
      const message = '{"event":"connect","id":0}';
      final sealed = dapp.encrypt(wallet.publicKey, utf8.encode(message));
      expect(sealed.length, 24 + message.length + 16);
      expect(wallet.decryptString(dapp.publicKey, sealed), message);
      // Reverse direction works with the same keypairs.
      final reply = wallet.encryptString(dapp.publicKey, "ok");
      expect(dapp.decryptString(wallet.publicKey, reply), "ok");
    });

    test("base64 bridge helpers round-trip", () {
      final dapp = SessionCrypto.generate();
      final wallet = SessionCrypto.generate();
      final b64 = dapp.encryptToBase64(wallet.publicKey, "hello bridge");
      expect(wallet.decryptFromBase64(dapp.publicKey, b64), "hello bridge");
      expect(wallet.decryptFromBase64(dapp.publicKey, "!!!"), isNull);
    });

    test("session transport agrees with raw box on this backend", () {
      // SessionCrypto (via QuickCrypto → active backend) must interop with
      // the raw SalsaBox primitives in both directions.
      final dapp = SessionCrypto.generate();
      final wallet = SessionCrypto.generate();
      final walletSk = BytesUtils.fromHexString(
        wallet.stringifyKeypair().secretKey,
      );
      final sealed = dapp.encryptString(wallet.publicKey, "cross-path");
      final viaRaw = SalsaBox.open(
        sealed,
        peerPublicKey: dapp.publicKey,
        secretKey: walletSk,
      );
      expect(viaRaw, isNotNull);
      expect(utf8.decode(viaRaw!), "cross-path");
      // And the reverse: raw-sealed payload opens via the session.
      final rawSealed = SalsaBox.seal(
        utf8.encode("reverse-path"),
        peerPublicKey: dapp.publicKey,
        secretKey: walletSk,
      );
      expect(wallet.decryptString(dapp.publicKey, rawSealed), "reverse-path");
    });

    test("resume from persisted keypair, mismatch rejected", () {
      final original = SessionCrypto.generate();
      final persisted = original.stringifyKeypair();
      expect(persisted.publicKey.length, 64);
      expect(persisted.secretKey.length, 64);
      final restored = SessionCrypto.fromKeypair(
        publicKey: BytesUtils.fromHexString(persisted.publicKey),
        secretKey: BytesUtils.fromHexString(persisted.secretKey),
      );
      expect(restored.sessionId, original.sessionId);
      expect(
        () => SessionCrypto.fromKeypair(
          publicKey: List<int>.filled(32, 0),
          secretKey: BytesUtils.fromHexString(persisted.secretKey),
        ),
        throwsA(anything),
      );
    });

    test("QuickCrypto box helpers agree with SalsaBox", () {
      final aliceSk = BytesUtils.fromHexString(aliceSecretHex).toList();
      final bobPk = BytesUtils.fromHexString(bobPubHex).toList();
      final nonce = BytesUtils.fromHexString(testNonceHex).toList();
      final sealed = QuickCrypto.salsaBoxSeal(
        peerPublicKey: bobPk,
        secretKey: aliceSk,
        plainText: utf8.encode(tweetnaclPlaintext),
        nonce: nonce,
      );
      expect(sealed.toHex(), tweetnaclVectorHex);
      final open = QuickCrypto.salsaBoxOpen(
        peerPublicKey: BytesUtils.fromHexString(alicePubHex).toList(),
        secretKey: BytesUtils.fromHexString(bobSecretHex).toList(),
        sealed: sealed,
      );
      expect(open, isNotNull);
      expect(utf8.decode(open!), tweetnaclPlaintext);
    });

    test("QuickCrypto detached box + beforenm quick calls", () {
      final aliceSk = BytesUtils.fromHexString(aliceSecretHex).toList();
      final bobPk = BytesUtils.fromHexString(bobPubHex).toList();
      final nonce = BytesUtils.fromHexString(testNonceHex).toList();
      final transport = QuickCrypto.salsaBoxBeforenm(
        peerPublicKey: bobPk,
        secretKey: aliceSk,
      );
      expect(transport.length, 32);
      final sealed = QuickCrypto.salsaBoxEncrypt(
        peerPublicKey: bobPk,
        secretKey: aliceSk,
        nonce: nonce,
        plainText: utf8.encode(tweetnaclPlaintext),
      );
      // Detached box body equals the golden prefixed body after the nonce.
      final golden = BytesUtils.fromHexString(tweetnaclVectorHex);
      expect(sealed.toList(), golden.sublist(24));
      final open = QuickCrypto.salsaBoxDecrypt(
        peerPublicKey: BytesUtils.fromHexString(alicePubHex).toList(),
        secretKey: BytesUtils.fromHexString(bobSecretHex).toList(),
        nonce: nonce,
        sealed: sealed,
      );
      expect(open, isNotNull);
      expect(utf8.decode(open!), tweetnaclPlaintext);
    });
  });

  group("AEADApi box routing (double backend)", () {
    test("backend-routed seal matches the golden vector", () {
      final sealed = blockchainUtils.api.aed.salsaBoxSeal(
        BytesUtils.fromHexString(testNonceHex),
        utf8.encode(tweetnaclPlaintext),
        peerPublicKey: BytesUtils.fromHexString(bobPubHex),
        secretKey: BytesUtils.fromHexString(aliceSecretHex),
      );
      expect(sealed.toHex(), tweetnaclVectorHex);
      final open = blockchainUtils.api.aed.salsaBoxOpen(
        sealed,
        peerPublicKey: BytesUtils.fromHexString(alicePubHex),
        secretKey: BytesUtils.fromHexString(bobSecretHex),
      );
      expect(open, isNotNull);
      expect(utf8.decode(open!), tweetnaclPlaintext);
    });

    test("backend-routed beforenm/detached round-trip", () {
      final aed = blockchainUtils.api.aed;
      final aliceSk = BytesUtils.fromHexString(aliceSecretHex).toList();
      final bobPk = BytesUtils.fromHexString(bobPubHex).toList();
      final viaApi = aed.salsaBoxBeforenm(
        peerPublicKey: bobPk,
        secretKey: aliceSk,
      );
      final direct = SalsaBox.beforenm(
        peerPublicKey: bobPk,
        secretKey: aliceSk,
      );
      expect(viaApi.toList(), direct.toList());
      final nonce = QuickCrypto.generateRandom(length: 24).toList();
      final pt = QuickCrypto.generateRandom(length: 77).toList();
      final sealed = aed.salsaBoxEncrypt(
        nonce,
        pt,
        peerPublicKey: bobPk,
        secretKey: aliceSk,
      );
      expect(sealed.length, pt.length + 16);
      final open = aed.salsaBoxDecrypt(
        nonce,
        sealed,
        peerPublicKey: BytesUtils.fromHexString(alicePubHex).toList(),
        secretKey: BytesUtils.fromHexString(bobSecretHex).toList(),
      );
      expect(open?.toList(), pt);
    });

    test("ValidatedAEADApi guards box arguments", () {
      final aed = ValidatedAEADApi(blockchainUtils.api.aed);
      final goodNonce = List<int>.filled(24, 7);
      final goodKey = List<int>.generate(32, (i) => i + 1);
      expect(
        () => aed.salsaBoxSeal(
          List<int>.filled(12, 0),
          [1],
          peerPublicKey: goodKey,
          secretKey: goodKey,
        ),
        throwsA(anything),
      );
      expect(
        () => aed.salsaBoxBeforenm(
          peerPublicKey: List<int>.filled(31, 0),
          secretKey: goodKey,
        ),
        throwsA(anything),
      );
      // Truncated prefixed input opens to null, never throws.
      expect(
        aed.salsaBoxOpen(
          List<int>.filled(10, 0),
          peerPublicKey: goodKey,
          secretKey: goodKey,
        ),
        isNull,
      );
      // Well-formed input passes validation and round-trips.
      final sealed = aed.salsaBoxSeal(
        goodNonce,
        [1, 2, 3],
        peerPublicKey: goodKey,
        secretKey: goodKey,
      );
      expect(sealed.length, 24 + 3 + 16);
      expect(
        aed
            .salsaBoxOpen(sealed, peerPublicKey: goodKey, secretKey: goodKey)
            ?.toList(),
        [1, 2, 3],
      );
      // Zero peer key is rejected by the box itself (zero shared secret).
      expect(
        () => aed.salsaBoxBeforenm(
          peerPublicKey: List<int>.filled(32, 0),
          secretKey: goodKey,
        ),
        throwsA(anything),
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(
    xsalsa20Poly1305Test,
    "XSalsa20-Poly1305 / SalsaBox / SessionCrypto",
  );
}
