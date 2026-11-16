import 'package:blockchain_utils/crypto/crypto/keys/ml_dsa/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/ml.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Pure-Dart implementation of ML-DSA key generation/signing/verification.
class DartMLDSASigningApi implements MLDSASigningApi {
  @override
  (BuBytes, BuBytes) keygen({required int level, List<int>? seed}) {
    final params = MLDSAParams.fromLevel(level);
    final engine = MLDSA(params);
    final result = engine.keygen(seed);
    return (result.publicKey, result.secretKey.takeBytes());
  }

  @override
  BuBytes publicKeyFromSecret({int? level, required List<int> sk}) {
    final params = MLDSAParams.fromSecretKey(sk);
    final engine = MLDSA(params);
    final result = engine.publicKeyFromSecretKey(sk);
    return result;
  }

  @override
  BuBytes sign({
    int? level,
    required List<int> sk,
    required List<int> message,
    List<int>? context,
    List<int>? rnd,
  }) {
    final params = MLDSAParams.fromSecretKey(sk);
    final engine = MLDSA(params);
    final result = engine.sign(sk, message, context: context ?? [], rnd: rnd);
    return result;
  }

  @override
  bool verify({
    int? level,
    required List<int> pk,
    required List<int> message,
    required List<int> signature,
    List<int>? context,
  }) {
    final params = MLDSAParams.fromPublicKey(pk);
    final engine = MLDSA(params);
    final result = engine.verify(
      pk,
      message,
      signature,
      context: context ?? [],
    );
    return result;
  }
}
