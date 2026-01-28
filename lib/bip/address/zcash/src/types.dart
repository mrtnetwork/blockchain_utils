import 'package:blockchain_utils/bip/zcash/src/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

enum ZCashAddressType {
  sprout(64),
  sapling(43),
  unified(null),
  p2pkh(20),
  p2sh(20),
  tex(20);

  final int? lengthInBytes;
  const ZCashAddressType(this.lengthInBytes);
}

class ZCashDecodedAddressResult {
  final List<ZUnifiedReceiver>? unifiedReceiver;
  final List<int> addressBytes;
  final ZcashNetwork network;
  final ZCashAddressType type;
  ZCashDecodedAddressResult({
    this.unifiedReceiver,
    required List<int> addressBytes,
    required this.type,
    required this.network,
  }) : addressBytes = addressBytes.asImmutableBytes,
       assert(
         (type != ZCashAddressType.unified && unifiedReceiver == null) ||
             (type == ZCashAddressType.unified && unifiedReceiver != null),
         "Unexpected zcash decoding result.",
       );
}
