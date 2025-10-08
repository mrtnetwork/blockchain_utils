import 'dart:typed_data';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/exception/exception.dart';
import 'package:blockchain_utils/cbor/types/types.dart';
import 'package:blockchain_utils/cbor/utils/float_utils.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/utils/utils.dart';

class _DecodeCborResult<T> {
  final T value;
  final int consumed;
  final CborLengthEncoding lengthEncoding;
  const _DecodeCborResult(
      {required this.value,
      required this.consumed,
      required this.lengthEncoding});
  _DecodeCborResult<T> addConsumed(int consumed) {
    return _DecodeCborResult(
        value: value,
        consumed: consumed + this.consumed,
        lengthEncoding: lengthEncoding);
  }
}

class CborUtils {
  /// Decode a CBOR (Concise Binary Object Representation) data stream represented by a `List<int>`.
  /// The method decodes the CBOR data and returns the resulting CborObject.
  static CborObject decodeCbor(List<int> cborBytes) {
    final decode = _decode(cborBytes);
    assert(decode.consumed == cborBytes.length, "cbor decoding faild.");
    return decode.value;
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
        throw CborException("Invalid RFC3339 format: $dateTimeString");
      }
      final datePart = DateTime.parse(parts[0]);
      return datePart;
    } else {
      // Parse the input string as a UTC time
      return DateTime.parse(dateTimeString).toUtc();
    }
  }

  static _DecodeCborResult<CborObject> _decode(List<int> cborBytes,
      {int offset = 0}) {
    final List<int> tags = [];
    int consumed = 0;
    for (int i = offset; i < cborBytes.length;) {
      final int first = cborBytes[i];

      final majorTag = first >> 5;
      final info = first & 0x1f;
      switch (majorTag) {
        case MajorTags.map:
          if (info == NumBytes.indefinite) {
            return _decodeDynamicMap(
                    cborBytes: cborBytes, offset: i, info: info, tags: tags)
                .addConsumed(consumed);
          }
          return _decodeMap(
                  cborBytes: cborBytes, offset: i, info: info, tags: tags)
              .addConsumed(consumed);
        case MajorTags.negInt:
        case MajorTags.posInt:
          return _parseInt(
                  mt: majorTag,
                  info: info,
                  offset: i,
                  cborBytes: cborBytes,
                  tags: tags)
              .addConsumed(consumed);
        case MajorTags.tag:
          final data = _decodeLength<int>(info, cborBytes, i);
          tags.add(data.value);
          i += data.consumed;
          consumed += data.consumed;
          continue;
        case MajorTags.byteString:
          return _decodeBytesString(
                  info: info, offset: i, cborBytes: cborBytes, tags: tags)
              .addConsumed(consumed);
        case MajorTags.utf8String:
          return _decodeUtf8String(
                  info: info, offset: i, cborBytes: cborBytes, tags: tags)
              .addConsumed(consumed);
        case MajorTags.simpleOrFloat:
          return _parseSimpleValue(
                  offset: i, info: info, bytes: cborBytes, tags: tags)
              .addConsumed(consumed);
        case MajorTags.array:
          if (info == NumBytes.indefinite) {
            return _decodeDynamicArray(
                    cborBytes: cborBytes, offset: i, info: info, tags: tags)
                .addConsumed(consumed);
          }
          return _decodeArray(
                  cborBytes: cborBytes, offset: i, info: info, tags: tags)
              .addConsumed(consumed);
        default:
          throw CborException(
              "invalid or unsuported cbor tag major: $majorTag ");
      }
    }
    throw const CborException("invalid or unsuported cbor tag");
  }

  static _DecodeCborResult<List<int>> _parsBytes(
      {required int info, required List<int> cborBytes, required int offset}) {
    final len = _decodeLength<int>(info, cborBytes, offset);
    final int end = len.consumed + len.value;
    final bytes = cborBytes.sublist(offset + len.consumed, offset + end);
    return _DecodeCborResult(
        value: bytes, consumed: end, lengthEncoding: len.lengthEncoding);
  }

  static _DecodeCborResult<T> _decodeLength<T>(
      int info, List<int> cborBytes, int offset) {
    Object value;
    int consumed = 1;
    CborLengthEncoding lengthEncoding = CborLengthEncoding.canonical;
    if (info < 24) {
      value = info;
    } else {
      offset++;
      final int len = 1 << (info - 24);
      final List<int> bytes = cborBytes.sublist(offset, offset + len);
      consumed = len + 1;
      if (len <= 4) {
        value = IntUtils.fromBytes(bytes);
        if (value as int <= 23) {
          lengthEncoding = CborLengthEncoding.nonCanonical;
        }
      } else if (len <= 8) {
        final decode = BigintUtils.fromBytes(bytes);
        if (decode.isValidInt) {
          value = decode.toInt();
        } else {
          if (0 is T) {
            throw const CborException('Length is to large for type int.');
          }
          value = decode;
        }
      } else {
        throw CborException('Invalid additional info for int: $info');
      }
    }
    if (value is int && BigInt.zero is T) {
      value = BigInt.from(value);
    }
    if (value is! T) {
      throw CborException("decode length casting faild.",
          details: {"expected": "$T", "value": value.runtimeType});
    }
    return _DecodeCborResult(
        value: value as T, consumed: consumed, lengthEncoding: lengthEncoding);
  }

  static _DecodeCborResult<CborObject> _decodeUtf8String(
      {required int info,
      required int offset,
      required List<int> cborBytes,
      required List<int> tags}) {
    if (info == NumBytes.indefinite) {
      final toList = _decodeDynamicArray(
          cborBytes: cborBytes, offset: offset, info: info, tags: tags);
      final stringList = (toList.value as CborListValue)
          .value
          .whereType<CborStringValue>()
          .map((e) => e.value)
          .toList();
      if (tags.isNotEmpty) {
        return _DecodeCborResult(
            value: CborTagValue(CborIndefiniteStringValue(stringList), tags),
            consumed: toList.consumed,
            lengthEncoding: toList.lengthEncoding);
      }
      return _DecodeCborResult(
          value: CborIndefiniteStringValue(stringList),
          consumed: toList.consumed,
          lengthEncoding: toList.lengthEncoding);
    }

    final bytes = _parsBytes(info: info, cborBytes: cborBytes, offset: offset);

    return _DecodeCborResult(
        value: _toStringObject(bytes.value, tags, bytes.lengthEncoding),
        consumed: bytes.consumed,
        lengthEncoding: bytes.lengthEncoding);
  }

  static CborObject _toStringObject(
      List<int> utf8Bytes, List<int> tags, CborLengthEncoding encoding) {
    final toString = StringUtils.decode(utf8Bytes);
    CborObject? toObj;
    if (tags.isEmpty) {
      toObj = CborStringValue(toString, lengthEncoding: encoding);
    } else if (CborBase64Types.values
        .any((element) => BytesUtils.bytesEqual(tags, element.tag))) {
      final baseType = CborBase64Types.values
          .firstWhere((element) => BytesUtils.bytesEqual(tags, element.tag));
      tags.clear();
      toObj = CborBaseUrlValue(toString, baseType);
    } else if (BytesUtils.bytesEqual(tags, CborTags.mime)) {
      tags.clear();
      toObj = CborMimeValue(toString);
    } else if (BytesUtils.bytesEqual(tags, CborTags.uri)) {
      tags.clear();
      toObj = CborUriValue(toString);
    } else if (BytesUtils.bytesEqual(tags, CborTags.regexp)) {
      tags.clear();
      toObj = CborRegxpValue(toString);
    } else if (BytesUtils.bytesEqual(tags, CborTags.dateString)) {
      tags.clear();
      final time = parseRFC3339DateTime(toString);
      toObj = CborStringDateValue(time);
    }
    toObj ??= CborStringValue(toString, lengthEncoding: encoding);
    return tags.isEmpty ? toObj : CborTagValue(toObj, tags);
  }

  static _DecodeCborResult<CborObject> _decodeBytesString(
      {required int info,
      required int offset,
      required List<int> cborBytes,
      required List<int> tags}) {
    if (info == NumBytes.indefinite) {
      final toList = _decodeDynamicArray(
          cborBytes: cborBytes, offset: offset, info: info, tags: tags);
      final bytesList = (toList.value as CborListValue)
          .value
          .whereType<CborBytesValue>()
          .map((e) => e.value)
          .toList();
      if (tags.isNotEmpty) {
        return _DecodeCborResult(
            value: CborTagValue(CborDynamicBytesValue(bytesList), tags),
            consumed: toList.consumed,
            lengthEncoding: toList.lengthEncoding);
      }
      return _DecodeCborResult(
          value: CborDynamicBytesValue(bytesList),
          consumed: toList.consumed,
          lengthEncoding: toList.lengthEncoding);
    }
    final bytes = _parsBytes(info: info, cborBytes: cborBytes, offset: offset);
    CborObject? val;
    if (BytesUtils.bytesEqual(tags, CborTags.negBigInt) ||
        BytesUtils.bytesEqual(tags, CborTags.posBigInt)) {
      BigInt big = BigintUtils.fromBytes(bytes.value);
      if (BytesUtils.bytesEqual(tags, CborTags.negBigInt)) {
        big = ~big;
      }
      tags.clear();
      if (big == BigInt.zero && bytes.value.isNotEmpty) {
        val = CborBigIntValue(big, encoding: CborLengthEncoding.nonCanonical);
      } else {
        val = CborBigIntValue(big);
      }
    }
    val ??= CborBytesValue(bytes.value);
    return _DecodeCborResult(
        value: tags.isEmpty ? val : CborTagValue(val, tags),
        consumed: bytes.consumed,
        lengthEncoding: bytes.lengthEncoding);
  }

  static _DecodeCborResult<CborObject> _decodeMap(
      {required List<int> cborBytes,
      required int offset,
      required int info,
      required List<int> tags}) {
    final decodeLen = _decodeLength<int>(info, cborBytes, offset);
    int consumed = decodeLen.consumed;
    final int length = decodeLen.value;
    final Map<CborObject, CborObject> objects = {};
    for (int lI = 0; lI < length; lI++) {
      final decodeKey = _decode(cborBytes, offset: consumed + offset);

      assert(BytesUtils.bytesEqual(
          decodeKey.value.encode(),
          cborBytes.sublist(
              consumed + offset, consumed + offset + decodeKey.consumed)));
      consumed += decodeKey.consumed;
      final decodeValue = _decode(cborBytes, offset: consumed + offset);
      assert(BytesUtils.bytesEqual(
          decodeValue.value.encode(),
          cborBytes.sublist(
              consumed + offset, consumed + offset + decodeValue.consumed)));
      assert(!objects.containsKey(decodeKey.value), "duplicate key found.");
      objects[decodeKey.value] = decodeValue.value;
      consumed += decodeValue.consumed;
    }
    final toMap = CborMapValue.definite(objects);
    if (tags.isEmpty) {
      return _DecodeCborResult(
          value: toMap,
          consumed: consumed,
          lengthEncoding: decodeLen.lengthEncoding);
    }
    return _DecodeCborResult(
        value: CborTagValue(toMap, tags),
        consumed: consumed,
        lengthEncoding: decodeLen.lengthEncoding);
  }

  static _DecodeCborResult<CborObject> _decodeDynamicMap(
      {required List<int> cborBytes,
      required int offset,
      required int info,
      required List<int> tags}) {
    int consumed = 1;
    final Map<CborObject, CborObject> objects = {};
    while (cborBytes[offset + consumed] != 0xff) {
      final decodeKey = _decode(cborBytes, offset: offset + consumed);
      assert(BytesUtils.bytesEqual(
          decodeKey.value.encode(),
          cborBytes.sublist(
              consumed + offset, consumed + offset + decodeKey.consumed)));
      consumed += decodeKey.consumed;
      final decodeValue = _decode(cborBytes, offset: offset + consumed);
      assert(BytesUtils.bytesEqual(
          decodeValue.value.encode(),
          cborBytes.sublist(
              consumed + offset, consumed + offset + decodeValue.consumed)));
      objects[decodeKey.value] = decodeValue.value;
      consumed += decodeValue.consumed;
    }
    consumed++;
    final toMap = CborMapValue.inDefinite(objects);
    if (tags.isEmpty) {
      return _DecodeCborResult(
          value: toMap,
          consumed: consumed,
          lengthEncoding: CborLengthEncoding.canonical);
    }
    return _DecodeCborResult(
        value: CborTagValue(toMap, tags),
        consumed: consumed,
        lengthEncoding: CborLengthEncoding.canonical);
  }

  static _DecodeCborResult<CborObject> _decodeArray(
      {required List<int> cborBytes,
      required int offset,
      required int info,
      required List<int> tags}) {
    final decodeLen = _decodeLength<int>(info, cborBytes, offset);
    int consumed = decodeLen.consumed;
    final int length = decodeLen.value;
    final List<CborObject> objects = [];
    for (int lI = 0; lI < length; lI++) {
      final decodeData = _decode(cborBytes, offset: consumed + offset);
      assert(
          BytesUtils.bytesEqual(
              decodeData.value.encode(),
              cborBytes.sublist(
                  consumed + offset, consumed + offset + decodeData.consumed)),
          "data: ${BytesUtils.toHexString(cborBytes.sublist(consumed + offset, consumed + offset + decodeData.consumed))}");
      objects.add(decodeData.value);
      consumed += decodeData.consumed;
      if ((consumed + offset) == cborBytes.length) break;
    }
    if (BytesUtils.bytesEqual(tags, CborTags.bigFloat) ||
        BytesUtils.bytesEqual(tags, CborTags.decimalFrac)) {
      return _DecodeCborResult(
          value: _decodeCborBigfloatOrDecimal(objects, tags),
          consumed: consumed,
          lengthEncoding: decodeLen.lengthEncoding);
    }
    if (BytesUtils.bytesEqual(tags, CborTags.set)) {
      tags.clear();
      final toObj = CborSetValue(objects.toSet());
      if (tags.isEmpty) {
        return _DecodeCborResult(
            value: toObj,
            consumed: consumed,
            lengthEncoding: decodeLen.lengthEncoding);
      }
      return _DecodeCborResult(
          value: CborTagValue(toObj, tags),
          consumed: consumed,
          lengthEncoding: decodeLen.lengthEncoding);
    }
    final toObj = CborListValue<CborObject>.definite(objects);
    if (tags.isEmpty) {
      return _DecodeCborResult(
          value: toObj,
          consumed: consumed,
          lengthEncoding: decodeLen.lengthEncoding);
    }
    return _DecodeCborResult(
        value: CborTagValue(toObj, tags),
        consumed: consumed,
        lengthEncoding: decodeLen.lengthEncoding);
  }

  static _DecodeCborResult<CborObject> _decodeDynamicArray(
      {required List<int> cborBytes,
      required int offset,
      required int info,
      required List<int> tags}) {
    int consomed = 1;
    final List<CborObject> objects = [];
    while (cborBytes[consomed + offset] != 0xff) {
      final decodeData = _decode(cborBytes, offset: consomed + offset);
      objects.add(decodeData.value);
      consomed += decodeData.consumed;
    }
    consomed++;
    final toObj = CborListValue<CborObject>.inDefinite(objects);
    if (tags.isEmpty) {
      return _DecodeCborResult(
          value: toObj,
          consumed: consomed,
          lengthEncoding: CborLengthEncoding.canonical);
    }
    return _DecodeCborResult(
        value: CborTagValue(toObj, tags),
        consumed: consomed,
        lengthEncoding: CborLengthEncoding.canonical);
  }

  static CborObject _decodeCborBigfloatOrDecimal(
      List<CborObject> objects, List<int> tags) {
    objects = objects.whereType<CborNumeric>().toList();
    if (objects.length != 2) {
      throw const CborException("invalid bigFloat array length");
    }
    if (BytesUtils.bytesEqual(tags, CborTags.decimalFrac)) {
      tags.clear();
      final toObj = CborDecimalFracValue.fromCborNumeric(
          objects[0] as CborNumeric, objects[1] as CborNumeric);
      if (tags.isEmpty) {
        return toObj;
      }
      return CborTagValue(toObj, tags);
    }
    tags.clear();
    final toObj = CborBigFloatValue.fromCborNumeric(
        objects[0] as CborNumeric, objects[1] as CborNumeric);
    if (tags.isEmpty) {
      return toObj;
    }
    return CborTagValue(toObj, tags);
  }

  static _DecodeCborResult<CborObject> _parseSimpleValue(
      {required int offset,
      required int info,
      required List<int> bytes,
      required List<int> tags}) {
    CborObject? obj;
    switch (info) {
      case SimpleTags.simpleFalse:
        obj = const CborBoleanValue(false);
        break;
      case SimpleTags.simpleTrue:
        obj = const CborBoleanValue(true);
        break;
      case SimpleTags.simpleNull:
        obj = const CborNullValue();
        break;
      case SimpleTags.simpleUndefined:
        obj = const CborUndefinedValue();
        break;
      default:
    }
    if (obj != null) {
      if (tags.isEmpty) {
        return _DecodeCborResult(
            value: obj,
            consumed: 1,
            lengthEncoding: CborLengthEncoding.canonical);
      }
      return _DecodeCborResult(
          value: CborTagValue(obj, tags),
          consumed: 1,
          lengthEncoding: CborLengthEncoding.canonical);
    }
    int consumed = 1;
    offset += 1;
    double val;
    switch (info) {
      case NumBytes.two:
        val = FloatUtils.floatFromBytes16(bytes.sublist(offset, offset + 2));
        consumed += 2;
        offset = offset + 2;
        break;
      case NumBytes.four:
        val = ByteData.view(
                Uint8List.fromList(bytes.sublist(offset, offset + 4)).buffer)
            .getFloat32(0, Endian.big);
        consumed += 4;
        offset = offset + 4;
        break;
      case NumBytes.eight:
        val = ByteData.view(
                Uint8List.fromList(bytes.sublist(offset, offset + 8)).buffer)
            .getFloat64(0, Endian.big);
        offset = offset + 8;
        consumed += 8;
        break;
      default:
        throw const CborException("Invalid simpleOrFloatTags");
    }
    if (BytesUtils.bytesEqual(tags, CborTags.dateEpoch)) {
      final dt = DateTime.fromMillisecondsSinceEpoch((val * 1000).round());
      tags.clear();
      obj = CborEpochFloatValue(dt);
    }
    obj ??= CborFloatValue(val);
    return _DecodeCborResult(
        value: tags.isEmpty ? obj : CborTagValue(obj, tags),
        consumed: consumed,
        lengthEncoding: CborLengthEncoding.canonical);
  }

  static _DecodeCborResult<CborObject> _parseInt(
      {required int mt,
      required int info,
      required int offset,
      required List<int> cborBytes,
      required List<int> tags}) {
    final data = _decodeLength<BigInt>(info, cborBytes, offset);
    final numb = data.value;
    CborNumeric? numericValue;
    BigInt val = numb;
    if (mt == MajorTags.negInt) {
      val = ~val;
    }
    if (val.isValidInt) {
      numericValue = CborIntValue(val.toInt());
    }
    numericValue ??= CborSafeIntValue(val);

    if (BytesUtils.bytesEqual(tags, CborTags.dateEpoch)) {
      final dt =
          DateTime.fromMillisecondsSinceEpoch(numericValue.toInt() * 1000);
      tags.clear();
      final toObj = CborEpochIntValue(dt);
      if (tags.isEmpty) {
        return _DecodeCborResult(
          value: toObj,
          consumed: data.consumed,
          lengthEncoding: data.lengthEncoding,
        );
      }
      return _DecodeCborResult(
        value: CborTagValue(toObj, tags),
        consumed: data.consumed,
        lengthEncoding: data.lengthEncoding,
      );
    }
    if (tags.isEmpty) {
      return _DecodeCborResult(
        value: numericValue,
        consumed: data.consumed,
        lengthEncoding: data.lengthEncoding,
      );
    }
    return _DecodeCborResult(
      value: CborTagValue(numericValue, tags),
      consumed: data.consumed,
      lengthEncoding: data.lengthEncoding,
    );
  }
}
