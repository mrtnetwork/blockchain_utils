import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constructs hash and HMAC instances for the supported algorithms.
abstract interface class HashApi {
  /// BLAKE2b with [digestLength] 1..64 bytes (default 64). Throws on out-of-range length.
  BuSerializableHash blake2b({int digestLength = 64, Blake2Config? config});

  /// BLAKE2s with [digestLength] 1..32 bytes (default 32). Throws on out-of-range length.
  BuSerializableHash blake2s({int digestLength = 32, Blake2Config? config});

  /// SHA-3 with [digestLength] 1..64 bytes (default 32). Throws on out-of-range length.
  BuSerializableHash sha3({int digestLength = 32});

  /// MD4, 16-byte digest.
  BuSerializableHash md4();

  /// MD5, 16-byte digest.
  BuSerializableHash md5();

  /// RIPEMD-320, 40-byte digest.
  BuSerializableHash ripemd320();

  /// RIPEMD-256, 32-byte digest.
  BuSerializableHash ripemd256();

  /// RIPEMD-160, 20-byte digest.
  BuSerializableHash ripemd160();

  /// RIPEMD-128, 16-byte digest.
  BuSerializableHash ripemd128();

  /// SHA-1, 20-byte digest.
  BuSerializableHash sha1();

  /// SHA-256, 32-byte digest.
  BuSerializableHash sha256();

  /// SHA-224, 28-byte digest.
  BuSerializableHash sha224();

  /// SHA-384, 48-byte digest.
  BuSerializableHash sha384();

  /// SHA-512, 64-byte digest.
  BuSerializableHash sha512();

  /// SHA-512/256, 32-byte digest.
  BuSerializableHash sha512256();

  /// XXHash with [bitLength] 64, 128 or 256 (default 64). Throws on other bit lengths.
  BuSerializableHash xxHash({int bitLength = 64});

  /// Keccak with [digestLength] 1..64 bytes (default 64 in interface, 32 in Dart backend). Throws on out-of-range length.
  BuSerializableHash keccak({int digestLength = 64});

  /// SHAKE128 extendable output.
  BuSerializableHash shake128();

  /// SHAKE256 extendable output.
  BuSerializableHash shake256();

  /// HMAC
  /// HMAC-SHA-256 with arbitrary-length [key].
  BuSerializableHash hmacSha256(List<int> key);

  /// HMAC-SHA-512 with arbitrary-length [key].
  BuSerializableHash hmacSha512(List<int> key);

  /// HMAC-SHA-384 with arbitrary-length [key].
  BuSerializableHash hmacSha384(List<int> key);

  /// Applies the Keccak-f[1600] permutation to 200-byte state [src]. Returns 200-byte state. Throws on crypto failure.
  BuBytes keccakF1600(BuBytes src);

  /// `PRF^nfOrchard(nk, ρ) := Poseidon(nk, ρ)` — LE Fp in/out (32 bytes).
  BuBytes pseudoRando({required List<int> nk, required List<int> rho});

  /// circomlib-compatible Poseidon over BN254 Fr (Sui zkLogin / Aptos
  /// keyless). [inputs] is concatenated 32-byte LE Fr elements (1..64);
  /// returns the 32-byte LE digest. Native backends built without the Rust
  /// `poseidon-bn254` feature throw unsupported.
  BuBytes poseidonBn254Hash(List<int> inputs);

  /// Sinsemilla shortCommit → LE Fp *x*, or `null` only when commit is undefined
  /// (Dart incomplete-point / Rust `sinsemilla_null`). Other failures throw.
  BuBytes? sinsemillaShortCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = 'z.cash:Orchard-CommitIvk',
  });

  /// Full Sinsemilla commit → Pasta compressed point, or `null` as above.
  BuBytes? sinsemillaCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = 'z.cash:Orchard-CommitIvk',
  });

  /// Pedersen hash over packed LSB-first bits → 32-byte Jubjub compressed.
  /// [personal] selects the generator set (`0` = note commitment,
  /// `1` = Merkle tree at [layer]); [bitLen] is the number of significant
  /// bits in [packedBits]. Routes to the active backend (pure-Dart
  /// PedersenHash, or native Rust). Throws on crypto failure.
  BuBytes pedersenHash({
    required int personal,
    int layer = 0,
    required BuBytes packedBits,
    required int bitLen,
  });

  /// Pedersen hash of a bit list. Same routing as [pedersenHash].
  BuBytes pedersenHashBitstring({
    required int personal,
    int layer = 0,
    required List<bool> bits,
  });
}

/// [HashApi] wrapper that validates arguments before delegating.
class ValidatedHashApi implements HashApi {
  final HashApi inner;
  const ValidatedHashApi(this.inner);

  @override
  BuSerializableHash<BuHashState> blake2b({
    int digestLength = 64,
    Blake2Config? config,
  }) {
    ApiValidate.digestLength(
      digestLength,
      operation: "blake2b",
      name: 'digestLength',
      min: 1,
      max: 64,
    );
    return inner.blake2b(config: config, digestLength: digestLength);
  }

  @override
  BuSerializableHash<BuHashState> blake2s({
    int digestLength = 32,
    Blake2Config? config,
  }) {
    ApiValidate.digestLength(
      digestLength,
      operation: "blake2s",
      name: 'digestLength',
      min: 1,
      max: 32,
    );
    return inner.blake2s(config: config, digestLength: digestLength);
  }

  @override
  BuSerializableHash<BuHashState> hmacSha256(List<int> key) {
    return inner.hmacSha256(key);
  }

  @override
  BuSerializableHash<BuHashState> hmacSha384(List<int> key) {
    return inner.hmacSha384(key);
  }

  @override
  BuSerializableHash<BuHashState> hmacSha512(List<int> key) {
    return inner.hmacSha512(key);
  }

  @override
  BuSerializableHash<BuHashState> keccak({int digestLength = 64}) {
    ApiValidate.digestLength(
      digestLength,
      operation: "keccak",
      name: 'digestLength',
      min: 1,
      max: 64,
    );
    return inner.keccak(digestLength: digestLength);
  }

  @override
  BuBytes keccakF1600(BuBytes src) {
    return inner.keccakF1600(src);
  }

  @override
  BuBytes pseudoRando({required List<int> nk, required List<int> rho}) {
    ApiValidate.length(nk, 32, operation: 'pseudoRando', name: 'nk');
    ApiValidate.length(rho, 32, operation: 'pseudoRando', name: 'rho');
    return inner.pseudoRando(nk: nk, rho: rho);
  }

  @override
  BuBytes poseidonBn254Hash(List<int> inputs) {
    if (inputs.length % 32 != 0) {
      throw CoreErrors.invalidOperationArguments(
        'poseidonBn254Hash',
        name: 'inputs',
        reason: 'Expected concatenated 32-byte elements.',
      );
    }
    final n = inputs.length ~/ 32;
    if (n < 1 || n > 64) {
      throw CoreErrors.invalidOperationArguments(
        'poseidonBn254Hash',
        name: 'inputs',
        reason: 'Expected 1..64 field elements, got $n.',
      );
    }
    return inner.poseidonBn254Hash(inputs);
  }

  @override
  BuBytes? sinsemillaShortCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = 'z.cash:Orchard-CommitIvk',
  }) {
    ApiValidate.length(r, 32, operation: 'sinsemillaShortCommit', name: 'r');
    return inner.sinsemillaShortCommit(r: r, bits: bits, domain: domain);
  }

  @override
  BuBytes? sinsemillaCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = 'z.cash:Orchard-CommitIvk',
  }) {
    ApiValidate.length(r, 32, operation: 'sinsemillaCommit', name: 'r');
    return inner.sinsemillaCommit(r: r, bits: bits, domain: domain);
  }

  @override
  BuBytes pedersenHash({
    required int personal,
    int layer = 0,
    required BuBytes packedBits,
    required int bitLen,
  }) {
    if (bitLen < 0 || (bitLen + 7) ~/ 8 > packedBits.length) {
      throw CoreErrors.invalidOperationArguments(
        "pedersenHash",
        name: "bitLen",
        reason: "bitLen exceeds packedBits length.",
      );
    }
    return inner.pedersenHash(
      personal: personal,
      layer: layer,
      packedBits: packedBits,
      bitLen: bitLen,
    );
  }

  @override
  BuBytes pedersenHashBitstring({
    required int personal,
    int layer = 0,
    required List<bool> bits,
  }) {
    return inner.pedersenHashBitstring(
      personal: personal,
      layer: layer,
      bits: bits,
    );
  }

  @override
  BuSerializableHash<BuHashState> md4() {
    return inner.md4();
  }

  @override
  BuSerializableHash<BuHashState> md5() {
    return inner.md5();
  }

  @override
  BuSerializableHash<BuHashState> ripemd128() {
    return inner.ripemd128();
  }

  @override
  BuSerializableHash<BuHashState> ripemd160() {
    return inner.ripemd160();
  }

  @override
  BuSerializableHash<BuHashState> ripemd256() {
    return inner.ripemd256();
  }

  @override
  BuSerializableHash<BuHashState> ripemd320() {
    return inner.ripemd320();
  }

  @override
  BuSerializableHash<BuHashState> sha1() {
    return inner.sha1();
  }

  @override
  BuSerializableHash<BuHashState> sha224() {
    return inner.sha224();
  }

  @override
  BuSerializableHash<BuHashState> sha256() {
    return inner.sha256();
  }

  @override
  BuSerializableHash<BuHashState> sha3({int digestLength = 32}) {
    ApiValidate.digestLength(
      digestLength,
      operation: "sha3",
      name: 'digestLength',
      min: 1,
      max: 64,
    );
    return inner.sha3();
  }

  @override
  BuSerializableHash<BuHashState> sha384() {
    return inner.sha384();
  }

  @override
  BuSerializableHash<BuHashState> sha512() {
    return inner.sha512();
  }

  @override
  BuSerializableHash<BuHashState> sha512256() {
    return inner.sha512256();
  }

  @override
  BuSerializableHash<BuHashState> shake128() {
    return inner.shake128();
  }

  @override
  BuSerializableHash<BuHashState> shake256() {
    return inner.shake256();
  }

  @override
  BuSerializableHash<BuHashState> xxHash({int bitLength = 64}) {
    final digestLength = (bitLength / 64).ceil() * 8;
    if (bitLength % 64 != 0 || ![8, 16, 32].contains(digestLength)) {
      throw CoreErrors.invalidOperationArguments(
        "XXHash",
        reason: "Invalid bitlength.",
      );
    }
    return inner.xxHash(bitLength: bitLength);
  }
}
