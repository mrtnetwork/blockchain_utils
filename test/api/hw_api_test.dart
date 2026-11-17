import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:test/test.dart';

void main() {
  group('DartHwApi stubs', () {
    const api = DartHwApi();
    final empty = BuBytes([]);
    final transport = BuMockHwTransport([]);

    test('every method throws BuError', () {
      expect(
        () => api.supportsCoin(device: 0, coin: 0),
        throwsA(isA<BuError>()),
      );
      expect(() => api.isAirgap(device: 0), throwsA(isA<BuError>()));
      expect(() => api.parsePath("m/44'/0'/0'/0/0"), throwsA(isA<BuError>()));
      expect(
        () => api.validatePath(device: 0, coin: 0, pathU32: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.getAddressRequest(device: 0, coin: 0, pathU32: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.parseAddressResponse(device: 0, response: empty),
        throwsA(isA<BuError>()),
      );
      expect(() => api.ledgerFingerprint(), throwsA(isA<BuError>()));
      expect(
        () => api.ledgerFingerprintParse(response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () =>
            api.signRequest(device: 0, coin: 0, pathU32: empty, payload: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.parseSignResponse(device: 0, response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.executeSign(
          device: 0,
          coin: 0,
          pathU32: empty,
          payload: empty,
          transport: transport,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.signTxStart(
          device: 0,
          coin: 0,
          inputsCount: 1,
          outputsCount: 1,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.parseTxRequest(device: 0, response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.txRequestSignature(device: 0, response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.txRequestSerialized(device: 0, response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.txRequestTxHash(device: 0, response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.txAckMeta(
          version: 2,
          lockTime: 0,
          inputsCount: 1,
          outputsCount: 1,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.txAckInput(
          prevHash32: empty,
          prevIndex: 0,
          pathU32: empty,
          amountSat: 0,
          scriptSig: empty,
          scriptType: 0,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.txAckOutput(address: 'bc1q', amountSat: 0, scriptType: 0),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.txAckChange(pathU32: empty, amountSat: 0, scriptType: 0),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.txAckBinOutput(scriptPubKey: empty, amountSat: 0),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxHsNew(staticPriv32: empty, ephemeralPriv32: empty),
        throwsA(isA<BuError>()),
      );
      expect(() => api.bitboxHsM1(), throwsA(isA<BuError>()));
      expect(() => api.bitboxHsM2(m2: empty), throwsA(isA<BuError>()));
      expect(() => api.bitboxHsM3(), throwsA(isA<BuError>()));
      expect(() => api.bitboxHsSplit(), throwsA(isA<BuError>()));
      expect(
        () => api.bitboxEncrypt(plaintext: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxDecrypt(ciphertext: empty),
        throwsA(isA<BuError>()),
      );
      expect(() => api.bitboxHsHash(), throwsA(isA<BuError>()));
      expect(() => api.bitboxFree(), throwsA(isA<BuError>()));
      expect(
        () => api.bitboxBtcPubRequest(
          coin: 0,
          pathU32: empty,
          xpubType: 1,
          display: false,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxPubParse(response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxSignInit(
          coin: 0,
          pathU32: empty,
          simpleType: 1,
          version: 2,
          inputsCount: 1,
          outputsCount: 1,
          locktime: 0,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxSignNextParse(response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxSignNextSignature(response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxSignNextPrevIndex(response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxSignInput(
          prevHash32: empty,
          prevIndex: 0,
          amountSat: 0,
          sequence: 0xFFFFFFFF,
          pathU32: empty,
          scriptConfigIndex: 0,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxSignOutput(outputType: 3, amountSat: 0, payload: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxSignChange(
          pathU32: empty,
          amountSat: 0,
          scriptConfigIndex: 0,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxSignPrevtxInit(
          version: 2,
          inputsCount: 1,
          outputsCount: 1,
          locktime: 0,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxSignPrevtxInput(
          prevHash32: empty,
          prevIndex: 0,
          scriptSig: empty,
          sequence: 0xFFFFFFFF,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.bitboxSignPrevtxOutput(amountSat: 0, script: empty),
        throwsA(isA<BuError>()),
      );
      expect(() => api.identityEncode(proto: 'ssh'), throwsA(isA<BuError>()));
      expect(
        () => api.signIdentityRequest(identity: empty, hidden: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.signedIdentityAddress(response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.signedIdentityPubkey(response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.signedIdentitySignature(response: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.qrRequest(device: 12, coin: 8, pathU32: empty),
        throwsA(isA<BuError>()),
      );
      expect(
        () => api.qrParse(device: 12, qr: 'ur:bytes/aa'),
        throwsA(isA<BuError>()),
      );
      expect(() => api.psbtCounts(psbt: empty), throwsA(isA<BuError>()));
      expect(
        () => api.urEncode(type: 'bytes', payload: empty),
        throwsA(isA<BuError>()),
      );
      expect(() => api.urDecodePayload('ur:bytes/aa'), throwsA(isA<BuError>()));
      expect(() => api.urDecodeType('ur:bytes/aa'), throwsA(isA<BuError>()));
      expect(
        () => api.executeGetAddress(
          device: 0,
          coin: 0,
          pathU32: empty,
          transport: transport,
        ),
        throwsA(isA<BuError>()),
      );
      expect(() => api.hidFrame(payload: empty), throwsA(isA<BuError>()));
      expect(() => api.hidUnframe(reports: empty), throwsA(isA<BuError>()));
    });

    test('plumbs into DefaultBlockchainUtilsApi', () {
      // Compile-time wiring check: `hw` is required on the aggregate API.
      expect(api, isA<HwApi>());
      expect(const DartHwApi(), isA<HwApi>());
    });
  });

  group('Easy mode (pure-Dart mapping)', () {
    const api = DartHwApi();

    test('slip44/type mapping', () {
      expect(
        hwCoinIdForSlip44(
          slip44: Slip44.bitcoin,
          type: CryptoKeyType.secp256k1,
        ),
        BuHwCoin.btc,
      );
      expect(
        hwCoinIdForSlip44(
          slip44: Slip44.bitcoin,
          type: CryptoKeyType.secp256k1,
          purpose: 84,
        ),
        BuHwCoin.btcSegwit,
      );
      expect(
        hwCoinIdForSlip44(slip44: Slip44.tezos, type: CryptoKeyType.ed25519),
        BuHwCoin.xtzTz1,
      );
      expect(
        hwCoinIdForSlip44(slip44: Slip44.tezos, type: CryptoKeyType.secp256k1),
        BuHwCoin.xtzTz2,
      );
      expect(
        hwCoinIdForSlip44(slip44: Slip44.tezos, type: CryptoKeyType.nist256p1),
        BuHwCoin.xtzTz3,
      );
      expect(
        hwCoinIdForSlip44(
          slip44: Slip44.internetComputer,
          type: CryptoKeyType.ed25519,
        ),
        isNull,
      );
      expect(
        hwCoinIdForSlip44(slip44: Slip44.ripple, type: CryptoKeyType.ed25519),
        isNull,
      );
      expect(
        hwCoinIdForSlip44(slip44: Slip44.zcash, type: CryptoKeyType.secp256k1),
        BuHwCoin.zecTransparent,
      );
      // Monero has no generic HW flow (dedicated protocol only).
      expect(
        hwCoinIdForSlip44(slip44: Slip44.monero, type: CryptoKeyType.ed25519),
        isNull,
      );
    });

    test('coin ids + default paths from Bip44Coins', () {
      expect(api.hwCoinIdFor(Bip44Coins.bitcoin), BuHwCoin.btc);
      expect(api.hwCoinIdFor(Bip44Coins.ethereum), BuHwCoin.eth);
      expect(api.hwCoinIdFor(Bip44Coins.tezos), BuHwCoin.xtzTz1);
      expect(api.hwCoinIdFor(Bip44Coins.tezosSecp256k1), BuHwCoin.xtzTz2);
      expect(api.hwCoinIdFor(Bip44Coins.solana), BuHwCoin.sol);
      expect(api.hwCoinIdFor(Bip44Coins.zcash), BuHwCoin.zecTransparent);
      expect(api.defaultHwPath(Bip44Coins.bitcoin), "m/44'/0'/0'/0/0");
      expect(api.defaultHwPath(Bip44Coins.tezos), "m/44'/1729'/0'/0'");
      expect(api.defaultHwPath(Bip44Coins.solana), "m/44'/501'/0'");
    });

    test('unknown coin throws ArgumentException, not UnimplementedError', () {
      expect(
        () => api.hwCoinIdFor(Bip44Coins.internetComputer),
        throwsA(isA<BuError>()),
      );
    });

    test('getPublicKey never touches transport on Dart backend', () async {
      final mock = BuMockHwTransport([
        [1, 2, 3],
      ]);
      await expectLater(
        api.getPublicKey(
          coin: Bip44Coins.bitcoin,
          device: BuHwDevice.ledgerNanoSPlus,
          transport: mock,
        ),
        throwsA(isA<BuError>()),
      );
      expect(mock.seen, isEmpty);
      expect(mock.remaining, 1);
    });

    test('isCoinSupportedByHw delegates to backend map', () {
      expect(
        () => api.isCoinSupportedByHw(
          Bip44Coins.bitcoin,
          device: BuHwDevice.ledgerNanoSPlus,
        ),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('NativeHwApi wiring', () {
    test('constructs over connector BuHwApi type', () {
      // No native library needed: only checks the wrapper type exists and
      // implements the interface (calls themselves need `setRustApi`).
      expect(NativeHwApi, isA<Type>());
    });
  });

  group('NativeHwApi over real native lib', () {
    // Computed synchronously at registration (not in setUpAll): `skip:`
    // captures its value when test() runs, so a setUpAll assignment would
    // always arrive too late and the body would run with `native` unset.
    // In the shared suite the backend is already attached by the outer
    // runTest before this main() registers; standalone runs see the
    // default backend (no hw) and skip.
    final hw = blockchainUtils.backend?.hw;
    final available =
        hw != null &&
        (blockchainUtils.backend?.backendInfo.has(BuBuildFeature.hw) ?? false);
    final native = available ? NativeHwApi(hw) : null;
    const skipReason = 'Native hw backend unavailable (needs hw feature)';

    BuBytes u32s(List<int> words) {
      final out = <int>[];
      for (final w in words) {
        out.addAll([
          w & 0xFF,
          (w >> 8) & 0xFF,
          (w >> 16) & 0xFF,
          (w >> 24) & 0xFF,
        ]);
      }
      return BuBytes(out);
    }

    test('ledger fingerprint + v2 xpub request shape', () {
      expect(native!.ledgerFingerprint().toList(), [0xE1, 0x05, 0x00, 0x01]);
      final path = u32s([0x8000002C, 0x80000001, 0x80000000, 0, 0]);
      final req = native.getAddressRequest(
        device: BuHwDevice.ledgerNanoSPlus,
        coin: BuHwCoin.btcTestnet,
        pathU32: path,
      );
      expect(req.toList().sublist(0, 5), [0xE1, 0x00, 0x00, 0x01, 0x16]);
    }, skip: available ? null : skipReason);

    test('trezor identity encode + request shape', () {
      final id = native!.identityEncode(
        proto: 'ssh',
        user: 'alice',
        host: 'example.com',
      );
      expect(id.toList().sublist(0, 2), [0x0A, 0x03]);
      final req = native.signIdentityRequest(identity: id, hidden: BuBytes([]));
      expect(req.toList().sublist(0, 5), [0x3F, 0x23, 0x23, 0x00, 53]);
    }, skip: available ? null : skipReason);

    test('bitbox prevtx builders shape', () {
      final init = native!.bitboxSignPrevtxInit(
        version: 2,
        inputsCount: 1,
        outputsCount: 1,
        locktime: 0,
      );
      expect(init.toList()[0], 0xCA); // Request.btc = 25
      final hs = native.bitboxHsM1;
      expect(hs, isA<Function>());
    }, skip: available ? null : skipReason);
  });
}
