import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [X25519Api] backed by the pure-Dart implementation in this package ([X25519]).
class DartX25519Api implements X25519Api {
  @override
  BuBytes diffieHellman({
    required List<int> privateKey,
    required List<int> peerPublic,
  }) {
    final x25519 = this.x25519(scalar: privateKey, u: peerPublic);
    if (x25519.isZero()) {
      throw CoreErrors.cryptoFailed("diffieHellman", reason: "Zero scalar.");
    }
    return x25519;
  }

  @override
  BuBytes x25519({required List<int> scalar, required List<int> u}) {
    return X25519.scalarMult(scalar, u);
  }

  @override
  BuBytes fromEd25519PublicKey(List<int> ed25519Pk) {
    return X25519.fromEd25519PublicKey(ed25519Pk);
  }

  @override
  BuBytes fromEd25519Seed(List<int> seed) {
    return X25519.fromEd25519Seed(seed);
  }

  @override
  BuBytes publicKey(List<int> privateKey) {
    final result = X25519Keypair.generate(seed: privateKey);
    return result.publicKey;
  }
}
