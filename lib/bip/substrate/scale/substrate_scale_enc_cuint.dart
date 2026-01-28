import 'dart:typed_data';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'substrate_scale_enc_base.dart';

/// A Substrate SCALE encoder for encoding unsigned integers as Compact Uints (CUints).
class SubstrateScaleCUintEncoder extends SubstrateScaleEncoderBase {
  const SubstrateScaleCUintEncoder();

  /// Encode the provided [value] as a Compact Uint (CUint) in Substrate SCALE format.
  @override
  List<int> encode(String value) {
    final v = BigInt.tryParse(value);

    if (v != null) {
      /// The maximum value for a single-byte encoding mode (6 bits).
      final BigInt singleByteModeMaxVal = (BigInt.one << 6) - BigInt.one;

      if (v <= singleByteModeMaxVal) {
        return BigintUtils.toBytes(v << 2, length: 1, order: Endian.little);
      }

      /// The maximum value for a two-byte encoding mode (14 bits).
      final BigInt twoByteModeMaxVal = (BigInt.one << 14) - BigInt.one;
      if (v <= twoByteModeMaxVal) {
        return BigintUtils.toBytes(
          (v << 2) | BigInt.from(0x01),
          length: 2,
          order: Endian.little,
        );
      }

      /// The maximum value for a four-byte encoding mode (30 bits).
      final BigInt fourByteModeMaxVal = (BigInt.one << 30) - BigInt.one;
      if (v <= fourByteModeMaxVal) {
        return BigintUtils.toBytes(
          (v << 2) | BigInt.from(0x02),
          length: 4,
          order: Endian.little,
        );
      }

      /// The maximum value for the big integer encoding mode (536 bits).
      final BigInt bigIntegerModeMaxVal = (BigInt.one << 536) - BigInt.one;
      if (v <= bigIntegerModeMaxVal) {
        final List<int> valueBytes = BigintUtils.toBytes(
          v,
          order: Endian.little,
        );
        final List<int> lenBytes = IntUtils.toBytes(
          (valueBytes.length - 4 << 2) | 0x03,
          length: 1,
          byteOrder: Endian.little,
        );
        return [...lenBytes, ...valueBytes];
      }
    }
    throw ArgumentException.invalidOperationArguments(
      "encode",
      name: "value",
      reason:
          v == null
              ? "Invalid integer for scale encoding."
              : "Value is to large for scale encoding.",
    );
  }
}
