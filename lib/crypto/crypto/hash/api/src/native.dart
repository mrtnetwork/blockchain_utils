import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [HashApi] backed by a native (FFI/platform) implementation.
class NativeHashApi implements HashApi {
  final BuHashApi api;
  const NativeHashApi(this.api);

  @override
  BuSerializableHash<BuHashState> blake2b({
    int digestLength = 64,
    Blake2Config? config,
  }) {
    return api
        .blake2b(digestLength: digestLength, config: config)
        .unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> blake2s({
    int digestLength = 32,
    Blake2Config? config,
  }) {
    return api
        .blake2s(digestLength: digestLength, config: config)
        .unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> hmacSha256(List<int> key) {
    return api.hmacSha256(key).unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> hmacSha384(List<int> key) {
    return api.hmacSha384(key).unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> hmacSha512(List<int> key) {
    return api.hmacSha512(key).unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> keccak({int digestLength = 64}) {
    return api
        .keccack(digestLength: digestLength)
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes keccakF1600(BuBytes src) {
    return api.keccakF1600(src).unwrapOrThrowCryptoError().asBytes;
  }

  // -- Poseidon / Sinsemilla (moved from NativeZCryptoApi) --
  static BuBytes _packBits(List<bool> bits) {
    final n = (bits.length + 7) ~/ 8;
    final out = BuBytes.zero(n);
    for (var i = 0; i < bits.length; i++) {
      if (bits[i]) {
        out[i >> 3] |= 1 << (i & 7);
      }
    }
    return out;
  }

  static BuBytes? _optional(BuResult<BuBytes> res, String op) {
    if (!res.isErr) {
      return res.value;
    }
    // Semantic null only (Rust sinsemilla_null → rc 12 → invalidPoint)
    if (res.error!.type == DefaultErrorType.invalidPoint) {
      return null;
    }
    res.unwrapOrThrowCryptoError();
    throw CoreErrors.cryptoFailed(op, reason: 'Unreachable state.');
  }

  @override
  BuBytes pseudoRando({required List<int> nk, required List<int> rho}) {
    if (nk.length != 32 || rho.length != 32) {
      throw CoreErrors.cryptoFailed(
        'pseudoRando',
        reason: 'nk and rho must be 32-byte LE Fp',
      );
    }
    return api
        .poseidonHashTwo(a: nk.asBytes, b: rho.asBytes)
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes pedersenHash({
    required int personal,
    int layer = 0,
    required BuBytes packedBits,
    required int bitLen,
  }) {
    if (bitLen < 0 || (bitLen + 7) ~/ 8 > packedBits.length) {
      throw CoreErrors.pedersenFailed(
        "pedersenHash",
        reason: "bitLen exceeds packedBits length.",
      );
    }
    if (personal != 0 && personal != 1) {
      throw CoreErrors.pedersenFailed(
        "pedersenHash",
        reason: "Unknown Pedersen personalization id $personal.",
      );
    }
    return api
        .pedersenHash(
          personal: personal,
          layer: layer,
          packedBits: packedBits,
          bitLen: bitLen,
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes pedersenHashBitstring({
    required int personal,
    int layer = 0,
    required List<bool> bits,
  }) {
    final packed = BuBytes.zero((bits.length + 7) ~/ 8);
    for (var i = 0; i < bits.length; i++) {
      if (bits[i]) {
        packed[i >> 3] |= 1 << (i & 7);
      }
    }
    return pedersenHash(
      personal: personal,
      layer: layer,
      packedBits: packed,
      bitLen: bits.length,
    );
  }

  @override
  BuBytes poseidonBn254Hash(List<int> inputs) {
    if (inputs.length % 32 != 0 || inputs.isEmpty || inputs.length > 64 * 32) {
      throw CoreErrors.cryptoFailed(
        'poseidonBn254Hash',
        reason: 'inputs must be 1..64 concatenated 32-byte LE Fr elements',
      );
    }
    final n = inputs.length ~/ 32;
    final parts = List<BuBytes>.generate(
      n,
      (i) => inputs.sublist(i * 32, (i + 1) * 32).asBytes,
    );
    return api
        .poseidonBn254Hash(inputs: parts)
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes? sinsemillaShortCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = 'z.cash:Orchard-CommitIvk',
  }) {
    if (r.length != 32) {
      throw CoreErrors.cryptoFailed(
        'sinsemillaShortCommit',
        reason: 'r must be 32-byte LE Vesta Fq',
      );
    }
    return _optional(
      api.sinsemillaShortCommit(
        domain: domain,
        packedBits: _packBits(bits),
        bitLen: bits.length,
        r: r.asBytes,
      ),
      'sinsemillaShortCommit',
    );
  }

  @override
  BuBytes? sinsemillaCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = 'z.cash:Orchard-CommitIvk',
  }) {
    if (r.length != 32) {
      throw CoreErrors.cryptoFailed(
        'sinsemillaCommit',
        reason: 'r must be 32-byte LE Vesta Fq',
      );
    }
    return _optional(
      api.sinsemillaCommit(
        domain: domain,
        packedBits: _packBits(bits),
        bitLen: bits.length,
        r: r.asBytes,
      ),
      'sinsemillaCommit',
    );
  }

  @override
  BuSerializableHash<BuHashState> md4() {
    return api.md4().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> md5() {
    return api.md5().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> ripemd128() {
    return api.ripemd128().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> ripemd160() {
    return api.ripemd160().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> ripemd256() {
    return api.ripemd256().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> ripemd320() {
    return api.ripemd320().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> sha1() {
    return api.sha1().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> sha224() {
    return api.sha224().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> sha256() {
    return api.sha256().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> sha3({int digestLength = 32}) {
    return api
        .sha3(digestLength: digestLength)
        .unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> sha384() {
    return api.sha384().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> sha512() {
    return api.sha512().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> sha512256() {
    return api.sha512256().unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> shake128() {
    return api.shake128(digestLength: 32).unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> shake256() {
    return api.shake256(digestLength: 32).unwrapOrThrowCryptoError();
  }

  @override
  BuSerializableHash<BuHashState> xxHash({int bitLength = 64}) {
    return api.xxHash(bitLength: bitLength).unwrapOrThrowCryptoError();
  }
}
