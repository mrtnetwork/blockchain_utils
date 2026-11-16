import 'package:blockchain_utils/crypto/crypto/aead/api/src/api.dart'
    show AEADApi;
import 'package:blockchain_utils/crypto/crypto/aead/chacha20poly1305/chacha20poly1305.dart'
    show ChaCha20Poly1305;
import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/salsa_box.dart'
    show SalsaBox;
import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/xsalsa20poly1305.dart'
    show XSalsa20Poly1305;
import 'package:blockchain_utils/crypto/crypto/aead/gcm/gcm.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/aes.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [AEADApi] backed by the pure-Dart implementations in this package
/// ([GCM]/[AES], [ChaCha20Poly1305], [XSalsa20Poly1305]).
class DartAEADApi implements AEADApi {
  @override
  BuAead aesGCM(List<int> aesKey) {
    return GCM(AES(aesKey));
  }

  @override
  BuAead chacha20Poly1305(List<int> key) {
    return ChaCha20Poly1305(key);
  }

  @override
  BuAead xsalsa20Poly1305(List<int> key) {
    return XSalsa20Poly1305(key);
  }

  @override
  BuBytes salsaBoxBeforenm({
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    return SalsaBox.beforenm(
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  @override
  BuBytes salsaBoxEncrypt(
    List<int> nonce,
    List<int> plaintext, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    return SalsaBox.encrypt(
      nonce,
      plaintext,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  @override
  BuBytes? salsaBoxDecrypt(
    List<int> nonce,
    List<int> sealed, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    return SalsaBox.decrypt(
      nonce,
      sealed,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  @override
  BuBytes salsaBoxSeal(
    List<int> nonce,
    List<int> plaintext, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    return SalsaBox.seal(
      plaintext,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
      nonce: nonce,
    );
  }

  @override
  BuBytes? salsaBoxOpen(
    List<int> prefixed, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    return SalsaBox.open(
      prefixed,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }
}
