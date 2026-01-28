import 'dart:typed_data';
import 'package:blockchain_utils/double/codec/double_utils.dart';
import 'package:blockchain_utils/double/codec/float_utils.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/protobuf/protobuf.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class ProtocolBufferDecoder {
  static List<ProtocolBufferDecoderResult> decode(
    List<int> bytes,
    List<ProtoFieldConfig> tags,
  ) {
    final List<ProtocolBufferDecoderResult> results = [];
    int index = 0;
    while (index < bytes.length) {
      final decodeTag = decodeVarint32(bytes, index);
      index += decodeTag.consumed;
      final int tag = decodeTag.value;
      final int fieldId = tag >> 3;
      final int wireType = tag & 0x07;
      final type = WireType.fromValue(wireType);
      final config = tags.firstWhereNullable((e) => e.fieldNumber == fieldId);
      if (config == null) {
        index += type.skip(bytes, index);
        continue;
      }
      final decode = _decode(bytes, config, offset: index);
      index += decode.consumed;
      results.add(decode);
    }
    // results.sort((a, b) {});
    List<ProtocolBufferDecoderResult> finalResult = [];
    for (final i in tags) {
      final same =
          results.where((e) => e.fieldNumber == i.fieldNumber).toList();
      if (same.isEmpty) continue;
      final haveMulti =
          i.fieldType == ProtoFieldType.repeated ||
          i.fieldType == ProtoFieldType.map;
      if (!haveMulti) {
        assert(same.length == 1);
        finalResult.addAll(same);
        continue;
      }
      finalResult.add(
        ProtocolBufferDecoderResult(
          value: same.map((e) => e.value).expand((e) => e).toList(),
          config: i,
          consumed: same.fold(0, (p, c) => p + c.consumed),
        ),
      );
    }

    return finalResult;
  }

  static LayoutDecodeResult<int> decodeVarint32(
    List<int> data,
    int offset, {
    bool sign = false,
  }) {
    int value = 0;
    int shift = 0;
    int index = offset;

    while (true) {
      final byte = data[index++];
      value |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) {
        break;
      }
      shift += 7;
    }

    if (sign && value > BinaryOps.maxInt32) {
      value = value - 0x100000000;
    }

    return LayoutDecodeResult(consumed: index - offset, value: value);
  }

  static ProtocolBufferDecoderResult _decode(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final encoding = config.fieldType;
    return switch (encoding) {
      ProtoFieldType.bytes => _decodeBytes(
        bytes,
        config,
        offset: offset,
        decodeWireType: decodeWiretype,
      ),
      ProtoFieldType.string => _decodeString(
        bytes,
        config,
        offset: offset,
        decodeWireType: decodeWiretype,
      ),
      ProtoFieldType.float || ProtoFieldType.double => _decodeDouble(
        bytes,
        config,
        decodeWiretype: decodeWiretype,
        offset: offset,
      ),
      ProtoFieldType.fixed32 || ProtoFieldType.sFixed32 => _decodeFixed32(
        bytes,
        config,
        decodeWiretype: decodeWiretype,
        offset: offset,
      ),
      ProtoFieldType.fixed64 || ProtoFieldType.sFixed64 => _decodeFixed64(
        bytes,
        config,
        decodeWiretype: decodeWiretype,
        offset: offset,
      ),
      ProtoFieldType.int32 ||
      ProtoFieldType.uint32 ||
      ProtoFieldType.enumType => _decodeInt32(
        bytes,
        config,
        decodeWiretype: decodeWiretype,
        offset: offset,
      ),
      ProtoFieldType.int64 || ProtoFieldType.uint64 => _decodeInt64(
        bytes,
        config,
        decodeWiretype: decodeWiretype,
        offset: offset,
      ),
      ProtoFieldType.sint32 => _decodeSint32(
        bytes,
        config,
        decodeWiretype: decodeWiretype,
        offset: offset,
      ),
      ProtoFieldType.sint64 => _deocdeSing64(
        bytes,
        config,
        decodeWiretype: decodeWiretype,
        offset: offset,
      ),
      ProtoFieldType.bool => _decodeBool(
        bytes,
        config,
        decodeWiretype: decodeWiretype,
        offset: offset,
      ),
      ProtoFieldType.message => _ecodableMessage(
        bytes,
        config,
        offset: offset,
        decodeWiretype: decodeWiretype,
      ),
      ProtoFieldType.repeated => _decodeList(
        bytes,
        config,
        offset: offset,
        decodeWiretype: decodeWiretype,
      ),
      ProtoFieldType.map => _decodeMap(
        bytes,
        config,
        offset: offset,
        decodeWireTyoe: decodeWiretype,
      ),
    };
  }

  static ProtocolBufferDecoderResult<List<int>> _decodeBytes(
    List<int> bytes,
    ProtoFieldConfig config, {
    int offset = 0,
    bool decodeWireType = false,
  }) {
    final start = offset;
    if (decodeWireType) {
      final (_, _, consumed) = WireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final decode = decodeVarint32(bytes, offset);
    offset += decode.consumed;
    final d = bytes.sublist(offset, offset + decode.value);
    offset += decode.value;
    return ProtocolBufferDecoderResult(
      config: config,
      value: d,
      consumed: offset - start,
    );
  }

  static ProtocolBufferDecoderResult _decodeString(
    List<int> bytes,
    ProtoFieldConfig config, {
    int offset = 0,
    bool decodeWireType = false,
  }) {
    final start = offset;

    if (decodeWireType) {
      final (_, _, consumed) = WireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final decode = decodeVarint32(bytes, offset);
    offset += decode.consumed;
    final d = bytes.sublist(offset, offset + decode.value);
    offset += decode.value;
    return ProtocolBufferDecoderResult(
      config: config,
      value: StringUtils.decode(d),
      consumed: offset - start,
    );
  }

  static ProtocolBufferDecoderResult _decodeMap(
    List<int> bytes,
    ProtoFieldConfig config, {
    int offset = 0,
    bool decodeWireTyoe = false,
  }) {
    final keyType = config.mapKeyType;
    final valueType = config.mapValueType;
    if (keyType == null || valueType == null) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        reason: "Invalid map tag config. missing inner key encoding type",
      );
    }
    final keyConfig = ProtoFieldConfig.internal(1, keyType);
    final valueConfig = ProtoFieldConfig.internal(2, valueType);
    final decode = _decodeBytes(
      bytes,
      config,
      offset: offset,
      decodeWireType: decodeWireTyoe,
    );
    final key = _decode(decode.value, keyConfig, decodeWiretype: true);
    final value = _decode(
      decode.value,
      valueConfig,
      offset: key.consumed,
      decodeWiretype: true,
    );
    return ProtocolBufferDecoderResult(
      value: [MapEntry(key.value, value.value)],
      config: config,
      consumed: decode.consumed,
    );
  }

  static ProtocolBufferDecoderResult<int> _decodeInt32(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = WireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final decode = decodeVarint32(
      bytes,
      offset,
      sign: config.fieldType == ProtoFieldType.int32,
    );
    offset += decode.consumed;
    return ProtocolBufferDecoderResult(
      config: config,
      value: decode.value,
      consumed: offset - start,
    );
  }

  static ProtocolBufferDecoderResult<int> _decodeFixed32(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = WireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final decode = IntUtils.fromBytes(
      bytes.sublist(offset, offset += 4),
      byteOrder: Endian.little,
      sign: config.fieldType == ProtoFieldType.sFixed32,
    );

    return ProtocolBufferDecoderResult<int>(
      config: config,
      value: decode,
      consumed: offset - start,
    );
  }

  static ProtocolBufferDecoderResult<BigInt> _decodeFixed64(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = WireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final encode = BigintUtils.fromBytes(
      bytes.sublist(offset, offset += 8),
      byteOrder: Endian.little,
      sign: config.fieldType == ProtoFieldType.sFixed64,
    );
    return ProtocolBufferDecoderResult(
      config: config,
      value: encode,
      consumed: offset - start,
    );
  }

  static ProtocolBufferDecoderResult<double> _decodeDouble(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = WireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final encoding = config.fieldType;

    final decode = switch (encoding) {
      ProtoFieldType.float => FloatCoder.fromBytes(
        bytes.sublist(offset, offset += 4),
        byteOrder: Endian.little,
      ),
      ProtoFieldType.double => DoubleCoder.fromBytes(
        bytes.sublist(offset, offset += 8),
        byteOrder: Endian.little,
      ),
      _ =>
        throw ArgumentException.invalidOperationArguments(
          "decodeDouble",
          reason: "Invalid encoding type.",
        ),
    };
    return ProtocolBufferDecoderResult(
      config: config,
      value: decode,
      consumed: offset - start,
    );
  }

  static (BigInt, int) _decodeVarintBig(
    List<int> bytes, {
    int startIndex = 0,
    bool sign = false,
  }) {
    BigInt result = BigInt.zero;
    int shift = 0;
    int index = startIndex;

    for (; index < bytes.length;) {
      final int byte = bytes[index++];
      result |= (BigInt.from(byte & 0x7F)) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }

    if (sign && result > BinaryOps.maxInt64) {
      result -= (BinaryOps.maxU64 + BigInt.one);
    }

    return (result, index - startIndex);
  }

  static ProtocolBufferDecoderResult<BigInt> _decodeInt64(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = WireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final (decode, consumed) = _decodeVarintBig(
      bytes,
      startIndex: offset,
      sign: config.fieldType == ProtoFieldType.int64,
    );
    offset += consumed;
    return ProtocolBufferDecoderResult(
      config: config,
      value: decode,
      consumed: offset - start,
    );
  }

  static int _zigZagDecode32(int n) {
    int value = n ~/ 2;
    if (n % 2 != 0) {
      value = -value - 1;
    }
    return value;
  }

  static BigInt _zigZagDecode64(BigInt n) {
    return (n >> 1) ^ (-(n & BigInt.one));
  }

  static ProtocolBufferDecoderResult<int> _decodeSint32(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = WireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final decode = decodeVarint32(bytes, offset);
    offset += decode.consumed;
    return ProtocolBufferDecoderResult(
      value: _zigZagDecode32(decode.value),
      consumed: offset - start,
      config: config,
    );
  }

  static ProtocolBufferDecoderResult<BigInt> _deocdeSing64(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = WireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final (decode, consumed) = _decodeVarintBig(bytes, startIndex: offset);
    offset += consumed;
    return ProtocolBufferDecoderResult(
      config: config,
      consumed: offset - start,
      value: _zigZagDecode64(decode),
    );
  }

  static ProtocolBufferDecoderResult<bool> _decodeBool(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = WireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final decode = decodeVarint32(bytes, offset);
    assert(decode.value == 0 || decode.value == 1);
    offset += decode.consumed;
    return ProtocolBufferDecoderResult(
      config: config,
      consumed: offset - start,
      value: decode.value == 1,
    );
  }

  static ProtocolBufferDecoderResult _decodeList(
    List<int> bytes,
    ProtoFieldConfig config, {
    int offset = 0,
    bool decodeWiretype = false,
  }) {
    List<Object> result = [];
    final inner = config.repeatedType;
    if (inner == null) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        reason:
            "Invalid list encoding tag config. missing list inner encoding type",
      );
    }
    final innerConfig = ProtoFieldConfig.internal(config.fieldNumber, inner);
    final isPacked = config.repeatedEncoding == ProtoRepeatedEncoding.packed;
    if (isPacked) {
      final decode = _decodeBytes(
        bytes,
        config,
        offset: offset,
        decodeWireType: decodeWiretype,
      );
      int start = 0;
      while (start < decode.value.length) {
        final r = _decode(decode.value, innerConfig, offset: start);
        start += r.consumed;
        result.add(r.value);
      }
      assert(start == decode.value.length);
      return ProtocolBufferDecoderResult(
        value: result,
        config: config,
        consumed: decode.consumed,
      );
    }
    final r = _decode(
      bytes,
      innerConfig,
      offset: offset,
      decodeWiretype: decodeWiretype,
    );
    result.add(r.value);
    return ProtocolBufferDecoderResult(
      value: result,
      config: config,
      consumed: r.consumed,
    );
  }

  static ProtocolBufferDecoderResult<List<int>> _ecodableMessage(
    List<int> bytes,
    ProtoFieldConfig config, {
    int offset = 0,
    bool decodeWiretype = false,
  }) {
    return _decodeBytes(
      bytes,
      config,
      offset: offset,
      decodeWireType: decodeWiretype,
    );
  }
}

class ProtocolBufferDecoderResult<T>
    with Equality
    implements Comparable<ProtocolBufferDecoderResult> {
  const ProtocolBufferDecoderResult({
    required this.value,
    required this.config,
    required this.consumed,
  });
  final T value;
  final int consumed;
  final ProtoFieldConfig config;
  int get fieldNumber => config.fieldNumber;
  @override
  String toString() {
    return "type: ${config.fieldType} tagNumber: ${config.fieldNumber} value: $value";
  }

  @override
  List<dynamic> get variables => [fieldNumber];

  @override
  int compareTo(ProtocolBufferDecoderResult<dynamic> other) {
    return fieldNumber.compareTo(other.fieldNumber);
  }
}

extension ProtocolBufferFiled on List<ProtocolBufferDecoderResult> {
  T _pickedSignle<T extends Object?>(
    int fieldNumber, {
    List<ProtoFieldType> expectedFieldType = const [],
    T? defaultValue,
    T Function(Object e)? convert,
  }) {
    final current = firstWhereNullable((e) => e.fieldNumber == fieldNumber);
    if (current == null) {
      if (null is T) return defaultValue as T;
      if (defaultValue != null) return defaultValue;
      throw ProtocolBufferException(
        "Missing value for fieldNumber $fieldNumber",
      );
    }
    if (expectedFieldType.isNotEmpty &&
        !expectedFieldType.contains(current.config.fieldType)) {
      throw ProtocolBufferException(
        "Unsupported field type for conversion as $T.",
      );
    }
    final v = current.value;
    if (convert != null) {
      return convert(v);
    }
    return v as T;
  }

  T getInt<T extends int?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle<T>(
      fieldNumber,
      defaultValue: defaultValue,
      expectedFieldType: ProtoFieldType.numericFields,
      convert: (e) => JsonParser.valueAsInt<T>(e),
    );
  }

  T getBigInt<T extends BigInt?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      expectedFieldType: ProtoFieldType.numericFields,
      convert: (e) => JsonParser.valueAsBigInt<T>(e),
    );
  }

  T getBytes<T extends List<int>?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      expectedFieldType: [ProtoFieldType.message, ProtoFieldType.bytes],
      convert: (e) => JsonParser.valueAsBytes<T>(e),
    );
  }

  T getString<T extends String?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      expectedFieldType: [ProtoFieldType.string],
      convert: (e) => JsonParser.valueAsString<T>(e),
    );
  }

  T getDouble<T extends double?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      expectedFieldType: ProtoFieldType.numericFields,
      convert: (e) => JsonParser.valueAsDouble<T>(e),
    );
  }

  T getBool<T extends bool?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      expectedFieldType: [ProtoFieldType.bool],
      convert: (e) => JsonParser.valueAsBool<T>(e),
    );
  }

  List<T> getList<T extends Object>(int fieldNumber, {List<T>? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      expectedFieldType: [ProtoFieldType.repeated],
      convert: (e) => JsonParser.valueEnsureAsList<T>(e),
    );
  }

  List<List<int>> getListOfBytes(
    int fieldNumber, {
    List<List<int>>? defaultValue,
  }) {
    return _pickedSignle<List<List<int>>>(
      fieldNumber,
      defaultValue: defaultValue,
      expectedFieldType: [ProtoFieldType.repeated],
      convert: (e) {
        return JsonParser.valueAsList<List>(
          e,
        ).map((e) => JsonParser.valueAsBytes<List<int>>(e)).toList();
      },
    );
  }

  List<T>? getListOrNull<T extends Object>(int fieldNumber) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: null,
      expectedFieldType: [ProtoFieldType.repeated, ProtoFieldType.map],
      convert: (e) {
        return JsonParser.valueEnsureAsList<T>(e);
      },
    );
  }

  Map<K, V> getMap<K extends Object, V extends Object>(
    int fieldNumber, {
    Map<K, V>? defaultValue,
  }) {
    final data = getListOrNull<MapEntry>(fieldNumber);
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      throw ProtocolBufferException(
        "Missing value for fieldNumber $fieldNumber",
      );
    }
    return Map<K, V>.fromEntries(
      data.map(
        (e) => MapEntry<K, V>(
          JsonParser.valueAs<K>(e.key),
          JsonParser.valueAs<V>(e.value),
        ),
      ),
    );
  }

  Map<K, V>? getMapOrNull<K extends Object, V extends Object>(int fieldNumber) {
    final data = getListOrNull<MapEntry>(fieldNumber);
    if (data == null) {
      return null;
    }
    return Map<K, V>.fromEntries(
      data.map(
        (e) => MapEntry<K, V>(
          JsonParser.valueAs<K>(e.key),
          JsonParser.valueAs<V>(e.value),
        ),
      ),
    );
  }

  ProtobufEnumVariant _toEnum(List<ProtobufEnumVariant> values, int index) {
    bool haveNegative = values.any((e) => e.protoValue.isNegative);
    int neg = index;
    if (haveNegative && neg >= 0x80000000) {
      neg -= 0x100000000;
    }
    return values.firstWhere(
      (e) => e.protoValue == index || e.protoValue == neg,
      orElse:
          () => throw ProtocolBufferException("No matching enum value found."),
    );
  }

  T getEnum<T extends ProtobufEnumVariant?>(
    int fieldNumber,
    List<T> values, {
    T? defaultValue,
  }) {
    final current = firstWhereNullable((e) => e.fieldNumber == fieldNumber);
    if (current == null) {
      if (null is T) return defaultValue ?? null as T;
      throw ProtocolBufferException(
        "Missing value for fieldNumber $fieldNumber",
      );
    }
    if (current.config.fieldType != ProtoFieldType.enumType) {
      throw ProtocolBufferException(
        "Unsupported field type for conversion as $T.",
      );
    }
    return JsonParser.valueAs(
      _toEnum(
        values.where((e) => e != null).toList().cast<ProtobufEnumVariant>(),
        current.value,
      ),
    );
  }

  List<T> getReapeatedEnum<T extends ProtobufEnumVariant>(
    int fieldNumber,
    List<T> values, {
    List<T>? defaultValue,
  }) {
    final current = getListOrNull<int>(fieldNumber);
    if (current == null) {
      if (defaultValue != null) return defaultValue;
      throw ProtocolBufferException(
        "Missing value for fieldNumber $fieldNumber",
      );
    }
    return JsonParser.valueEnsureAsList<T>(
      current.map((e) => _toEnum(values, e)).toList(),
    );
  }

  List<T>? getReapeatedEnumOrNull<T extends ProtobufEnumVariant>(
    int fieldNumber,
    List<T> values, {
    List<T>? defaultValue,
  }) {
    final current = getListOrNull<int>(fieldNumber);
    if (current == null) {
      return defaultValue;
    }
    return JsonParser.valueEnsureAsList<T>(
      current.map((e) => _toEnum(values, e)).toList(),
    );
  }
}
