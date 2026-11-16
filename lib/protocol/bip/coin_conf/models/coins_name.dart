/// A class that represents the names and abbreviations of a cryptocurrency coin.
///
/// It stores the full name and its abbreviation, making it easy to access and display.
class CoinNames {
  /// The full name of the cryptocurrency.
  final String name;

  /// The abbreviation or ticker symbol of the cryptocurrency.
  final String abbreviation;

  const CoinNames(this.name, this.abbreviation);

  @override
  String toString() {
    return name;
  }
}
