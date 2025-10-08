import 'dart:math';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

List<int> bip39MnemonicToBytes(Mnemonic mnemonic) {
  final decoder = Bip39MnemonicDecoder();
  final language = decoder.findLanguage(mnemonic);

  final mnemonicBinStr = decoder.mnemonicToBinaryStr(mnemonic, language.item1);
  final mnemonicBitLen = mnemonicBinStr.length;
  final padBitLen = mnemonicBitLen % 8 == 0
      ? mnemonicBitLen
      : mnemonicBitLen + (8 - mnemonicBitLen % 8);
  final result =
      BytesUtils.fromBinary(mnemonicBinStr, zeroPadByteLen: padBitLen);
  return [mnemonic.wordsCount(), ...result];
}

// Bytes → Mnemonic
List<String> bytesToBip39Mnemonic(List<int> bytes) {
  int length = bytes[0];
  bytes = bytes.sublist(1);
  final toBinary = BytesUtils.toBinary(bytes,
      zeroPadBitLen: length * Bip39MnemonicConst.wordBitLen);
  bytes = bytes.sublist(1);
  final words = <String>[];
  for (var i = 0;
      i + Bip39MnemonicConst.wordBitLen <= toBinary.length;
      i += Bip39MnemonicConst.wordBitLen) {
    final wordBinStr = toBinary.substring(i, i + Bip39MnemonicConst.wordBitLen);
    final wordIdx = int.parse(wordBinStr, radix: 2);
    words.add(Bip39Languages.english.wordList[wordIdx]);
  }
  return words;
}

void main() {
  print([
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
  ].join(" "));
  // return;
  // for (int c = 8; c < 41; c++) {
  //   for (int i = 0; i < 1000; i++) {
  //     final mnemoci = List.generate(
  //         c,
  //         (i) => Bip39Languages.english.wordList
  //             .elementAt(Random.secure().nextInt(2048)));
  //     // print(mnemoci.toStr());
  //     assert(CompareUtils.iterableIsEqual(
  //         bytesToBip39Mnemonic(
  //             bip39MnemonicToBytes(Mnemonic.fromList(mnemoci))),
  //         mnemoci.toList()));
  //     print('done!');
  //   }
  // }
  // return;
  group("Ton Mnemonic", _test);
}

void _test() {
  test("mnemonic seed generator", () {
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
    expect(privateKey.publicKey.toHex(withPrefix: false),
        "cd1fea46e4a59115211ed483161bb315a8e0028ae190b24c1838351dc0bdf040");
  });

  test("mnemonic seed generator_2", () {
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
    expect(privateKey.toHex(),
        "ab460eb3462747a1e57e75e2c6a3afab420a7a297f53d5258b9b7fe25113cebe");
  });

  test("mnemonic with password", () {
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
    expect(privateKey.toHex(),
        "b91ad008bdf851289acaa77401612674ea3906eba0ca044374ff38f2a170ba85");
    print(privateKey.publicKey.toHex());
  });
  test("validate mnemonic", () {
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
    expect(validator.isValid(Mnemonic.fromList(mnemonic)), false);
    expect(
        validator.isValid(Mnemonic.fromList(mnemonic), password: "MRTNETWORK"),
        true);
  });
}
