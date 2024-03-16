import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';

/// A class for tracking and building a sequence of bytes (List<int>) for CBOR encoding.
class CborBytesTracker {
  /// Constructor for creating a CborBytesTracker instance.
  CborBytesTracker();

  /// A buffer used to accumulate the bytes for CBOR encoding.
  final DynamicByteTracker _buffer = DynamicByteTracker();

  /// Retrieve the accumulated bytes as a List<int> from the buffer.
  List<int> toBytes() {
    return _buffer.toBytes();
  }

  /// Append a single UInt8 value to the byte sequence in the buffer.
  void pushUInt8(int val) {
    pushBytes([val]);
  }

  /// Append a list of integer values (chunk) to the byte sequence in the buffer.
  void pushBytes(List<int> chunk) {
    BytesUtils.validateBytes(chunk);
    _buffer.add(chunk);
  }

  /// Append a list of CBOR tags to the byte sequence in the buffer.
  void pushTags(List<int> tags) {
    for (int i in tags) {
      pushInt(MajorTags.tag, i);
    }
  }

  /// Append a special byte representing indefinite length for the provided major tag.
  void pushIndefinite(int majorTag) {
    majorTag <<= 5;
    pushBytes([majorTag | NumBytes.indefinite]);
  }

  /// Append a special byte (0xff) to indicate indefinite length for a dynamic element.
  void breakDynamic() {
    pushBytes([0xff]);
  }

  /// Append a major tag and its value to the byte sequence in the buffer.
  void pushMajorTag(int majorTag, int value) {
    majorTag <<= 5;
    pushUInt8(majorTag | value);
  }

  /// Append an integer value with a specified major tag to the byte sequence in the buffer.
  void pushInt(
    int majorTag,
    int value,
  ) {
    majorTag <<= 5;
    int? length = bytesLength(value);
    pushUInt8(majorTag | (length ?? value));
    if (length == null) return;
    final int len = 1 << (length - 24);
    if (len <= 4) {
      pushBytes(IntUtils.toBytes(value, length: len));
    } else {
      pushBigint(BigInt.from(value));
    }
  }

  int? bytesLength(int value) {
    if (value < 24) {
      return null;
    } else if (value <= mask8) {
      return NumBytes.one;
    } else if (value <= mask16) {
      return NumBytes.two;
    } else if (value <= mask32) {
      return NumBytes.four;
    } else {
      return NumBytes.eight;
    }
  }

  /// Append a BigInt value with a specified major tag to the byte sequence in the buffer.
  void pushBigint(BigInt value) {
    pushBytes(BigintUtils.toBytes(value, length: 8));
  }
}
