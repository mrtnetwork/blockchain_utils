import 'package:blockchain_utils/exception/exception.dart';

/// Contains constants related to BIP32 key network versions.
class Bip32KeyNetVersionsConst {
  /// The byte length of a BIP32 key network version.
  static const int keyNetVersionByteLen = 4;
}

class Bip32KeyNetVersions {
  late final List<int> _pubNetVer;
  late final List<int> _privNetVer;

  /// constractur for Bip32KeyNetVersions
  Bip32KeyNetVersions(List<int> pubNetVer, List<int> privNetVer) {
    if (pubNetVer.length != length || privNetVer.length != length) {
      throw const ArgumentException("Invalid key net version length");
    }

    _pubNetVer = pubNetVer;
    _privNetVer = privNetVer;
  }

  /// Get the key net version length.
  static int get length {
    return Bip32KeyNetVersionsConst.keyNetVersionByteLen;
  }

  /// Get public net version.
  List<int> get public {
    return List<int>.from(_pubNetVer);
  }

  /// Get private net version.
  List<int> get private {
    return List<int>.from(_privNetVer);
  }
}
