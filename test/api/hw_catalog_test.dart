import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:test/test.dart';

import '../utils.dart';

/// HwCatalog: device list, coin filter, variant filter. Pure data logic.
void hwCatalogTest() {
  test("devices lists all 17 with transport labels", () {
    final devs = HwCatalog.devices();
    expect(devs.length, BuHwKind.values.length);
    final trezorT = devs.where((d) => d.kind == BuHwKind.trezorModelT).single;
    expect(trezorT.transport, 'USB');
    expect(
      devs.where((d) => d.kind == BuHwKind.coldcardQr).single.transport,
      'QR',
    );
  });

  test("coinsFor filters per device", () {
    final trezor = HwCatalog.coinsFor(BuHwKind.trezorModelT);
    expect(trezor.contains(Bip44Coins.bitcoin), isTrue);
    final bitbox = HwCatalog.coinsFor(BuHwKind.bitBox02);
    // P2PKH-bitcoin is impossible on BitBox; segwit-bitcoin is listed.
    expect(bitbox.contains(Bip44Coins.bitcoin), isFalse);
    expect(bitbox.contains(Bip84Coins.bitcoin), isTrue);
    // vechain has no rows anywhere: absent for every device
    expect(
      HwCatalog.coinsFor(BuHwKind.ledgerNanoSPlus).contains(Bip44Coins.vechain),
      isFalse,
    );
  });

  test("variantsFor + bestFor resolve per coin", () {
    // BIP-44 bitcoin carries the p2pkh rows; BIP-84 bitcoin the p2wpkh rows.
    expect(HwCatalog.variantsFor(Bip44Coins.bitcoin, BuHwKind.bitBox02), [
      'p2pkh',
    ]);
    expect(HwCatalog.bestFor(Bip44Coins.bitcoin, 'p2pkh'), HwReadiness.ready);
    expect(HwCatalog.variantsFor(Bip84Coins.bitcoin, BuHwKind.bitBox02), [
      'p2wpkh',
    ]);
    expect(HwCatalog.bestFor(Bip84Coins.bitcoin, 'p2wpkh'), HwReadiness.ready);
    expect(
      HwCatalog.bestFor(Bip44Coins.ripple, 'secp256k1'),
      HwReadiness.needsAppWork,
    );
    expect(
      HwCatalog.bestFor(Bip44Coins.vechain, 'secp256k1'),
      HwReadiness.unknown,
    );
  });

  test("hwReadinessFor / isSupportedByHw resolve coin+device", () {
    // Pinned variant answers.
    expect(
      hwReadinessFor(
        coin: Bip44Coins.bitcoin,
        device: BuHwDevice.bitBox02,
        variant: 'p2pkh',
      ),
      HwReadiness.impossible,
    );
    expect(
      hwReadinessFor(
        coin: Bip84Coins.bitcoin,
        device: BuHwDevice.bitBox02,
        variant: 'p2wpkh',
      ),
      HwReadiness.ready,
    );
    // Unpinned collapses to best variant.
    expect(
      hwReadinessFor(coin: Bip84Coins.bitcoin, device: BuHwDevice.bitBox02),
      HwReadiness.ready,
    );
    // Unknown device id / unlisted coin never ship.
    expect(
      hwReadinessFor(coin: Bip44Coins.bitcoin, device: 999, variant: 'p2pkh'),
      HwReadiness.unknown,
    );
    expect(
      hwReadinessFor(coin: Bip44Coins.vechain, device: BuHwDevice.trezorModelT),
      HwReadiness.unknown,
    );
    // Boolean gate: ready-only.
    expect(
      isSupportedByHw(
        coin: Bip84Coins.bitcoin,
        device: BuHwDevice.bitBox02,
        variant: 'p2wpkh',
      ),
      isTrue,
    );
    expect(
      isSupportedByHw(
        coin: Bip44Coins.bitcoin,
        device: BuHwDevice.bitBox02,
        variant: 'p2pkh',
      ),
      isFalse,
    );
    expect(
      isSupportedByHw(
        coin: Bip44Coins.ripple,
        device: BuHwDevice.ledgerNanoSPlus,
      ),
      isFalse,
    ); // needsAppWork is not ready
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(hwCatalogTest, "HwCatalog");
}
