import 'dart:typed_data';

import 'package:blockchain_utils/numbers/bigint_utils.dart';
import 'package:blockchain_utils/cbor/types/set.dart';
import 'package:blockchain_utils/cbor/utils/float_utils.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/types/base.dart';
import 'package:blockchain_utils/cbor/types/bigfloat.dart';
import 'package:blockchain_utils/cbor/types/bigint.dart';
import 'package:blockchain_utils/cbor/types/boolean.dart';
import 'package:blockchain_utils/cbor/types/bytes.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/types/datetime.dart';
import 'package:blockchain_utils/cbor/types/decimal.dart';
import 'package:blockchain_utils/cbor/types/double.dart';
import 'package:blockchain_utils/cbor/types/int.dart';
import 'package:blockchain_utils/cbor/types/int64.dart';
import 'package:blockchain_utils/cbor/types/list.dart';
import 'package:blockchain_utils/cbor/types/map.dart';
import 'package:blockchain_utils/cbor/types/mime.dart';
import 'package:blockchain_utils/cbor/types/null.dart';
import 'package:blockchain_utils/cbor/types/regex.dart';
import 'package:blockchain_utils/cbor/types/string.dart';
import 'package:blockchain_utils/cbor/types/url.dart';
import 'package:blockchain_utils/string/string.dart';

class CborUtils {
  /// Decode a CBOR (Concise Binary Object Representation) data stream represented by a List<int>.
  /// The method decodes the CBOR data and returns the resulting CborObject.
  static CborObject decodeCbor(List<int> cborBytes) {
    return _decode(cborBytes).$1;
  }

  /// Parse a datetime string in RFC3339 format and return a corresponding DateTime object.
  /// The method checks if the input string contains a timezone offset. If it does, it splits the string
  /// into date and offset parts, parses the date part, and returns it. If there's no offset, it parses
  /// the input string as a UTC time.
  static DateTime parseRFC3339DateTime(String dateTimeString) {
    // Check if the input string contains a timezone offset
    if (dateTimeString.contains('+')) {
      // Split the string into the date and offset parts
      final parts = dateTimeString.split('+');
      if (parts.length != 2) {
        throw FormatException("Invalid format: $dateTimeString");
      }
      final datePart = DateTime.parse(parts[0]);
      return datePart;
    } else {
      // Parse the input string as a UTC time
      return DateTime.parse(dateTimeString).toUtc();
    }
  }

  static (CborObject, int) _decode(List<int> cborBytes) {
    final List<int> tags = [];
    for (int i = 0; i < cborBytes.length;) {
      final int first = cborBytes[i];
      final majorTag = first >> 5;
      final info = first & 0x1f;

      switch (majorTag) {
        case MajorTags.map:
          if (info == NumBytes.indefinite) {
            return _decodeDynamicMap(cborBytes, i, info, tags);
          }
          return _decodeMap(cborBytes, i, info, tags);
        case MajorTags.negInt:
        case MajorTags.posInt:
          return _parseInt(majorTag, info, i, cborBytes, tags);
        case MajorTags.tag:
          final data = _decodeLength(info, cborBytes.sublist(i));
          tags.add(data.$1);
          i += data.$2;
          continue;
        case MajorTags.byteString:
          return _decodeBytesString(info, i, cborBytes, tags);
        case MajorTags.utf8String:
          return _decodeUtf8String(info, i, cborBytes, tags);
        case MajorTags.simpleOrFloat:
          return _parseSimpleValue(i, info, cborBytes, tags);
        case MajorTags.array:
          if (info == NumBytes.indefinite) {
            return _decodeDynamicArray(cborBytes, i, info, tags);
          }
          return _decodeArray(cborBytes, i, info, tags);
        default:
          throw ArgumentError(
              "invalid or unsuported cbor tag major: $majorTag ");
      }
    }
    throw ArgumentError("invalid or unsuported cbor tag");
  }

  // static BigInt _BigintUtils.fromBytes(List<int> bytes) {
  //   BigInt result = BigInt.zero;
  //   for (int i = 0; i < bytes.length; i++) {
  //     result = result << 8 | BigInt.from(readUint8(bytes, i));
  //   }
  //   return result;
  // }

  static (List<int>, int) _parsBytes(int info, List<int> cborBytes) {
    final len = _decodeLength(info, cborBytes);
    final int end = (len.$2 + len.$1 as int);
    final bytes = cborBytes.sublist(len.$2, end);
    return (bytes, end);
  }

  static (dynamic, int) _decodeLength(int info, List<int> cborBytes) {
    if (info < 24) {
      return (info, 1);
    }
    final int len = 1 << (info - 24);
    ByteData buf =
        ByteData.view(Uint8List.fromList(cborBytes.sublist(1, len + 1)).buffer);
    const int shift32 = 0x100000000; // 2^32
    const int maxSafeHigh = 0x1fffff;
    switch (info) {
      case NumBytes.one:
        return (buf.getUint8(0), 2);
      case NumBytes.two:
        return (buf.getUint16(0, Endian.big), 3);
      case NumBytes.four:
        return (buf.getUint32(0, Endian.big), 5);
      case NumBytes.eight:
        final f = buf.getUint32(0, Endian.big);
        final g = buf.getUint32(4, Endian.big);
        if (f > maxSafeHigh) {
          final big = (BigInt.from(f) * BigInt.from(shift32)) + BigInt.from(g);
          if (big.isValidInt) {
            return (big.toInt(), 9);
          }
          return (big, 9);
        }
        return ((f * shift32) + g, 9);
      default:
        throw ArgumentError('Invalid additional info for int: $info');
    }
  }

  static (CborObject, int) _decodeUtf8String(
      int info, int i, List<int> cborBytes, List<int> tags) {
    if (info == NumBytes.indefinite) {
      final toList = _decodeDynamicArray(cborBytes, i, info, tags);
      final stringList = toList.$1.value
          .whereType<CborStringValue>()
          .map((e) => e.value)
          .toList();
      return (CborIndefiniteStringValue(stringList, tags), toList.$2);
    }

    final bytes = _parsBytes(info, cborBytes.sublist(i));

    return (_toStringObject(bytes.$1, tags), (bytes.$2 + i));
  }

  static CborObject _toStringObject(List<int> utf8Bytes, List<int> tags) {
    final toString = StringUtils.decode(utf8Bytes);
    if (tags.isEmpty) {
      return CborStringValue(toString);
    } else if (CborBase64Types.values
        .any((element) => tags.contains(element.tag))) {
      final baseType = CborBase64Types.values
          .firstWhere((element) => tags.contains(element.tag));
      tags.removeWhere((element) => element == baseType.tag);
      return CborBaseUrlValue(toString, baseType, tags);
    } else if (tags.contains(CborTags.mime)) {
      tags.removeWhere((element) => element == CborTags.mime);
      return CborMimeValue(toString, tags);
    } else if (tags.contains(CborTags.uri)) {
      tags.removeWhere((element) => element == CborTags.uri);
      return CborUriValue(toString, tags);
    } else if (tags.contains(CborTags.regexp)) {
      tags.removeWhere((element) => element == CborTags.regexp);
      return CborRegxpValue(toString, tags);
    } else if (tags.contains(CborTags.dateString)) {
      tags.removeWhere((element) => element == CborTags.dateString);
      final time = parseRFC3339DateTime(toString);
      return CborStringDateValue(time, tags);
    }
    return CborStringValue(toString, tags);
  }

  static (CborObject, int) _decodeBytesString(
      int info, int i, List<int> cborBytes, List<int> tags) {
    if (info == NumBytes.indefinite) {
      final toList = _decodeDynamicArray(cborBytes, i, info, tags);
      final bytesList = toList.$1.value
          .whereType<CborBytesValue>()
          .map((e) => e.value)
          .toList();
      return (CborDynamicBytesValue(bytesList, tags), toList.$2);
    }
    final bytes = _parsBytes(info, cborBytes.sublist(i));
    CborObject? val;
    if (tags.contains(CborTags.negBigInt) ||
        tags.contains(CborTags.posBigInt)) {
      BigInt big = BigintUtils.fromBytes(bytes.$1);
      if (tags.contains(CborTags.negBigInt)) {
        big = ~big;
      }
      tags.removeWhere((element) =>
          element == CborTags.negBigInt || element == CborTags.posBigInt);
      val = CborBigIntValue(big, tags);
    }
    val ??= CborBytesValue(bytes.$1, tags);
    return (val, bytes.$2 + i);
  }

  static (CborObject, int) _decodeMap(
      List<int> cborBytes, int offset, int info, List<int> tags) {
    int index = offset + 1;
    Map<CborObject, CborObject> objects = {};
    for (int lI = 0; lI < info; lI++) {
      final decodeKey = _decode(cborBytes.sublist(index));
      index += decodeKey.$2;
      final decodeValue = _decode(cborBytes.sublist(index));
      objects[decodeKey.$1] = decodeValue.$1;
      index += decodeValue.$2;
    }
    return (CborMapValue.fixedLength(objects), index);
  }

  static (CborObject, int) _decodeDynamicMap(
      List<int> cborBytes, int offset, int info, List<int> tags) {
    int index = offset + 1;
    Map<CborObject, CborObject> objects = {};
    while (cborBytes[index] != 0xff) {
      final decodeKey = _decode(cborBytes.sublist(index));
      index += decodeKey.$2;
      final decodeValue = _decode(cborBytes.sublist(index));
      objects[decodeKey.$1] = decodeValue.$1;
      index += decodeValue.$2;
    }

    return (CborMapValue.dynamicLength(objects), index + 1);
  }

  static (CborObject, int) _decodeArray(
      List<int> cborBytes, int offset, int info, List<int> tags) {
    int index = offset + 1;
    List<CborObject> objects = [];
    for (int lI = 0; lI < info; lI++) {
      final decodeData = _decode(cborBytes.sublist(index));
      objects.add(decodeData.$1);
      index += decodeData.$2;
    }
    if (tags.contains(CborTags.bigFloat) ||
        tags.contains(CborTags.decimalFrac)) {
      return (_decodeCborBigfloatOrDecimal(objects, tags), index);
    }
    if (tags.contains(CborTags.set)) {
      tags.removeWhere((element) => element == CborTags.set);
      return (CborSetValue(objects.toSet(), tags), index);
    }
    return (CborListValue.fixedLength(objects, tags), index);
  }

  static (CborListValue, int) _decodeDynamicArray(
      List<int> cborBytes, int offset, int info, List<int> tags) {
    int index = offset + 1;
    List<CborObject> objects = [];
    while (cborBytes[index] != 0xff) {
      final decodeData = _decode(cborBytes.sublist(index));
      objects.add(decodeData.$1);
      index += decodeData.$2;
    }
    return (CborListValue.dynamicLength(objects), index + 1);
  }

  static CborObject _decodeCborBigfloatOrDecimal(
      List<CborObject> objects, List<int> tags) {
    objects = objects.whereType<CborNumeric>().toList();
    if (objects.length != 2) {
      throw StateError("invalid bigFloat array length");
    }
    if (tags.contains(CborTags.decimalFrac)) {
      tags.removeWhere((element) => element == CborTags.decimalFrac);
      return CborDecimalFracValue.fromCborNumeric(
          objects[0] as CborNumeric, objects[1] as CborNumeric, tags);
    }
    tags.removeWhere((element) => element == CborTags.bigFloat);
    return CborBigFloatValue.fromCborNumeric(
        objects[0] as CborNumeric, objects[1] as CborNumeric, tags);
  }

  static (CborObject, int) _parseSimpleValue(
      int i, int info, List<int> bytes, List<int> tags) {
    int offset = i + 1;
    switch (info) {
      case SimpleTags.simpleFalse:
        return (CborBoleanValue(false, tags), offset);
      case SimpleTags.simpleTrue:
        return (CborBoleanValue(true, tags), offset);
      case SimpleTags.simpleNull:
        return (CborNullValue(tags), offset);
      case SimpleTags.simpleUndefined:
        return (CborUndefinedValue(tags), offset);
      default:
    }

    double val;
    switch (info) {
      case NumBytes.two:
        val = FloatUtils.floatFromBytes16(bytes.sublist(offset, offset + 2));
        offset = offset + 2;
        break;
      case NumBytes.four:
        val = ByteData.view(
                Uint8List.fromList(bytes.sublist(offset, offset + 4)).buffer)
            .getFloat32(0, Endian.big);
        offset = offset + 4;
        break;
      case NumBytes.eight:
        val = ByteData.view(
                Uint8List.fromList(bytes.sublist(offset, offset + 8)).buffer)
            .getFloat64(0, Endian.big);
        offset = offset + 8;
        break;
      default:
        throw StateError("Invalid simpleOrFloatTags");
    }
    if (tags.contains(CborTags.dateEpoch)) {
      final dt = DateTime.fromMillisecondsSinceEpoch((val * 1000).round());
      tags.removeWhere((element) => element == CborTags.dateEpoch);
      return (CborEpochFloatValue(dt, tags), offset);
    }
    return (CborFloatValue(val, tags), offset);
  }

  static (CborObject, int) _parseInt(
      int mt, int info, int i, List<int> cborBytes, List<int> tags) {
    final data = _decodeLength(info, cborBytes.sublist(i));
    final val = data.$1;
    CborNumeric? numericValue;
    final index = data.$2 + i;
    if (val is BigInt) {
      if (val.bitLength > 64) {
        throw StateError("invalid int value");
      }
      if (val.isValidInt) {
        numericValue =
            CborInt64Value(mt == MajorTags.negInt ? ~val : val, tags);
      }
    }
    numericValue ??= CborIntValue(mt == MajorTags.negInt ? ~val : val, tags);
    if (tags.contains(CborTags.dateEpoch)) {
      final dt =
          DateTime.fromMillisecondsSinceEpoch(numericValue.toInt() * 1000);
      tags.removeWhere((element) => element == CborTags.dateEpoch);
      return (CborEpochIntValue(dt, tags), index);
    }
    return (numericValue, index);
  }
}
