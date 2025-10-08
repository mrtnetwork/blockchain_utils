/// The `bip39_menemonic_languages` library provides a collection of mnemonic word lists
/// for different languages as defined in BIP-39 (Bitcoin Improvement Proposal 39).
/// These word lists are used for creating and recovering cryptocurrency wallets.

library;

import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic.dart';

/// Part for the Chinese Simplified BIP-39 mnemonic word list.
part 'chinese_simplified.dart';

/// Part for the Chinese Traditional BIP-39 mnemonic word list.
part 'chinese_traditional.dart';

/// Part for the English BIP-39 mnemonic word list.
part 'english.dart';

/// Part for the Spanish BIP-39 mnemonic word list.
part 'spanish.dart';

/// Part for the Czech BIP-39 mnemonic word list.
part 'czech.dart';

/// Part for the French BIP-39 mnemonic word list.
part 'french.dart';

/// Part for the Italian BIP-39 mnemonic word list.
part 'italian.dart';

/// Part for the Japanese BIP-39 mnemonic word list.
part 'japanese.dart';

/// Part for the Korean BIP-39 mnemonic word list.
part 'korean.dart';

/// Part for the Portuguese BIP-39 mnemonic word list.
part 'portuguese.dart';

/// Returns the BIP-39 word list for the specified language.
List<String> bip39WordList(Bip39Languages language) {
  switch (language) {
    case Bip39Languages.english:
      return _english;
    case Bip39Languages.spanish:
      return _spanish;
    case Bip39Languages.portuguese:
      return _portuguese;
    case Bip39Languages.korean:
      return _korean;
    case Bip39Languages.japanese:
      return _japanese;
    case Bip39Languages.italian:
      return _italian;
    case Bip39Languages.french:
      return _french;
    case Bip39Languages.czech:
      return _czech;
    case Bip39Languages.chineseTraditional:
      return _chineseTraditional;
    case Bip39Languages.chineseSimplified:
      return _chineseSimplified;
    default:
      return _english;
  }
}
