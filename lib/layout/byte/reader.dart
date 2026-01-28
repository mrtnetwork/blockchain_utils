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

  LayoutDecodeResult<int> decodeScaleAsInteger(int offset) {
    final decode = LayoutSerializationUtils.decodeScale(_bytes, offset: offset);
    if (!decode.value.isValidInt) {
      throw const LayoutException("scale number is too large for int.");
    }
    return LayoutDecodeResult(
      consumed: decode.consumed,
      value: decode.value.toInt(),
    );
  }

  LayoutDecodeResult<BigInt> decodeScale(int offset) {
    return LayoutSerializationUtils.decodeScale(_bytes, offset: offset);
  }

  int getScaleLength(int offset) {
    return LayoutSerializationUtils.getScaleRequiredLength(_bytes[offset]);
  }

  int getVarintLength(int offset) {
    return LayoutSerializationUtils.getVarintLength(_bytes[offset]);
  }

  LayoutDecodeResult<int> decodeVarintAsInteger(int offset) {
    final decode = LayoutSerializationUtils.decodeVarint(
      _bytes,
      offset: offset,
    );
    if (!decode.value.isValidInt) {
      throw const LayoutException("varint number is too large for int.");
    }
    return LayoutDecodeResult(
      consumed: decode.consumed,
      value: decode.value.toInt(),
    );
  }

  int at(int index) => _bytes[index];

  int get last => _bytes.last;
  bool isEnd(int offset) {
    return offset >= _bytes.length;
  }
}
