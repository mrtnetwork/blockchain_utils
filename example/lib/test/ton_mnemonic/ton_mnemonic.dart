import 'package:blockchain_utils/blockchain_utils.dart';

void tonMnemonic() {
  _test();
  _test2();
  _test3();
  _test4();
}

void _test() {
  final mnemonic = [
    "current",
    "phrase",
    "now",
    "sea",
    "verify",
    "chapter",
    "rain",
    "below",
    "office",
    "voice",
    "trade",
    "share",
    "inject",
    "impulse",
    "empower",
    "bitter",
    "fee",
    "half",
    "excess",
    "oval",
    "genuine",
    "happy",
    "wrong",
    "trust"
  ];
  final seed =
      TonSeedGenerator(Mnemonic.fromList(mnemonic)).generate(password: "");
  final privateKey = Ed25519PrivateKey.fromBytes(
      seed.sublist(0, Ed25519KeysConst.privKeyByteLen));
  assert(privateKey.publicKey.toHex(withPrefix: false) ==
      "cd1fea46e4a59115211ed483161bb315a8e0028ae190b24c1838351dc0bdf040");
}

void _test2() {
  final mnemonic = [
    "smoke",
    "area",
    "audit",
    "artist",
    "tennis",
    "owner",
    "salute",
    "donate",
    "hole",
    "victory",
    "such",
    "boost",
    "ahead",
    "jeans",
    "protect",
    "decade",
    "report",
    "float",
    "rather",
    "sheriff",
    "salad",
    "supreme",
    "acquire",
    "bulb"
  ];
  final seed =
      TonSeedGenerator(Mnemonic.fromList(mnemonic)).generate(password: "");
  final privateKey = Ed25519PrivateKey.fromBytes(
      seed.sublist(0, Ed25519KeysConst.privKeyByteLen));
  assert(privateKey.toHex() ==
      "ab460eb3462747a1e57e75e2c6a3afab420a7a297f53d5258b9b7fe25113cebe");
}

void _test3() {
  final mnemonic = [
    "woman",
    "harvest",
    "crawl",
    "blind",
    "piece",
    "portion",
    "draft",
    "write",
    "win",
    "coil",
    "lawsuit",
    "illegal"
  ];
  final seed = TonSeedGenerator(Mnemonic.fromList(mnemonic))
      .generate(password: "MRTNETWORK");
  final privateKey = Ed25519PrivateKey.fromBytes(
      seed.sublist(0, Ed25519KeysConst.privKeyByteLen));
  assert(privateKey.toHex() ==
      "b91ad008bdf851289acaa77401612674ea3906eba0ca044374ff38f2a170ba85");
}

void _test4() {
  final mnemonic = [
    "woman",
    "harvest",
    "crawl",
    "blind",
    "piece",
    "portion",
    "draft",
    "write",
    "win",
    "coil",
    "lawsuit",
    "illegal"
  ];
  final validator = TomMnemonicValidator();
  assert(validator.isValid(Mnemonic.fromList(mnemonic)), false);
  assert(validator.isValid(Mnemonic.fromList(mnemonic), password: "MRTNETWORK"),
      true);
}
