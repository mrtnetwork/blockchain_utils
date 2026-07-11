import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  final context = DefaultZCryptoContext();
  test("Sapling/ZIP32", () {
    final i1h = Bip32KeyIndex.hardenIndex(1);
    final i2h = Bip32KeyIndex.hardenIndex(2);
    final i3h = Bip32KeyIndex.hardenIndex(3);
    final m = Zip32Sapling.fromSeed(
      BytesUtils.fromHexString(
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
      ),
    );
    final m1h = m.childKey(i1h, context: context);
    final m1h2h = m.derivePath(
      Bip32Path(elems: [i1h, i2h]).toString(),
      context: context,
    );
    final m1h2h3h = m1h2h.childKey(i3h, context: context);
    final xfvks = [
      m.publicKey,
      m1h.publicKey,
      m1h2h.publicKey,
      m1h2h3h.publicKey,
    ];
    final xsks = [m, m1h, m1h2h, m1h2h3h];
    for (final i in _tVecotr.indexed) {
      final xsk = xsks.elementAt(i.$1);
      final tv = _TestVector.fromJson(i.$2);
      expect(xsk.privateKey.sk.ask.toBytes(), tv.ask);
      expect(xsk.privateKey.sk.nsk.toBytes(), tv.nsk);
      expect(xsk.privateKey.sk.ovk.inner, tv.ovk);
      expect(xsk.privateKey.keyData.dk.inner, tv.dk);
      expect(xsk.privateKey.keyData.chainCode.toBytes(), tv.c);
      final internalXsk = xsk.privateKey.deriveInternal();
      expect(internalXsk.sk.ask.toBytes(), tv.ask);
      expect(internalXsk.sk.nsk.toBytes(), tv.internalNsk);
      expect(internalXsk.sk.ovk.inner, tv.internalOvk);
      expect(internalXsk.keyData.dk.inner, tv.internalDk);
      expect(internalXsk.keyData.chainCode.toBytes(), tv.c);
      expect(internalXsk.toBytes(), tv.internalXsk);

      {
        final xfvk = xfvks.elementAt(i.$1);
        expect(xfvk.fvk.vk.ak.toBytes(), tv.ak);
        expect(xfvk.fvk.vk.nk.toBytes(), tv.nk);
        expect(xfvk.fvk.ovk.inner, tv.ovk);
        expect(xfvk.keyData.dk.toBytes(), tv.dk);
        expect(xfvk.keyData.chainCode.toBytes(), tv.c);
        expect(xfvk.fvk.vk.ivk().toBytes(), tv.ivk);
        DiversifierIndex index = DiversifierIndex.zero();
        (Diversifier, DiversifierIndex)? s = xfvk.keyData.dk.findDiversifier(
          index,
        );
        if (s?.$2 == index) {
          expect(s!.$1.inner, tv.d0);
        } else {
          expect(tv.d0, null);
        }

        index = index.increment();
        s = xfvk.keyData.dk.findDiversifier(index);
        if (s?.$2 == index) {
          expect(s!.$1.inner, tv.d1);
        } else {
          expect(tv.d1, null);
        }
        index = index.increment();
        s = xfvk.keyData.dk.findDiversifier(index);
        if (s?.$2 == index) {
          expect(s!.$1.inner, tv.d2);
        } else {
          expect(tv.d2, null);
        }
        final dmx = DiversifierIndex(List<int>.filled(11, 0xff));
        s = xfvk.keyData.dk.findDiversifier(dmx);
        if (s?.$2 != null) {
          expect(s!.$1.inner, tv.dmax);
        } else {
          expect(tv.dmax, null);
        }
        final internalXfk = xfvk.deriveInternal();
        expect(internalXfk.fvk.vk.ak.toBytes(), tv.ak);
        expect(internalXfk.fvk.vk.nk.toBytes(), tv.internalNk);
        expect(internalXfk.fvk.ovk.inner, tv.internalOvk);
        expect(internalXfk.keyData.dk.inner, tv.internalDk);
        expect(internalXfk.fvk.vk.ivk().toBytes(), tv.internalIvk);
        final dfvk = xfvk.toDiversifiableFullViewingKey();
        final ivk = dfvk.toExternalIvk();
        expect(ivk.toBytes().sublist(0, 32), tv.dk);
        expect(ivk.toBytes().sublist(32), tv.ivk);
        final ivkRt = SaplingIncomingViewingKey.fromBytes(ivk.toBytes());
        expect(ivk.dk.inner, ivkRt.dk.inner);
        expect(ivk.ivk.inner, ivkRt.ivk.inner);
      }
    }
  });
}

class _TestVector {
  List<int>? ask;
  List<int>? nsk;
  List<int> ovk;
  List<int> dk;
  List<int> c;
  List<int> ak;
  List<int> nk;
  List<int> ivk;
  List<int>? xsk;
  List<int> xfvk;
  List<int> fp;
  List<int>? d0;
  List<int>? d1;
  List<int>? d2;
  List<int>? dmax;
  List<int>? internalNsk;
  List<int> internalOvk;
  List<int> internalDk;
  List<int> internalNk;
  List<int> internalIvk;
  List<int>? internalXsk;
  List<int> internalXfvk;
  List<int> internalFp;
  factory _TestVector.fromJson(Map<String, dynamic> json) {
    return _TestVector(
      ovk: json.valueAsBytes("ovk"),
      dk: json.valueAsBytes("dk"),
      c: json.valueAsBytes("c"),
      ak: json.valueAsBytes("ak"),
      nk: json.valueAsBytes("nk"),
      ivk: json.valueAsBytes("ivk"),
      xfvk: json.valueAsBytes("xfvk"),
      fp: json.valueAsBytes("fp"),
      internalOvk: json.valueAsBytes("internalOvk"),
      internalDk: json.valueAsBytes("internalDk"),
      internalNk: json.valueAsBytes("internalNk"),
      internalIvk: json.valueAsBytes("internalIvk"),
      internalXfvk: json.valueAsBytes("internalXfvk"),
      internalFp: json.valueAsBytes("internalFp"),
      ask: json.valueAsBytes("ask"),
      d0: json.valueAsBytes("d0"),
      d1: json.valueAsBytes("d1"),
      d2: json.valueAsBytes("d2"),
      dmax: json.valueAsBytes("dmax"),
      internalNsk: json.valueAsBytes("internalNsk"),
      internalXsk: json.valueAsBytes("internalXsk"),
      nsk: json.valueAsBytes("nsk"),
      xsk: json.valueAsBytes("xsk"),
    );
  }
  _TestVector({
    this.ask,
    this.nsk,
    required this.ovk,
    required this.dk,
    required this.c,
    required this.ak,
    required this.nk,
    required this.ivk,
    this.xsk,
    required this.xfvk,
    required this.fp,
    this.d0,
    this.d1,
    this.d2,
    this.dmax,
    this.internalNsk,
    required this.internalOvk,
    required this.internalDk,
    required this.internalNk,
    required this.internalIvk,
    this.internalXsk,
    required this.internalXfvk,
    required this.internalFp,
  });
}

List<Map<String, dynamic>> _tVecotr = [
  {
    "ask": "b6c00c93d36032b9a268e99e86a860776560bf0e83c1a10b51f607c954742506",
    "nsk": "8204ede83b2f1fbd84f9b45d7f996e2ebd0a030ad243b48ed39f748a8821ea06",
    "ovk": "395884890323b9d4933c021db89bcf767df21977b2ff0683848321a4df4afb21",
    "dk": "77c17cb75b7796afb39f0f3e91c924607da56fa9a20e283509bc8a3ef996a172",
    "c": "d0947c4b03bf72a37ab44f72276d1cf3fdcd7ebf3e73348b7e550d752018668e",
    "ak": "93442e5feffbff16e7217202dc7306729ffffe85af5683bce2642e3eeb5d3871",
    "nk": "dce8e7edece04b8950417f85ba57691b783c45b1a27422db1693dceb67b10106",
    "ivk": "4847a130e799d3dbea36a1c16467d621fb2d80e30b3b1d1a426893415dad6601",
    "xsk":
        "000000000000000000d0947c4b03bf72a37ab44f72276d1cf3fdcd7ebf3e73348b7e550d752018668eb6c00c93d36032b9a268e99e86a860776560bf0e83c1a10b51f607c9547425068204ede83b2f1fbd84f9b45d7f996e2ebd0a030ad243b48ed39f748a8821ea06395884890323b9d4933c021db89bcf767df21977b2ff0683848321a4df4afb2177c17cb75b7796afb39f0f3e91c924607da56fa9a20e283509bc8a3ef996a172",
    "xfvk":
        "000000000000000000d0947c4b03bf72a37ab44f72276d1cf3fdcd7ebf3e73348b7e550d752018668e93442e5feffbff16e7217202dc7306729ffffe85af5683bce2642e3eeb5d3871dce8e7edece04b8950417f85ba57691b783c45b1a27422db1693dceb67b10106395884890323b9d4933c021db89bcf767df21977b2ff0683848321a4df4afb2177c17cb75b7796afb39f0f3e91c924607da56fa9a20e283509bc8a3ef996a172",
    "fp": "14c2713adce93a830ea83a051908b7447783f5d106c0985e02550e426f27597c",
    "d0": "d8621b981cf300e9d4cc89",
    "d1": "48ea17a199c84bd1baa5d4",
    "internalNsk":
        "511233636b95fd0afb6bf8193a7d8f49efd736a988775c54f956687646eaab07",
    "internalOvk":
        "9dc477fe1e7d282913f651654d3985f09d53c2d3b5763d7a723bcbd6ee053d5a",
    "internalDk":
        "40ddc56e6975138c0839e580b54d6d999dc616843cfe041e8f388b124ef7b5ed",
    "internalNk":
        "a3831a5c6933f8ec6aa5ce316c508b7991cd94d3bdb700a1c427a6ae15e72fb5",
    "internalIvk":
        "790577321c511804636ee6baa4eea779b4a46a5a12f85d365074a09d054f3401",
    "internalXsk":
        "000000000000000000d0947c4b03bf72a37ab44f72276d1cf3fdcd7ebf3e73348b7e550d752018668eb6c00c93d36032b9a268e99e86a860776560bf0e83c1a10b51f607c954742506511233636b95fd0afb6bf8193a7d8f49efd736a988775c54f956687646eaab079dc477fe1e7d282913f651654d3985f09d53c2d3b5763d7a723bcbd6ee053d5a40ddc56e6975138c0839e580b54d6d999dc616843cfe041e8f388b124ef7b5ed",
    "internalXfvk":
        "000000000000000000d0947c4b03bf72a37ab44f72276d1cf3fdcd7ebf3e73348b7e550d752018668e93442e5feffbff16e7217202dc7306729ffffe85af5683bce2642e3eeb5d3871a3831a5c6933f8ec6aa5ce316c508b7991cd94d3bdb700a1c427a6ae15e72fb59dc477fe1e7d282913f651654d3985f09d53c2d3b5763d7a723bcbd6ee053d5a40ddc56e6975138c0839e580b54d6d999dc616843cfe041e8f388b124ef7b5ed",
    "internalFp":
        "8264edec63b155001d8496685cc7c21ea957c6f591090a1c20e52a4189b8bb96",
  },
  {
    "ask": "d5f7e92efb7abe04dc8c148b0b3b0fc23e0429f00208ff93b68d21a6e131bd04",
    "nsk": "372a7c6822cbe603f3465c4b9b6558f3a3512decd434012e67bffcf657e5750a",
    "ovk": "2530761933348c1fcf14355433a8d291167fbb37b2ce37ca97160a47ec331c69",
    "dk": "f288400fd65f9adfe3a7c3720aceee0dae050d0a819d619f92e9e2cb4434d526",
    "c": "6fccaa45a8206b063ebb68c610e05927aa94d61be93ec25eb4f82efd68caaedb",
    "ak": "cfca79d337bc689813e409a54e3e72ad8e2f703ae6f8223c9becbde9a8a35f53",
    "nk": "513de64085d35a3adf23d89d5a21cdee4db4c625bd6a3c3c624bef4344141deb",
    "ivk": "f6e75cd980c30eabc61f49ac68f488573ab3e6afe15376375d34e406702ffd02",
    "xsk":
        "0114c2713a010000806fccaa45a8206b063ebb68c610e05927aa94d61be93ec25eb4f82efd68caaedbd5f7e92efb7abe04dc8c148b0b3b0fc23e0429f00208ff93b68d21a6e131bd04372a7c6822cbe603f3465c4b9b6558f3a3512decd434012e67bffcf657e5750a2530761933348c1fcf14355433a8d291167fbb37b2ce37ca97160a47ec331c69f288400fd65f9adfe3a7c3720aceee0dae050d0a819d619f92e9e2cb4434d526",
    "xfvk":
        "0114c2713a010000806fccaa45a8206b063ebb68c610e05927aa94d61be93ec25eb4f82efd68caaedbcfca79d337bc689813e409a54e3e72ad8e2f703ae6f8223c9becbde9a8a35f53513de64085d35a3adf23d89d5a21cdee4db4c625bd6a3c3c624bef4344141deb2530761933348c1fcf14355433a8d291167fbb37b2ce37ca97160a47ec331c69f288400fd65f9adfe3a7c3720aceee0dae050d0a819d619f92e9e2cb4434d526",
    "fp": "768423cb88d22dee91b5b7661e72ed009557eba144c78d1aa71a3e88b6910696",
    "d1": "bcc323e8da39b496c05051",
    "dmax": "2514320d339c666a254c06",
    "internalNsk":
        "5d470f9779cc257f21288f505a4e65b38eb853f1a24563b9f6741726f4d30103",
    "internalOvk":
        "7864e8c79ceaab97e6ae5bca10f7d51df4209ad0d46e80ac180d50d3ff09a670",
    "internalDk":
        "54f11e3fa30d34d6a74def1e6d5daf58cfc7d78b27cb0715c1affa29ae3992fa",
    "internalNk":
        "31424875d6a5ed75de200bb5c1d81aec4dff1650b78bb0cade3c8c7ab03df111",
    "internalIvk":
        "e5426b5b80b1186797016580c1f41c3419683aac77cf8de02f2f9807d150b402",
    "internalXsk":
        "0114c2713a010000806fccaa45a8206b063ebb68c610e05927aa94d61be93ec25eb4f82efd68caaedbd5f7e92efb7abe04dc8c148b0b3b0fc23e0429f00208ff93b68d21a6e131bd045d470f9779cc257f21288f505a4e65b38eb853f1a24563b9f6741726f4d301037864e8c79ceaab97e6ae5bca10f7d51df4209ad0d46e80ac180d50d3ff09a67054f11e3fa30d34d6a74def1e6d5daf58cfc7d78b27cb0715c1affa29ae3992fa",
    "internalXfvk":
        "0114c2713a010000806fccaa45a8206b063ebb68c610e05927aa94d61be93ec25eb4f82efd68caaedbcfca79d337bc689813e409a54e3e72ad8e2f703ae6f8223c9becbde9a8a35f5331424875d6a5ed75de200bb5c1d81aec4dff1650b78bb0cade3c8c7ab03df1117864e8c79ceaab97e6ae5bca10f7d51df4209ad0d46e80ac180d50d3ff09a67054f11e3fa30d34d6a74def1e6d5daf58cfc7d78b27cb0715c1affa29ae3992fa",
    "internalFp":
        "1287c379023569164eb523ffdd72031c35e1859f3ef8d4830a2991ba7e15de2d",
  },
  {
    "ask": "7ff35db69e13c36f59ad9c08d32d5227378da0cff971fd424baef9a6332f5106",
    "nsk": "779c6ee4a03944eba28bc9bdc1329a391407f48c410d5ae0a364f59959bfde00",
    "ovk": "d9fc7101bf907f41886a7330a5d6a7bd23535e305eb7679bc23d7605936185ac",
    "dk": "e4699e9a86e031c54b21cdd0960ac18ddd61ec9f7ae98d5582a6faf65f3248d1",
    "c": "4479086c75d080796020f500c1e30a54cfe29dda36f2144fb33a50806fbef7da",
    "ak": "9a853f9544713797e0851764da392e68534b1d948dae4742ee765c727572ab4e",
    "nk": "f166a28a4f88cec12141a82d2120bd6d8caf879c9a1b3ad2118501364f5d4fbe",
    "ivk": "33bd46015a2cad17d6e015eb88861b0c917796246570521c9e1ae4b1c8311d06",
    "xsk":
        "02768423cb020000804479086c75d080796020f500c1e30a54cfe29dda36f2144fb33a50806fbef7da7ff35db69e13c36f59ad9c08d32d5227378da0cff971fd424baef9a6332f5106779c6ee4a03944eba28bc9bdc1329a391407f48c410d5ae0a364f59959bfde00d9fc7101bf907f41886a7330a5d6a7bd23535e305eb7679bc23d7605936185ace4699e9a86e031c54b21cdd0960ac18ddd61ec9f7ae98d5582a6faf65f3248d1",
    "xfvk":
        "02768423cb020000804479086c75d080796020f500c1e30a54cfe29dda36f2144fb33a50806fbef7da9a853f9544713797e0851764da392e68534b1d948dae4742ee765c727572ab4ef166a28a4f88cec12141a82d2120bd6d8caf879c9a1b3ad2118501364f5d4fbed9fc7101bf907f41886a7330a5d6a7bd23535e305eb7679bc23d7605936185ace4699e9a86e031c54b21cdd0960ac18ddd61ec9f7ae98d5582a6faf65f3248d1",
    "fp": "0bdc2d2b6eb1f927cbabdbb9d43db8de857bb716df86cecf081e1a2b74fcad55",
    "internalNsk":
        "7b17176527f917990f9f5179cb23c16ec0a926edc41ab2ba42137bef5c209f09",
    "internalOvk":
        "c612cbc977307e5352a1588bd70f41af11e73b7bc6bcbc732aa306c21cd00f3a",
    "internalDk":
        "35ef4d265951dcaaec26ef8fbdf84c92b790049d0993772efb4397f04930f167",
    "internalNk":
        "8d0555e8e020c9d360685d242f2ba9f774613fa09401f125bca929eca486a3d1",
    "internalIvk":
        "7f7ceefa65428e8b7076191a2393957b9c095061d8cce1283dd15c2b5e8fc305",
    "internalXsk":
        "02768423cb020000804479086c75d080796020f500c1e30a54cfe29dda36f2144fb33a50806fbef7da7ff35db69e13c36f59ad9c08d32d5227378da0cff971fd424baef9a6332f51067b17176527f917990f9f5179cb23c16ec0a926edc41ab2ba42137bef5c209f09c612cbc977307e5352a1588bd70f41af11e73b7bc6bcbc732aa306c21cd00f3a35ef4d265951dcaaec26ef8fbdf84c92b790049d0993772efb4397f04930f167",
    "internalXfvk":
        "02768423cb020000804479086c75d080796020f500c1e30a54cfe29dda36f2144fb33a50806fbef7da9a853f9544713797e0851764da392e68534b1d948dae4742ee765c727572ab4e8d0555e8e020c9d360685d242f2ba9f774613fa09401f125bca929eca486a3d1c612cbc977307e5352a1588bd70f41af11e73b7bc6bcbc732aa306c21cd00f3a35ef4d265951dcaaec26ef8fbdf84c92b790049d0993772efb4397f04930f167",
    "internalFp":
        "e0baa5dbb806c721333c6308345fc51c2dc1e009da044778a3c3294d6817a3c4",
  },
  {
    "ask": "4593d24d21e35937f152cf90461c332f69503c104581d683e0ac29f84decaf07",
    "nsk": "1ac87ec2123f5057e3c0f858e80dfa0ee4553ded27b7b5abfbb6fa6effa7bb0b",
    "ovk": "1e36ea0cf2be2e9d6ce380a8af18e75da9225551fbef8b98311b5c9c1b4b9ee3",
    "dk": "57fc6c59a4f3ad5a6f609db671d28cbf703f0d14dc363aaaed70729c107bbb6a",
    "c": "33dc012d7690ced2cd2bcb2cc3e463e28d8c29ef3b01be59b2bdfc385bbdc74b",
    "ak": "9c6d859a752c305d6263de95f2fcf734b126df2456c7d31bc601c8ddec409112",
    "nk": "d3ee41f84b5a9508b61d29b2fb45636d19aa10d782cd978cfe6715492fcd224e",
    "ivk": "d138e137c6671de782fb01ba911d9864bebc4436ccb388b4c1ce0256a8db7401",
    "xsk":
        "030bdc2d2b0300008033dc012d7690ced2cd2bcb2cc3e463e28d8c29ef3b01be59b2bdfc385bbdc74b4593d24d21e35937f152cf90461c332f69503c104581d683e0ac29f84decaf071ac87ec2123f5057e3c0f858e80dfa0ee4553ded27b7b5abfbb6fa6effa7bb0b1e36ea0cf2be2e9d6ce380a8af18e75da9225551fbef8b98311b5c9c1b4b9ee357fc6c59a4f3ad5a6f609db671d28cbf703f0d14dc363aaaed70729c107bbb6a",
    "xfvk":
        "030bdc2d2b0300008033dc012d7690ced2cd2bcb2cc3e463e28d8c29ef3b01be59b2bdfc385bbdc74b9c6d859a752c305d6263de95f2fcf734b126df2456c7d31bc601c8ddec409112d3ee41f84b5a9508b61d29b2fb45636d19aa10d782cd978cfe6715492fcd224e1e36ea0cf2be2e9d6ce380a8af18e75da9225551fbef8b98311b5c9c1b4b9ee357fc6c59a4f3ad5a6f609db671d28cbf703f0d14dc363aaaed70729c107bbb6a",
    "fp": "df0a89bd883539c07b89e04c92764ec2d159690f5ad5dd3d0ad8ac2969de22c8",
    "dmax": "b831c2965a860ad760ec2a",
    "internalNsk":
        "9c393c5bd7664d63efa1baea99fc6dc474fea753ce84c881d9ef28778675b105",
    "internalOvk":
        "69aab02ea643579d4d852af8b432b88d1ca000444ab0737a4115e063f148d272",
    "internalDk":
        "8826a93c65c66e75543274e672adf559f7d7265e99cc11da4a1420a37b92f7ab",
    "internalNk":
        "59baa90f834a661bf2be4246a43d189c7d0e17a8247b4fd9d2e153a5973dc8ec",
    "internalIvk":
        "8a86fb2781fe6f24d960dddb2f7813c031fec55d26ccdee1f7182a3ec683cf04",
    "internalXsk":
        "030bdc2d2b0300008033dc012d7690ced2cd2bcb2cc3e463e28d8c29ef3b01be59b2bdfc385bbdc74b4593d24d21e35937f152cf90461c332f69503c104581d683e0ac29f84decaf079c393c5bd7664d63efa1baea99fc6dc474fea753ce84c881d9ef28778675b10569aab02ea643579d4d852af8b432b88d1ca000444ab0737a4115e063f148d2728826a93c65c66e75543274e672adf559f7d7265e99cc11da4a1420a37b92f7ab",
    "internalXfvk":
        "030bdc2d2b0300008033dc012d7690ced2cd2bcb2cc3e463e28d8c29ef3b01be59b2bdfc385bbdc74b9c6d859a752c305d6263de95f2fcf734b126df2456c7d31bc601c8ddec40911259baa90f834a661bf2be4246a43d189c7d0e17a8247b4fd9d2e153a5973dc8ec69aab02ea643579d4d852af8b432b88d1ca000444ab0737a4115e063f148d2728826a93c65c66e75543274e672adf559f7d7265e99cc11da4a1420a37b92f7ab",
    "internalFp":
        "3f63161d5b437204f7012a3a1d36581dab397a843b2c589811edcc5b501cd4eb",
  },
];
