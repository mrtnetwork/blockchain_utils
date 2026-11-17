import 'package:blockchain_utils/protocol/zcash/src/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// Zcash address format (transparent, shielded, or unified).
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
      orElse:
          () =>
              throw CoreErrors.addressValidationFailed(
                reason: "Invalid Zcash address type.",
                details: {"got": value?.toString()},
              ),
    );
  }
}

/// Result of decoding a Zcash address.
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
  }) : addressBytes = addressBytes.asImmutableBytes {
    final bool valid =
        (type != ZcashAddressType.unified && unifiedReceiver == null) ||
        (type == ZcashAddressType.unified && unifiedReceiver != null);
    if (!valid) {
      throw CoreErrors.addressBytesValidationFailed(
        reason: "Unexpected zcash decoding result.",
      );
    }
  }
}
