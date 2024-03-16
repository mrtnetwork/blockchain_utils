import 'package:blockchain_utils/exception/exception.dart';

/// An enumeration of Ada Shelley address network tags.
class ADANetwork {
  /// Mainnet network tag with a value of 1.
  static const ADANetwork mainnet = ADANetwork._("mainnet", 1, 764824073);

  /// Testnet network tag with a value of 0.
  /// This network does not exist anymore.
  static const ADANetwork testnet = ADANetwork._("testnet", 0, 1097911063);

  /// Testnet network tag with a value of 0.
  static const ADANetwork testnetPreview = ADANetwork._("testnetPreview", 0, 2);

  /// Testnet network tag with a value of 0.
  static const ADANetwork testnetPreprod = ADANetwork._("testnetPreprod", 0, 1);

  final int value;
  final int protocolMagic;
  final String name;

  /// Constants representing header types for Ada Shelley addresses.
  const ADANetwork._(this.name, this.value, this.protocolMagic);

  static const List<ADANetwork> values = [
    mainnet,
    testnet,
    testnetPreview,
    testnetPreprod
  ];

  static ADANetwork fromTag(int tag) {
    return values.firstWhere(
      (element) => element.value == tag,
      orElse: () => throw ArgumentException("Invalid network tag. $tag"),
    );
  }

  static ADANetwork fromProtocolMagic(int? protocolMagic) {
    if (protocolMagic == null) return ADANetwork.mainnet;
    return values.firstWhere(
      (element) => element.protocolMagic == protocolMagic,
      orElse: () => throw ArgumentException(
          "Invalid protocol magic or network does not supported."),
    );
  }

  @override
  String toString() {
    return "ADANetwork.$name";
  }
}
