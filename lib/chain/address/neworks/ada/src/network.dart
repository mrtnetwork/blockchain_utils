import 'package:blockchain_utils/exception/exception/core_errors.dart';

/// An enumeration of Ada Shelley address network tags.
enum ADANetwork {
  /// Mainnet network tag with a value of 1.
  mainnet("mainnet", 1, 764824073),

  /// Testnet network tag with a value of 0.
  /// This network does not exist anymore.
  testnet("testnet", 0, 1097911063),

  /// Testnet network tag with a value of 0.
  testnetPreview("testnetPreview", 0, 2),

  /// Testnet network tag with a value of 0.
  testnetPreprod("testnetPreprod", 0, 1);

  final int value;
  final int protocolMagic;
  final String name;

  const ADANetwork(this.name, this.value, this.protocolMagic);

  bool get isTestnet => this != mainnet;

  /// Get the first network matching [tag] (ambiguous for testnets, which
  /// all share tag 0 - use [fromTags] or [fromProtocolMagic] to disambiguate).
  static ADANetwork fromTag(int tag) {
    return values.firstWhere(
      (element) => element.value == tag,
      orElse: () => throw CoreErrors.addressValidationFailed(),
    );
  }

  /// Get all networks matching [tag].
  static List<ADANetwork> fromTags(int tag) {
    final tags = values.where((element) => element.value == tag).toList();
    if (tags.isEmpty) throw CoreErrors.addressValidationFailed();
    return tags;
  }

  /// Get the network matching [protocolMagic], or mainnet if null.
  static ADANetwork fromProtocolMagic(int? protocolMagic) {
    if (protocolMagic == null) return ADANetwork.mainnet;
    return values.firstWhere(
      (element) => element.protocolMagic == protocolMagic,
      orElse: () => throw CoreErrors.addressValidationFailed(),
    );
  }

  @override
  String toString() {
    return "ADANetwork.$name";
  }
}
