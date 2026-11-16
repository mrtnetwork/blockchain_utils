import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Verified hardware-wallet support rows, assigned to `BipCoinConfig.hwSupport`.
///
/// Flat lists: each entry carries its own [HwVariantSupport.variant]
/// (`'p2pkh' | 'p2wpkh' | 'p2sh' | 'p2tr'` for UTXO coins, curve name for
/// the rest) and is resolved with `hwFor(config.hwSupport, variant)`.
/// No entry for a variant = unknown (never shipped as supported).
///
/// Readiness discipline: `ready` ONLY where a live emulator/Speculos proof
/// ran (banked in `latest.md`); everything else is `needsAppWork`,
/// `impossible`, or absent (= `unknown`).
abstract final class HwVariants {
  static const _tModelT = BuHwKind.trezorModelT;
  static const _tSafe5 = BuHwKind.trezorSafe5;
  static const _ledgerSP = BuHwKind.ledgerNanoSPlus;
  static const _bitbox = BuHwKind.bitBox02;

  // -- Bitcoin P2PKH (BIP-44) -------------------------------------------
  static const bitcoinP2pkh = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'p2pkh',
      readiness: HwReadiness.ready,
      why: 'live: SignTx swap + direct verify 2026-10',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'p2pkh',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'app-bitcoin v2 policy flow not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'p2pkh',
      readiness: HwReadiness.impossible,
      why: 'no legacy path in BitBox02 firmware',
    ),
  ];

  // -- Bitcoin P2WPKH (BIP-84) -------------------------------------------
  static const bitcoinP2wpkh = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'p2wpkh',
      readiness: HwReadiness.ready,
      why: 'same ?## codec as proven P2PKH flow',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'p2wpkh',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'wpkh() policy flow not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'p2wpkh',
      readiness: HwReadiness.ready,
      why: 'live: BB-SIGN-VERIFY-OK 2026-10',
    ),
  ];

  // -- Bitcoin P2SH-wrapped segwit (BIP-49) -------------------------------
  static const bitcoinP2sh = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'p2sh',
      readiness: HwReadiness.needsAppWork,
      why: 'same codec, needs emulator proof',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'p2sh',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'sh(wpkh()) policy flow not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'p2sh',
      readiness: HwReadiness.needsAppWork,
      why: 'P2WPKH_P2SH exists in btc.proto, needs live proof',
    ),
  ];

  // -- Bitcoin taproot (BIP-86) ------------------------------------------
  static const bitcoinP2tr = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'p2tr',
      readiness: HwReadiness.needsAppWork,
      why: 'same codec, needs emulator proof (One excluded: no taproot)',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'p2tr',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'tr() policy flow not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'p2tr',
      readiness: HwReadiness.needsAppWork,
      why: 'P2TR exists in btc.proto, needs live proof',
    ),
  ];

  // -- Ethereum (secp256k1) ----------------------------------------------
  static const ethereum = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'secp256k1',
      readiness: HwReadiness.needsAppWork,
      why: 'firmware supports ETH, our codec not built yet',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'secp256k1',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'ETH app APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'secp256k1',
      readiness: HwReadiness.needsAppWork,
      why: 'firmware supports ETH, our codec not built yet',
    ),
  ];

  // -- XRP secp256k1 ------------------------------------------------------
  static const xrpSecp = [
    HwVariantSupport(
      device: _tSafe5,
      variant: 'secp256k1',
      readiness: HwReadiness.needsAppWork,
      models: 'Safe 3/5/7 per Suite (One/T unverified)',
      why: 'trezor.io/coins lists XRP on Safe models',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'secp256k1',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'hw-app-xrp default curve, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'secp256k1',
      readiness: HwReadiness.impossible,
      why: 'no XRP path in BitBox02 firmware',
    ),
  ];

  // -- XRP ed25519 --------------------------------------------------------
  static const xrpEd = [
    HwVariantSupport(
      device: _tSafe5,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no ed25519 path in Trezor XRP firmware',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'hw-app-xrp ed25519 flag verified in API docs',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no XRP path in BitBox02 firmware',
    ),
  ];

  static const tron = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'secp256k1',
      readiness: HwReadiness.needsAppWork,
      why: 'trezor.io/coins lists TRX (some models)',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'secp256k1',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Tron app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'secp256k1',
      readiness: HwReadiness.impossible,
      why: 'no TRX path in BitBox02 firmware',
    ),
  ];

  static const litecoin = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'p2pkh',
      readiness: HwReadiness.needsAppWork,
      why: 'same codec as BTC, needs emulator proof',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'p2pkh',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'same v2 policy shape as BTC, needs proof',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'p2pkh',
      readiness: HwReadiness.needsAppWork,
      models: 'BitBoxApp natively',
      why: 'firmware supports LTC, needs live proof',
    ),
  ];

  static const solana = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      why: 'trezor.io/coins lists SOL (some models)',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Solana app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no SOL path in BitBox02 firmware',
    ),
  ];

  static const cardano = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      why: 'trezor.io/coins lists ADA',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Cardano app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'via AdaLite/NuFi only, never BitBoxApp',
      why: 'firmware supports ADA via external wallets',
    ),
  ];

  // -- The rest: one row-set per chain, honest statuses only ---------------
  // Template per entry: Trezor (firmware list or impossible), Ledger
  // (per-coin app exists => needsAppWork), BitBox (impossible unless the
  // coin is BTC/LTC/ETH/ADA).

  static const bitcoinCash = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'p2pkh',
      readiness: HwReadiness.needsAppWork,
      why: 'same codec as BTC, needs emulator proof',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'p2pkh',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'BCH app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'p2pkh',
      readiness: HwReadiness.impossible,
      why: 'no BCH path in BitBox02 firmware',
    ),
  ];

  static const stellar = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      why: 'trezor.io/coins lists XLM',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Stellar app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no XLM path in BitBox02 firmware',
    ),
  ];

  static const zcashTransparent = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'p2pkh',
      readiness: HwReadiness.needsAppWork,
      why: 'trezor.io/coins lists ZEC (transparent)',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'p2pkh',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'transparent ZEC signs like BTC; shielded: nobody',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'p2pkh',
      readiness: HwReadiness.impossible,
      why: 'no ZEC path in BitBox02 firmware',
    ),
  ];

  static const cosmosSecp = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'secp256k1',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no Cosmos app in Trezor firmware',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'secp256k1',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Cosmos app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'secp256k1',
      readiness: HwReadiness.impossible,
      why: 'no ATOM path in BitBox02 firmware',
    ),
  ];

  static const cosmosOtherCurves = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no Cosmos app in Trezor firmware',
    ),
    HwVariantSupport(
      device: _tModelT,
      variant: 'nist256p1',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no Cosmos app in Trezor firmware',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Cosmos app is secp256k1-only',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'nist256p1',
      readiness: HwReadiness.impossible,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Cosmos app is secp256k1-only',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no ATOM path in BitBox02 firmware',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'nist256p1',
      readiness: HwReadiness.impossible,
      why: 'no ATOM path in BitBox02 firmware',
    ),
  ];

  static const ton = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.unknown,
      why: 'not confirmed on trezor.io/coins - verify before shipping',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'TON app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no TON path in BitBox02 firmware',
    ),
  ];

  static const aptos = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no APT path in Trezor firmware',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Aptos app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no APT path in BitBox02 firmware',
    ),
  ];

  static const sui = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no SUI path in Trezor firmware',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Sui app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no SUI path in BitBox02 firmware',
    ),
  ];

  static const near = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no NEAR path in Trezor firmware',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'NEAR app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no NEAR path in BitBox02 firmware',
    ),
  ];

  static const tezos = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      why: 'Trezor firmware supports XTZ, our codec not built yet',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Tezos app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no XTZ path in BitBox02 firmware',
    ),
  ];

  static const filecoin = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'secp256k1',
      readiness: HwReadiness.needsAppWork,
      why: 'in Trezor supported-coins list (FIL)',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'secp256k1',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Filecoin app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'secp256k1',
      readiness: HwReadiness.impossible,
      why: 'no FIL path in BitBox02 firmware',
    ),
  ];

  static const internetComputer = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no ICP path in Trezor firmware',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'ICP app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no ICP path in BitBox02 firmware',
    ),
  ];

  static const algorand = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no ALGO path in Trezor firmware',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Algorand app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no ALGO path in BitBox02 firmware',
    ),
  ];

  static const hedera = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no HBAR path in Trezor firmware',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Hedera app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no HBAR path in BitBox02 firmware',
    ),
  ];

  static const polkadot = [
    HwVariantSupport(
      device: _tModelT,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      models: 'all Trezor models',
      why: 'no Substrate path in Trezor firmware',
    ),
    HwVariantSupport(
      device: _ledgerSP,
      variant: 'ed25519',
      readiness: HwReadiness.needsAppWork,
      models: 'Nano S+/X/Flex/Stax (per-app)',
      why: 'Polkadot app exists, APDU codec not built yet',
    ),
    HwVariantSupport(
      device: _bitbox,
      variant: 'ed25519',
      readiness: HwReadiness.impossible,
      why: 'no DOT path in BitBox02 firmware',
    ),
  ];
}
