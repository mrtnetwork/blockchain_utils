import 'package:blockchain_utils/exception/const/const.dart';

/// Enumeration representing different modes for public keys used in P2PKH addresses.
///
/// This enum defines different modes for public keys that can be used in P2PKH (Pay-to-Public-Key-Hash)
/// addresses. These modes may include compressed and uncompressed public keys, among others.
enum PubKeyModes {
  compressed(0),
  uncompressed(1);

  const PubKeyModes(this.value);
  final int value;

  bool get isCompressed => this == compressed;

  static PubKeyModes fromValue(int? value, {PubKeyModes? defaultValue}) {
    return values.firstWhere((e) => e.value == value, orElse: () {
      if (defaultValue != null && value == null) return defaultValue;
      throw ExceptionConst.itemNotFound(item: 'public format');
    });
  }
}
