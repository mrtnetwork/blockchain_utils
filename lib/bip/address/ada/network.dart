import 'package:blockchain_utils/bip/address/exception/exception.dart';

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

  /// Constants representing header types for Ada Shelley addresses.
  const ADANetwork(this.name, this.value, this.protocolMagic);

  bool get isTestnet => this != mainnet;

  static ADANetwork fromTag(int tag) {
    return values.firstWhere(
      (element) => element.value == tag,
      orElse: () => throw AddressConverterException.addressValidationFailed(),
    );
  }

  static List<ADANetwork> fromTags(int tag) {
    final tags = values.where((element) => element.value == tag).toList();
    if (tags.isEmpty) throw AddressConverterException.addressValidationFailed();
    return tags;
  }

  static ADANetwork fromProtocolMagic(int? protocolMagic) {
    if (protocolMagic == null) return ADANetwork.mainnet;
    return values.firstWhere(
      (element) => element.protocolMagic == protocolMagic,
      orElse: () => throw AddressConverterException.addressValidationFailed(),
    );
  }

  @override
  String toString() {
    return "ADANetwork.$name";
  }
}
