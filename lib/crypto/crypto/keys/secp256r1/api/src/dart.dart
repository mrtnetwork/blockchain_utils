import 'package:blockchain_utils/crypto/crypto/keys/secp256r1/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

/// Pure-Dart secp256r1 signing/verification on [Secp256r1Point].
class DartSecp256r1SigningApi implements Secp256r1SigningApi {
  const DartSecp256r1SigningApi();
  @override
  IECDSASignature sign({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? extraEntropy,
  }) {
    List<int>? secret = sk.asBytes;
    try {
      final signature = Secp256r1EcdsaUtils.ecdsaSign(
        extraEntropy: extraEntropy,
        secret: secret,
        hashBytes: digest,
        pubKey: publicKey,
      );
      // Low-S normalize (matches the secp256k1 path and the Rust backend):
      // networks expect canonical `s <= n/2`; both forms verify, but only
      // low-S is consensus-accepted. Negating `s` preserves R (and hence
      // the recovery id).
      final s = Secp256r1Fr.fromBytes(signature.s);
      final neg = -s;
      final sBytes =
          BytesUtils.compareBytes(s.toBytes(), neg.toBytes()) <= 0
              ? s.toBytes()
              : neg.toBytes();
      return IECDSASignature(
        r: signature.r,
        s: sBytes,
        recoveryId: signature.recoveryId,
      );
    } finally {
      secret = null;
    }
  }

  @override
  bool verify({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  }) {
    final Secp256r1Point pubKeyPoint;
    try {
      pubKeyPoint = Secp256r1Point.fromBytes(publicKey);
    } catch (_) {
      return false;
    }
    return Secp256r1EcdsaUtils.ecdsaVerifySignature(
      signature: signature,
      hashBytes: digest,
      pubKeyPoint: pubKeyPoint,
    );
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    try {
      final point = Secp256r1Point.fromBytes(publicKey);
      if (point.isZero()) return null;
      return BuBytes.immutable(point.toBytes());
    } catch (_) {
      return null;
    }
  }
}
