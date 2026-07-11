import 'dart:typed_data';
import 'package:blockchain_utils/double/codec/double_utils.dart';
import 'package:blockchain_utils/double/codec/float_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/proto/exception/exception.dart';
import 'package:blockchain_utils/proto/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/bytes_tracker.dart';
import 'package:blockchain_utils/utils/json/exception/exception.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class ProtoBufferEncoder {
  static List<int> encodeField(
    Object value,
    ProtoFieldConfig config, {
    ProtoSyntax syntax = ProtoSyntax.v2,
  }) {
    return _encodeField(value: value, config: config, syntax: syntax) ?? [];
  }

  static List<int> encode({
    required List<Object?> protoValues,
    required ProtoMessageConfig config,
  }) {
    final bufferFields = config.fields;
    if (bufferFields.length != protoValues.length) {
      throw ProtoException(
        "The values and field IDs must have the same length.",
        details: {
          "fieldIds": bufferFields.length.toString(),
          "variables": protoValues.length.toString(),
        },
      );
    }
    return protoValues.indexed
        .map((e) {
          final value = e.$2;
          if (value == null) return null;
          final encode = _encodeField(
            value: value,
            config: config.fields.elementAt(e.$1),
            syntax: config.syntax,
          );
          return encode;
        })
        .expand((e) => e ?? <int>[])
        .toList();
  }

  static List<int>? _encodeField({
    required Object value,
    required ProtoFieldConfig config,
    required ProtoSyntax syntax,
    bool packed = false,
    bool skipDefault = true,
  }) {
    try {
      skipDefault &= syntax.isV3 && !config.hasOptionalFalg;
      final encoding = config.fieldType;
      switch (encoding) {
        case ProtoFieldType.bytes:
          final List<int> v = JsonParser.valueAsBytes(value, allowHex: true);
          if (v.isEmpty && skipDefault) return null;
          return _encodeBytes(v, config);
        case ProtoFieldType.enumType:
          int index = switch (value) {
            final int r => r,
            final ProtoEnumVariant r => r.value,
            _ =>
              throw ArgumentException.invalidOperationArguments(
                "encode",
                reason:
                    "Invalid enum type. value must be integer or type of `ProtoEnumVariant`",
              ),
          };
          if (index == 0 && skipDefault) return null;
          return _encodeEnum(index, config, packed: packed);
        case ProtoFieldType.string:
          final String v = JsonParser.valueAsString(value);
          if (v.isEmpty && skipDefault) return null;
          return _encodeBytes(
            JsonParser.valueAsBytes(
              v,
              allowHex: false,
              encoding: StringEncoding.utf8,
            ),
            config,
          );
        case ProtoFieldType.float:
        case ProtoFieldType.double:
          final double v = JsonParser.valueAsDouble<double>(value);
          if (v == 0.0 && skipDefault) return null;
          return _encodeDouble(v, config, packed: packed);
        case ProtoFieldType.fixed32:
        case ProtoFieldType.sFixed32:
          final int v = JsonParser.valueAsInt<int>(value);
          if (v == 0 && skipDefault) return null;
          return _encodeFixed32(v, config, packed: packed);
        case ProtoFieldType.fixed64:
        case ProtoFieldType.sFixed64:
          final BigInt v = JsonParser.valueAsBigInt<BigInt>(value);
          if (v == BigInt.zero && skipDefault) return null;
          return _encodeFixed64(v, config, packed: packed);
        case ProtoFieldType.int32:
        case ProtoFieldType.uint32:
          final int v = JsonParser.valueAsInt<int>(value);
          if (v == 0 && skipDefault) return null;
          return _encodeInt32(v, config, packed: packed);
        case ProtoFieldType.int64:
        case ProtoFieldType.uint64:
          final BigInt v = JsonParser.valueAsBigInt<BigInt>(value);
          if (v == BigInt.zero && skipDefault) return null;
          return _encodeInt64(v, config, packed: packed);
        case ProtoFieldType.sint32:
          final int v = JsonParser.valueAsInt<int>(value);
          if (v == 0 && skipDefault) return null;
          return _encodeSint32(v, config, packed: packed);
        case ProtoFieldType.sint64:
          final BigInt v = JsonParser.valueAsBigInt<BigInt>(value);
          if (v == BigInt.zero && skipDefault) return null;
          return _encodeSint64(v, config, packed: packed);
        case ProtoFieldType.bool:
          final bool v = JsonParser.valueAsBool<bool>(value);
          if (!v && skipDefault) return null;
          return _encodeBool(v, config, packed: packed);
        case ProtoFieldType.message:
          return _ecodableMessage(switch (value) {
            IProtoMessage buffer => buffer.toBuffer(),
            _ => JsonParser.valueAsBytes<List<int>>(value),
          }, config);
        case ProtoFieldType.repeated:
          final List<Object> v = JsonParser.valueEnsureAsList(value);
          if (v.isEmpty && skipDefault) return null;
          return _encodeList(value: v, wiretype: config, syntax: syntax);
        case ProtoFieldType.map:
          final Map v = JsonParser.valueAsMap(value);
          if (v.isEmpty && skipDefault) return null;
          return _encodeMap(value: v, wiretype: config, syntaxt: syntax);
      }
    } on JsonParserError {
      throw ArgumentException.invalidOperationArguments(
        "encode",
        reason: "Invalid value provided for field number ${config.fieldNumber}",
        details: {"value": value.toString()},
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
      ...wiretype.encodeKey(ProtoWireType.lengthDelimited),
      ...lengthEncoded,
      ...value,
    ];
  }

  static List<int> _encodeMap({
    required Map value,
    required ProtoFieldConfig wiretype,
    required ProtoSyntax syntaxt,
  }) {
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
      final encodeKey = _encodeField(
        value: i.key,
        config: keyConfig,
        syntax: syntaxt,
        skipDefault: false,
      );
      final encodeValue = _encodeField(
        value: i.value,
        config: valueConfig,
        syntax: syntaxt,
        skipDefault: false,
      );
      if (encodeKey == null || encodeValue == null) {
        throw ArgumentException.invalidOperationArguments(
          "encode",
          reason: "Unexpected map encoding result.",
        );
      }
      final e = [...encodeKey, ...encodeValue];
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
        details: {
          "value": value.toString(),
          "fieldNumber": config.fieldNumber.toString(),
        },
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
        details: {
          "value": value.toString(),
          "fieldNumber": config.fieldNumber.toString(),
        },
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
    return [...config.encodeKey(ProtoWireType.varint), ...encode];
  }

  static List<int> _encodeEnum(
    int index,
    ProtoFieldConfig config, {
    bool packed = false,
  }) {
    _validateInteger(
      min: BinaryOps.minInt32,
      max: BinaryOps.maxInt32,
      value: index,
      config: config,
    );
    index &= BinaryOps.mask32;
    final encode = encodeVarint32(index);
    if (packed) {
      return encode;
    }
    return [...config.encodeKey(ProtoWireType.varint), ...encode];
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
    final encode = value.toLeBytes(length: 4, sign: !isU32);
    if (packed) {
      return encode;
    }
    return [...config.encodeKey(ProtoWireType.fixed32), ...encode];
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
    final encode = value.toLeBytes(length: 8, sign: !isU64);
    if (packed) {
      return encode;
    }
    return [...config.encodeKey(ProtoWireType.fixed64), ...encode];
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
      return [...config.encodeKey(ProtoWireType.fixed32), ...encode];
    }
    return [...config.encodeKey(ProtoWireType.fixed64), ...encode];
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
    return [...config.encodeKey(ProtoWireType.varint), ...encode];
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
    return [...config.encodeKey(ProtoWireType.varint), ...encode];
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
    return [...config.encodeKey(ProtoWireType.varint), ...encode];
  }

  static List<int> _encodeBool(
    bool value,
    ProtoFieldConfig wiretype, {
    bool packed = false,
  }) {
    return _encodeInt32(value ? 1 : 0, wiretype, packed: packed);
  }

  static List<int> _encodeList({
    required List<Object> value,
    required ProtoFieldConfig wiretype,
    required ProtoSyntax syntax,
  }) {
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
      final encodeElem = _encodeField(
        value: i,
        config: innerConfig,
        packed: isPacked,
        syntax: syntax,
        skipDefault: false,
      );
      if (encodeElem == null) {
        throw ArgumentException.invalidOperationArguments(
          "encode",
          reason: "Unexpected array encoding result.",
        );
      }
      tracker.add(encodeElem);
    }
    final bytes = tracker.toBytes();
    if (!isPacked) return bytes;
    return _encodeBytes(bytes, wiretype);
  }

  static List<int> _ecodableMessage(
    //  message,
    List<int> message,
    ProtoFieldConfig wiretype,
  ) {
    return _encodeBytes(message, wiretype);
  }
}
