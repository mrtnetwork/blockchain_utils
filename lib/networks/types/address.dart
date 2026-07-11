import 'package:blockchain_utils/networks/types/network.dart';
import 'package:blockchain_utils/utils/utils.dart';

abstract class IAddress with Equality {
  BlockchainNetwork get blockchainNetwork;
  List<int> encodeAsIAddress();

  /// view address
  String get address;

  /// the specefic type of address in network like (Primary address monero)
  String? get viewType;
}
