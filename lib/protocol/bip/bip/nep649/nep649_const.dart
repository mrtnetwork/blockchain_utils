import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';

/// Constants for NEP-649 paths, mirrors `Bip44Const` + `Eip2334Const`.
class Nep649Const {
  /// The name of the NEP-649 specification.
  static const String specName = 'NEP-0649';

  /// BIP-44 purpose level.
  static const int purpose = 44;

  /// The purpose index for NEP-649, derived as a hardened index (44').
  static final Bip32KeyIndex purposeIndex = Bip32KeyIndex.hardenIndex(purpose);

  /// NEAR coin type (`Slip44.nearProtocol`).
  static const int nearCoinType = 397;

  /// Default short path `m/44'/397'/0'`.
  static const String defaultShortPath = "m/44'/397'/0'";

  /// Default full path `m/44'/397'/0'/0'/1'`.
  static const String defaultFullPath = "m/44'/397'/0'/0'/1'";
}
