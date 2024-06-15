import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'substrate_scale_enc_base.dart';

/// An abstract base class for encoding unsigned integers in Substrate SCALE format.
abstract class SubstrateScaleUintEncoder extends SubstrateScaleEncoderBase {
  const SubstrateScaleUintEncoder();

  /// Encode the provided [value] as a Substrate SCALE Uint with the specified byte length
  static List<int> _encodeWithBytesLength(String value, int bytesLen) {
    final v = BigInt.parse(value);
    final maxVal = (BigInt.one << (bytesLen * 8)) - BigInt.one;
    if (v < BigInt.zero || v > maxVal) {
      throw ArgumentException('Invalid integer value ($value)');
    }

    return BigintUtils.toBytes(v,
        length: bytesLen, order: bytesLen >= 2 ? Endian.little : Endian.big);
  }
}

/// A Substrate SCALE encoder for encoding 8-bit unsigned integers (U8).
class SubstrateScaleU8Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU8Encoder();

  /// Encode the provided [value] as an 8-bit unsigned integer (U8) in Substrate SCALE format.
  @override
  List<int> encode(String value) {
    return SubstrateScaleUintEncoder._encodeWithBytesLength(value, 1);
  }
}

/// A Substrate SCALE encoder for encoding 16-bit unsigned integers (U16).
class SubstrateScaleU16Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU16Encoder();

  /// Encode the provided [value] as a 16-bit unsigned integer (U16) in Substrate SCALE format.
  @override
  List<int> encode(String value) {
    return SubstrateScaleUintEncoder._encodeWithBytesLength(value, 2);
  }
}

/// A Substrate SCALE encoder for encoding 32-bit unsigned integers (U32).
class SubstrateScaleU32Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU32Encoder();

  /// Encode the provided [value] as a 32-bit unsigned integer (U32) in Substrate SCALE format.
  @override
  List<int> encode(String value) {
    return SubstrateScaleUintEncoder._encodeWithBytesLength(value, 4);
  }
}

/// A Substrate SCALE encoder for encoding 64-bit unsigned integers (U64).
class SubstrateScaleU64Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU64Encoder();

  /// Encode the provided [value] as a 64-bit unsigned integer (U64) in Substrate SCALE format.
  @override
  List<int> encode(String value) {
    return SubstrateScaleUintEncoder._encodeWithBytesLength(value, 8);
  }
}

/// A Substrate SCALE encoder for encoding 128-bit unsigned integers (U128).
class SubstrateScaleU128Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU128Encoder();

  /// Encode the provided [value] as a 128-bit unsigned integer (U128) in Substrate SCALE format.
  @override
  List<int> encode(String value) {
    return SubstrateScaleUintEncoder._encodeWithBytesLength(value, 16);
  }
}

/// A Substrate SCALE encoder for encoding 256-bit unsigned integers (U256).
class SubstrateScaleU256Encoder extends SubstrateScaleUintEncoder {
  const SubstrateScaleU256Encoder();

  /// Encode the provided [value] as a 256-bit unsigned integer (U256) in Substrate SCALE format.
  @override
  List<int> encode(String value) {
    return SubstrateScaleUintEncoder._encodeWithBytesLength(value, 32);
  }
}
