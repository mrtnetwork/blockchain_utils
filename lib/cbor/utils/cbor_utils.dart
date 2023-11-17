import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/cbor/utils/float_utils.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';

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
      final stringList = (toList.$1 as CborListValue)
          .value
          .whereType<CborStringValue>()
          .map((e) => e.value)
          .toList();
      if (tags.isNotEmpty) {
        return (
          CborTagValue(CborIndefiniteStringValue(stringList), tags),
          toList.$2
        );
      }
      return (CborIndefiniteStringValue(stringList), toList.$2);
    }

    final bytes = _parsBytes(info, cborBytes.sublist(i));

    return (_toStringObject(bytes.$1, tags), (bytes.$2 + i));
  }

  static CborObject _toStringObject(List<int> utf8Bytes, List<int> tags) {
    final toString = StringUtils.decode(utf8Bytes);
    CborObject? toObj;
    if (tags.isEmpty) {
      toObj = CborStringValue(toString);
    } else if (CborBase64Types.values
        .any((element) => tags.contains(element.tag))) {
      final baseType = CborBase64Types.values
          .firstWhere((element) => tags.contains(element.tag));
      tags.removeWhere((element) => element == baseType.tag);
      toObj = CborBaseUrlValue(toString, baseType);
    } else if (tags.contains(CborTags.mime)) {
      tags.removeWhere((element) => element == CborTags.mime);
      toObj = CborMimeValue(toString);
    } else if (tags.contains(CborTags.uri)) {
      tags.removeWhere((element) => element == CborTags.uri);
      toObj = CborUriValue(toString);
    } else if (tags.contains(CborTags.regexp)) {
      tags.removeWhere((element) => element == CborTags.regexp);
      toObj = CborRegxpValue(toString);
    } else if (tags.contains(CborTags.dateString)) {
      tags.removeWhere((element) => element == CborTags.dateString);
      final time = parseRFC3339DateTime(toString);
      toObj = CborStringDateValue(time);
    }
    toObj ??= CborStringValue(toString);
    return tags.isEmpty ? toObj : CborTagValue(toObj, tags);
  }

  static (CborObject, int) _decodeBytesString(
      int info, int i, List<int> cborBytes, List<int> tags) {
    if (info == NumBytes.indefinite) {
      final toList = _decodeDynamicArray(cborBytes, i, info, tags);
      final bytesList = toList.$1.value
          .whereType<CborBytesValue>()
          .map((e) => e.value)
          .toList();
      if (tags.isNotEmpty) {
        return (
          CborTagValue(CborDynamicBytesValue(bytesList), tags),
          toList.$2
        );
      }
      return (CborDynamicBytesValue(bytesList), toList.$2);
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
      val = CborBigIntValue(big);
    }
    val ??= CborBytesValue(bytes.$1);
    return (tags.isEmpty ? val : CborTagValue(val, tags), bytes.$2 + i);
  }

  static (CborObject, int) _decodeMap(
      List<int> cborBytes, int offset, int info, List<int> tags) {
    // s
    // int index = offset + 1;

    final decodeLen = _decodeLength(info, cborBytes);
    int index = offset + decodeLen.$2;
    final int length = decodeLen.$1;
    Map<CborObject, CborObject> objects = {};
    for (int lI = 0; lI < length; lI++) {
      final decodeKey = _decode(cborBytes.sublist(index));
      index += decodeKey.$2;
      final decodeValue = _decode(cborBytes.sublist(index));
      objects[decodeKey.$1] = decodeValue.$1;
      index += decodeValue.$2;
    }
    final toMap = CborMapValue.fixedLength(objects);
    return (tags.isEmpty ? toMap : CborTagValue(toMap, tags), index);
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
    final toMap = CborMapValue.dynamicLength(objects);
    return (tags.isEmpty ? toMap : CborTagValue(toMap, tags), index + 1);
  }

  static (CborObject, int) _decodeArray(
      List<int> cborBytes, int offset, int info, List<int> tags) {
    final decodeLen = _decodeLength(info, cborBytes);
    int index = offset + decodeLen.$2;
    final int length = decodeLen.$1;
    List<CborObject> objects = [];
    for (int lI = 0; lI < length; lI++) {
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
      final toObj = CborSetValue(objects.toSet());
      return (tags.isEmpty ? toObj : CborTagValue(toObj, tags), index);
    }
    final toObj = CborListValue.fixedLength(objects);
    return (tags.isEmpty ? toObj : CborTagValue(toObj, tags), index);
  }

  static (CborObject, int) _decodeDynamicArray(
      List<int> cborBytes, int offset, int info, List<int> tags) {
    int index = offset + 1;
    List<CborObject> objects = [];
    while (cborBytes[index] != 0xff) {
      final decodeData = _decode(cborBytes.sublist(index));
      objects.add(decodeData.$1);
      index += decodeData.$2;
    }
    final toObj = CborListValue.dynamicLength(objects);
    return (tags.isEmpty ? toObj : CborTagValue(toObj, tags), index + 1);
  }

  static CborObject _decodeCborBigfloatOrDecimal(
      List<CborObject> objects, List<int> tags) {
    objects = objects.whereType<CborNumeric>().toList();
    if (objects.length != 2) {
      throw StateError("invalid bigFloat array length");
    }
    if (tags.contains(CborTags.decimalFrac)) {
      tags.removeWhere((element) => element == CborTags.decimalFrac);
      final toObj = CborDecimalFracValue.fromCborNumeric(
          objects[0] as CborNumeric, objects[1] as CborNumeric);
      return tags.isEmpty ? toObj : CborTagValue(toObj, tags);
    }
    tags.removeWhere((element) => element == CborTags.bigFloat);
    final toObj = CborBigFloatValue.fromCborNumeric(
        objects[0] as CborNumeric, objects[1] as CborNumeric);
    return tags.isEmpty ? toObj : CborTagValue(toObj, tags);
  }

  static (CborObject, int) _parseSimpleValue(
      int i, int info, List<int> bytes, List<int> tags) {
    int offset = i + 1;
    CborObject? obj;
    switch (info) {
      case SimpleTags.simpleFalse:
        obj = CborBoleanValue(false);
        break;
      case SimpleTags.simpleTrue:
        obj = CborBoleanValue(true);
        break;
      case SimpleTags.simpleNull:
        obj = CborNullValue();
        break;
      case SimpleTags.simpleUndefined:
        obj = CborUndefinedValue();
        break;
      default:
    }
    if (obj != null) {
      if (tags.isEmpty) {
        return (obj, offset);
      }
      return (CborTagValue(obj, tags), offset);
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
      obj = CborEpochFloatValue(dt);
    }
    obj ??= CborFloatValue(val);
    return (tags.isEmpty ? obj : CborTagValue(obj, tags), offset);
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
        numericValue = CborInt64Value(mt == MajorTags.negInt ? ~val : val);
      }
    }
    numericValue ??= CborIntValue(mt == MajorTags.negInt ? ~val : val);
    if (tags.contains(CborTags.dateEpoch)) {
      final dt =
          DateTime.fromMillisecondsSinceEpoch(numericValue.toInt() * 1000);
      tags.removeWhere((element) => element == CborTags.dateEpoch);
      final toObj = CborEpochIntValue(dt);
      return (tags.isEmpty ? toObj : CborTagValue(toObj, tags), index);
    }
    return (
      tags.isEmpty ? numericValue : CborTagValue(numericValue, tags),
      index
    );
  }
}
