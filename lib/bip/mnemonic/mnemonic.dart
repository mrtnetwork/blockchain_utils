/// Represents a mnemonic phrase used for various cryptographic purposes.
/// It encapsulates a list of mnemonic words and provides methods for working
/// with these words.
class Mnemonic {
  final List<String> _mnemonicList;

  /// Creates a new Mnemonic instance from a list of mnemonic words.
  Mnemonic(this._mnemonicList);

  /// Creates a new Mnemonic instance from a mnemonic phrase provided as a string.
  /// The provided mnemonic string is normalized into a list of words.
  Mnemonic.fromString(String mnemonicStr)
      : _mnemonicList = List<String>.unmodifiable(_normalize(mnemonicStr));

  /// Creates a new Mnemonic instance from a list of mnemonic words.
  Mnemonic.fromList(List<String> mnemonicList)
      : _mnemonicList = List<String>.unmodifiable(mnemonicList);

  /// Returns the number of words in the mnemonic phrase.
  int wordsCount() {
    return _mnemonicList.length;
  }

  /// Returns the mnemonic phrase as a list of words.
  List<String> toList() {
    return _mnemonicList;
  }

  /// Returns the mnemonic phrase as a string with words separated by spaces.
  String toStr() {
    return _mnemonicList.join(' ');
  }

  /// Returns the mnemonic phrase as a string with words separated by spaces.
  @override
  String toString() {
    return "${toStr().substring(0, toStr().length ~/ 3)}...";
  }

  /// Normalizes a mnemonic string by splitting it into a list of words.
  static List<String> _normalize(String mnemonic) {
    return mnemonic.split(' ');
  }
}
