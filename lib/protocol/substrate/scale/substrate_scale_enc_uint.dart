import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// An abstract base class for encoding values in Substrate SCALE format.
abstract class SubstrateScaleEncoderBase {
  const SubstrateScaleEncoderBase();

  /// Encode the provided [value] in Substrate SCALE format.
  BuBytes encode(String value);
}

/// A Substrate SCALE encoder for string values represented as bytes.
class SubstrateScaleBytesEncoder extends SubstrateScaleEncoderBase {
  const SubstrateScaleBytesEncoder();

  /// Encode the provided [value] as bytes and wrap it in Substrate SCALE format.
  @override
  BuBytes encode(String value) {
    final toBytes = StringUtils.encode(value);
    final List<int> lengthBytes = const SubstrateScaleCUintEncoder().encode(
      toBytes.length.toString(),
    );
    return BuBytes([...lengthBytes, ...toBytes]);
  }
}

/// An abstract base class for encoding unsigned integers in Substrate SCALE format.
abstract class SubstrateScaleUintEncoder extends SubstrateScaleEncoderBase {
  final int bitlength;
  const SubstrateScaleUintEncoder(this.bitlength);

  /// Encode the provided [value] as a Substrate SCALE Uint with the specified byte length
  static BuBytes _encodeWithBytesLength(String value, int bytesLen) {
    final v = BigInt.tryParse(value);
    final maxVal = (BigInt.one << (bytesLen * 8)) - BigInt.one;
    if (v == null || v < BigInt.zero || v > maxVal) {
      throw CoreErrors.invalidOperationArguments(
        "SubstrateScaleUintEncoder",
        name: "value",
        reason: 'Invalid integer for scale encoding.',
      );
    }

    return BigintUtils.toBytes(
      v,
      length: bytesLen,
      byteOrder: bytesLen >= 2 ? Endian.little : Endian.big,
    );
  }

  /// Encode the provided [value] as an 8-bit unsigned integer (U8) in Substrate SCALE format.
  @override
  BuBytes encode(String value) {
    return SubstrateScaleUintEncoder._encodeWithBytesLength(
      value,
      bitlength ~/ 8,
    );
  }
}

/// A Substrate SCALE encoder for encoding 8-bit unsigned integers (U8).
class SubstrateScaleU8Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU8Encoder() : super(8);
}

/// A Substrate SCALE encoder for encoding 16-bit unsigned integers (U16).
class SubstrateScaleU16Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU16Encoder() : super(16);
}

/// A Substrate SCALE encoder for encoding 32-bit unsigned integers (U32).
class SubstrateScaleU32Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU32Encoder() : super(32);
}

/// A Substrate SCALE encoder for encoding 64-bit unsigned integers (U64).
class SubstrateScaleU64Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU64Encoder() : super(64);
}

/// A Substrate SCALE encoder for encoding 128-bit unsigned integers (U128).
class SubstrateScaleU128Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU128Encoder() : super(128);
}

/// A Substrate SCALE encoder for encoding 256-bit unsigned integers (U256).
class SubstrateScaleU256Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU256Encoder() : super(256);
}

/// A Substrate SCALE encoder for encoding unsigned integers as Compact Uints (CUints).
class SubstrateScaleCUintEncoder extends SubstrateScaleEncoderBase {
  const SubstrateScaleCUintEncoder();

  /// Encode the provided [value] as a Compact Uint (CUint) in Substrate SCALE format.
  @override
  BuBytes encode(String value) {
    final v = BigInt.tryParse(value);

    if (v != null) {
      /// The maximum value for a single-byte encoding mode (6 bits).
      final BigInt singleByteModeMaxVal = (BigInt.one << 6) - BigInt.one;

      if (v <= singleByteModeMaxVal) {
        return (v << 2).toLeBytes(length: 1);
      }

      /// The maximum value for a two-byte encoding mode (14 bits).
      final BigInt twoByteModeMaxVal = (BigInt.one << 14) - BigInt.one;
      if (v <= twoByteModeMaxVal) {
        return ((v << 2) | BigInt.from(0x01)).toLeBytes(length: 2);
      }

      /// The maximum value for a four-byte encoding mode (30 bits).
      final BigInt fourByteModeMaxVal = (BigInt.one << 30) - BigInt.one;
      if (v <= fourByteModeMaxVal) {
        return ((v << 2) | BigInt.from(0x02)).toLeBytes(length: 4);
      }

      /// The maximum value for the big integer encoding mode (536 bits).
      final BigInt bigIntegerModeMaxVal = (BigInt.one << 536) - BigInt.one;
      if (v <= bigIntegerModeMaxVal) {
        final List<int> valueBytes = v.toLeBytes();
        final List<int> lenBytes = ((valueBytes.length - 4 << 2) | 0x03)
            .toBytes(length: 1, byteOrder: Endian.little);
        return BuBytes([...lenBytes, ...valueBytes]);
      }
    }
    throw CoreErrors.invalidOperationArguments(
      "encode",
      name: "value",
      reason:
          v == null
              ? "Invalid integer for scale encoding."
              : "Value is too large for scale encoding.",
    );
  }
}
