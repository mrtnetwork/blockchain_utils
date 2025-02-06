import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core.dart';

/// A layout class for encoding and decoding integers using LEB128 (Little Endian Base 128) format.
///
/// LEB128 is a variable-length encoding method that is efficient for representing small numbers compactly.
/// This layout is used in serialization frameworks like BCS (Binary Canonical Serialization).
class LEB128DIntLayout extends Layout<int> {
  /// Constructor for [LEB128IntLayout].
  ///
  /// [layout] is the underlying integer layout used for validation.
  /// [property] is an optional key associated with this layout for structured data handling.
  LEB128DIntLayout(this.layout, {String? property})
      : super(-1, property: property);

  /// The integer layout used to validate values before encoding.
  final IntegerLayout layout;

  /// Decodes a LEB128-encoded integer from a byte list starting at [startIndex].
  ///
  /// This method reads bytes until the most significant bit (MSB) is 0,
  /// which signals the end of the encoded integer.
  static int readVarint(List<int> bytes, {int startIndex = 0}) {
    int result = 0;
    int shift = 0;
    for (int i = startIndex; i < bytes.length; i++) {
      final int byte = bytes[i];
      result |= (byte & 0x7F) << shift;
      shift += 7;
      if ((byte & 0x80) == 0) {
        break;
      }
    }

    return result;
  }

  /// Encodes an integer [value] using LEB128 format.
  ///
  /// The method breaks the integer into 7-bit chunks, setting the MSB
  /// to 1 for all but the last byte to indicate continuation.
  static List<int> writeVarint(int value) {
    final List<int> dest = [];
    while (value >= 0x80) {
      dest.add((value & 0x7F) | 0x80);
      value >>= 7;
    }
    dest.add(value & 0x7F);
    return dest;
  }

  /// Calculates the span (number of bytes) occupied by a LEB128-encoded integer.
  ///
  /// - [bytes]: The byte reader containing the data.
  /// - [offset]: The starting position to read from.
  /// - [source]: Optional integer source (not used here).
  ///
  /// Returns the number of bytes consumed by the LEB128-encoded integer.
  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, int? source}) {
    int span = 0;
    while ((bytes!.at(offset + span) & 0x80) != 0) {
      span++;
    }
    return span + 1;
  }

  /// Decodes a LEB128-encoded integer from the byte stream starting at [offset].
  ///
  /// - [bytes]: The byte stream to decode from.
  /// - [offset]: The starting position for decoding.
  ///
  /// Returns a [LayoutDecodeResult] containing the decoded integer and bytes consumed.
  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final span = getSpan(bytes, offset: offset);
    final decode = readVarint(bytes.sublist(offset, offset + span));
    return LayoutDecodeResult(consumed: span, value: decode);
  }

  /// Encodes an integer [source] using LEB128 and writes it to the byte writer.
  ///
  /// - [source]: The integer value to encode.
  /// - [writer]: The byte writer to output the encoded data.
  /// - [offset]: The position in the writer to start writing.
  ///
  /// Returns the number of bytes written after encoding.
  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    layout.validate(source);
    final encode = writeVarint(source);
    writer.setAll(offset, encode);
    return encode.length;
  }

  /// Creates a copy (clone) of the current layout with an optional new [property].
  ///
  /// Useful when reusing the layout structure with different property associations.
  @override
  LEB128DIntLayout clone({String? newProperty}) {
    return LEB128DIntLayout(layout, property: newProperty);
  }
}
