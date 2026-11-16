import 'package:blockchain_utils/chain/types/network.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Common interface implemented by every network's address type.
abstract class IAddress with Equality {
  /// Network this address belongs to.
  BlockchainNetwork get blockchainNetwork;

  /// Encodes this address back to its raw byte representation.
  BuBytes encodeAsIAddress();

  /// The address string.
  String get address;

  /// Address subtype within the network (e.g. Monero's "Primary" address).
  String? get viewType;
}
