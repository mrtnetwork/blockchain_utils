/// Library for Monero mnemonic language support.
library;

import 'package:blockchain_utils/bip/monero/mnemonic/monero_mnemonic.dart';

/// Part for the Chinese Simplified Monero mnemonic language.
part 'chinese_simplified.dart';

/// Part for the English Monero mnemonic language.
part 'english.dart';

/// Part for the Spanish Monero mnemonic language.
part 'spanish.dart';

/// Part for the French Monero mnemonic language.
part 'french.dart';

/// Part for the Italian Monero mnemonic language.
part 'italian.dart';

/// Part for the Japanese Monero mnemonic language.
part 'japanese.dart';

/// Part for the Portuguese Monero mnemonic language.
part 'portuguese.dart';

/// Part for the Dutch Monero mnemonic language.
part 'dutch.dart';

/// Part for the German Monero mnemonic language.
part 'german.dart';

/// Part for the Russian Monero mnemonic language.
part 'russian.dart';

/// A function that returns a list of words for a specific Monero language.
List<String> moneroMnemonicWorsList(MoneroLanguages language) {
  switch (language) {
    case MoneroLanguages.chineseSimplified:
      return _chineseSimplified;
    case MoneroLanguages.dutch:
      return _dutch;
    case MoneroLanguages.english:
      return _english;
    case MoneroLanguages.french:
      return _french;
    case MoneroLanguages.german:
      return _german;
    case MoneroLanguages.italian:
      return _italian;
    case MoneroLanguages.japanese:
      return _japanese;
    case MoneroLanguages.portuguese:
      return _portuguese;
    case MoneroLanguages.spanish:
      return _spanish;
    case MoneroLanguages.russian:
      return _russian;
    default:
      throw UnimplementedError(
          "monero mnemonic does not support ${language.name}");
  }
}
