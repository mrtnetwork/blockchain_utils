import 'dart:typed_data';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'substrate_scale_enc_base.dart';

/// Constants related to Substrate SCALE Compact Uint (CUint) encoding.
class SubstrateScaleCUintEncoderConst {
  /// The maximum value for a single-byte encoding mode (6 bits).
  static final BigInt singleByteModeMaxVal = (BigInt.one << 6) - BigInt.one;

  /// The maximum value for a two-byte encoding mode (14 bits).
  static final BigInt twoByteModeMaxVal = (BigInt.one << 14) - BigInt.one;

  /// The maximum value for a four-byte encoding mode (30 bits).
  static final BigInt fourByteModeMaxVal = (BigInt.one << 30) - BigInt.one;

  /// The maximum value for the big integer encoding mode (536 bits).
  static final BigInt bigIntegerModeMaxVal = (BigInt.one << 536) - BigInt.one;
}

/// A Substrate SCALE encoder for encoding unsigned integers as Compact Uints (CUints).
class SubstrateScaleCUintEncoder extends SubstrateScaleEncoderBase {
  const SubstrateScaleCUintEncoder();

  /// Encode the provided [value] as a Compact Uint (CUint) in Substrate SCALE format.
  ///
  /// This method takes an unsigned integer value [value], encodes it as a Compact Uint (CUint)
  /// in Substrate SCALE format, and returns the encoded value as a `List<int>`.
  @override
  List<int> encode(String value) {
    final v = BigInt.parse(value);
    if (v <= SubstrateScaleCUintEncoderConst.singleByteModeMaxVal) {
      return BigintUtils.toBytes(v << 2, length: 1, order: Endian.little);
    }
    if (v <= SubstrateScaleCUintEncoderConst.twoByteModeMaxVal) {
      return BigintUtils.toBytes((v << 2) | BigInt.from(0x01),
          length: 2, order: Endian.little);
    }
    if (v <= SubstrateScaleCUintEncoderConst.fourByteModeMaxVal) {
      return BigintUtils.toBytes((v << 2) | BigInt.from(0x02),
          length: 4, order: Endian.little);
    }
    if (v <= SubstrateScaleCUintEncoderConst.bigIntegerModeMaxVal) {
      final List<int> valueBytes = BigintUtils.toBytes(v,
          order: Endian.little, length: BigintUtils.orderLen(v));
      final List<int> lenBytes = IntUtils.toBytes(
          (valueBytes.length - 4 << 2) | 0x03,
          length: 1,
          byteOrder: Endian.little);
      return List<int>.from([...lenBytes, ...valueBytes]);
    }

    throw ArgumentException("Out of range integer value ($value)");
  }
}
