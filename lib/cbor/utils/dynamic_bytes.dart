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

  /// Append a 16-bit integer value in big-endian format to the byte sequence in the buffer.
  void pushUint16Be(int val) {
    final result = List<int>.filled(2, 0);
    writeUint16BE(val, result);
    pushBytes(result);
  }

  List<int> _toUint32Be(int val) {
    final result = List<int>.filled(4, 0);
    writeUint32BE(val, result);
    return result;
  }

  /// Append a 32-bit integer value in big-endian format to the byte sequence in the buffer.
  void pushUint32Be(int val) {
    pushBytes(_toUint32Be(val));
  }

  /// Append a list of integer values (chunk) to the byte sequence in the buffer.
  void pushBytes(List<int> chunk) {
    for (final i in chunk) {
      if (i < 0 || i > mask8) {
        throw ArgumentException(
            "invalid byte ${chunk[i] < 0 ? "-" : ""}0x${chunk[i].abs().toRadixString(16)}");
      }
    }
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
    if (value < 24) {
      pushUInt8(majorTag | value);
      return;
    } else if (value <= mask8) {
      pushUInt8(majorTag | NumBytes.one);
      pushUInt8(value);
      return;
    } else if (value <= mask16) {
      pushUInt8(majorTag | NumBytes.two);
      pushUint16Be(value);
    } else if (value <= mask32) {
      pushUInt8(majorTag | NumBytes.four);
      pushUint32Be(value);
    } else {
      pushUInt8(majorTag | NumBytes.eight);
      pushBigint(BigInt.from(value));
    }
  }

  /// Append a BigInt value with a specified major tag to the byte sequence in the buffer.
  void pushBigint(
    BigInt value,
  ) {
    final shift32 = BigInt.from(0x100000000);
    final quotient = value ~/ shift32;
    final remainder = value % shift32;
    pushBytes(_toUint32Be(quotient.toInt()));
    pushBytes(_toUint32Be(remainder.toInt()));
  }
}
