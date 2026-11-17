import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Constants related to the BIP32 derivation path components.
class Bip32PathConst {
  /// List of characters representing hardened keys in the path.
  static const List<String> hardenedChars = ["'", "h", "p"];

  /// Character representing the master key in the path.
  static const String masterChar = "m";
}

/// Represents a BIP32 derivation path, a sequence of key indices.
class Bip32Path {
  /// List of BIP32 key indices in the path.
  final List<Bip32KeyIndex> elems;

  /// Indicates whether the path is absolute (starting from the master key).
  final bool isAbsolute;

  /// Creates a Bip32Path instance.
  ///
  /// [elems] is an optional list of key indices in the path.
  /// [isAbsolute] specifies if the path is absolute (default: true).
  Bip32Path({List<Bip32KeyIndex> elems = const [], this.isAbsolute = true})
    : elems = elems.immutable;

  /// Adds a key index element to the path and returns a new Bip32Path.
  Bip32Path addElem(Bip32KeyIndex elem) {
    return Bip32Path(elems: [...elems, elem], isAbsolute: isAbsolute);
  }

  /// Returns the length of the BIP32 path.
  int length() {
    return elems.length;
  }

  /// Converts the BIP32 path to a list of integer key indices.
  List<int> toList() {
    return [for (final elem in elems) elem.toInt()];
  }

  /// override toString for return absolute path
  @override
  String toString() {
    return toPath();
  }

  String toPath() {
    var pathStr = isAbsolute ? "${Bip32PathConst.masterChar}/" : "";
    for (final elem in elems) {
      if (!elem.isHardened) {
        pathStr += "${elem.toInt()}/";
      } else {
        pathStr += "${Bip32KeyIndex.unhardenIndex(elem.toInt()).toInt()}'/";
      }
    }
    if (pathStr.isEmpty) return pathStr;
    return pathStr.substring(0, pathStr.length - 1);
  }
}

/// A utility class for parsing BIP32 derivation paths and converting them to Bip32Path objects.
class Bip32PathParser {
  /// Parses a BIP32 derivation path represented as a string and returns a Bip32Path object.
  ///
  /// [path] is the BIP32 path string to be parsed.
  static Bip32Path parse(String path) {
    if (path.endsWith("/")) {
      path = path.substring(0, path.length - 1);
    }

    return _parseElements(
      path.split("/").where((elem) => elem.isNotEmpty).toList(),
    );
  }

  /// Parses individual elements of a BIP32 path and constructs a Bip32Path object.
  ///
  /// [pathElems] is a list of path elements to be parsed.
  static Bip32Path _parseElements(List<String> pathElems) {
    bool isAbsolute = false;

    if (pathElems.isNotEmpty && pathElems[0] == Bip32PathConst.masterChar) {
      pathElems = pathElems.sublist(1);
      isAbsolute = true;
    }

    final List<Bip32KeyIndex> parsedElems = pathElems.map(_parseElem).toList();
    return Bip32Path(elems: parsedElems, isAbsolute: isAbsolute);
  }

  /// Parses an individual path element and returns a Bip32KeyIndex object.
  ///
  /// [pathElem] is the path element to be parsed.
  static Bip32KeyIndex _parseElem(String pathElem) {
    pathElem = pathElem.trim();
    final bool isHardened =
        Bip32PathConst.hardenedChars
            .where((element) => pathElem.endsWith(element))
            .isNotEmpty;

    if (isHardened) {
      pathElem = pathElem.substring(0, pathElem.length - 1);
    }
    final bool isNumeric = int.tryParse(pathElem) != null;
    if (!isNumeric) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid path element.",
        details: {"path": pathElem},
      );
    }
    return isHardened
        ? Bip32KeyIndex.hardenIndex(int.parse(pathElem))
        : Bip32KeyIndex(int.parse(pathElem));
  }
}
