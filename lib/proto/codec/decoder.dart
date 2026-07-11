import 'dart:typed_data';
import 'package:blockchain_utils/double/codec/double_utils.dart';
import 'package:blockchain_utils/double/codec/float_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/proto/exception/exception.dart';
import 'package:blockchain_utils/proto/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
// import 'package:cosmos_sdk/src/generator/protobuf/protobuf.dart';

class ProtoBufferDecoder {
  static ProtoBufferDecoderResult decode({
    required List<int> bytes,
    required ProtoMessageConfig messageConfig,
  }) {
    return decodeFields(
      bytes,
      messageConfig.fields,
      syntax: messageConfig.syntax,
    );
  }

  static ProtoBufferDecoderResult decodeFields(
    List<int> bytes,
    List<ProtoFieldConfig> tags, {
    ProtoSyntax syntax = ProtoSyntax.v3,
  }) {
    final List<ProtoBufferDecodedField> results = [];
    int index = 0;
    while (index < bytes.length) {
      final decodeTag = decodeVarint32(bytes, index);
      index += decodeTag.consumed;
      final int tag = decodeTag.value;
      final int fieldId = tag >> 3;
      final int wireType = tag & 0x07;
      final type = ProtoWireType.fromValue(wireType);
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
    List<ProtoBufferDecodedField> finalResult = [];
    for (final i in tags) {
      final same =
          results.where((e) => e.fieldNumber == i.fieldNumber).toList();
      if (same.isEmpty) continue;
      final haveMulti =
          i.fieldType == ProtoFieldType.repeated ||
          i.fieldType == ProtoFieldType.map;
      if (!haveMulti) {
        finalResult.addAll(same);
        continue;
      }
      finalResult.add(
        ProtoBufferDecodedField(
          value: same.map((e) => e.value).expand((e) => e).toList(),
          config: i,
          consumed: same.fold(0, (p, c) => p + c.consumed),
        ),
      );
    }

    return ProtoBufferDecoderResult(fields: finalResult, syntax: syntax);
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

  static ProtoBufferDecodedField _decode(
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
      ProtoFieldType.int64 || ProtoFieldType.uint64 => decodeVarint64(
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

  static ProtoBufferDecodedField<List<int>> _decodeBytes(
    List<int> bytes,
    ProtoFieldConfig config, {
    int offset = 0,
    bool decodeWireType = false,
  }) {
    final start = offset;
    if (decodeWireType) {
      final (_, _, consumed) = ProtoWireType.decode(
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
    return ProtoBufferDecodedField(
      config: config,
      value: d,
      consumed: offset - start,
    );
  }

  static ProtoBufferDecodedField _decodeString(
    List<int> bytes,
    ProtoFieldConfig config, {
    int offset = 0,
    bool decodeWireType = false,
  }) {
    final start = offset;

    if (decodeWireType) {
      final (_, _, consumed) = ProtoWireType.decode(
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
    return ProtoBufferDecodedField(
      config: config,
      value: StringUtils.decode(d),
      consumed: offset - start,
    );
  }

  static ProtoBufferDecodedField _decodeMap(
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
    return ProtoBufferDecodedField(
      value: [MapEntry(key.value, value.value)],
      config: config,
      consumed: decode.consumed,
    );
  }

  static ProtoBufferDecodedField<int> _decodeInt32(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = ProtoWireType.decode(
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
    return ProtoBufferDecodedField(
      config: config,
      value: decode.value,
      consumed: offset - start,
    );
  }

  static ProtoBufferDecodedField<int> _decodeFixed32(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = ProtoWireType.decode(
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

    return ProtoBufferDecodedField<int>(
      config: config,
      value: decode,
      consumed: offset - start,
    );
  }

  static ProtoBufferDecodedField<BigInt> _decodeFixed64(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = ProtoWireType.decode(
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
    return ProtoBufferDecodedField(
      config: config,
      value: encode,
      consumed: offset - start,
    );
  }

  static ProtoBufferDecodedField<double> _decodeDouble(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = ProtoWireType.decode(
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
    return ProtoBufferDecodedField(
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

  static ProtoBufferDecodedField<BigInt> decodeVarint64(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = ProtoWireType.decode(
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
    return ProtoBufferDecodedField(
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

  static ProtoBufferDecodedField<int> _decodeSint32(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = ProtoWireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final decode = decodeVarint32(bytes, offset);
    offset += decode.consumed;
    return ProtoBufferDecodedField(
      value: _zigZagDecode32(decode.value),
      consumed: offset - start,
      config: config,
    );
  }

  static ProtoBufferDecodedField<BigInt> _deocdeSing64(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = ProtoWireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final (decode, consumed) = _decodeVarintBig(bytes, startIndex: offset);
    offset += consumed;
    return ProtoBufferDecodedField(
      config: config,
      consumed: offset - start,
      value: _zigZagDecode64(decode),
    );
  }

  static ProtoBufferDecodedField<bool> _decodeBool(
    List<int> bytes,
    ProtoFieldConfig config, {
    bool decodeWiretype = false,
    int offset = 0,
  }) {
    final start = offset;
    if (decodeWiretype) {
      final (_, _, consumed) = ProtoWireType.decode(
        bytes,
        offset,
        expectedTag: config.fieldNumber,
      );
      offset += consumed;
    }
    final decode = decodeVarint32(bytes, offset);
    assert(decode.value == 0 || decode.value == 1);
    offset += decode.consumed;
    return ProtoBufferDecodedField(
      config: config,
      consumed: offset - start,
      value: decode.value == 1,
    );
  }

  static ProtoBufferDecodedField _decodeList(
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
      return ProtoBufferDecodedField(
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
    return ProtoBufferDecodedField(
      value: result,
      config: config,
      consumed: r.consumed,
    );
  }

  static ProtoBufferDecodedField<List<int>> _ecodableMessage(
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

class ProtoBufferDecodedField<T>
    with Equality
    implements Comparable<ProtoBufferDecodedField> {
  const ProtoBufferDecodedField({
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
  int compareTo(ProtoBufferDecodedField<dynamic> other) {
    return fieldNumber.compareTo(other.fieldNumber);
  }
}

class ProtoBufferDecoderResult {
  final List<ProtoBufferDecodedField> fields;
  final ProtoSyntax syntax;
  const ProtoBufferDecoderResult({required this.fields, required this.syntax});
  ProtoBufferDecodedField? getTagNumberField(int fieldNumber) {
    return fields.firstWhereNullable((e) => e.fieldNumber == fieldNumber);
  }
}

extension ExtProtocolBufferFiled on ProtoBufferDecoderResult {
  T _pickedSignle<T extends Object?>(
    int fieldNumber, {
    List<ProtoFieldType> expectedFieldType = const [],
    T? defaultValue,
    required T? Function() v3DefaultValue,
    T Function(Object e)? convert,
  }) {
    final current = getTagNumberField(fieldNumber);
    if (current == null) {
      if (null is T) return defaultValue as T;
      if (defaultValue != null) return defaultValue;
      if (syntax.isV3) {
        final value = v3DefaultValue();
        if (value != null) return value;
      }
      throw ProtoException("Missing value for fieldNumber $fieldNumber");
    }
    if (expectedFieldType.isNotEmpty &&
        !expectedFieldType.contains(current.config.fieldType)) {
      throw ProtoException("Unsupported field type for conversion as $T.");
    }
    final v = current.value;
    if (convert != null) {
      return convert(v);
    }
    return v as T;
  }

  bool fieldExists(int fieldNumber) =>
      fields.any((e) => e.fieldNumber == fieldNumber);

  T getInt<T extends int?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle<T>(
      fieldNumber,
      defaultValue: defaultValue,
      v3DefaultValue: () => 0 as T,
      expectedFieldType: ProtoFieldType.numericFields,
      convert: (e) => JsonParser.valueAsInt<T>(e),
    );
  }

  T getBigInt<T extends BigInt?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      v3DefaultValue: () => BigInt.zero as T,
      expectedFieldType: ProtoFieldType.numericFields,
      convert: (e) => JsonParser.valueAsBigInt<T>(e),
    );
  }

  T getBytes<T extends List<int>?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      v3DefaultValue: () => <int>[] as T,
      expectedFieldType: [ProtoFieldType.message, ProtoFieldType.bytes],
      convert: (e) => JsonParser.valueAsBytes<T>(e),
    );
  }

  T getString<T extends String?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      v3DefaultValue: () => "" as T,
      expectedFieldType: [ProtoFieldType.string],
      convert: (e) => JsonParser.valueAsString<T>(e),
    );
  }

  T getDouble<T extends double?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      v3DefaultValue: () => 0.0 as T,
      expectedFieldType: ProtoFieldType.numericFields,
      convert: (e) => JsonParser.valueAsDouble<T>(e),
    );
  }

  T getBool<T extends bool?>(int fieldNumber, {T? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      v3DefaultValue: () => false as T,
      expectedFieldType: [ProtoFieldType.bool],
      convert: (e) => JsonParser.valueAsBool<T>(e),
    );
  }

  List<T> getList<T extends Object>(int fieldNumber, {List<T>? defaultValue}) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: defaultValue,
      v3DefaultValue: () => <T>[],
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
      v3DefaultValue: () => <List<int>>[],
      expectedFieldType: [ProtoFieldType.repeated],
      convert: (e) {
        return JsonParser.valueAsList<List>(
          e,
        ).map((e) => JsonParser.valueAsBytes<List<int>>(e)).toList();
      },
    );
  }

  List<List<int>> getListOfBytesOrEmpty(int fieldNumber) {
    return getListOfBytes(fieldNumber, defaultValue: const []);
  }

  T messageTo<T extends Object?>(
    int fieldNumber,
    T Function(List<int>) convert,
  ) {
    if (null is T) {
      final message = getBytes<List<int>?>(fieldNumber);
      if (message == null) return null as T;
      return convert(message);
    }
    final message = getBytes<List<int>>(fieldNumber);
    return convert(message);
  }

  T integerTo<T extends Object?>(int fieldNumber, T Function(int) convert) {
    if (null is T) {
      final message = getInt<int?>(fieldNumber);
      if (message == null) return null as T;
      return convert(message);
    }
    final message = getInt<int>(fieldNumber);
    return convert(message);
  }

  T stringTo<T extends Object?>(int fieldNumber, T Function(String) convert) {
    if (null is T) {
      final message = getString<String?>(fieldNumber);
      if (message == null) return null as T;
      return convert(message);
    }
    final message = getString<String>(fieldNumber);
    return convert(message);
  }

  List<T>? getListOrNull<T extends Object>(int fieldNumber) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: null,
      v3DefaultValue: () => null,
      expectedFieldType: [ProtoFieldType.repeated, ProtoFieldType.map],
      convert: (e) {
        return JsonParser.valueEnsureAsList<T>(e);
      },
    );
  }

  List<T> getListOrEmpty<T extends Object>(int fieldNumber) {
    return _pickedSignle(
      fieldNumber,
      defaultValue: <T>[],
      v3DefaultValue: () => <T>[],
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
      if (syntax.isV3) {
        return <K, V>{};
      }
      throw ProtoException("Missing value for fieldNumber $fieldNumber");
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

  Map<K, V> getMapField<K extends Object, V extends Object>({
    required int fieldNumber,
    required V Function(Object? valye) valueMapper,
    required K Function(Object? valye) keyMapper,
    Map<K, V>? defaultValue,
  }) {
    final data = getListOrNull<MapEntry>(fieldNumber);
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      if (syntax.isV3) {
        return <K, V>{};
      }
      throw ProtoException("Missing value for fieldNumber $fieldNumber");
    }
    return Map<K, V>.fromEntries(
      data.map((e) => MapEntry<K, V>(keyMapper(e.key), valueMapper(e.value))),
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

  ProtoEnumVariant _toEnum(List<ProtoEnumVariant> values, int index) {
    bool haveNegative = values.any((e) => e.value.isNegative);
    int neg = index;
    if (haveNegative && neg >= 0x80000000) {
      neg -= 0x100000000;
    }
    return values.firstWhere(
      (e) => e.value == index || e.value == neg,
      orElse: () => throw ProtoException("No matching enum value found."),
    );
  }

  T getEnum<T extends ProtoEnumVariant?>(
    int fieldNumber,
    List<T> values, {
    T? defaultValue,
  }) {
    final defaultValues = values.whereType<ProtoEnumVariant>().toList();
    final current = getTagNumberField(fieldNumber);
    if (current == null) {
      if (defaultValue != null) return defaultValue;
      if (null is T) return null as T;
      if (syntax.isV3) {
        return defaultValues.firstWhere(
              (e) => e.value == 0,
              orElse:
                  () =>
                      throw ProtoException(
                        "Missing value for fieldNumber $fieldNumber",
                      ),
            )
            as T;
      }
      throw ProtoException("Missing value for fieldNumber $fieldNumber");
    }
    if (current.config.fieldType != ProtoFieldType.enumType) {
      throw ProtoException("Unsupported field type for conversion as $T.");
    }
    return JsonParser.valueAs(_toEnum(defaultValues, current.value));
  }

  List<T> getReapeatedEnum<T extends ProtoEnumVariant>(
    int fieldNumber,
    List<T> values, {
    List<T>? defaultValue,
  }) {
    final current = getListOrNull<int>(fieldNumber);
    if (current == null) {
      if (defaultValue != null) return defaultValue;
      if (syntax.isV3) {
        return <T>[];
      }
      throw ProtoException("Missing value for fieldNumber $fieldNumber");
    }
    return JsonParser.valueEnsureAsList<T>(
      current.map((e) => _toEnum(values, e)).toList(),
    );
  }

  List<T>? getReapeatedEnumOrNull<T extends ProtoEnumVariant>(
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
