/// Float encoding/decoding for CBOR: converts a Dart `double` to/from the
/// smallest IEEE 754 format (16/32/64-bit) that holds it exactly, and
/// back again.
///
/// Independent implementation: rather than manually decoding a double's
/// IEEE 754 bit pattern into (mantissa, exponent) and reasoning about
/// exponent-bias arithmetic to determine whether a smaller format can
/// hold a value exactly, this just tries encoding to the smaller format
/// and decoding back, comparing the result to the original - if they're
/// equal, the smaller format is exact. Much simpler to get right (no
/// mantissa/exponent bias arithmetic to verify by hand), and it reuses
/// the same encode/decode logic needed anyway to actually produce the
/// CBOR bytes, rather than duplicating the bit-width reasoning in a
/// second, separate form.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:blockchain_utils/encoding/cbor/core/tags.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// The three IEEE 754 binary floating-point formats CBOR can use.
enum FloatLength {
  bytes16(5, 10),
  bytes32(8, 23),
  bytes64(11, 52);

  /// Number of bits reserved for the exponent and mantissa in this format.
  final int exponentBitLength;
  final int mantissaBitLength;

  const FloatLength(this.exponentBitLength, this.mantissaBitLength);

  /// The exponent bias for this format (e.g. 15 for float16, 1023 for
  /// float64).
  int get exponentBias => (1 << (exponentBitLength - 1)) - 1;

  /// Number of bytes this format is encoded as.
  int get numBytes {
    switch (this) {
      case FloatLength.bytes64:
        return NumBytes.eight;
      case FloatLength.bytes32:
        return NumBytes.four;
      case FloatLength.bytes16:
        return NumBytes.two;
    }
  }

  /// [FloatLength.values] indexed by position, throwing [CborException]
  /// for an out-of-range index rather than the default RangeError.
  static FloatLength getByIndex(int index) {
    try {
      final v = values.elementAtOrNull(index);
      if (v != null) {
        return v;
      }
    } catch (_) {}
    throw BuError(DefaultErrorType.invalidLength,"Invalid float length index.");
  }
}

class FloatUtils {
  final double value;

  // (fits in float16, fits in float32) - computed once at construction
  // and cached, since `type`/`toBytes` may each consult it, and the
  // float32 check is skipped entirely once the float16 check already
  // succeeds (fitting in the smaller format implies fitting in the
  // larger one, so there's nothing more to check).
  final (bool, bool) _fits;

  FloatUtils(this.value) : _fits = _computeFits(value);

  bool get isLessThan16 => _fits.$1;
  bool get isLessThan32 => _fits.$2;

  /// The smallest format [value] can be represented in without loss.
  FloatLength get type {
    if (isLessThan16) return FloatLength.bytes16;
    if (isLessThan32) return FloatLength.bytes32;
    return FloatLength.bytes64;
  }

  static (bool, bool) _computeFits(double value) {
    // NaN and +/-Infinity are representable exactly in every IEEE 754
    // format, but a round-trip *equality* check would wrongly say NaN
    // doesn't fit (NaN != NaN, per IEEE 754 - and per Dart, which follows
    // it). CBOR's usual convention is also to always emit these in the
    // smallest (float16) form regardless of the original NaN payload
    // bits, so both are special-cased to always "fit" rather than run
    // through the round-trip check below.
    if (value.isNaN || value.isInfinite) return const (true, true);

    final fits16 = _fitsFloat16(value);
    if (fits16) return const (true, true);
    return (false, _fitsFloat32(value));
  }

  static bool _fitsFloat16(double v) {
    return _doubleFromFloat16Bits(_float16BitsFromDouble(v)) == v;
  }

  static bool _fitsFloat32(double v) {
    // Float32List natively truncates to float32 precision on write and
    // widens back to double on read - no manual bit math needed here,
    // unlike float16, which Dart's typed_data has no native support for
    // (hence the manual bit manipulation below).
    return Float32List.fromList([v])[0] == v;
  }

  /// Whether [value] fits in [type] without loss, without needing to
  /// construct a [FloatUtils] first.
  static bool isLessThan(double value, FloatLength type) {
    switch (type) {
      case FloatLength.bytes16:
        return _computeFits(value).$1;
      case FloatLength.bytes32:
        return _computeFits(value).$2;
      case FloatLength.bytes64:
        return true; // every double fits in float64, trivially
    }
  }

  // ---------------------------------------------------------------------
  // float16: manual bit manipulation, since Dart's typed_data doesn't
  // support it natively the way it does float32/float64.
  // ---------------------------------------------------------------------

  static int _float16BitsFromDouble(double value) {
    // Convert via float32 first: float32's exponent range is a strict
    // superset of float16's, so re-biasing from float32's exponent
    // (bias 127) to float16's (bias 15) is a simple, well-understood
    // conversion path - going straight from float64 would mean re-biasing
    // from a very different bias (1023) and handling a much wider
    // exponent range that mostly just needs clamping away again.
    final float32Bits = Float32List.fromList([value]).buffer.asUint32List()[0];

    final sign = (float32Bits & 0x80000000) >> 31;
    final exponent = (float32Bits & 0x7F800000) >> 23;
    final fraction = float32Bits & 0x007FFFFF;

    if (exponent == 0) {
      // Denormalized number or zero.
      return (sign << 15) | ((fraction >> 13) & 0x03FF);
    }
    if (exponent == 0xFF) {
      if (fraction != 0) {
        // NaN - preserve NaN-ness rather than collapsing to infinity.
        // Neither IEEE 754 nor CBOR require preserving the exact NaN
        // payload bits, so this just emits the canonical quiet NaN
        // (0x7E00 for +NaN): exponent all-ones, top fraction bit set.
        return (sign << 15) | (0x1F << 10) | 0x200;
      }
      return (sign << 15) | (0x1F << 10); // true infinity
    }

    final newExponent = exponent - 127 + 15;
    if (newExponent < 0) {
      return sign << 15; // too small for float16 - rounds to zero
    }
    if (newExponent > 0x1F) {
      return (sign << 15) | (0x1F << 10); // too large - clamp to infinity
    }
    return (sign << 15) | (newExponent << 10) | ((fraction >> 13) & 0x03FF);
  }

  static double _doubleFromFloat16Bits(int bits) {
    return floatFromBytes16([(bits >> 8) & 0xFF, bits & 0xFF]);
  }

  BuBytes _encodeFloat16([Endian? endianness]) {
    final bits = _float16BitsFromDouble(value);
    final bytes = BuBytes.unsafeMutable([
      (bits >> 8) & 0xFF,
      bits & 0xFF,
    ]); // big-endian
    if ((endianness ?? Endian.big) == Endian.big) return bytes;
    return bytes.reverse();
  }

  BuBytes _encodeFloat64([Endian? endianness]) {
    final byteData = ByteData(8);
    byteData.setFloat64(0, value, endianness ?? Endian.big);
    return BuBytes.unsafeMutable(byteData.buffer.asUint8List());
  }

  BuBytes _encodeFloat32([Endian? endianness]) {
    final byteData = ByteData(4);
    byteData.setFloat32(0, value, endianness ?? Endian.big);
    return BuBytes.unsafeMutable(byteData.buffer.asUint8List());
  }

  /// Encodes [value] into bytes using [decodFloatType], or (if null) the
  /// smallest format it fits without loss. Returns the encoded bytes
  /// together with the format actually used.
  ///
  /// [allowFloat16]: when picking the format automatically (i.e.
  /// [decodFloatType] is null), whether float16 is allowed as that choice.
  ///
  /// Throws [CborException] if [decodFloatType] is explicitly given as
  /// float16 or float32 but [value] doesn't fit that format exactly.
  (BuBytes, FloatLength) toBytes(
    FloatLength? decodFloatType, {
    Endian? endianness,
    bool allowFloat16 = true,
  }) {
    if (decodFloatType == null) {
      if (allowFloat16 && isLessThan16) {
        return (_encodeFloat16(endianness), FloatLength.bytes16);
      } else if (isLessThan32) {
        return (_encodeFloat32(endianness), FloatLength.bytes32);
      }
      return (_encodeFloat64(endianness), FloatLength.bytes64);
    }
    final BuBytes bytes;
    switch (decodFloatType) {
      case FloatLength.bytes16:
        if (!isLessThan16) {
          throw BuError(DefaultErrorType.badCbor,"Float value is larger than float16.");
        }
        bytes = _encodeFloat16(endianness);
        break;
      case FloatLength.bytes32:
        if (!isLessThan32) {
          throw BuError(DefaultErrorType.badCbor,"Float value is larger than float32.");
        }
        bytes = _encodeFloat32(endianness);
        break;
      case FloatLength.bytes64:
        bytes = _encodeFloat64(endianness);
        break;
    }
    return (bytes, decodFloatType);
  }

  /// Decodes a 16-bit float from [bytes] (big-endian) into a `double`.
  static double floatFromBytes16(List<int> bytes) {
    if (bytes.length != 2) {
      throw BuError(DefaultErrorType.invalidArgument,"Invalid bytes for float16.");
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));
    final bits = byteData.getUint16(0, Endian.big);

    final sign = (bits >> 15) & 0x1;
    var exponent = (bits >> 10) & 0x1F;
    final fraction = bits & 0x3FF;

    if (exponent == 0x1F) {
      if (fraction == 0) {
        return sign == 0 ? double.infinity : double.negativeInfinity;
      }
      return double.nan;
    }
    if (exponent == 0 && fraction == 0) {
      return sign == 0 ? 0.0 : -0.0;
    }

    exponent -= 15;
    return (sign == 0 ? 1.0 : -1.0) *
        (1.0 + fraction / 1024.0) *
        math.pow(2.0, exponent);
  }
}
