// Permission is hereby granted, free of charge,
// to any person obtaining a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';

// Enum representing different floating-point formats and their characteristics.
class FloatLength {
  static const FloatLength bytes16 = FloatLength._(5, 10);
  static const FloatLength bytes32 = FloatLength._(8, 23);
  static const FloatLength bytes64 = FloatLength._(11, 52);

  /// Number of bits reserved for the exponent and mantissa in each format.
  final int exponentBitLength;
  final int mantissaBitLength;

  /// Constructor that sets the bit lengths for exponent and mantissa.
  const FloatLength._(this.exponentBitLength, this.mantissaBitLength);

  /// Calculate the exponent bias for the format.
  int get exponentBias => (1 << (exponentBitLength - 1)) - 1;

  /// Determine the number of bytes required to represent a value in this format.
  int get numBytes {
    switch (this) {
      case FloatLength.bytes64:
        return NumBytes.eight;
      case FloatLength.bytes32:
        return NumBytes.four;
      default:
        return NumBytes.two;
    }
  }

  // Enum values as a list for iteration
  static const List<FloatLength> values = [
    bytes16,
    bytes32,
    bytes64,
  ];

  // Enum value accessor by index
  static FloatLength getByIndex(int index) {
    if (index >= 0 && index < values.length) {
      return values[index];
    }
    throw MessageException('Index out of bounds', details: {"input": index});
  }
}

class FloatUtils {
  FloatUtils(this.value);
  final double value;
  late final _isLess = _isLessThan(value);
  bool get isLessThan32 => _isLess.item2;
  bool get isLessThan16 => _isLess.item1;

  static Tuple<int, int> _decodeBits(int bits) {
    const int mantissaBitLength = 52;
    const int exponentBitLength = 11;
    const exponentBias = (1 << (exponentBitLength - 1)) - 1;
    final mantissaBits = bits & ((1 << mantissaBitLength) - 1);
    final exponentBits =
        (bits >> mantissaBitLength) & ((1 << exponentBitLength) - 1);
    final sign = !((bits >> (exponentBitLength + mantissaBitLength)) == 0);

    int mantissa;
    int exponent;
    if (exponentBits == 0) {
      exponent = 1 - exponentBias - mantissaBitLength;
      mantissa = mantissaBits;
    } else {
      exponent = exponentBits - exponentBias - mantissaBitLength;
      mantissa = mantissaBits | (1 << mantissaBitLength);
    }

    if (sign) {
      mantissa = -mantissa;
    }
    while (mantissa.isEven && mantissa != 0) {
      mantissa >>= 1;
      exponent += 1;
    }
    return Tuple(mantissa, exponent);
  }

  static int _toBits(double value, [Endian? endian]) {
    List<int> toBytes = Float64List.fromList([value]).buffer.asUint8List();
    if ((endian ?? Endian.big) == Endian.big) {
      toBytes = List<int>.from(toBytes.reversed, growable: false);
    }
    int bits = 0;
    for (final b in toBytes) {
      bits <<= 8;
      bits |= b;
    }
    return bits;
  }

  /// Check if a double value is less than the maximum representable value in the specified floating-point format.
  static bool isLessThan(double value, FloatLength type, [Endian? endian]) {
    if (value.isNaN || value.isInfinite) {
      return true;
    }
    final int bits = _toBits(value, endian);
    return _dobuleLessThan(bits, type);
  }

  static Tuple<bool, bool> _isLessThan(double value, [Endian? endian]) {
    if (value.isNaN || value.isInfinite) {
      return const Tuple(true, true);
    }
    final int bits = _toBits(value, endian);
    final isLesThan16 = _dobuleLessThan(bits, FloatLength.bytes16);
    if (isLesThan16) {
      return const Tuple(true, true);
    }
    final isLessThan32 = _dobuleLessThan(bits, FloatLength.bytes32);
    if (isLessThan32) {
      return const Tuple(false, true);
    }
    return const Tuple(false, false);
  }

  static bool _dobuleLessThan(int bits, FloatLength type) {
    final int mantissaBitLength = type.mantissaBitLength;
    final int exponentBitLength = type.exponentBitLength;
    final exponentBias = type.exponentBias;
    final de = _decodeBits(bits);
    if (de.item1 == 0) {
      return true;
    }
    if (mantissaBitLength + 1 < de.item1.bitLength) {
      return false;
    }

    final exponent = de.item2 +
        mantissaBitLength +
        exponentBias +
        (de.item1.bitLength - (mantissaBitLength + 1));

    if (exponent >= ((1 << exponentBitLength) - 1)) {
      return false;
    }

    if (exponent >= 1) {
      return true;
    }

    final subnormalExp = -(exponentBias - 1 + mantissaBitLength);
    final subnormalMantissaLength =
        de.item1.bitLength + de.item2 - subnormalExp;

    return subnormalMantissaLength > 0 &&
        subnormalMantissaLength <= mantissaBitLength;
  }

  List<int> _encodeFloat16([Endian? endianness]) {
    final Uint16List float16View = Uint16List(1);
    final Float32List float32View = Float32List(1);

    float32View[0] = value;

    final int float32Bits =
        float32View.buffer.asUint8List().buffer.asUint32List()[0];

    final int sign = (float32Bits & 0x80000000) >> 31;
    final int exponent = (float32Bits & 0x7F800000) >> 23;
    final int fraction = float32Bits & 0x007FFFFF;

    if (exponent == 0) {
      // Denormalized number or zero
      float16View[0] = sign << 15 | ((fraction >> 13) & 0x03FF);
    } else if (exponent == 0xFF) {
      // Infinity or NaN, represented as infinity
      float16View[0] = sign << 15 | 0x1F << 10 | 0x000;
    } else {
      // Normalized number
      int newExponent = exponent - 127 + 15;
      if (newExponent < 0) {
        // Round to zero if exponent is too small for float16
        float16View[0] = sign << 15;
      } else if (newExponent > 0x1F) {
        // Clamp to the maximum representable exponent
        float16View[0] = sign << 15 | 0x1F << 10 | 0x000;
      } else {
        float16View[0] =
            sign << 15 | (newExponent << 10) | ((fraction >> 13) & 0x03FF);
      }
    }

    // Specify the endianness when converting to List<int>
    final List<int> uint8List = float16View.buffer.asUint8List();
    if ((endianness ?? Endian.big) == Endian.big) {
      return List<int>.from([uint8List[1], uint8List[0]]);
    } else {
      return uint8List;
    }
  }

  List<int> _encodeFloat64([Endian? endianness]) {
    final ByteData byteData = ByteData(8);
    byteData.setFloat64(0, value, endianness ?? Endian.big);
    return byteData.buffer.asUint8List();
  }

  List<int> _encodeFloat32([Endian? endianness]) {
    final ByteData byteData = ByteData(4);
    byteData.setFloat32(0, value, endianness ?? Endian.big);
    return byteData.buffer.asUint8List();
  }

  /// Encode the floating-point value into a byte representation using the specified floating-point format.
  /// Returns a tuple containing the encoded bytes and the format used.
  Tuple<List<int>, FloatLength> toBytes(FloatLength? decodFloatType,
      [Endian? endianness]) {
    if (decodFloatType == null) {
      if (isLessThan16) {
        return Tuple(_encodeFloat16(endianness), FloatLength.bytes16);
      } else if (isLessThan32) {
        return Tuple(_encodeFloat32(endianness), FloatLength.bytes32);
      }
      return Tuple(_encodeFloat64(endianness), FloatLength.bytes64);
    }
    final List<int> bytes;
    switch (decodFloatType) {
      case FloatLength.bytes16:
        if (!isLessThan16) {
          throw const ArgumentException("overflow bytes");
        }
        bytes = _encodeFloat16(endianness);
        break;
      case FloatLength.bytes32:
        if (!isLessThan32) {
          throw const ArgumentException("overflow bytes");
        }
        bytes = _encodeFloat32(endianness);
        break;
      default:
        bytes = _encodeFloat64(endianness);
        break;
    }
    return Tuple(bytes, decodFloatType);
  }

  /// Decode a 16-bit floating-point value from a byte array and return it as a double.
  static double floatFromBytes16(List<int> bytes) {
    if (bytes.length != 2) {
      throw const ArgumentException(
          'Input byte array must be exactly 2 bytes long for Float16');
    }

    ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));
    int int16Bits = byteData.getInt16(0, Endian.big);

    int sign = (int16Bits >> 15) & 0x1;
    int exponent = (int16Bits >> 10) & 0x1F;
    int fraction = int16Bits & 0x3FF;

    double value;

    if (exponent == 0x1F) {
      if (fraction == 0) {
        value = sign == 0 ? double.infinity : double.negativeInfinity;
      } else {
        value = double.nan;
      }
    } else if (exponent == 0 && fraction == 0) {
      value = sign == 0 ? 0.0 : -0.0;
    } else {
      exponent -= 15;
      value = sign == 0 ? 1.0 : -1.0;
      value *= (1.0 + fraction / 1024.0) * math.pow(2.0, exponent);
    }

    return value;
  }
}
