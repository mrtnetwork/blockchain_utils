/*
  The MIT License (MIT)
  
  Copyright (c) 2021 Emanuele Bellocchia

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
  of the Software, and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  
  Note: This code has been adapted from its original Python version to Dart.
*/

/*
  The 3-Clause BSD License
  
  Copyright (c) 2023 Mohsen Haydari (MRTNETWORK)
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  
  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions, and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice, this
     list of conditions, and the following disclaimer in the documentation and/or
     other materials provided with the distribution.
  3. Neither the name of the [organization] nor the names of its contributors may be
     used to endorse or promote products derived from this software without
     specific prior written permission.
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
  OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'bip32_ex.dart';

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
    var pathStr = isAbsolute ? "${Bip32PathConst.masterChar}/" : "";
    for (final elem in elems) {
      if (!elem.isHardened) {
        pathStr += "${elem.toInt()}/";
      } else {
        pathStr += "${Bip32KeyIndex.unhardenIndex(elem.toInt()).toInt()}'/";
      }
    }
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
        path.split("/").where((elem) => elem.isNotEmpty).toList());
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
    final bool isHardened = Bip32PathConst.hardenedChars
        .where((element) => pathElem.endsWith(element))
        .isNotEmpty;

    if (isHardened) {
      pathElem = pathElem.substring(0, pathElem.length - 1);
    }
    final bool isNumeric = int.tryParse(pathElem) != null;
    if (!isNumeric) {
      throw Bip32PathError("Invalid path element ($pathElem)");
    }
    return isHardened
        ? Bip32KeyIndex.hardenIndex(int.parse(pathElem))
        : Bip32KeyIndex(int.parse(pathElem));
  }
}
