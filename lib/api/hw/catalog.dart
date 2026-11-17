import 'package:blockchain_utils/protocol/bip/bip/conf/config/bip_coin_conf.dart';
import 'package:blockchain_utils/protocol/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Static catalog over the variant-keyed `hwSupport` rows: which devices
/// exist, which coins/variants each device can sign, and how proven.
///
/// Pure data + filtering — no transport, no native library. UI layers
/// (like the example app) drive device list → coin filter → key fetch
/// off these three functions.
abstract final class HwCatalog {
  /// All known devices with family/transport labels for list UIs.
  static List<({BuHwKind kind, String name, String family, String transport})>
  devices() {
    String familyOf(BuHwKind k) {
      switch (k) {
        case BuHwKind.ledgerNanoSPlus:
        case BuHwKind.ledgerNanoX:
        case BuHwKind.ledgerFlex:
        case BuHwKind.ledgerStax:
          return 'Ledger';
        case BuHwKind.trezorOne:
        case BuHwKind.trezorModelT:
        case BuHwKind.trezorSafe3:
        case BuHwKind.trezorSafe5:
        case BuHwKind.trezorSafe7:
        case BuHwKind.keepKey:
        case BuHwKind.oneKey:
          return 'Trezor';
        case BuHwKind.bitBox02:
          return 'BitBox02';
        case BuHwKind.passport:
          return 'Passport';
        case BuHwKind.keystone3:
        case BuHwKind.keystonePro:
          return 'Keystone';
        case BuHwKind.coldcardQr:
          return 'Coldcard';
        case BuHwKind.jadeQr:
          return 'Jade';
      }
    }

    const usb = {
      BuHwKind.ledgerNanoSPlus,
      BuHwKind.ledgerNanoX,
      BuHwKind.ledgerFlex,
      BuHwKind.ledgerStax,
      BuHwKind.trezorOne,
      BuHwKind.trezorModelT,
      BuHwKind.trezorSafe3,
      BuHwKind.trezorSafe5,
      BuHwKind.trezorSafe7,
      BuHwKind.keepKey,
      BuHwKind.oneKey,
      BuHwKind.bitBox02,
    };
    const names = {
      BuHwKind.ledgerNanoSPlus: 'Ledger Nano S Plus',
      BuHwKind.ledgerNanoX: 'Ledger Nano X',
      BuHwKind.ledgerFlex: 'Ledger Flex',
      BuHwKind.ledgerStax: 'Ledger Stax',
      BuHwKind.trezorOne: 'Trezor Model One',
      BuHwKind.trezorModelT: 'Trezor Model T',
      BuHwKind.trezorSafe3: 'Trezor Safe 3',
      BuHwKind.trezorSafe5: 'Trezor Safe 5',
      BuHwKind.trezorSafe7: 'Trezor Safe 7',
      BuHwKind.keepKey: 'KeepKey',
      BuHwKind.oneKey: 'OneKey',
      BuHwKind.bitBox02: 'BitBox02',
      BuHwKind.passport: 'Passport',
      BuHwKind.keystone3: 'Keystone 3',
      BuHwKind.keystonePro: 'Keystone Pro',
      BuHwKind.coldcardQr: 'Coldcard Q',
      BuHwKind.jadeQr: 'Jade QR',
    };
    return [
      for (final k in BuHwKind.values)
        (
          kind: k,
          name: names[k]!,
          family: familyOf(k),
          transport: usb.contains(k) ? 'USB' : 'QR',
        ),
    ];
  }

  /// Raw support rows for one coin (empty when the coin's config carries
  /// none — treated as unknown everywhere downstream).
  static List<HwVariantSupport> rowsFor(CryptoCoins coin) {
    final conf = coin.conf;
    if (conf is BipCoinConfig) return conf.hwSupport;
    return const [];
  }

  /// Coins having at least one claim for [kind] that is not `impossible`.
  /// Sorted with `ready` coins first. Covers every proposal enum
  /// (BIP-44 bitcoin and BIP-84 bitcoin are distinct entries, as they
  /// should be — different purposes, different addresses).
  static List<CryptoCoins> coinsFor(BuHwKind kind) {
    final out = <CryptoCoins>[];
    for (final coin in CryptoCoins.values) {
      final rows = rowsFor(coin).where((r) => r.device == kind).toList();
      if (rows.any((r) => r.readiness != HwReadiness.impossible)) {
        out.add(coin);
      }
    }
    out.sort((a, b) {
      final ra = hwBest([
        for (final r in rowsFor(a))
          if (r.device == kind) r,
      ]);
      final rb = hwBest([
        for (final r in rowsFor(b))
          if (r.device == kind) r,
      ]);
      return rb.index.compareTo(ra.index);
    });
    return out;
  }

  /// Variant keys available for ([coin], [kind]) (any readiness).
  static List<String> variantsFor(CryptoCoins coin, BuHwKind kind) {
    return [
      for (final r in rowsFor(coin))
        if (r.device == kind) r.variant,
    ];
  }

  /// Best readiness for ([coin], [variant]); `unknown` when unlisted.
  static HwReadiness bestFor(CryptoCoins coin, String variant) {
    return hwBest(hwFor(rowsFor(coin), variant));
  }
}
