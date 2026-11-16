import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_key_data.dart';

class Eip2334Const {
  /// The name of the EIP-2334 specification.
  static const String specName = 'EIP-2334';

  /// Purpose `12381` (BLS12-381). MUST only be used with EIP-2333 KDF.
  static const int purpose = 12381;

  /// Purpose index (plain: EIP-2334 paths have no hardened keys).
  static final Eip2333KeyIndex purposeIndex = Eip2333KeyIndex(purpose);

  /// Ethereum Beacon-chain coin type `3600 (= 60^2)`.
  static const int ethereumCoinType = 3600;

  /// Fixed `use` level for withdrawal keys and their signing children.
  static const int withdrawalUse = 0;
  static const int signingUse = 0;
}
