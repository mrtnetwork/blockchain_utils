import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

/// Deterministic per-signature nonce ("k") generation for DSA/ECDSA, per
/// RFC 6979 (https://www.rfc-editor.org/rfc/rfc6979). Curve-agnostic: pass
/// the curve's order explicitly.
class RFC6979 {
  /// RFC 6979 §3.2 steps b–g: instantiates the HMAC-DRBG from the private
  /// key and the (padded) message digest, returning the (K, V) state that
  /// step h's candidate-generation loop starts from.
  ///
  /// Takes the already-padded message octets, so curve-specific entry
  /// points can reduce them with field arithmetic instead of a BigInt
  /// order.
  static (List<int> k, List<int> v) _instantiateWithOctets({
    required List<int> secexpBytes,
    required List<int> dataOctets,
    required CbHashFunc hashFunc,
    List<int>? extraEntropy,
  }) {
    final int holen;
    {
      final holenHash = hashFunc();
      try {
        holen = holenHash.getDigestLength;
      } finally {
        holenHash.clean();
      }
    }
    final List<List<int>> bx = [
      secexpBytes,
      dataOctets,
      extraEntropy ?? const [],
    ];

    List<int> v = List<int>.filled(holen, 0x01);
    List<int> k = List<int>.filled(holen, 0x00);

    HMAC hmac = HMAC(hashFunc, k);
    hmac.update([...v, 0x00]);
    for (final part in bx) {
      hmac.update(part);
    }
    k = hmac.digest();

    hmac.clean();
    hmac = HMAC(hashFunc, k);
    hmac.update(v);
    v = hmac.digest();

    hmac.clean();
    hmac = HMAC(hashFunc, k);
    hmac.update([...v, 0x01]);
    for (final part in bx) {
      hmac.update(part);
    }
    k = hmac.digest();

    hmac.clean();

    v = HMAC.hmac(hashFunc, k, v);
    return (k, v);
  }

  /// Generates a deterministic `k` mod n as raw 32-byte big-endian bytes —
  /// for callers that already work with fixed-width scalars.
  ///
  /// [secexp] must already be int2octets-encoded (padded to 32 bytes).
  /// Reduction uses field arithmetic only (no BigInt order).
  static List<int> generateSecp256k1KBytes({
    required List<int> secexp,
    required CbHashFunc hashFunc,
    required List<int> data,
    int retryGn = 0,
    List<int>? extraEntropy,
  }) {
    // Both secp256k1 and secp256r1 have 256-bit orders.
    const int rolen = 32;
    final base = Secp256k1Fr.from(Uint64(256));
    var dataAcc = Secp256k1Fr.zero;
    for (final byte in data) {
      dataAcc = dataAcc * base + Secp256k1Fr.from(Uint64(byte));
    }
    var (k, v) = _instantiateWithOctets(
      secexpBytes: secexp,
      dataOctets: dataAcc.toBytes(),
      hashFunc: hashFunc,
      extraEntropy: extraEntropy,
    );

    while (true) {
      List<int> t = [];
      while (t.length < rolen) {
        v = HMAC.hmac(hashFunc, k, v);
        t = [...t, ...v];
      }
      // set_b32 semantics: big-endian parse, reduced only by the range
      // check below (fromBytes throws on t >= order, accepts zero, which
      // is then explicitly rejected per RFC 6979: k must be in [1, q-1]).
      bool ok = false;
      try {
        ok = !Secp256k1Fr.fromBytes(t).isZero();
      } catch (_) {
        ok = false;
      }
      if (ok) {
        if (retryGn <= 0) {
          return t;
        }
        retryGn -= 1;
      }
      k = HMAC.hmac(hashFunc, k, [...v, 0x00]);
      v = HMAC.hmac(hashFunc, k, v);
    }
  }

  /// secp256r1 variant of [generateSecp256k1KBytes].
  static List<int> generateSecp256r1KBytes({
    required List<int> secexp,
    required CbHashFunc hashFunc,
    required List<int> data,
    int retryGn = 0,
    List<int>? extraEntropy,
  }) {
    const int rolen = 32;
    final base = Secp256r1Fr.from(Uint64(256));
    var dataAcc = Secp256r1Fr.zero;
    for (final byte in data) {
      dataAcc = dataAcc * base + Secp256r1Fr.from(Uint64(byte));
    }
    var (rk, rv) = _instantiateWithOctets(
      secexpBytes: secexp,
      dataOctets: dataAcc.toBytes(),
      hashFunc: hashFunc,
      extraEntropy: extraEntropy,
    );

    while (true) {
      List<int> tr = [];
      while (tr.length < rolen) {
        rv = HMAC.hmac(hashFunc, rk, rv);
        tr = [...tr, ...rv];
      }
      bool rOk = false;
      try {
        rOk = !Secp256r1Fr.fromBytes(tr).isZero();
      } catch (_) {
        rOk = false;
      }
      if (rOk) {
        if (retryGn <= 0) {
          return tr;
        }
        retryGn -= 1;
      }
      rk = HMAC.hmac(hashFunc, rk, [...rv, 0x00]);
      rv = HMAC.hmac(hashFunc, rk, rv);
    }
  }
}
