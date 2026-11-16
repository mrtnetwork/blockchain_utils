import 'package:blockchain_utils/crypto/crypto/aead/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/aead/xsalsa20poly1305/salsa_box.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [AEADApi] backed by a native (FFI/platform) implementation.
class NativeAEADApi implements AEADApi {
  final BuAeadApi api;
  const NativeAEADApi(this.api);
  @override
  BuAead aesGCM(List<int> aesKey) {
    final aes = api.aesGcm(aesKey);
    return aes.unwrapOrThrowCryptoError();
  }

  @override
  BuAead chacha20Poly1305(List<int> key) {
    final result = api.chacha20Poly1305(key);
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuAead xsalsa20Poly1305(List<int> key) {
    final result = api.xsalsa20Poly1305(key);
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes salsaBoxBeforenm({
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    final result = api.salsaBoxBeforenm(
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes salsaBoxEncrypt(
    List<int> nonce,
    List<int> plaintext, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    final result = api.salsaBoxEncrypt(
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
      nonce: nonce,
      plaintext: plaintext,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes? salsaBoxDecrypt(
    List<int> nonce,
    List<int> sealed, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    final result = api.salsaBoxDecrypt(
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
      nonce: nonce,
      sealed: sealed,
    );
    // `ok(null)` = authentication failure (never throws on attacker input).
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes salsaBoxSeal(
    List<int> nonce,
    List<int> plaintext, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    final sealed = salsaBoxEncrypt(
      nonce,
      plaintext,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
    try {
      return BuBytes.concat([nonce, sealed]);
    } finally {
      sealed.forceZero();
    }
  }

  @override
  BuBytes? salsaBoxOpen(
    List<int> prefixed, {
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    // Nonce-prefixed framing is backend-independent: split here, open the
    // body through the native box.
    if (prefixed.length < SalsaBox.minPrefixedLength) {
      return null;
    }
    final nonce = prefixed.sublist(0, SalsaBox.nonceLength);
    final sealed = prefixed.sublist(SalsaBox.nonceLength);
    return salsaBoxDecrypt(
      nonce,
      sealed,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }
}
