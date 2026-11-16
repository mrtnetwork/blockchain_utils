import 'package:blockchain_utils/encoding/layout/core/types/compact_bytes.dart';

/// Compact-length-prefixed bit sequence; the wire length is a bit count
/// while the payload is stored byte-aligned.
class BitSequenceLayout extends CompactLengthPrefixedLayout<List<int>> {
  BitSequenceLayout({super.property});

  @override
  int lengthToByteCount(int value) => value ~/ 8;

  @override
  int byteCountToLength(int byteCount) => byteCount * 8;

  @override
  List<int> fromBytes(List<int> bytes) => bytes;

  @override
  List<int> toBytes(List<int> source) => source;

  @override
  BitSequenceLayout clone({String? newProperty}) {
    return BitSequenceLayout(property: newProperty);
  }
}
