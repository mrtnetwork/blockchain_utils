import 'package:blockchain_utils/crypto/crypto/aead/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/aead/api/src/native.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/api/src/native.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/api/core/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/group.dart';
import 'package:blockchain_utils/crypto/crypto/group/ed25519/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/group/ed25519/api/src/native.dart';
import 'package:blockchain_utils/crypto/crypto/group/ristretto/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/group/ristretto/api/src/native.dart';
import 'package:blockchain_utils/crypto/crypto/hash/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/hash/api/src/native.dart';
import 'package:blockchain_utils/crypto/crypto/key_derivation/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/key_derivation/api/src/native.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/crypto/crypto/monero/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/monero/api/src/native.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/api/src/native.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/api/src/dart.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/api/src/native.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/api/src/native.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/api/src/native.dart';
import 'package:blockchain_utils/api/hw/hw.dart';
import 'package:blockchain_utils/api/sapling/sapling.dart';
import 'package:blockchain_utils/api/orchard/orchard.dart';
import 'package:blockchain_utils/api/merkle/merkle.dart';
import 'package:blockchain_utils/api/rng/rng.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Shared [BlockchainUtils] singleton used to access the configured backend.
final blockchainUtils = BlockchainUtils._();

/// Facade selecting the active [BlockchainUtilsApi] backend (Dart or Rust).
final class BlockchainUtils {
  BlockchainUtils._();
  late BlockchainUtilsApi _api = dartApi();

  /// The native backend instance held from the last [setRustApi], if any.
  ///
  /// One init, one instance: the connector no longer keeps a global, so the
  /// instance is owned here and handed to whoever needs direct native access.
  /// Cleared by [setDartApi].
  Bu? _backend;

  /// Currently selected backend.
  BlockchainUtilsApi get api => _api;

  /// Native backend instance from the last [setRustApi], or `null` on the
  /// pure-Dart backend. Prefer the typed `api.*` facades over this escape
  /// hatch.
  Bu? get backend => _backend;

  /// Whether a native backend is active (set via [setRustApi]).
  bool get hasNativeBackend => _backend != null;

  bool _sealed = false;

  /// Whether [seal] was called.
  bool get isSealed => _sealed;

  /// One-way latch: after [seal], [setApi], [setRustApi] and [setDartApi]
  /// throw. Call once during app startup, after the backend is selected, to
  /// prevent any later code (injected scripts, plugins) from silently
  /// swapping the crypto backend — e.g. for an exfiltrating fake whose
  /// `sign()` receives raw secret keys. Tests never seal, so backend
  /// switching keeps working there.
  void seal() => _sealed = true;

  void _checkNotSealed(String op) {
    if (_sealed) {
      throw BuError(
        DefaultErrorType.invalidState,
        'BlockchainUtils is sealed ($op blocked): backend can no longer '
        'be swapped.',
      );
    }
  }

  /// Groth16 proof verification (BLS12-381 + BN254, e.g. Sui zkLogin).
  ///
  /// Rust backend only (FFI on the VM, WASM in the browser): there is no
  /// pure-Dart pairing implementation. Throws [BuError] unless a
  /// native backend was selected via [setRustApi].
  BuGroth16Api get groth16 {
    final bu = _backend;
    if (bu == null) {
      throw BuError(
        DefaultErrorType.unsupported,
        'Groth16 needs the Rust backend: call '
        'blockchainUtils.setRustApi() (VM: BU_BACKEND=ffi, browser: wasm) '
        'before verifying proofs.',
      );
    }
    return bu.groth16;
  }

  /// Sets the active [BlockchainUtilsApi] implementation directly.
  void setApi(BlockchainUtilsApi api, {bool seal = false}) {
    _checkNotSealed('setApi');
    _api = api;
    if (seal) {
      this.seal();
    }
  }

  /// Selects the Rust backend via [Bu].
  ///
  /// Cross-platform safe: each platform reads only its own fields.
  /// - Native VM: [libraryPath] selects the dynamic library
  ///   (`DynamicLibrary.open`); `null` uses the platform default name.
  ///   The wasm fields are ignored.
  /// - Web: [wasmGlueUrl] selects the wasm-bindgen glue ES module
  ///   (default `wasm_assets/bu.js`, relative to the page), loaded with a
  ///   dynamic `import()`; [wasmModuleUrl] overrides the `.wasm` location
  ///   (`null` defaults to `bu_bg.wasm` next to the glue via the module's
  ///   `import.meta.url`, or a pre-set `globalThis.__bu_wasm_url`).
  ///   [libraryPath] is ignored. The glue must be a `--target web` build
  ///   (see `tool/build_backends.dart --wasm` in blockchain_utils_connector):
  ///   a `--target no-modules` classic script has no exports and fails to
  ///   load — no companion files are needed. Await `Bu.ensureWasmLoaded`
  ///   (see `BlockchainUtilsTestApi.initWasmBrowser`) before calling this
  ///   on web, as [Bu.init] alone does not fetch the module.
  void setRustApi({
    String? libraryPath,
    String? wasmGlueUrl,
    String? wasmModuleUrl,

    /// Route [QuickCrypto.generateRandom] through the backend RNG
    /// (seeded from Fortuna on first use). Pass `false` to keep the
    /// current generator (e.g. a custom one from `setupRandom`).
    bool randomFromBackend = true,

    bool seal = false,
  }) {
    _checkNotSealed('setRustApi');
    final bu = Bu.init(
      BuConfig(
        libraryPath: libraryPath,
        wasmGlueUrl: wasmGlueUrl,
        wasmModuleUrl: wasmModuleUrl,
      ),
    );
    final frostApi = NativeFrostApi(bu.frost);
    blockchainUtils.setApi(
      DefaultBlockchainUtilsApi(
        hash: NativeHashApi(bu.hash),
        blockCipher: NativeBlockCipherApi(bu.blockCipher),
        ff1: ValidatedFf1Api(NativeFf1Api(bu.ff1)),
        ed25519: NativeEd25519CurveApi(bu.curves.ed25519()),
        secp256k1: NativeSecp256k1CurveApi(bu.curves.secp256k1()),
        secp256r1: NativeSecp256r1CurveApi(bu.curves.secp256r1()),
        jubjub: NativeJubJubCurveApi(bu.curves.jubjub()),
        signing: DefaultBlockchainUtilsSigningApi(
          secp256k1: ValidatedSecp256k1SigningApi(
            NativeSecp256k1SigningApi(bu.secp256k1Signing),
          ),
          ed25519: NativeED25519SigningApi(bu.ed25519Signing),
          secp256r1: NativeSecp256r1SigningApi(bu.secp256r1Signing),
          bls: NativeBlsSigningApi(bu.blsSigning),
          mldsa: NativeMLDSASigningApi(bu.mlDsa),
          jubjub: NativeRedJubJubSigningApi(bu.reddsa),
          pallas: NativeRedPallasSigningApi(bu.reddsa),
          sr25519: NativeSr25519SigningApi(bu.sr25519),
        ),
        aed: NativeAEADApi(bu.aead),
        streamCipher: NativeStreamCipherApi(bu.streamCipher),
        keyDerivation: NativeKeyDerivationApi(bu.bindings),
        g1: NativeG1ProjectiveCurveApi(bu.curves.g1()),
        g2: NativeG2ProjectiveCurveApi(bu.curves.g2()),
        bn254G1: NativeBn254G1CurveApi(bu.curves.bn254G1()),
        bn254G2: NativeBn254G2CurveApi(bu.curves.bn254G2()),
        muSig2: NativeMuSig2Api(bu.musig2),
        frost: frostApi,
        dkls23: ValidatedDkls23KeysApi(NativeDkls23KeysApi(bu.dkls23)),
        pallas: NativePallasCurveApi(bu.curves.pallas()),
        vesta: NativeVestaCurveApi(bu.curves.vesta()),
        ristretto: NativeRistrettoCurveApi(bu.curves.ristretto()),
        x25519: NativeX25519Api(bu.x25519),
        monero: NativeMoneroApi(bu.monero),
        hw: NativeHwApi(bu.hw),
        sapling: NativeSaplingApi(bu.sapling),
        orchard: NativeOrchardApi(bu.orchard),
        merkle: NativeMerkleApi(bu.merkle),
        rng: NativeRngApi(bu.rng),
      ),
      seal: seal,
    );
    _backend = bu;
    if (randomFromBackend) QuickCrypto.setupBackendRng();
  }

  DefaultBlockchainUtilsApi dartApi() => DefaultBlockchainUtilsApi(
    hash: DartHashApi(),
    blockCipher: DartBlockCipherApi(),
    ff1: ValidatedFf1Api(DartFf1Api()),
    ed25519: DartEd25519CurveApi(),
    secp256k1: WeierstrassSecp256k1CurveApi(),
    secp256r1: WeierstrassSecp256r1CurveApi(),
    jubjub: DartJubJubCurveApi(),
    signing: DefaultBlockchainUtilsSigningApi(
      secp256k1: ValidatedSecp256k1SigningApi(DartSecp256k1SigningApi()),
      ed25519: DartED25519SigningApi(),
      secp256r1: DartSecp256r1SigningApi(),
      bls: DartBlsSigningApi(),
      mldsa: DartMLDSASigningApi(),
      jubjub: DartRedJubJubSigningApi(),
      pallas: DartRedPallasSigningApi(),
      sr25519: DartSr25519SigningApi(),
    ),
    aed: DartAEADApi(),
    streamCipher: DartStreamCipherApi(),
    keyDerivation: DartKeyDerivationApi(),
    g1: DartG1ProjectiveCurveApi(),
    g2: DartG2ProjectiveCurveApi(),
    bn254G1: DartBn254G1CurveApi(),
    bn254G2: DartBn254G2CurveApi(),
    muSig2: DartMuSig2Api(),
    frost: const DartFrostApi(),
    dkls23: const DartDkls23KeysApi(),
    pallas: DartPallasCurveApi(),
    vesta: DartVestaCurveApi(),
    ristretto: DartRistrettoCurveApi(),
    x25519: DartX25519Api(),
    monero: const DartMoneroApi(),
    hw: const DartHwApi(),
    sapling: const DartSaplingApi(),
    orchard: const DartOrchardApi(),
    merkle: const DartMerkleApi(),
    rng: const DartRngApi(),
  );

  /// Selects the pure-Dart backend; no native library or WASM setup required.
  void setDartApi({bool seal = false}) {
    _checkNotSealed('setDartApi');
    // Pure-Dart backend: no Bu.init / native library required.
    _backend = null;
    setApi(dartApi(), seal: seal);
    // The backend RNG only exists on native: restore the Fortuna default so
    // generateRandom keeps working after switching back from Rust.
    QuickCrypto.setupRandom(null);
  }
}
