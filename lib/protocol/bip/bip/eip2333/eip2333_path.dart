import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_data.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Path constants, mirrors `Bip32PathConst`.
class Eip2333PathConst {
  /// Master identifier.
  static const String masterChar = 'm';
}

// (purpose + ETH coin type) path; EIP-2333 defines no path itself.
/// Derivation path for EIP-2333 keys (EIP-2334 layout), e.g. `m/12381/3600/0/0`.
///
/// Hardened markers (`'`, `h`, `p`) are rejected: EIP-2334 paths do not
/// support hardened keys.
class Eip2333Path {
  final List<Eip2333KeyIndex> elems;
  final bool isAbsolute;
  Eip2333Path({List<Eip2333KeyIndex> elems = const [], this.isAbsolute = true})
    : elems = elems.immutable;

  Eip2333Path addElem(Eip2333KeyIndex elem) {
    return Eip2333Path(elems: [...elems, elem], isAbsolute: isAbsolute);
  }

  int length() => elems.length;
  List<int> toList() => [for (final e in elems) e.toInt()];

  @override
  String toString() => toPath();

  String toPath() {
    var pathStr = isAbsolute ? '${Eip2333PathConst.masterChar}/' : '';
    for (final elem in elems) {
      pathStr += '${elem.toInt()}/';
    }
    if (pathStr.isEmpty) return pathStr;
    return pathStr.substring(0, pathStr.length - 1);
  }
}

/// Parser for EIP-2333 paths, mirrors `Bip32PathParser`.
class Eip2333PathParser {
  static const List<String> _forbiddenSuffix = ["'", 'h', 'p', 'H'];

  static Eip2333Path parse(String path) {
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return _parseElements(path.split('/').where((e) => e.isNotEmpty).toList());
  }

  static Eip2333Path _parseElements(List<String> pathElems) {
    bool isAbsolute = false;
    if (pathElems.isNotEmpty && pathElems[0] == Eip2333PathConst.masterChar) {
      pathElems = pathElems.sublist(1);
      isAbsolute = true;
    }
    final parsed = pathElems.map(_parseElem).toList();
    return Eip2333Path(elems: parsed, isAbsolute: isAbsolute);
  }

  static Eip2333KeyIndex _parseElem(String elem) {
    elem = elem.trim();
    for (final s in _forbiddenSuffix) {
      if (elem.endsWith(s)) {
        throw BuError(DefaultErrorType.unsupported,
          'Hardened keys are not supported in EIP-2333/EIP-2334.',
          details: {'path': elem},
        );
      }
    }
    if (int.tryParse(elem) == null) {
      throw BuError(DefaultErrorType.invalidArgument,'Invalid path element.', details: {'path': elem});
    }
    return Eip2333KeyIndex(int.parse(elem));
  }
}
