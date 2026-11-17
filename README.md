# blockchain_utils

Pure-Dart cryptography + blockchain toolkit with an optional Rust backend behind one typed API.

- **Dual backend, one API:** pure Dart by default, Rust (`FFI` on VM, `WASM` in browser) for speed. Switch at runtime with `blockchainUtils.setRustApi()` / `setDartApi()`. All crypto goes through `blockchainUtils.api.*`.
- **Zero-dependency Rust core:** `no_std`-compatible, constant-time primitives, maintained at [mrtnetwork/blockchain-utils](https://github.com/mrtnetwork/blockchain-utils). Dart FFI and wasm-bindgen glue are generated from `blockchain_utils_connector` (`tool/build_backends.dart`).
- **Cross-platform:** iOS, Android, Web, Linux, Windows, macOS.
- **No external crypto dependencies** in the Dart core.

Inspired in part by [bip_utils](https://github.com/ebellocchia/bip_utils), [python-ecdsa](https://github.com/tlsfuzzer/python-ecdsa), [schnorrkel](https://github.com/w3f/schnorrkel), [stablelib](https://github.com/StableLib/stablelib), [strobe](https://github.com/rozbb/strobe-rs).

> Legacy docs/tests for the old pure-Dart-only releases live in git history and in
> [mrtnetwork/blockchain_utils](https://github.com/mrtnetwork/blockchain_utils) before the dual-backend rewrite.
> If you are migrating from `<8.0.0`, read [Breaking changes](#breaking-changes) first.

## Quick start

```dart
import 'package:blockchain_utils/blockchain_utils.dart';

void main() {
  // Default: pure-Dart backend. Nothing to init.
  final digest = QuickCrypto.sha256Hash([1, 2, 3]);
  print(digest.toHex());
}
```

Use the typed backend API instead of static helpers when you care which backend runs:

```dart
final api = blockchainUtils.api;
final h = api.hash.sha256()
  ..update([1, 2, 3]);
final digest = h.digest().asBytes;
h.clean();
```

### Rust backend (FFI on VM, WASM on web)

```dart
import 'package:blockchain_utils/blockchain_utils.dart';

Future<void> main() async {
  // Native VM: loads the platform dynamic library.
  // Web: loads wasm-bindgen glue (default `wasm_assets/bu.js`).
  // Await WASM module load first on web (see BlockchainUtilsTestApi.initWasmBrowser).
  blockchainUtils.setRustApi();
  print(blockchainUtils.hasNativeBackend); // true

  final sig = blockchainUtils.api.signing.secp256k1.sign(
    privateKey: privateKeyBytes,
    messageHash: hash32,
  );
}
```

Lock the backend at startup in production apps so injected code cannot swap it:

```dart
blockchainUtils.setRustApi(seal: true);
// or: blockchainUtils.setDartApi(seal: true);
// or: blockchainUtils.setApi(myApi, seal: true);
```

Notes:

- `blockchainUtils.backend` exposes the raw `Bu` instance (escape hatch; prefer `api.*`).
- `blockchainUtils.groth16` is **Rust-only** (no pure-Dart pairing). It throws `BuError` on the Dart backend.
- `QuickCrypto.generateRandom` can be routed through the backend RNG with `randomFromBackend: true` (default in `setRustApi`). When the Rust backend is set, all high-level APIs (`QuickCrypto`, keys, signing, ciphers, hashes, KDFs, protocol helpers) run through Rust.

## Breaking changes

If you come from the old pure-Dart-only `blockchain_utils` releases:

1. **Dual backend is the architecture now.** Crypto no longer lives only in static Dart classes. The supported entry point is `blockchainUtils.api.*` (`hash`, `signing`, `secp256k1`, `blockCipher`, `aed`, `keyDerivation`, `monero`, `sapling`, `orchard`, `merkle`, `hw`, `rng`, ...). `QuickCrypto` helpers delegate to the active backend.
2. **Connector split.** Shared types (`BuBytes`, `SecretBytes`, `BuHashApi`, `BuError`, `BuConfig`, Monero scan types, ...) now come from `blockchain_utils_connector`. Imports of internal paths may need updating.
3. **`BigInt` replaced by fixed `Uint64` arithmetic** in CryptoOps, Secp256k1, JubJub, BLS12-381, Pasta curves (v7). Faster, but low-level numeric APIs changed.
4. **CBOR is strict.** No migration/fallback for old payloads. `CborListValue` / `CborMapValue` constructors renamed (`fixedLength` -> `definite`, `dynamicLength` -> `indefinite`) and only accept `CborValue`. Nullable fields use `rawValueAt<T?>`, not `maybeRawValueAt` / `maybeObjectAt`.
5. **`SecretWallet` renamed** to `Web3SecretStorageDefinitionV3` (encrypt/decrypt bytes, Ethereum keystore compatible).
6. **Hex / hashing fast paths changed** (performance rewrite); behavior is identical but do not depend on internal functions.
7. **Rust-only features throw on Dart.** Groth16 verification (BLS12-381 / BN254, e.g. Sui zkLogin) requires `setRustApi()`; the Dart backend throws `unsupported`.
8. **Backend sealing.** New `seal()` one-way latch blocks later `setApi` / `setRustApi` / `setDartApi`. Tests never seal.
9. **Minimum SDK `>=3.7.0`**, unified service/provider architecture, constant-time private-key and signing paths (except secp256r1), ported Bitcoin secp256k1.
10. **Hardware-wallet flow is API-driven** (`HwApi`, `HwCatalog`, readiness tables) with Rust `hw` message codecs (APDU / Trezor / UR / PSBT); transport stays injected (`USB-HID/BLE/NFC` native, WebHID/WebUSB on web). Currently **simulation-tested only — not verified with real devices**.

## Backend support

Same typed API on both backends unless noted.

| Area | Pure Dart (default) | Rust (`setRustApi`) |
|---|---|---|
| Hash, HMAC, XOFs | ✅ | ✅ (faster) |
| Curves / signing (secp256k1, secp256r1, Ed25519, BLS, ML-DSA, RedDSA, sr25519) | ✅ | ✅ (constant-time, faster) |
| Ciphers / AEAD / KDF / RNG | ✅ | ✅ |
| MuSig2 / FROST / DKLs23 | ✅ | ✅ |
| Sapling / Orchard / Merkle | ✅ | ✅ |
| Monero helpers / RingCT | ✅ | ✅ |
| Hardware-wallet codecs | ✅ | ✅ |
| Groth16 prove/verify (BLS12-381, BN254) | ❌ throws `unsupported` | ✅ (needs `groth16` / `groth16-prover` features) |
| `blockchainUtils.backend` (`Bu`) | `null` | active instance |

Build flavors: default = `std + halo2 + groth16 + ffi + monero`; `no_std + alloc` supported; `--features multicore` for parallel MSM/FFT prove; `--target web` glue for browsers (`tool/build_backends.dart --wasm`).

## Supported tables

Legend: ✅ supported on both backends unless a note says Rust-only.

### Hash / MAC / XOF

| Primitive | Notes |
|---|---|
| SHA-1, SHA-224, SHA-256, SHA-384, SHA-512, SHA-512/256 | streaming via `api.hash.*` |
| SHA-3 (224/256/384/512), SHAKE128, SHAKE256 | variable digest supported |
| Keccak + `keccakF1600` | |
| BLAKE2b / BLAKE2s | keyed, salt, personalization |
| MD4, MD5 | legacy interop only |
| RIPEMD-128/160/256/320, `hash160` | |
| HMAC-SHA-256/384/512 | |
| XXHash (64/128/256), CRC16/CRC32/XModem | checksums |
| Poseidon (BN254, circomlib-compatible), Poseidon Orchard, Sinsemilla commit/short-commit, Pedersen hash, `pseudoRando` | Zcash / zkLogin paths |

### Ciphers / AEAD / KDF / RNG

| Primitive | Notes |
|---|---|
| AES (ECB, CBC, CTR), paddings | via `api.blockCipher` |
| ChaCha20, XChaCha20, XSalsa20-Poly1305, ChaCha20-Poly1305, AES-GCM | via `api.aed` / `api.streamCipher` |
| FF1 (format-preserving), F4Jumble | |
| PBKDF2 (SHA-256/512), scrypt, HKDF | via `api.keyDerivation` |
| X25519, ECDH helpers | |
| Fortuna-seeded RNG (`api.rng`, `QuickCrypto.generateRandom`) | `randomFromBackend` opt-in on Rust |
| JWT, Strobe, Merlin transcripts | `crypto/protocol` |

### Curves and signing

| Scheme | Sign / verify | Curve arithmetic |
|---|---|---|
| secp256k1 ECDSA + Schnorr (incl. BIP-340, MuSig2, FROST) | ✅ | ✅ |
| secp256r1 (P-256) ECDSA | ✅ | ✅ |
| Ed25519 / Ed25519-kholaw, Ristretto, X25519 | ✅ | ✅ |
| sr25519 (Schnorrkel), VRF sign/verify | ✅ | ✅ |
| BLS12-381 (min-pubkey / min-sig), EIP-2333/2334 | ✅ | G1/G2 ✅ |
| BN254 G1/G2 | ✅ (verify paths) | ✅ |
| JubJub + RedJubJub (RedDSA) | ✅ | ✅ |
| Pallas/Vesta + RedPallas, Pasta IPA | ✅ | ✅ |
| ML-DSA-65 (+ NEP-649 paths for NEAR) | ✅ | — |
| DKLs23 threshold ECDSA | ✅ | — |

Chain transaction signers: Bitcoin (ECDSA/Schnorr, incl. BCH Schnorr), Litecoin, Dogecoin, Dash, BSV, Ethereum/EVM, Tron, Solana, XRP (ECDSA/Ed25519), Cardano, Cosmos-style chains, Substrate (ECDSA/Ed25519/sr25519).

### Threshold / multi-party / ZK helpers

| Protocol | Dart | Rust |
|---|---|---|
| MuSig2 (nonce / aggregate / sign / verify) | ✅ | ✅ |
| FROST (secp256k1 + Ed25519) | ✅ | ✅ |
| DKLs23 threshold ECDSA | ✅ | ✅ |
| Groth16 verifier (BLS12-381, BN254) | ❌ | ✅ |
| Halo2 core (Pasta IPA) for Orchard path | ✅ | ✅ |
| Sapling + Orchard notes/nullifiers/commitments, Merkle trees | ✅ | ✅ |
| Solana ZK (ElGamal / proofs, via `solana_zk`) | ✅ | ✅ |

### Encodings

| Codec |
|---|
| Hex, Base32, Base58 (+Base58-XMR), Base58Check, Base64, Base64-URL |
| Bech32 / Bech32m, SegWit Bech32, CashAddr (BCH) |
| SS58 (Substrate) |
| DER, CBOR (definite/indefinite, tags, bigfloat/bigint/datetime), JSON, UTF-8, double codec |
| Layout / buffer reader-writer, Proto codec (+ google well-known types) |
| UUIDv4, Web3 Secret Storage V3, WIF, BIP38 paper wallets |

### Addresses

Bitcoin `P2PKH / P2SH / P2WPKH / P2TR`, BCH CashAddr, Litecoin/Doge/Dash/BSV variants, Ethereum/EVM (incl. checksummed), Tron, Solana, XRP (classic + X-address), Cardano Shelley/Byron (enterprise/base/reward/pointer), Cosmos/Injective/THOR-style Bech32, Substrate SS58, Polkadot/Kusama-compatible, NEAR (incl. implicit), Nano, Algorand, Aptos (incl. secp256k1/secp256r1/multikey/multi-Ed25519), Sui (secp256k1/secp256r1/Ed25519/multisig), Stellar (incl. contract), Ton, Ripple, Tezos (`tz1/tz2/tz3`), Monero (standard/integrated/subaddress), Zcash transparent + shielded (see below), Filecoin, EOS, Elrond/MultiversX, Avalanche, Harmony ONE, OKEx, Neo, ICON, Ergo, Zilliqa, plus SLIP-173 / Bech32 HRP tables.

### HD wallets / mnemonics / derivation

| Standard | Support |
|---|---|
| BIP-39 (generation, validation, seed, 12/15/18/21/24 words, passphrases, multi-language) | ✅ |
| BIP-32 (multi-curve: secp256k1, secp256r1, Ed25519, sr25519 flows) | ✅ |
| SLIP-10, SLIP-32, SLIP-44 registry | ✅ |
| BIP-44 / BIP-49 / BIP-84 / BIP-86 account hierarchies + coin configs (hundreds of coins) | ✅ |
| Electrum V1 / V2 (segwit + standard) | ✅ |
| Monero mnemonic (25-word, seed, subaddresses) + Monero keys/addresses | ✅ |
| Algorand mnemonic | ✅ |
| Ton mnemonic + Ton addresses/keys | ✅ |
| Cardano (Icarus/Ledger-style) + Shelley/Byron addresses | ✅ |
| ZIP-32 (Sapling/Orchard HD), Unified viewing/spending keys | ✅ |
| EIP-2333/2334 (BLS), NEP-649 (ML-DSA/NEAR) | ✅ |
| Substrate (mini-secret/seed, sr25519/ed25519/ecdsa derive) | ✅ |

### Zcash

Transparent (`P2PKH/P2SH`), Sapling (addresses, notes, nullifiers, viewing/spending keys), Orchard (notes, actions, IVK/OVK, viewing/spending keys), Unified Addresses (UA with receivers), Unified Spending/Viewing/Incoming-Viewing keys (`USK/UFVK/UIVK`), F4Jumble, RedJubJub/RedPallas (RedDSA) signatures, Sinsemilla + Pedersen hashes, Merkle bridges, ZIP-32 derivation.

### Hardware wallets

> Status: simulation-tested only. HW message codecs, readiness tables (`HwCatalog`,
> `hwReadinessFor` / `isSupportedByHw`), and signing flows are currently validated
> against simulated transports and fixtures — **not yet tested with real devices**.
> Expect gaps before using this with real funds.

Message codecs (no transport in core): APDU, Trezor protobuf, Uniform Resources (UR), PSBT, unified `HardwareWallet` interface. Transports are injected: USB-HID/BLE/NFC natively, WebHID/WebUSB on web.

Supported families (see `HwCatalog.devices()` / per-coin `hwSupport` rows; readiness varies by coin/variant — query `hwReadinessFor` / `isSupportedByHw`):

Ledger (Nano S Plus, Nano X, Flex, Stax) · Trezor (Model One, Model T, Safe 3/5/7) · KeepKey · OneKey · BitBox02 · Passport · Keystone 3/Pro · Coldcard Q · Jade QR.

Coin flows include BTC (legacy/segwit/taproot), ETH/EVM, TRX, XRP, ATOM, FIL (secp), XTZ (`tz1/tz2/tz3`), SOL, APT, SUI (Ed25519), NEAR, XLM, DOT (SLIP), ADA (Icarus), ZEC transparent. Shielded Zcash and Monero multi-round protocols have no generic HW flow.

Check support offline (no device needed):

```dart
hwReadinessFor(coin: CryptoCoins.bitcoin, device: BuHwKind.ledgerNanoX.id);
isSupportedByHw(coin: CryptoCoins.ethereum, device: BuHwKind.trezorModelT.id);
HwCatalog.coinsFor(BuHwKind.ledgerNanoX);
```

### Services / utils

Chain service abstractions with a single provider architecture (`service/`), gRPC helpers, amount conversion (human <-> base units), BIP coin config registry, address key validators, constant-time helpers, `Uint64` fixed arithmetic with web/native variants.

## Examples and tests

- `test/` holds thousands of vectors/examples across encodings, crypto, addresses, mnemonics, signers, Sapling/Orchard, and HW codecs.
- `example/blockchain_utils_example.dart` is a minimal pure-Dart sample (hash + BIP-39/BIP-44).

## Contributing

- Fork, branch, make focused changes, ensure tests pass, open a PR with a clear description.
- New crypto must land in **both** backends (or explicitly document Rust-only, like Groth16) with test vectors.
- This package is not released with migration shims for old serialized payloads; CBOR and key formats are strict by design.

## Issues

File feature requests and bugs in the issue tracker.
