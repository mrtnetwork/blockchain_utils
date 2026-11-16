import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/point/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [HashApi] backed by this package's pure-Dart hash implementations.
class DartHashApi implements HashApi {
  @override
  SerializableHash<Blake2State> blake2b({
    int digestLength = 64,
    Blake2Config? config,
  }) {
    return BLAKE2b(digestLength: digestLength, config: config);
  }

  @override
  SerializableHash<Blake2State> blake2s({
    int digestLength = 32,
    Blake2Config? config,
  }) {
    return BLAKE2s(digestLength: digestLength, config: config);
  }

  @override
  SerializableHash<SH1State> md4() {
    return MD4();
  }

  @override
  SerializableHash<SH1State> md5() {
    return MD5();
  }

  @override
  SerializableHash<SH1State> ripemd128() {
    return RIPEMD128();
  }

  @override
  SerializableHash<SH1State> ripemd160() {
    return RIPEMD160();
  }

  @override
  SerializableHash<SH1State> ripemd256() {
    return RIPEMD256();
  }

  @override
  SerializableHash<SH1State> ripemd320() {
    return RIPEMD320();
  }

  @override
  SerializableHash<SH1State> sha1() {
    return SHA1();
  }

  @override
  SerializableHash<SHA256State> sha224() {
    return SHA224();
  }

  @override
  SerializableHash<SHA256State> sha256() {
    return SHA256();
  }

  @override
  SerializableHash<KeccakState> sha3({int digestLength = 32}) {
    return SHA3(digestLength);
  }

  @override
  SerializableHash<SHA512State> sha384() {
    return SHA384();
  }

  @override
  SerializableHash<SHA512State> sha512() {
    return SHA512();
  }

  @override
  SerializableHash<SHA512State> sha512256() {
    return SHA512256();
  }

  @override
  SerializableHash<HashBytesState> xxHash({int bitLength = 64}) {
    return XXHash(bitLength: bitLength);
  }

  @override
  SerializableHash<KeccakState> keccak({int digestLength = 32}) {
    return Keccak(digestLength);
  }

  @override
  SerializableHash<KeccakState> shake128() {
    return SHAKE128();
  }

  @override
  SerializableHash<KeccakState> shake256() {
    return SHAKE256();
  }

  @override
  SerializableHash hmacSha256(List<int> key) {
    return HMAC(sha256, key);
  }

  @override
  SerializableHash hmacSha384(List<int> key) {
    return HMAC(sha384, key);
  }

  @override
  SerializableHash hmacSha512(List<int> key) {
    return HMAC(sha512, key);
  }

  @override
  BuBytes keccakF1600(BuBytes src) {
    return Keccak.keccakF1600(src);
  }

  // -- Poseidon / Sinsemilla (moved from DartZCryptoApi) --
  DartHashApi({
    List<PallasPoint>? sinsemillaS,
    PoseidonSpec<PallasFp>? poseidonSpec,
  }) : _sinsemillaS = sinsemillaS ?? SinsemillaConst.sPoints,
       _poseidonSpec = poseidonSpec ?? P128Pow5T3Fp();

  final List<PallasPoint> _sinsemillaS;
  final PoseidonSpec<PallasFp> _poseidonSpec;
  final Map<String, CommitDomain> _domains = {};

  PoseidonHash<PallasFp> get _poseidon => PoseidonHash(_poseidonSpec);

  CommitDomain _commitDomain(String domain) {
    return _domains[domain] ??= CommitDomain.create(
      domain,
      sinsemillaS: _sinsemillaS,
    );
  }

  @override
  BuBytes pseudoRando({required List<int> nk, required List<int> rho}) {
    final out = _poseidon.hash([
      PallasFp.fromBytes(nk),
      PallasFp.fromBytes(rho),
    ]);
    return out.toBytes();
  }

  @override
  BuBytes poseidonBn254Hash(List<int> inputs) {
    throw BuError(DefaultErrorType.unsupported, 'NativeHashApi.poseidonBn254Hash: pure-Dart backend has not support; '
          'use NativeHashApi via blockchainUtils.setRustApi().',
    );
  }

  @override
  BuBytes? sinsemillaShortCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = 'z.cash:Orchard-CommitIvk',
  }) {
    final x = _commitDomain(
      domain,
    ).shortCommit(msg: bits, r: VestaFq.fromBytes(r));
    return x?.toBytes();
  }

  @override
  BuBytes? sinsemillaCommit({
    required List<int> r,
    required List<bool> bits,
    String domain = 'z.cash:Orchard-CommitIvk',
  }) {
    final p = _commitDomain(domain).commit(msg: bits, r: VestaFq.fromBytes(r));
    return p?.toBytes();
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
    final bits = List<bool>.generate(
      bitLen,
      (i) => ((packedBits[i >> 3] >> (i & 7)) & 1) == 1,
    );
    return _pedersenHashBits(
      personalization: _pedersenPersonalization(personal, layer),
      bits: bits,
    );
  }

  @override
  BuBytes pedersenHashBitstring({
    required int personal,
    int layer = 0,
    required List<bool> bits,
  }) {
    return _pedersenHashBits(
      personalization: _pedersenPersonalization(personal, layer),
      bits: bits,
    );
  }

  static Personalization _pedersenPersonalization(int personal, int layer) {
    return switch (personal) {
      0 => const PersonalizationNoteCommitment(),
      1 => PersonalizationMerkleTree(layer),
      _ =>
        throw CoreErrors.pedersenFailed(
          "pedersenHash",
          reason: "Unknown Pedersen personalization id $personal.",
        ),
    };
  }

  static BuBytes _pedersenHashBits({
    required Personalization personalization,
    required List<bool> bits,
  }) {
    return PedersenHash()
        .hash(personalization: personalization, inputBits: bits)
        .toBytes();
  }
}
