import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import '../../quick_hex.dart';
import 'test_vector.dart' show testVector;

const String _passphrase = "MRT";
void main() {
  test("bip39", () {
    for (final i in testVector.shuffleTake()) {
      final lower = (i["lang"] as String).replaceAll("_", "").toLowerCase();
      final lang = Bip39Languages.values.firstWhere(
        (element) => element.name.toLowerCase() == lower,
      );
      final mn = Bip39MnemonicGenerator(
        lang,
      ).fromEntropy(BytesUtils.fromHexString(i["entropy"]));
      expect(mn.toStr(), i["mnemonic"]);
      final decode = Bip39MnemonicDecoder(lang).decode(mn.toStr());
      expect(decode.toHex(), i["entropy"]);
      final decodeWithChecksum = Bip39MnemonicDecoder(
        lang,
      ).decodeWithChecksum(mn.toStr());
      expect(decodeWithChecksum.toHex(), i["checksum"]);
      final seed = Bip39SeedGenerator(mn).generate(_passphrase);
      expect(seed.toHex(), i["seed"]);
    }
  });

  test("Validate mnemonic hashes", () {
    for (final i in Bip39Languages.values) {
      final hash = Crc32().quickIntDigest(
        i.wordList.expand((e) => StringUtils.encode(e)).toList(),
      );
      expect(_mnemonicHashes[i], hash);
    }
  });
  test("Validate monero mnemonic hashes", () {
    for (final i in MoneroLanguages.values) {
      final hash = Crc32().quickIntDigest(
        i.wordList.expand((e) => StringUtils.encode(e)).toList(),
      );
      expect(_moneroMnemonicHashes[i], hash);
    }
  });
  test("Validate electrum mnemonic hashes", () {
    for (final i in ElectrumV1Languages.values) {
      final hash = Crc32().quickIntDigest(
        i.wordList.expand((e) => StringUtils.encode(e)).toList(),
      );
      expect(_electrumMnemonicHashes[i], hash);
    }
  });
}

const Map<ElectrumV1Languages, int> _electrumMnemonicHashes = {
  ElectrumV1Languages.english: 458534894,
};

const Map<MoneroLanguages, int> _moneroMnemonicHashes = {
  MoneroLanguages.chineseSimplified: 1454449693,
  MoneroLanguages.dutch: 1405751291,
  MoneroLanguages.english: 3836972269,
  MoneroLanguages.french: 2959809254,
  MoneroLanguages.german: 3820263521,
  MoneroLanguages.italian: 2975200997,
  MoneroLanguages.japanese: 342675788,
  MoneroLanguages.portuguese: 4112333557,
  MoneroLanguages.spanish: 3196358853,
  MoneroLanguages.russian: 2160736786,
};
const Map<Bip39Languages, int> _mnemonicHashes = {
  Bip39Languages.chineseSimplified: 3233653354,
  Bip39Languages.chineseTraditional: 1724483501,
  Bip39Languages.czech: 621209069,
  Bip39Languages.english: 2176441764,
  Bip39Languages.french: 1195320237,
  Bip39Languages.italian: 310547521,
  Bip39Languages.korean: 46702841,
  Bip39Languages.portuguese: 3325037601,
  Bip39Languages.japanese: 1236430910,
  Bip39Languages.spanish: 1146021513,
};
