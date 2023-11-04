import 'bip32_key_net_ver.dart';

/// The `Bip32Const` class defines constants for different Bip32KeyNetVersions.
class Bip32Const {
  /// mainnet key net version
  static final Bip32KeyNetVersions mainNetKeyNetVersions = Bip32KeyNetVersions(
      List<int>.from([0x04, 0x88, 0xb2, 0x1e]),
      List<int>.from([0x04, 0x88, 0xad, 0xe4]));

  /// testnet key network version
  static final Bip32KeyNetVersions testNetKeyNetVersions = Bip32KeyNetVersions(
      List<int>.from([0x04, 0x35, 0x87, 0xcf]),
      List<int>.from([0x04, 0x35, 0x83, 0x94]));

  /// kholaw key net version
  static Bip32KeyNetVersions kholawKeyNetVersions = Bip32KeyNetVersions(
      List<int>.from([0x04, 0x88, 0xb2, 0x1e]),
      List<int>.from([0x0f, 0x43, 0x31, 0xd4]));
}
