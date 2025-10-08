import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/constant/constant.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'leb128.dart';
import 'numeric.dart';

/// A layout class for handling LEB128 (Little Endian Base 128) encoded integers.
///
/// LEB128 is a variable-length encoding used to store integers compactly.
/// This layout is commonly used to represent offsets, lengths, or counts in BCS (Binary Canonical Serialization).
class LEB128U32OffsetLayout extends ExternalOffsetLayout {
  /// Constructor for the LEB128U32OffsetLayout.
  /// [property] is an optional key to associate this layout with specific data fields.
  LEB128U32OffsetLayout({super.property});

  /// Internal layout used for encoding and decoding LEB128 integers.
  final LEB128IntLayout layout = LEB128IntLayout(LayoutConst.u32());

  /// Indicates that this layout represents a count (such as the length of a vector).
  @override
  bool isCount() {
    return true;
  }

  /// Decodes a LEB128-encoded integer from the provided byte reader starting at [offset].
  ///
  /// - [bytes]: The byte stream to read from.
  /// - [offset]: The position in the byte stream to start reading (default is 0).
  ///
  /// Returns a [LayoutDecodeResult] containing the decoded integer value.
  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = layout.decode(bytes, offset: offset);
    return decode;
  }

  /// Encodes an integer [source] using LEB128 encoding and writes it to the provided byte writer.
  ///
  /// - [source]: The integer value to encode.
  /// - [writer]: The byte writer to write the encoded bytes to.
  /// - [offset]: The position in the byte stream to start writing (default is 0).
  ///
  /// Returns the number of bytes written after encoding.
  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    final encodeLength = LEB128IntLayout.writeVarint(source);
    writer.setAll(offset, encodeLength);
    return encodeLength.length;
  }

  /// Creates a copy (clone) of the current layout with an optional new property name.
  ///
  /// Useful when working with nested layouts or reusing layout definitions with different properties.
  @override
  LEB128U32OffsetLayout clone({String? newProperty}) {
    return LEB128U32OffsetLayout(property: newProperty);
  }

  /// Determines the span (length in bytes) of the LEB128-encoded data.
  ///
  /// - [bytes]: Optional byte reader to inspect the data for dynamic spans.
  /// - [offset]: Starting position in the byte stream (default is 0).
  /// - [source]: Optional source value to calculate the expected span without decoding.
  ///
  /// Returns the number of bytes required to represent the encoded data.
  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, int? source}) {
    return layout.getSpan(bytes, offset: offset, source: source);
  }
}
