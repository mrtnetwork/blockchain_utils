import 'dart:typed_data';

import 'package:blockchain_utils/double/codec/double_utils.dart';
import 'package:blockchain_utils/double/codec/float_utils.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/protobuf/types/types.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/bytes_tracker.dart';
import 'package:blockchain_utils/utils/json/exception/exception.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class ProtocolBufferEncoder {
  static List<int> encode(
    Object value,
    ProtoFieldConfig config, {
    bool packed = false,
  }) {
    try {
      final encoding = config.fieldType;
      return switch (encoding) {
        ProtoFieldType.bytes => _encodeBytes(
          JsonParser.valueAsBytes(value, allowHex: true),
          config,
        ),
        ProtoFieldType.enumType => _encodeEnum(value, config, packed: packed),
        ProtoFieldType.string => _encodeBytes(
          JsonParser.valueAsBytes(
            JsonParser.valueAsString(value),
            allowHex: false,
            encoding: StringEncoding.utf8,
          ),
          config,
        ),
        ProtoFieldType.float || ProtoFieldType.double => _encodeDouble(
          JsonParser.valueAsDouble<double>(value),
          config,
          packed: packed,
        ),
        ProtoFieldType.fixed32 || ProtoFieldType.sFixed32 => _encodeFixed32(
          JsonParser.valueAsInt(value),
          config,
          packed: packed,
        ),
        ProtoFieldType.fixed64 || ProtoFieldType.sFixed64 => _encodeFixed64(
          JsonParser.valueAsBigInt(value),
          config,
          packed: packed,
        ),
        ProtoFieldType.int32 || ProtoFieldType.uint32 => _encodeInt32(
          JsonParser.valueAsInt(value),
          config,
          packed: packed,
        ),
        ProtoFieldType.int64 || ProtoFieldType.uint64 => _encodeInt64(
          JsonParser.valueAsBigInt(value),
          config,
          packed: packed,
        ),
        ProtoFieldType.sint32 => _encodeSint32(
          JsonParser.valueAsInt(value),
          config,
          packed: packed,
        ),
        ProtoFieldType.sint64 => _encodeSint64(
          JsonParser.valueAsBigInt(value),
          config,
          packed: packed,
        ),
        ProtoFieldType.bool => _encodeBool(
          JsonParser.valueAsBool(value),
          config,
          packed: packed,
        ),
        ProtoFieldType.message => _ecodableMessage(
          JsonParser.valueAs(value),
          config,
        ),
        ProtoFieldType.repeated => _encodeList(
          JsonParser.valueEnsureAsList(value),
          config,
        ),
        ProtoFieldType.map => _encodeMap(JsonParser.valueAsMap(value), config),
      };
    } on JSONHelperException {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        reason: "Invalid value provided for field number ${config.fieldNumber}",
        details: {"value": value},
      );
    }
  }

  static List<int> encodeVarint32(int value) {
    final List<int> result = [];
    while (value > 0x7F) {
      result.add((value & 0x7F) | 0x80);
      value >>= 7;
    }
    result.add(value);
    return result;
  }

  static int _zigZagEncode32(int n) {
    return n >= 0 ? n * 2 : (-n * 2) - 1;
  }

  static BigInt _zigZagEncode64(BigInt n) {
    return (n << 1) ^ (n >> 63);
  }

  static List<int> _encodeVarintBig(BigInt value) {
    final List<int> dest = [];
    final mask = BigInt.from(0x80);
    final mask2 = BigInt.from(0x7F);
    while (value >= mask) {
      dest.add(((value & mask2) | mask).toU8);
      value >>= 7;
    }
    dest.add((value & mask2).toU8);
    return dest;
  }

  static List<int> _encodeBytes(List<int> value, ProtoFieldConfig wiretype) {
    final lengthEncoded = encodeVarint32(value.length);
    return [
      ...wiretype.encodeKey(WireType.lengthDelimited),
      ...lengthEncoded,
      ...value,
    ];
  }

  static List<int> _encodeMap(Map value, ProtoFieldConfig wiretype) {
    if (value.isEmpty) return [];
    final keyType = wiretype.mapKeyType;
    final valueType = wiretype.mapValueType;
    if (keyType == null || valueType == null) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        reason: "Invalid map tag config. missing inner key encoding type",
      );
    }
    final keyConfig = ProtoFieldConfig.internal(1, keyType);
    final valueConfig = ProtoFieldConfig.internal(2, valueType);
    final List<int> result = [];
    for (final i in value.entries) {
      final e = [...encode(i.key, keyConfig), ...encode(i.value, valueConfig)];
      result.addAll(_encodeBytes(e, wiretype));
    }
    return result;
  }

  static void _validateInteger({
    required int min,
    required int max,
    required int value,
    required ProtoFieldConfig config,
  }) {
    if (value < min || value > max) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        reason: "Invalid integer for type ${config.fieldType.name}.",
        details: {"value": value, "fieldNumber": config.fieldNumber},
      );
    }
  }

  static void _validateBigInteger({
    required BigInt min,
    required BigInt max,
    required BigInt value,
    required ProtoFieldConfig config,
  }) {
    if (value < min || value > max) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        reason: "Invalid integer for type ${config.fieldType.name}.",
        details: {"value": value, "fieldNumber": config.fieldNumber},
      );
    }
  }

  static List<int> _encodeInt32(
    int value,
    ProtoFieldConfig config, {
    bool packed = false,
  }) {
    final isU32 = config.fieldType == ProtoFieldType.uint32;
    _validateInteger(
      max: isU32 ? BinaryOps.maxUint32 : BinaryOps.maxInt32,
      min: isU32 ? 0 : BinaryOps.minInt32,
      value: value,
      config: config,
    );
    final encode = switch (value.isNegative) {
      false => encodeVarint32(value),
      true => _encodeVarintBig(BigInt.from(value) & BinaryOps.maskBig64),
    };
    if (packed) {
      return encode;
    }
    return [...config.encodeKey(WireType.varint), ...encode];
  }

  static List<int> _encodeEnum(
    Object value,
    ProtoFieldConfig config, {
    bool packed = false,
  }) {
    int enumIndex = switch (value) {
      final int r => r,
      final ProtobufEnumVariant r => r.protoValue,
      _ =>
        throw ArgumentException.invalidOperationArguments(
          "encode",
          reason:
              "Invalid enum type. value must be integer or type of `ProtobufEnumVariant`",
        ),
    };
    _validateInteger(
      min: BinaryOps.minInt32,
      max: BinaryOps.maxInt32,
      value: enumIndex,
      config: config,
    );
    enumIndex &= BinaryOps.mask32;
    final encode = encodeVarint32(enumIndex);
    if (packed) {
      return encode;
    }
    return [...config.encodeKey(WireType.varint), ...encode];
  }

  static List<int> _encodeFixed32(
    int value,
    ProtoFieldConfig config, {
    bool packed = false,
  }) {
    final isU32 = config.fieldType == ProtoFieldType.fixed32;
    _validateInteger(
      min: isU32 ? 0 : BinaryOps.minInt32,
      max: isU32 ? BinaryOps.maxUint32 : BinaryOps.maxInt32,
      value: value,
      config: config,
    );
    final encode = IntUtils.toBytes(value, byteOrder: Endian.little, length: 4);
    if (packed) {
      return encode;
    }
    return [...config.encodeKey(WireType.fixed32), ...encode];
  }

  static List<int> _encodeFixed64(
    BigInt value,
    ProtoFieldConfig config, {
    bool packed = false,
  }) {
    final isU64 = config.fieldType == ProtoFieldType.fixed64;
    _validateBigInteger(
      max: isU64 ? BinaryOps.maxU64 : BinaryOps.maxInt64,
      min: isU64 ? BigInt.zero : BinaryOps.minInt64,
      value: value,
      config: config,
    );
    final encode = BigintUtils.toBytes(value, order: Endian.little, length: 8);
    if (packed) {
      return encode;
    }
    return [...config.encodeKey(WireType.fixed64), ...encode];
  }

  static List<int> _encodeDouble(
    double value,
    ProtoFieldConfig config, {
    bool packed = false,
  }) {
    final encoding = config.fieldType;

    final encode = switch (encoding) {
      ProtoFieldType.float => FloatCoder.toBytes(
        value,
        byteOrder: Endian.little,
      ),
      ProtoFieldType.double => DoubleCoder.toBytes(
        value,
        byteOrder: Endian.little,
      ),
      _ =>
        throw ArgumentException.invalidOperationArguments(
          "encodeDouble",
          reason: "Invalid encoding type.",
        ),
    };
    if (packed) {
      return encode;
    }
    if (encoding == ProtoFieldType.float) {
      return [...config.encodeKey(WireType.fixed32), ...encode];
    }
    return [...config.encodeKey(WireType.fixed64), ...encode];
  }

  static List<int> _encodeInt64(
    BigInt value,
    ProtoFieldConfig config, {
    bool packed = false,
  }) {
    final bool isU64 = config.fieldType == ProtoFieldType.uint64;
    _validateBigInteger(
      max: isU64 ? BinaryOps.maxU64 : BinaryOps.maxInt64,
      min: isU64 ? BigInt.zero : BinaryOps.minInt64,
      value: value,
      config: config,
    );
    final encode = switch (value.isNegative) {
      false => _encodeVarintBig(value),
      true => _encodeVarintBig(value & BinaryOps.maskBig64),
    };
    if (packed) return encode;
    return [...config.encodeKey(WireType.varint), ...encode];
  }

  static List<int> _encodeSint32(
    int value,
    ProtoFieldConfig config, {
    bool packed = false,
  }) {
    _validateInteger(
      max: BinaryOps.maxInt32,
      min: BinaryOps.minInt32,
      value: value,
      config: config,
    );
    final encode = encodeVarint32(_zigZagEncode32(value));
    if (packed) return encode;
    return [...config.encodeKey(WireType.varint), ...encode];
  }

  static List<int> _encodeSint64(
    BigInt value,
    ProtoFieldConfig config, {
    bool packed = false,
  }) {
    _validateBigInteger(
      max: BinaryOps.maxInt64,
      min: BinaryOps.minInt64,
      value: value,
      config: config,
    );
    final encode = _encodeVarintBig(_zigZagEncode64(value));
    if (packed) return encode;
    return [...config.encodeKey(WireType.varint), ...encode];
  }

  static List<int> _encodeBool(
    bool value,
    ProtoFieldConfig wiretype, {
    bool packed = false,
  }) {
    return _encodeInt32(value ? 1 : 0, wiretype, packed: packed);
  }

  static List<int> _encodeList(List<Object> value, ProtoFieldConfig wiretype) {
    if (value.isEmpty) return [];
    final inner = wiretype.repeatedType;
    if (inner == null) {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        reason:
            "Invalid list encoding tag config. missing list inner encoding type",
      );
    }
    final innerConfig = ProtoFieldConfig.internal(wiretype.fieldNumber, inner);
    final isPacked = wiretype.repeatedEncoding == ProtoRepeatedEncoding.packed;
    final tracker = DynamicByteTracker();
    for (final i in value) {
      tracker.add(encode(i, innerConfig, packed: isPacked));
    }
    final bytes = tracker.toBytes();
    if (!isPacked) return bytes;
    return _encodeBytes(bytes, wiretype);
  }

  static List<int> _ecodableMessage(
    ProtobufEncodableMessage message,
    ProtoFieldConfig wiretype,
  ) {
    return _encodeBytes(message.toBuffer(), wiretype);
  }
}
