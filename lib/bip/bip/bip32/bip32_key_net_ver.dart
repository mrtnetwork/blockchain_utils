import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

/// Contains constants related to BIP32 key network versions.
class Bip32KeyNetVersionsConst {
  /// The byte length of a BIP32 key network version.
  static const int keyNetVersionByteLen = 4;
}

class Bip32KeyNetVersions {
  late final List<int> _pubNetVer;
  late final List<int> _privNetVer;
  Bip32KeyNetVersions._(this._pubNetVer, this._privNetVer);

  /// constractur for Bip32KeyNetVersions
  factory Bip32KeyNetVersions(List<int> pubNetVer, List<int> privNetVer) {
    if (pubNetVer.length != length || privNetVer.length != length) {
      throw const ArgumentException("Invalid key net version length");
    }
    return Bip32KeyNetVersions._(
        pubNetVer.asImmutableBytes, privNetVer.asImmutableBytes);
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
