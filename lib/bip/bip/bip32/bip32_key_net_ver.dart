import 'package:blockchain_utils/bip/bip/hd_key/types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

/// Contains constants related to BIP32 key network versions.
class Bip32KeyNetVersionsConst {
  /// The byte length of a BIP32 key network version.
  static const int keyNetVersionByteLen = 4;
}

class Bip32KeyNetVersions implements HDKeyNetVar {
  final List<int> pubNetVer;
  final List<int> privNetVer;
  const Bip32KeyNetVersions.unsafe(this.pubNetVer, this.privNetVer);
  Bip32KeyNetVersions._(List<int> pubNetVer, List<int> privNetVer)
    : pubNetVer = pubNetVer.asImmutableBytes,
      privNetVer = privNetVer.asImmutableBytes;

  /// constractur for Bip32KeyNetVersions
  factory Bip32KeyNetVersions(List<int> pubNetVer, List<int> privNetVer) {
    if (pubNetVer.length != length || privNetVer.length != length) {
      throw ArgumentException.invalidOperationArguments(
        "Bip32KeyNetVersions",
        reason: "Invalid key net version length.",
      );
    }
    return Bip32KeyNetVersions._(
      pubNetVer.asImmutableBytes,
      privNetVer.asImmutableBytes,
    );
  }

  /// Get the key net version length.
  static int get length {
    return Bip32KeyNetVersionsConst.keyNetVersionByteLen;
  }

  /// Get public net version.
  List<int> get public {
    return pubNetVer.clone();
  }

  /// Get private net version.
  List<int> get private {
    return privNetVer.clone();
  }
}
