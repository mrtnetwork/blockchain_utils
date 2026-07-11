import 'package:blockchain_utils/bip/zcash/src/types.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

enum ZcashAddressType {
  sprout("Sprout", 0),
  sapling("Sapling", 1),
  unified("Unified", 2),
  p2pkh("P2pkh", 3),
  p2sh("P2sh", 4),
  tex("Tex", 5);

  int? get lengthInBytes {
    return switch (this) {
      ZcashAddressType.sprout => 64,
      ZcashAddressType.sapling => 43,
      ZcashAddressType.p2pkh ||
      ZcashAddressType.tex ||
      ZcashAddressType.p2sh => 20,
      _ => null,
    };
  }

  final String name;
  final int value;
  const ZcashAddressType(this.name, this.value);

  static ZcashAddressType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(name: "ZcashAddressType"),
    );
  }
}

class ZcashDecodedAddressResult {
  final List<ZUnifiedReceiver>? unifiedReceiver;
  final List<int> addressBytes;
  final ZcashNetwork network;
  final ZcashAddressType type;
  ZcashDecodedAddressResult({
    this.unifiedReceiver,
    required List<int> addressBytes,
    required this.type,
    required this.network,
  }) : addressBytes = addressBytes.asImmutableBytes,
       assert(
         (type != ZcashAddressType.unified && unifiedReceiver == null) ||
             (type == ZcashAddressType.unified && unifiedReceiver != null),
         "Unexpected zcash decoding result.",
       );
}
