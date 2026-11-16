import 'package:blockchain_utils/api/hw/catalog.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/protocol/bip/slip/slip44/slip44.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Readiness of ([coin], [device]) — optionally pinned to one address
/// variant (`'p2pkh' | 'p2wpkh' | 'p2sh' | 'p2tr'`, curve name otherwise).
///
/// Without [variant], collapses to the best readiness across all of the
/// coin's variants for that device. Unknown device id or unlisted coin
/// yields [HwReadiness.unknown] (never shipped as supported).
///
/// This answers "can it sign", not "is it connected": combine with the
/// runtime address/key-match probes before any signing UI.
HwReadiness hwReadinessFor({
  required CryptoCoins coin,
  required int device,
  String? variant,
}) {
  final kind = BuHwKind.fromId(device);
  if (kind == null) return HwReadiness.unknown;
  final rows = HwCatalog.rowsFor(coin).where((r) => r.device == kind);
  if (variant != null) {
    return hwBest([for (final r in rows) if (r.variant == variant) r]);
  }
  return hwBest(rows.toList());
}

/// True only when ([coin], [device]) is live-proven ([variant] pins one
/// address type/curve; without it, true when ANY variant is ready).
/// Everything else — including `needsAppWork` — is false: "coming soon"
/// is not "can sign".
bool isSupportedByHw({
  required CryptoCoins coin,
  required int device,
  String? variant,
}) {
  return hwReadinessFor(coin: coin, device: device, variant: variant) ==
      HwReadiness.ready;
}

/// Map a `(SLIP44, key type, purpose)` triple to a connector [BuHwCoin] id.
///
/// Returns `null` when the coin has no HW flow in the Rust `hw` core
/// (unknown SLIP44, or a curve variant no device speaks, e.g. SUI secp256r1).
/// A non-null id does NOT mean your device supports it — that is the
/// offline curve-table check [HwApi.supportsCoin] (no transport, no device).
int? hwCoinIdForSlip44({
  required int slip44,
  required CryptoKeyType type,
  int purpose = 44,
}) {
  switch (slip44) {
    case Slip44.bitcoin:
      if (type != CryptoKeyType.secp256k1) return null;
      return switch (purpose) {
        84 => BuHwCoin.btcSegwit,
        86 => BuHwCoin.btcTaproot,
        _ => BuHwCoin.btc,
      };
    case Slip44.ethereum:
      // Covers every EVM chain reusing 60 (BSC, Polygon, Avax-C, …).
      return type == CryptoKeyType.secp256k1 ? BuHwCoin.eth : null;
    case Slip44.tron:
      return type == CryptoKeyType.secp256k1 ? BuHwCoin.trx : null;
    case Slip44.ripple:
      return type == CryptoKeyType.secp256k1 ? BuHwCoin.xrp : null;
    case Slip44.atom:
      return type == CryptoKeyType.secp256k1 ? BuHwCoin.atom : null;
    case Slip44.filecoin:
      return type == CryptoKeyType.secp256k1 ? BuHwCoin.filSecp : null;
    case Slip44.tezos:
      return switch (type) {
        CryptoKeyType.ed25519 => BuHwCoin.xtzTz1,
        CryptoKeyType.secp256k1 => BuHwCoin.xtzTz2,
        CryptoKeyType.nist256p1 => BuHwCoin.xtzTz3,
        _ => null,
      };
    case Slip44.solana:
      return type == CryptoKeyType.ed25519 ? BuHwCoin.sol : null;
    case Slip44.aptos:
      return type == CryptoKeyType.ed25519 ? BuHwCoin.apt : null;
    case Slip44.sui:
      return type == CryptoKeyType.ed25519 ? BuHwCoin.suiEd : null;
    case Slip44.nearProtocol:
      return type == CryptoKeyType.ed25519 ? BuHwCoin.near : null;
    case Slip44.stellar:
      return type == CryptoKeyType.ed25519 ? BuHwCoin.xlm : null;
    case Slip44.polkadot:
      return type == CryptoKeyType.ed25519 ? BuHwCoin.dotSlip : null;
    case Slip44.cardano:
      // Known id, but Ledger/Trezor generic apps report unsupported curve.
      return type == CryptoKeyType.ed25519Kholaw ? BuHwCoin.adaIcarus : null;
    case Slip44.monero:
      // No generic HW flow: XMR needs view+spend keys and a dedicated
      // multi-round protocol (Ledger/Trezor Monero apps), not getAddress.
      return null;
    case Slip44.zcash:
      // Transparent only; shielded (Sapling/Orchard) is on no HW wallet.
      return type == CryptoKeyType.secp256k1 ? BuHwCoin.zecTransparent : null;
    default:
      return null;
  }
}
