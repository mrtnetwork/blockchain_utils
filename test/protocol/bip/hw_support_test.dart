import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:test/test.dart';

import '../../utils.dart';

/// Hardware-wallet support rows on coin configs: variant filtering,
/// provenance present, unknown-by-default.
void hwSupportTest() {
  test("BTC p2pkh rows: trezor ready, ledger next, bitbox impossible", () {
    final rows = hwFor(Bip44Conf().bitcoinMainNet.hwSupport, 'p2pkh');
    expect(rows.length, 3);
    final byDevice = {for (final r in rows) r.device: r};
    expect(byDevice[BuHwKind.trezorModelT]!.readiness, HwReadiness.ready);
    expect(byDevice[BuHwKind.ledgerNanoSPlus]!.readiness,
        HwReadiness.needsAppWork);
    expect(byDevice[BuHwKind.bitBox02]!.readiness, HwReadiness.impossible);
    for (final r in rows) {
      expect(r.why.isNotEmpty, isTrue);
    }
    expect(hwBest(rows), HwReadiness.ready);
  });

  test("BTC p2wpkh rows live on the BIP-84 config", () {
    final rows = hwFor(Bip84Conf().bitcoinMainNet.hwSupport, 'p2wpkh');
    expect(
        rows
            .where((r) =>
                r.device == BuHwKind.bitBox02 &&
                r.readiness == HwReadiness.ready)
            .length,
        1);
    // p2pkh key absent here: unknown, never shipped
    expect(hwFor(Bip84Conf().bitcoinMainNet.hwSupport, 'p2pkh'), isEmpty);
  });

  test("XRP curves disagree per device (the variant-keyed case)", () {
    final secp = hwFor(Bip44Conf().ripple.hwSupport, 'secp256k1');
    final ed = hwFor(Bip44Conf().rippleEd25519.hwSupport, 'ed25519');
    expect(
        secp
            .where((r) =>
                r.device == BuHwKind.trezorSafe5 &&
                r.readiness == HwReadiness.needsAppWork)
            .length,
        1);
    expect(
        secp
            .where((r) =>
                r.device == BuHwKind.bitBox02 &&
                r.readiness == HwReadiness.impossible)
            .length,
        1);
    expect(
        ed
            .where((r) =>
                r.device == BuHwKind.trezorSafe5 &&
                r.readiness == HwReadiness.impossible)
            .length,
        1);
    expect(
        ed
            .where((r) =>
                r.device == BuHwKind.ledgerNanoSPlus &&
                r.readiness == HwReadiness.needsAppWork)
            .length,
        1);
  });

  test("unlisted coins default to unknown", () {
    expect(hwFor(Bip44Conf().vechain.hwSupport, 'secp256k1'), isEmpty);
    expect(hwBest([]), HwReadiness.unknown);
  });

  test("second batch: BCH/XLM/ZEC/ATOM/TON/APT/SUI/NEAR/XTZ/FIL/ICP/ALGO/HBAR/DOT", () {
    final checks = <List<HwVariantSupport>, String>{
      Bip44Conf().bitcoinCashMainNet.hwSupport: 'p2pkh',
      Bip44Conf().stellar.hwSupport: 'ed25519',
      Bip44Conf().zcashMainNet.hwSupport: 'p2pkh',
      Bip44Conf().cosmos.hwSupport: 'secp256k1',
      Bip44Conf().tonMainnet.hwSupport: 'ed25519',
      Bip44Conf().aptos.hwSupport: 'ed25519',
      Bip44Conf().suiEd25519.hwSupport: 'ed25519',
      Bip44Conf().nearProtocol.hwSupport: 'ed25519',
      Bip44Conf().tezos.hwSupport: 'ed25519',
      Bip44Conf().filecoin.hwSupport: 'secp256k1',
      Bip44Conf().internetComputer.hwSupport: 'ed25519',
      Bip44Conf().algorand.hwSupport: 'ed25519',
      Bip44Conf().hedera.hwSupport: 'ed25519',
      Bip44Conf().polkadotEd25519Slip.hwSupport: 'ed25519',
    };
    for (final e in checks.entries) {
      final rows = hwFor(e.key, e.value);
      expect(rows.isNotEmpty, isTrue, reason: e.value);
      // BitBox must be impossible on all of these (no such firmware paths)
      expect(
          rows
              .where((r) =>
                  r.device == BuHwKind.bitBox02 &&
                  r.readiness == HwReadiness.impossible)
              .length,
          1,
          reason: e.value);
      for (final r in rows) {
        expect(r.why.isNotEmpty, isTrue);
      }
    }
    // every row resolves a best that is not unknown
    expect(
        hwBest(hwFor(Bip44Conf().tezos.hwSupport, 'ed25519')),
        HwReadiness.needsAppWork);
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(hwSupportTest, "HwSupport");
}
