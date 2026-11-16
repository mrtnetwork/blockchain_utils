import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../../utils.dart';

String _onTrieHandle(List<int> publicKey) {
  final digest = QuickCrypto.sha3256Hash([
    ...utf8.encode('near:ml-dsa-65-pubkey-hash:v1'),
    ...publicKey,
  ]);
  return 'ml-dsa-65-hash:${Base58Encoder.encode(digest)}';
}

String _nodeSecret(Slip10Mldsa65 node) {
  return node.privateKey.toBytes().useValue(
    (b) => BytesUtils.toHexString(b),
    zero: true,
  );
}

void mldsa65Test() {
  test('nep649 official vectors (all levels)', () {
    final vectors = [
      {
        'seed': '000102030405060708090a0b0c0d0e0f',
        'path': "m/0'/1'/2'/2'/1000000000'",
        'levels': [0, 1, 2, 2, 1000000000],
        'secrets': [
          'dbe1e4f588227dec9e2dc59a4534e7721bf3e977452f0193591603f79880795b',
          'ee139cc19250043529ae16f3d716208298deefa7cfd4a5a2d9af7ac6d6cac4a1',
          'a14dd01ed1fc242b0613e1e0911cc67c1b4f790860649068bc1eda32c89a0e5d',
          '5ec67a61dcd29fa73ab142c6bd54e745b4c47272f2339810bfe1f30a55342a26',
          '636c66df2469c084e524faa342810079b1e10c7ed92de94c10e8860695e6b56e',
          '3a7a1bdc57af0ee8a92da8ec4d900ecfeb269c13073127f032794af13f86c038',
        ],
        'chains': [
          '7e74b6275f92cc4fb2cbdac0c63cb5e7ac2bce1ded2b7dbc7bf2232f772578d5',
          'd8b27c87ec212d6501629199262a9d0d66ec26deab313c26a474bc4ddd5dce7c',
          '60219beef857bd0bc7870424c4f60464decb097a18ae37b035df22ebaa7515b9',
          'dc7b0e1379b3f1acd02d1e25f13d8bb16830ca68c73b00d900b9030a41d6a658',
          '565cb34027c3b54773f7f48e329bc86db7ffc6f618b112af6d59a3f82501e17a',
          'dc65d6cf4fa993c2f04fae2b41d70d8c5ba4c9d2042ea5720bf42a2315a6b7db',
        ],
      },
      {
        'seed':
            'fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542',
        'path': "m/0'/2147483647'/1'/2147483646'/2'",
        'levels': [0, 2147483647, 1, 2147483646, 2],
        'secrets': [
          '67c25895a02758460a9bd084aed3fb3db0ec33b85219d6723e356013da7a6714',
          'e8bf8681f4a1a1d6c854e69b75fd0b39069b21ad983d74cf901dcb01985e9091',
          '4cfca7898c7bbb4a0bb7dc3d14a2d489eaaa87f2c4593985525d256f93cf8888',
          '969352513da88e996a133be855316dc3b46a0cd9792ff340c3bf5a06fa826c3f',
          'ea4de14b6b31d080ad6dc5150642e59e79b83c4fdb90224b1c0d27a3240133da',
          'b73d5dd516a99ab278011406a328066f80f34c1ae878aa9fa5b92c4ef95a965f',
        ],
        'chains': [
          '0e696f43f0e71c1c9febf61f43f10903385b78cee5871915472027b25ba755cc',
          'd977be3c8525364e155764ef76b985126d8f6be41b55e6e50a9915ae29f27a56',
          '45406bac7fc36390d89ac938bff6ca1ebf9fc6da2057d1580b26a8f2e25a0d2f',
          '10ffddec3c4acf719afe528b1ced03e0f7d8555999c11b69376bd5ff4e04dbea',
          '3580d842e9d8d6a072b77d95e08b0a87648edfaec9bc25cee6c9127d1aa4a679',
          '55a202d3f7803dd79e31c454e65eb7da49dee824b467bfed5204df980e71571d',
        ],
      },
      {
        'seed':
            '85d44f13ba9c837a8fe51474cd7b7ed6777591808aca0eb1d5695e914a060c8efbf0ee7e325e24490d69ca824af62071416504ddca17332d2a28bea7377792da',
        'path': "m/44'/397'/0'",
        'levels': [44, 397, 0],
        'secrets': [
          '765883590f2bb53c8186828791f58b59231a3945d695464f117f677c7fac55ec',
          'fe556e3fa041d7b8cad66516c8b45b4ccf585c137d5e1898d145c20651828f94',
          '9058b860f62989e323875ac4b1f5e11f61b659bb7f4faf244c9b69151b7d36aa',
          'e82fe9d0fd2a6af0798736fc2ed44907faf66d4a7a543499e7f1c04f18a7d3c4',
        ],
        'chains': [
          '7e326a33cdeedc0a32ce01e834831dddc253e27b3d00c87c59c159e662ef257b',
          'f0344afcced1f9e18e6cfbae4f204820a3d9a19f0b23327c1a59ab8365c2f905',
          '685f1b3530adcb2918fb8ba1debf0ca5cf79bedeba4bf0f9be2058525b991aeb',
          'c95feddbe3025baf6bc5b448b4c8f5c81817b653d594fe554f80c2da8e1a431d',
        ],
      },
      {
        'seed':
            '85d44f13ba9c837a8fe51474cd7b7ed6777591808aca0eb1d5695e914a060c8efbf0ee7e325e24490d69ca824af62071416504ddca17332d2a28bea7377792da',
        'path': "m/44'/397'/1'/0'/1'",
        'levels': [44, 397, 1, 0, 1],
        'secrets': [
          '765883590f2bb53c8186828791f58b59231a3945d695464f117f677c7fac55ec',
          'fe556e3fa041d7b8cad66516c8b45b4ccf585c137d5e1898d145c20651828f94',
          '9058b860f62989e323875ac4b1f5e11f61b659bb7f4faf244c9b69151b7d36aa',
          '1812e5494894435be5c70bfcb2d6bd53fcc6191eec024ce7a4342d56720afcaf',
          '062c474daddf5bfa470d9092c20760e1d59c4138b8782a692707cc4f46575735',
          'b4a7a302422d48cd8dd0cfd98b3bad14d9f604be7df1cadd8b13c489931de4a0',
        ],
        'chains': [
          '7e326a33cdeedc0a32ce01e834831dddc253e27b3d00c87c59c159e662ef257b',
          'f0344afcced1f9e18e6cfbae4f204820a3d9a19f0b23327c1a59ab8365c2f905',
          '685f1b3530adcb2918fb8ba1debf0ca5cf79bedeba4bf0f9be2058525b991aeb',
          'c1cc4a79bd9cb7010b91dc50858b6651b35add2c393dd7bbef37801bfd40ee9e',
          '1709a088075b83872aec842c829cab2f828df9a7014557593070e40a2920f031',
          '8ecf7d820efdb058ca5e818fdcbdeb67d5f2449bcbceb7e7b8223e0735a13a09',
        ],
      },
    ];
    for (final v in vectors) {
      final seed = BytesUtils.fromHexString(v['seed']! as String);
      Slip10Mldsa65 node = Slip10Mldsa65.fromSeed(seed);
      final secrets = v['secrets']! as List<String>;
      final chains = v['chains']! as List<String>;
      expect(_nodeSecret(node), secrets[0]);
      expect(node.chainCode.toBytes().toHex(), chains[0]);
      expect(node.depth.toInt(), 0);
      final levels = v['levels']! as List<int>;
      for (int i = 0; i < levels.length; i++) {
        node = node.childKey(Bip32KeyIndex.hardenIndex(levels[i]));
        expect(_nodeSecret(node), secrets[i + 1]);
        expect(node.chainCode.toBytes().toHex(), chains[i + 1]);
        expect(node.depth.toInt(), i + 1);
      }
      // derivePath must match stepwise derivation.
      final viaPath = Slip10Mldsa65.fromSeed(
        seed,
      ).derivePath(v['path']! as String);
      expect(_nodeSecret(viaPath), secrets.last);
      node.dispose();
      viaPath.dispose();
    }
  });

  test('nep649 keygen handles (fips204 end-to-end)', () {
    final leaves = [
      (
        '000102030405060708090a0b0c0d0e0f',
        "m/0'/1'/2'/2'/1000000000'",
        'ml-dsa-65-hash:6LMQVvdtSYUurcvSmGawzSeF7iU1XTEyvdwPygVFVEgi',
      ),
      (
        'fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542',
        "m/0'/2147483647'/1'/2147483646'/2'",
        'ml-dsa-65-hash:FKC35xcBdnHW4DiKnaJeCjQXm4piGGtNEwFnZecksiFs',
      ),
      (
        '85d44f13ba9c837a8fe51474cd7b7ed6777591808aca0eb1d5695e914a060c8efbf0ee7e325e24490d69ca824af62071416504ddca17332d2a28bea7377792da',
        "m/44'/397'/0'",
        'ml-dsa-65-hash:9vwLPu52AWDLcuTv6NJrTudA6yAfUYQjScU5123i2pkr',
      ),
      (
        '85d44f13ba9c837a8fe51474cd7b7ed6777591808aca0eb1d5695e914a060c8efbf0ee7e325e24490d69ca824af62071416504ddca17332d2a28bea7377792da',
        "m/44'/397'/1'/0'/1'",
        'ml-dsa-65-hash:JBu84QBdS41ujeAyMwxp8pBpe7R7nC2wfwcgyPmY2WoB',
      ),
    ];
    for (final (seedHex, path, handle) in leaves) {
      final node = Slip10Mldsa65.fromSeed(
        BytesUtils.fromHexString(seedHex),
      ).derivePath(path);
      final kp = node.privateKey.keyPair();
      try {
        expect(kp.publicKey.toBytes().length, 1952);
        expect(_onTrieHandle(kp.publicKey.toBytes()), handle);
      } finally {
        kp.dispose();
        node.dispose();
      }
    }
  });

  test('nep649 defaults and edge cases', () {
    final seed = BytesUtils.fromHexString(
      '85d44f13ba9c837a8fe51474cd7b7ed6777591808aca0eb1d5695e914a060c8efbf0ee7e325e24490d69ca824af62071416504ddca17332d2a28bea7377792da',
    );
    final master = Slip10Mldsa65.fromSeed(seed);
    expect(Nep649Const.defaultShortPath, "m/44'/397'/0'");
    expect(Nep649Const.defaultFullPath, "m/44'/397'/0'/0'/1'");

    // Non-hardened derivation must fail.
    expect(
      () => master.childKey(Bip32KeyIndex(0)),
      throwsA(isA<BuError>()),
    );
    expect(
      () => master.derivePath('m/44/397/0'),
      throwsA(isA<BuError>()),
    );
    // Public-only nodes cannot derive.
    final watchOnly = Slip10Mldsa65.fromPublicKey(master.publicKey.toBytes());
    expect(
      () => watchOnly.childKey(Bip32KeyIndex.hardenIndex(0)),
      throwsA(isA<BuError>()),
    );
    // Seed length 128..512 bits enforced.
    expect(
      () => Slip10Mldsa65.fromSeed(List.filled(15, 1)),
      throwsA(isA<BuError>()),
    );
    expect(
      () => Slip10Mldsa65.fromSeed(List.filled(65, 1)),
      throwsA(isA<BuError>()),
    );
    master.dispose();
    watchOnly.dispose();
  });
  test('mldsa private fromBytes round-trip', () {
    final node = Slip10Mldsa65.fromSeed(
      BytesUtils.fromHexString('000102030405060708090a0b0c0d0e0f'),
    ).derivePath("m/0'");
    final kp = node.privateKey.keyPair();
    try {
      final restored = BaseMLDSAPrivateKey.fromBytes(kp.toBytes());
      try {
        expect(
          restored.publicKey.toBytes().toHex(),
          kp.publicKey.toBytes().toHex(),
        );
      } finally {
        restored.dispose();
      }
      expect(
        () => BaseMLDSAPrivateKey.fromBytes(List.filled(10, 1)),
        throwsA(isA<BuError>()),
      );
    } finally {
      kp.dispose();
      node.dispose();
    }
  });
  test('nep649 coin wiring (Nep649Coins + Nep649 wallet)', () {
    const coin = Nep649Coins.nearMldsa;
    expect(coin.identifier, 3000);
    expect(coin.proposal, CoinProposal.nep649);
    expect(coin.proposal.isBip, true);
    expect(CryptoCoins.fromIdentifier(3000), coin);
    expect(Nep649Coins.fromName('nearMldsa'), coin);
    expect(CryptoCoins.getCoin('nearMldsa', CoinProposal.nep649), coin);
    // Bip44 registry does not carry the coin: derivation lives in Nep649.
    expect(Bip44Coins.fromName('nearMldsa'), isNull);

    final conf = coin.conf;
    expect(conf.type, CryptoKeyType.mldsa65);
    expect(conf.coinIdx, Slip44.nearProtocol);
    expect(conf.coinNames.name, 'Near Protocol');

    final seed = BytesUtils.fromHexString(
      '85d44f13ba9c837a8fe51474cd7b7ed6777591808aca0eb1d5695e914a060c8efbf0ee7e325e24490d69ca824af62071416504ddca17332d2a28bea7377792da',
    );
    // Wallet navigation matches the official vectors and path helpers.
    final master = Nep649.fromSeed(seed, Nep649Coins.nearMldsa);
    expect(master.specName, 'NEP-0649');
    expect(master.level, Bip44Levels.master);
    final short = master.deriveDefaultPath;
    expect(short.level, Bip44Levels.account);
    expect(
      _nodeSecret(short.slip10Object),
      'e82fe9d0fd2a6af0798736fc2ed44907faf66d4a7a543499e7f1c04f18a7d3c4',
    );
    final full = master.purpose.coin
        .account(1)
        .change(Bip44Changes.chainExt)
        .addressIndex(1);
    expect(full.level, Bip44Levels.addressIndex);
    expect(
      _nodeSecret(full.slip10Object),
      'b4a7a302422d48cd8dd0cfd98b3bad14d9f604be7df1cadd8b13c489931de4a0',
    );
    // Address format through the coin config.
    expect(short.publicKey.toAddress.startsWith('ml-dsa-65:'), true);
    expect(
      short.publicKey.toAddress,
      'ml-dsa-65:${Base58Encoder.encode(short.publicKey.toPublicKeyBytes())}',
    );
    master.slip10Object.dispose();
    short.slip10Object.dispose();
    full.slip10Object.dispose();
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(mldsa65Test, 'Slip10Mldsa65');
}
