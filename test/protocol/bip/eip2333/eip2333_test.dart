import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

void eip2333Test() {
  test('eip2333 master and child vectors', () {
    final vectors = [
      {
        'seed':
            'c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04',
        'master':
            '6083874454709270928345386274498605044986640685124978867557563392430687146096',
        'childIndex': 0,
        'child':
            '20397789859736650942317412262472558107875392172444076792671091975210932703118',
      },
      {
        'seed':
            '3141592653589793238462643383279502884197169399375105820974944592',
        'master':
            '29757020647961307431480504535336562678282505419141012933316116377660817309383',
        'childIndex': 3141592653,
        'child':
            '25457201688850691947727629385191704516744796114925897962676248250929345014287',
      },
      {
        'seed':
            '0099FF991111002299DD7744EE3355BBDD8844115566CC55663355668888CC00',
        'master':
            '27580842291869792442942448775674722299803720648445448686099262467207037398656',
        'childIndex': 4294967295,
        'child':
            '29358610794459428860402234341874281240803786294062035874021252734817515685787',
      },
      {
        'seed':
            'd4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3',
        'master':
            '19022158461524446591288038168518313374041767046816487870552872741050760015818',
        'childIndex': 42,
        'child':
            '31372231650479070279774297061823572166496564838472787488249775572789064611981',
      },
    ];
    for (final v in vectors) {
      final seed = BytesUtils.fromHexString(v['seed']! as String);
      final master = Eip2333Bls.fromSeed(seed);
      expect(master.privateKey.toBigInt().toString(), v['master']);
      final child = master.childKey(Eip2333KeyIndex(v['childIndex']! as int));
      expect(child.privateKey.toBigInt().toString(), v['child']);
      expect(child.depth.toInt(), 1);
      master.dispose();
      child.dispose();
    }
  });

  test('eip2333 path derivation m/12381/3600/0/0', () {
    final seed = BytesUtils.fromHexString(
      'c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04',
    );
    final master = Eip2333Bls.fromSeed(seed);
    final viaPath = master.derivePath('m/12381/3600/0/0');
    Eip2333Bls manual = master
        .childKey(Eip2333KeyIndex(12381))
        .childKey(Eip2333KeyIndex(3600))
        .childKey(Eip2333KeyIndex(0))
        .childKey(Eip2333KeyIndex(0));
    expect(
      viaPath.privateKey.toBigInt().toString(),
      manual.privateKey.toBigInt().toString(),
    );

    final withdrawal = master.derivePath('m/12381/3600/0/0');
    final signing = master.derivePath('m/12381/3600/0/0/0');
    expect(
      signing.privateKey.toBigInt().toString(),
      withdrawal.childKey(Eip2333KeyIndex(0)).privateKey.toBigInt().toString(),
    );
    master.dispose();
  });

  test('eip2334 coin wiring (Eip2334Coins + Eip2334 wallet)', () {
    const coin = Eip2334Coins.ethereumBls;

    expect(coin.identifier, 3001);
    expect(coin.proposal, CoinProposal.eip2334);
    expect(CryptoCoins.fromIdentifier(3001), coin);
    expect(Eip2334Coins.fromName('ethereumBls'), coin);
    expect(CryptoCoins.getCoin('ethereumBls', CoinProposal.eip2334), coin);
    // Bip44 registry does not carry the coin: derivation lives in Eip2334.
    expect(Bip44Coins.fromName('ethereumBls'), isNull);
    final conf = coin.conf;
    expect(conf.type, CryptoKeyType.bls12G1);
    expect(conf.coinIdx, Eip2334Const.ethereumCoinType);

    final seed = BytesUtils.fromHexString(
      'c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04',
    );
    final master = Eip2334.fromSeed(seed, Eip2334Coins.ethereumBls);
    expect(master.specName, 'EIP-2334');
    expect(master.level, Eip2334Levels.master);
    // Navigation matches the engine path helpers.
    final engine = Eip2333Bls.fromSeed(seed);
    final withdrawal = master.deriveDefaultPath;
    expect(withdrawal.level, Eip2334Levels.use);
    expect(
      withdrawal.privateKey.key.toBigInt().toString(),
      engine.derivePath('m/12381/3600/0/0').privateKey.toBigInt().toString(),
    );
    final signing = withdrawal.signingKey;
    expect(signing.level, Eip2334Levels.signing);
    expect(
      signing.privateKey.key.toBigInt().toString(),
      engine.derivePath('m/12381/3600/0/0/0').privateKey.toBigInt().toString(),
    );
    final acc2 = master.purpose.coin.account(2).use(0);
    expect(acc2.level, Eip2334Levels.use);
    expect(
      acc2.privateKey.key.toBigInt().toString(),
      engine.derivePath('m/12381/3600/2/0').privateKey.toBigInt().toString(),
    );
    // Validator keys have no addresses.
    expect(
      () => withdrawal.publicKey.toAddress,
      throwsA(isA<BuError>()),
    );
    // Wrong-level navigation throws.
    expect(() => master.coin, throwsA(isA<BuError>()));
    master.eip2333Object.dispose();
    engine.dispose();
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(eip2333Test, 'Eip2333');
}
