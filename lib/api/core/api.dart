import 'package:blockchain_utils/crypto/crypto/aead/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/hash/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/key_derivation/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/dkls23/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redjubjub/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ml_dsa/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redpallas/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256r1/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/x25519/src/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/monero/api/src/api.dart';
import 'package:blockchain_utils/api/sapling/api.dart';
import 'package:blockchain_utils/api/orchard/api.dart';
import 'package:blockchain_utils/api/merkle/api.dart';
import 'package:blockchain_utils/api/rng/api.dart';
import 'package:blockchain_utils/api/hw/api.dart';

/// Unified entry point for all blockchain crypto subsystems.
abstract interface class BlockchainUtilsApi {
  /// Streaming/one-shot hashes (SHA-2, SHA-3, BLAKE2, Keccak, RIPEMD, MD, XOFs, Poseidon/Sinsemilla).
  abstract final HashApi hash;

  /// Signing operations grouped by signature scheme.
  abstract final BlockchainUtilsSigningApi signing;

  /// secp256k1 curve arithmetic.
  abstract final Secp256k1CurveApi secp256k1;

  /// secp256r1 (P-256) curve arithmetic.
  abstract final Secp256r1CurveApi secp256r1;

  /// JubJub curve arithmetic.
  abstract final JubJubCurveApi jubjub;

  /// Pallas curve arithmetic.
  abstract final PallasCurveApi pallas;

  /// Vesta curve arithmetic.
  abstract final VestaCurveApi vesta;

  /// BLS12-381 G1 curve arithmetic.
  abstract final G1ProjectiveCurveApi g1;

  /// BLS12-381 G2 curve arithmetic.
  abstract final G2ProjectiveCurveApi g2;

  /// BN254 G1 curve arithmetic.
  abstract final Bn254G1CurveApi bn254G1;

  /// BN254 G2 curve arithmetic.
  abstract final Bn254G2CurveApi bn254G2;

  /// Ed25519 curve arithmetic.
  abstract final Ed25519CurveApi ed25519;

  /// Block ciphers (AES and modes).
  abstract final BlockCipherApi blockCipher;

  /// FF1 format-preserving encryption.
  abstract final Ff1Api ff1;

  /// Authenticated encryption with associated data (AEAD).
  abstract final AEADApi aed;

  /// Stream ciphers (ChaCha20 and variants).
  abstract final StreamCipherApi streamCipher;

  /// Key derivation functions (HKDF, PBKDF2, etc.).
  abstract final KeyDerivationApi keyDerivation;

  /// MuSig2 multi-signature protocol.
  abstract final MuSig2Api muSig2;

  /// FROST threshold-signature protocol (secp256k1 + Ed25519).
  abstract final FrostApi frost;

  /// DKLs23 threshold ECDSA protocol.
  abstract final Dkls23KeysApi dkls23;

  /// Ristretto group arithmetic.
  abstract final RistrettoCurveApi ristretto;

  /// X25519 (RFC 7748) Diffie-Hellman.
  abstract final X25519Api x25519;

  /// Monero cryptography helpers.
  abstract final MoneroApi monero;

  /// Hardware wallet interface.
  abstract final HwApi hw;

  /// Zcash Sapling protocol helpers.
  abstract final SaplingApi sapling;

  /// Zcash Orchard protocol helpers.
  abstract final OrchardApi orchard;

  /// Merkle tree helpers.
  abstract final MerkleApi merkle;

  /// Random number generation.
  abstract final RngApi rng;
}

/// Grouped signing backends by signature scheme.
abstract interface class BlockchainUtilsSigningApi {
  /// secp256k1 signing (ECDSA/Schnorr).
  abstract final Secp256k1SigningApi secp256k1;

  /// Ed25519 signing.
  abstract final ED25519SigningApi ed25519;

  /// secp256r1 (P-256) signing.
  abstract final Secp256r1SigningApi secp256r1;

  /// BLS signing.
  abstract final BlsSigningApi bls;

  /// ML-DSA post-quantum signing.
  abstract final MLDSASigningApi mldsa;

  /// RedJubJub signing.
  abstract final RedJubJubSigningApi jubjub;

  /// RedPallas signing.
  abstract final RedPallasSigningApi pallas;

  /// Sr25519 signing.
  abstract final Sr25519SigningApi sr25519;
}

/// Default [BlockchainUtilsSigningApi] implementation wiring every scheme.
class DefaultBlockchainUtilsSigningApi implements BlockchainUtilsSigningApi {
  /// See [BlockchainUtilsSigningApi.secp256k1].
  @override
  final Secp256k1SigningApi secp256k1;

  /// See [BlockchainUtilsSigningApi.ed25519].
  @override
  final ED25519SigningApi ed25519;

  /// See [BlockchainUtilsSigningApi.secp256r1].
  @override
  final Secp256r1SigningApi secp256r1;

  /// See [BlockchainUtilsSigningApi.bls].
  @override
  final BlsSigningApi bls;

  /// See [BlockchainUtilsSigningApi.mldsa].
  @override
  final MLDSASigningApi mldsa;

  /// See [BlockchainUtilsSigningApi.jubjub].
  @override
  final RedJubJubSigningApi jubjub;

  /// See [BlockchainUtilsSigningApi.pallas].
  @override
  final RedPallasSigningApi pallas;

  /// See [BlockchainUtilsSigningApi.sr25519].
  @override
  final Sr25519SigningApi sr25519;
  const DefaultBlockchainUtilsSigningApi({
    required this.secp256k1,
    required this.ed25519,
    required this.secp256r1,
    required this.bls,
    required this.mldsa,
    required this.jubjub,
    required this.pallas,
    required this.sr25519,
  });
}

/// Default [BlockchainUtilsApi] implementation wiring every subsystem.
class DefaultBlockchainUtilsApi implements BlockchainUtilsApi {
  /// See [BlockchainUtilsApi.hash].
  @override
  final HashApi hash;

  /// See [BlockchainUtilsApi.secp256k1].
  @override
  final Secp256k1CurveApi secp256k1;

  /// See [BlockchainUtilsApi.secp256r1].
  @override
  final Secp256r1CurveApi secp256r1;

  /// See [BlockchainUtilsApi.ed25519].
  @override
  final Ed25519CurveApi ed25519;

  /// See [BlockchainUtilsApi.signing].
  @override
  final BlockchainUtilsSigningApi signing;

  /// See [BlockchainUtilsApi.blockCipher].
  @override
  final BlockCipherApi blockCipher;

  /// See [BlockchainUtilsApi.ff1].
  @override
  final Ff1Api ff1;

  /// See [BlockchainUtilsApi.aed].
  @override
  final AEADApi aed;

  /// See [BlockchainUtilsApi.streamCipher].
  @override
  final StreamCipherApi streamCipher;

  /// See [BlockchainUtilsApi.keyDerivation].
  @override
  final KeyDerivationApi keyDerivation;

  /// See [BlockchainUtilsApi.g1].
  @override
  final G1ProjectiveCurveApi g1;

  /// See [BlockchainUtilsApi.g2].
  @override
  final G2ProjectiveCurveApi g2;

  /// See [BlockchainUtilsApi.bn254G1].
  @override
  final Bn254G1CurveApi bn254G1;

  /// See [BlockchainUtilsApi.bn254G2].
  @override
  final Bn254G2CurveApi bn254G2;

  /// See [BlockchainUtilsApi.muSig2].
  @override
  final MuSig2Api muSig2;

  /// See [BlockchainUtilsApi.frost].
  @override
  final FrostApi frost;

  /// See [BlockchainUtilsApi.dkls23].
  @override
  final Dkls23KeysApi dkls23;

  /// See [BlockchainUtilsApi.jubjub].
  @override
  final JubJubCurveApi jubjub;

  /// See [BlockchainUtilsApi.pallas].
  @override
  final PallasCurveApi pallas;

  /// See [BlockchainUtilsApi.vesta].
  @override
  final VestaCurveApi vesta;

  /// See [BlockchainUtilsApi.ristretto].
  @override
  final RistrettoCurveApi ristretto;

  /// See [BlockchainUtilsApi.x25519].
  @override
  final X25519Api x25519;

  /// See [BlockchainUtilsApi.monero].
  @override
  final MoneroApi monero;

  /// See [BlockchainUtilsApi.hw].
  @override
  final HwApi hw;

  /// See [BlockchainUtilsApi.sapling].
  @override
  final SaplingApi sapling;

  /// See [BlockchainUtilsApi.orchard].
  @override
  final OrchardApi orchard;

  /// See [BlockchainUtilsApi.merkle].
  @override
  final MerkleApi merkle;

  /// See [BlockchainUtilsApi.rng].
  @override
  final RngApi rng;

  const DefaultBlockchainUtilsApi({
    required this.hash,
    required this.secp256k1,
    required this.secp256r1,
    required this.ed25519,
    required this.signing,
    required this.blockCipher,
    required this.ff1,
    required this.aed,
    required this.streamCipher,
    required this.keyDerivation,
    required this.g1,
    required this.g2,
    required this.bn254G1,
    required this.bn254G2,
    required this.muSig2,
    required this.frost,
    required this.dkls23,
    required this.jubjub,
    required this.pallas,
    required this.vesta,
    required this.ristretto,
    required this.x25519,
    required this.monero,
    required this.hw,
    required this.sapling,
    required this.orchard,
    required this.merkle,
    required this.rng,
  });
}
