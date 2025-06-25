part of 'package:blockchain_utils/layout/byte/byte_handler.dart';

class LayoutByteReader {
  LayoutByteReader(List<int> bytes) : _bytes = List<int>.unmodifiable(bytes);
  LayoutByteReader.write(this._bytes);
  final List<int> _bytes;
  List<int> get bytes => _bytes;
  int get length => _bytes.length;

  List<int> sublist(int start, int end) {
    return _bytes.sublist(start, end);
  }

  // LayoutByteReader getReader(int start, int end) {
  //   return LayoutByteReader(_bytes.sublist(start, end));
  // }

  Tuple<int, int> getCompactLengthInfos(int offset) {
    final length =
        LayoutSerializationUtils.decodeLength(_bytes, offset: offset);
    if (!length.item2.isValidInt) {
      throw const LayoutException("compact value is too large for length.");
    }
    return Tuple(length.item1, length.item2.toInt());
  }

  Tuple<int, BigInt> getCompactBigintInfos(int offset) {
    final length =
        LayoutSerializationUtils.decodeLength(_bytes, offset: offset);
    return Tuple(length.item1, length.item2);
  }

  int getCompactDataOffset(int offset) {
    return LayoutSerializationUtils.getDataCompactOffset(_bytes[offset]);
  }

  Tuple<int, int> getCompactTotalLenght(int offset) {
    try {
      final decode = LayoutSerializationUtils.decodeLengthWithDetails(_bytes,
          offset: offset);
      return decode;
    } catch (e) {
      rethrow;
    }
  }

  int at(int index) => _bytes[index];

  int get last => _bytes.last;
}
