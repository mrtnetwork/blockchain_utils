part of "package:blockchain_utils/layout/byte/byte_handler.dart";

/// A utility class for writing layout bytes dynamically.
class LayoutByteWriter {
  // static const int _minimuBufferLength = 1024;
  final bool growable;
  LayoutByteWriter(int span)
      : _buffer = LayoutByteReader.write(
            span >= 0 ? List.filled(span, 0) : List.empty(growable: true)),
        growable = span < 0;
  final LayoutByteReader _buffer;

  /// Get the last byte in the tracked bytes.
  int get last => _buffer.last;

  LayoutByteReader get reader => _buffer;

  /// buffer bytes.
  List<int> toBytes() {
    return _buffer._bytes;
  }

  List<int> sublist(int start, int end) {
    return _buffer.sublist(start, end);
  }

  int get length => _buffer.length;

  void _filled(int end) {
    if (growable) {
      if (end > _buffer.length) {
        final filled = end - (_buffer.length);
        _buffer._bytes.addAll(List<int>.filled(filled, 0, growable: true));
      }
    }
  }

  void setAll(int index, List<int> bytes) {
    _filled(index + bytes.length);
    _buffer._bytes.setAll(index, bytes);
  }

  void set(int offset, int value) {
    _filled(offset);
    _buffer._bytes[offset] = value & mask8;
  }

  int at(int pos) => _buffer._bytes[pos];
}
