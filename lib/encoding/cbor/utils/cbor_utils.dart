import 'dart:typed_data';
import 'package:blockchain_utils/encoding/cbor/core/cbor.dart';
import 'package:blockchain_utils/encoding/cbor/types/types.dart';
import 'package:blockchain_utils/encoding/cbor/utils/float_utils.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class _DecodeCborResult<T> {
  final T value;
  final int consumed;
  final CborLengthEncoding lengthEncoding;
  const _DecodeCborResult({
    required this.value,
    required this.consumed,
    required this.lengthEncoding,
  });
  _DecodeCborResult<T> addConsumed(int consumed) {
    return _DecodeCborResult(
      value: value,
      consumed: consumed + this.consumed,
      lengthEncoding: lengthEncoding,
    );
  }
}

class CborUtils {
  /// Decode a CBOR (Concise Binary Object Representation) data stream represented by a `List<int>`.
  /// The method decodes the CBOR data and returns the resulting CborObject.
  static T decodeCbor<T extends CborObject>(List<int> cborBytes) {
    final _DecodeCborResult<CborObject> decoded;
    try {
      decoded = _decode(cborBytes);
    } on BuError {
      // Already the right exception type with a specific message - no
      // need to rewrap it into something more generic.
      rethrow;
    } on RangeError catch (e) {
      // Malformed/truncated input running off the end of the byte array
      // surfaces as a RangeError from the underlying list indexing -
      // convert it into the same exception type every other decode
      // failure uses, rather than leaking an unrelated-looking error.
      throw BuError(DefaultErrorType.badCbor,
        "Invalid CBOR bytes: truncated or malformed input.",
        details: {"error": e.toString()},
      );
    }
    if (decoded.consumed != cborBytes.length) {
      throw BuError(DefaultErrorType.invalidLength,
        "Invalid CBOR bytes: trailing data after a complete value.",
        details: {
          "consumed": decoded.consumed.toString(),
          "totalLength": cborBytes.length.toString(),
        },
      );
    }

    try {
      return decoded.value.cast<T>();
    } catch (_) {
      throw BuError(DefaultErrorType.badCbor,
        "Decoded CBOR value is not a $T.",
        details: {"actualType": decoded.value.runtimeType.toString()},
      );
    }
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
        throw BuError(DefaultErrorType.invalidArgument,"Invalid RFC3339 format: $dateTimeString");
      }
      try {
        final datePart = DateTime.parse(parts[0]);
        return datePart;
      } on FormatException catch (e) {
        throw BuError(DefaultErrorType.invalidArgument,
          "Invalid RFC3339 format: $dateTimeString",
          details: {"error": e.toString()},
        );
      }
    } else {
      try {
        return DateTime.parse(dateTimeString).toUtc();
      } on FormatException catch (e) {
        throw BuError(DefaultErrorType.invalidArgument,
          "Invalid RFC3339 format: $dateTimeString",
          details: {"error": e.toString()},
        );
      }
    }
  }

  static _DecodeCborResult<CborObject> _decode(
    List<int> cborBytes, {
    int offset = 0,
  }) {
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
              cborBytes: cborBytes,
              offset: i,
              info: info,
              tags: tags,
            ).addConsumed(consumed);
          }
          return _decodeMap(
            cborBytes: cborBytes,
            offset: i,
            info: info,
            tags: tags,
          ).addConsumed(consumed);
        case MajorTags.negInt:
        case MajorTags.posInt:
          return _parseInt(
            mt: majorTag,
            info: info,
            offset: i,
            cborBytes: cborBytes,
            tags: tags,
          ).addConsumed(consumed);
        case MajorTags.tag:
          final data = _decodeLength<int>(info, cborBytes, i);
          tags.add(data.value);
          i += data.consumed;
          consumed += data.consumed;
          continue;
        case MajorTags.byteString:
          return _decodeBytesString(
            info: info,
            offset: i,
            cborBytes: cborBytes,
            tags: tags,
          ).addConsumed(consumed);
        case MajorTags.utf8String:
          return _decodeUtf8String(
            info: info,
            offset: i,
            cborBytes: cborBytes,
            tags: tags,
          ).addConsumed(consumed);
        case MajorTags.simpleOrFloat:
          return _parseSimpleValue(
            offset: i,
            info: info,
            bytes: cborBytes,
            tags: tags,
          ).addConsumed(consumed);
        case MajorTags.array:
          if (info == NumBytes.indefinite) {
            return _decodeDynamicArray(
              cborBytes: cborBytes,
              offset: i,
              info: info,
              tags: tags,
            ).addConsumed(consumed);
          }
          return _decodeArray(
            cborBytes: cborBytes,
            offset: i,
            info: info,
            tags: tags,
          ).addConsumed(consumed);
        default:
          throw BuError(DefaultErrorType.badCbor,
            "Invalid or unsupported CBOR tag major: $majorTag ",
          );
      }
    }
    throw const BuError(DefaultErrorType.badCbor,"Invalid or unsupported CBOR tag.");
  }

  static _DecodeCborResult<List<int>> _parsBytes({
    required int info,
    required List<int> cborBytes,
    required int offset,
  }) {
    final len = _decodeLength<int>(info, cborBytes, offset);
    final int end = len.consumed + len.value;
    final bytes = cborBytes.sublist(offset + len.consumed, offset + end);
    return _DecodeCborResult(
      value: bytes,
      consumed: end,
      lengthEncoding: len.lengthEncoding,
    );
  }

  static _DecodeCborResult<T> _decodeLength<T>(
    int info,
    List<int> cborBytes,
    int offset,
  ) {
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
        if (decode.isSafeInt()) {
          value = decode.toInt();
        } else {
          if (0 is T) {
            throw const BuError(DefaultErrorType.invalidLength,'Length is too large for type int.');
          }
          value = decode;
        }
      } else {
        throw BuError(DefaultErrorType.invalidArgument,'Invalid additional info for int: $info');
      }
    }
    if (value is int && BigInt.zero is T) {
      value = BigInt.from(value);
    }
    if (value is! T) {
      throw BuError(DefaultErrorType.invalidLength,
        "decode length casting failed.",
        details: {"expected": "$T", "value": value.runtimeType.toString()},
      );
    }
    return _DecodeCborResult(
      value: value as T,
      consumed: consumed,
      lengthEncoding: lengthEncoding,
    );
  }

  static _DecodeCborResult<CborObject> _decodeUtf8String({
    required int info,
    required int offset,
    required List<int> cborBytes,
    required List<int> tags,
  }) {
    if (info == NumBytes.indefinite) {
      final toList = _decodeDynamicArray(
        cborBytes: cborBytes,
        offset: offset,
        info: info,
        tags: tags,
      );
      final stringList =
          (toList.value as CborListValue).value
              .whereType<CborStringValue>()
              .map((e) => e.value)
              .toList();
      if (tags.isNotEmpty) {
        return _DecodeCborResult(
          value: CborTagValue(CborIndefiniteStringValue(stringList), tags),
          consumed: toList.consumed,
          lengthEncoding: toList.lengthEncoding,
        );
      }
      return _DecodeCborResult(
        value: CborIndefiniteStringValue(stringList),
        consumed: toList.consumed,
        lengthEncoding: toList.lengthEncoding,
      );
    }

    final bytes = _parsBytes(info: info, cborBytes: cborBytes, offset: offset);

    return _DecodeCborResult(
      value: _toStringObject(bytes.value, tags, bytes.lengthEncoding),
      consumed: bytes.consumed,
      lengthEncoding: bytes.lengthEncoding,
    );
  }

  static CborObject _toStringObject(
    List<int> utf8Bytes,
    List<int> tags,
    CborLengthEncoding encoding,
  ) {
    final toString = StringUtils.decode(utf8Bytes);
    CborObject? toObj;
    if (tags.isEmpty) {
      toObj = CborStringValue(toString, lengthEncoding: encoding);
    } else if (CborBase64Types.values.any(
      (element) => BytesUtils.bytesEqual(tags, element.tag),
    )) {
      final baseType = CborBase64Types.values.firstWhere(
        (element) => BytesUtils.bytesEqual(tags, element.tag),
      );
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
      toObj = CborRegexpValue(toString);
    } else if (BytesUtils.bytesEqual(tags, CborTags.dateString)) {
      tags.clear();
      final time = parseRFC3339DateTime(toString);
      toObj = CborStringDateValue(time);
    }
    toObj ??= CborStringValue(toString, lengthEncoding: encoding);
    return tags.isEmpty ? toObj : CborTagValue(toObj, tags);
  }

  static _DecodeCborResult<CborObject> _decodeBytesString({
    required int info,
    required int offset,
    required List<int> cborBytes,
    required List<int> tags,
  }) {
    if (info == NumBytes.indefinite) {
      final toList = _decodeDynamicArray(
        cborBytes: cborBytes,
        offset: offset,
        info: info,
        tags: tags,
      );
      final bytesList =
          (toList.value as CborListValue).value
              .whereType<CborBytesValue>()
              .map((e) => e.value)
              .toList();
      if (tags.isNotEmpty) {
        return _DecodeCborResult(
          value: CborTagValue(CborDynamicBytesValue(bytesList), tags),
          consumed: toList.consumed,
          lengthEncoding: toList.lengthEncoding,
        );
      }
      return _DecodeCborResult(
        value: CborDynamicBytesValue(bytesList),
        consumed: toList.consumed,
        lengthEncoding: toList.lengthEncoding,
      );
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
      lengthEncoding: bytes.lengthEncoding,
    );
  }

  static _DecodeCborResult<CborObject> _decodeMap({
    required List<int> cborBytes,
    required int offset,
    required int info,
    required List<int> tags,
  }) {
    final decodeLen = _decodeLength<int>(info, cborBytes, offset);
    int consumed = decodeLen.consumed;
    final int length = decodeLen.value;
    final Map<CborObject, CborObject> objects = {};
    for (int lI = 0; lI < length; lI++) {
      final decodeKey = _decode(cborBytes, offset: consumed + offset);
      consumed += decodeKey.consumed;
      final decodeValue = _decode(cborBytes, offset: consumed + offset);
      // CBOR map with duplicate keys (invalid per RFC 8949 -
      // and a real correctness/security concern, since different
      // consumers of the same bytes could disagree on which value "the"
      // key maps to) was accepted without complaint in production.
      if (objects.containsKey(decodeKey.value)) {
        throw BuError(DefaultErrorType.badCbor,
          "Invalid CBOR map: duplicate key.",
          details: {"key": decodeKey.value.toString()},
        );
      }
      objects[decodeKey.value] = decodeValue.value;
      consumed += decodeValue.consumed;
    }
    final toMap = CborMapValue.definite(objects);
    if (tags.isEmpty) {
      return _DecodeCborResult(
        value: toMap,
        consumed: consumed,
        lengthEncoding: decodeLen.lengthEncoding,
      );
    }
    return _DecodeCborResult(
      value: CborTagValue(toMap, tags),
      consumed: consumed,
      lengthEncoding: decodeLen.lengthEncoding,
    );
  }

  static _DecodeCborResult<CborObject> _decodeDynamicMap({
    required List<int> cborBytes,
    required int offset,
    required int info,
    required List<int> tags,
  }) {
    int consumed = 1;
    final Map<CborObject, CborObject> objects = {};
    while (true) {
      // Bounds-checked before indexing: truncated input missing the 0xFF
      // terminator used to run off the end of cborBytes here, surfacing
      // as a raw RangeError instead of a clean parse error.
      if (offset + consumed >= cborBytes.length) {
        throw const BuError(DefaultErrorType.invalidLength,
          "Invalid CBOR bytes: unterminated indefinite-length map.",
        );
      }
      if (cborBytes[offset + consumed] == 0xff) break;

      final decodeKey = _decode(cborBytes, offset: offset + consumed);
      consumed += decodeKey.consumed;
      final decodeValue = _decode(cborBytes, offset: offset + consumed);
      // This indefinite-length map path had no duplicate-key check at
      // all before (not even an assert) - see the definite-length
      // _decodeMap fix above for why this matters.
      if (objects.containsKey(decodeKey.value)) {
        throw BuError(DefaultErrorType.badCbor,
          "Invalid CBOR map: duplicate key.",
          details: {"key": decodeKey.value.toString()},
        );
      }
      objects[decodeKey.value] = decodeValue.value;
      consumed += decodeValue.consumed;
    }
    consumed++;
    final toMap = CborMapValue.inDefinite(objects);
    if (tags.isEmpty) {
      return _DecodeCborResult(
        value: toMap,
        consumed: consumed,
        lengthEncoding: CborLengthEncoding.canonical,
      );
    }
    return _DecodeCborResult(
      value: CborTagValue(toMap, tags),
      consumed: consumed,
      lengthEncoding: CborLengthEncoding.canonical,
    );
  }

  static _DecodeCborResult<CborObject> _decodeArray({
    required List<int> cborBytes,
    required int offset,
    required int info,
    required List<int> tags,
  }) {
    final decodeLen = _decodeLength<int>(info, cborBytes, offset);
    int consumed = decodeLen.consumed;
    final int length = decodeLen.value;
    final List<CborObject> objects = [];
    for (int lI = 0; lI < length; lI++) {
      final decodeData = _decode(cborBytes, offset: consumed + offset);
      objects.add(decodeData.value);
      consumed += decodeData.consumed;
      if ((consumed + offset) == cborBytes.length) break;
    }
    if (BytesUtils.bytesEqual(tags, CborTags.bigFloat) ||
        BytesUtils.bytesEqual(tags, CborTags.decimalFrac)) {
      return _DecodeCborResult(
        value: _decodeCborBigfloatOrDecimal(objects, tags),
        consumed: consumed,
        lengthEncoding: decodeLen.lengthEncoding,
      );
    }
    if (BytesUtils.bytesEqual(tags, CborTags.set)) {
      tags.clear();
      final toObj = CborSetValue(objects.toSet());
      if (tags.isEmpty) {
        return _DecodeCborResult(
          value: toObj,
          consumed: consumed,
          lengthEncoding: decodeLen.lengthEncoding,
        );
      }
      return _DecodeCborResult(
        value: CborTagValue(toObj, tags),
        consumed: consumed,
        lengthEncoding: decodeLen.lengthEncoding,
      );
    }
    final toObj = CborListValue<CborObject>.definite(objects);
    if (tags.isEmpty) {
      return _DecodeCborResult(
        value: toObj,
        consumed: consumed,
        lengthEncoding: decodeLen.lengthEncoding,
      );
    }
    return _DecodeCborResult(
      value: CborTagValue(toObj, tags),
      consumed: consumed,
      lengthEncoding: decodeLen.lengthEncoding,
    );
  }

  static _DecodeCborResult<CborObject> _decodeDynamicArray({
    required List<int> cborBytes,
    required int offset,
    required int info,
    required List<int> tags,
  }) {
    int consumed = 1;
    final List<CborObject> objects = [];
    while (true) {
      // Bounds-checked before indexing - see the same fix in
      // _decodeDynamicMap for why (truncated input missing the 0xFF
      // terminator used to run off the end of cborBytes here).
      if (consumed + offset >= cborBytes.length) {
        throw const BuError(DefaultErrorType.invalidLength,
          "Invalid CBOR bytes: unterminated indefinite-length array.",
        );
      }
      if (cborBytes[consumed + offset] == 0xff) break;

      final decodeData = _decode(cborBytes, offset: consumed + offset);
      objects.add(decodeData.value);
      consumed += decodeData.consumed;
    }
    consumed++;
    final toObj = CborListValue<CborObject>.inDefinite(objects);
    if (tags.isEmpty) {
      return _DecodeCborResult(
        value: toObj,
        consumed: consumed,
        lengthEncoding: CborLengthEncoding.canonical,
      );
    }
    return _DecodeCborResult(
      value: CborTagValue(toObj, tags),
      consumed: consumed,
      lengthEncoding: CborLengthEncoding.canonical,
    );
  }

  static CborObject _decodeCborBigfloatOrDecimal(
    List<CborObject> objects,
    List<int> tags,
  ) {
    objects = objects.whereType<CborNumeric>().toList();
    if (objects.length != 2) {
      throw const BuError(DefaultErrorType.invalidLength,"Invalid BigFloat array length.");
    }
    if (BytesUtils.bytesEqual(tags, CborTags.decimalFrac)) {
      tags.clear();
      final toObj = CborDecimalFracValue.fromCborNumeric(
        objects[0] as CborNumeric,
        objects[1] as CborNumeric,
      );
      if (tags.isEmpty) {
        return toObj;
      }
      return CborTagValue(toObj, tags);
    }
    tags.clear();
    final toObj = CborBigFloatValue.fromCborNumeric(
      objects[0] as CborNumeric,
      objects[1] as CborNumeric,
    );
    if (tags.isEmpty) {
      return toObj;
    }
    return CborTagValue(toObj, tags);
  }

  static _DecodeCborResult<CborObject> _parseSimpleValue({
    required int offset,
    required int info,
    required List<int> bytes,
    required List<int> tags,
  }) {
    CborObject? obj;
    switch (info) {
      case SimpleTags.simpleFalse:
        obj = const CborBooleanValue(false);
        break;
      case SimpleTags.simpleTrue:
        obj = const CborBooleanValue(true);
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
          lengthEncoding: CborLengthEncoding.canonical,
        );
      }
      return _DecodeCborResult(
        value: CborTagValue(obj, tags),
        consumed: 1,
        lengthEncoding: CborLengthEncoding.canonical,
      );
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
          Uint8List.fromList(bytes.sublist(offset, offset + 4)).buffer,
        ).getFloat32(0, Endian.big);
        consumed += 4;
        offset = offset + 4;
        break;
      case NumBytes.eight:
        val = ByteData.view(
          Uint8List.fromList(bytes.sublist(offset, offset + 8)).buffer,
        ).getFloat64(0, Endian.big);
        offset = offset + 8;
        consumed += 8;
        break;
      default:
        throw const BuError(DefaultErrorType.invalidLength,"Invalid simple/float tag length.");
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
      lengthEncoding: CborLengthEncoding.canonical,
    );
  }

  static _DecodeCborResult<CborObject> _parseInt({
    required int mt,
    required int info,
    required int offset,
    required List<int> cborBytes,
    required List<int> tags,
  }) {
    final data = _decodeLength<BigInt>(info, cborBytes, offset);
    final numb = data.value;
    CborNumeric? numericValue;
    BigInt val = numb;
    if (mt == MajorTags.negInt) {
      val = ~val;
    }
    if (val.isSafeInt()) {
      numericValue = CborIntValue(val.toInt());
    }
    numericValue ??= CborSafeIntValue(val);

    if (BytesUtils.bytesEqual(tags, CborTags.dateEpoch)) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        numericValue.toInt() * 1000,
      );
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
