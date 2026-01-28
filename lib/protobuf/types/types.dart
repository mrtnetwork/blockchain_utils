import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/protobuf/codec/decoder.dart';
import 'package:blockchain_utils/protobuf/codec/encoder.dart';
import 'package:blockchain_utils/protobuf/exception/exception.dart';

abstract mixin class ProtobufEncodableMessage {
  static List<ProtocolBufferDecoderResult> deserialize(
    List<int> bytes,
    List<ProtoFieldConfig> fields,
  ) {
    return ProtocolBufferDecoder.decode(bytes, fields);
  }

  List<ProtoFieldConfig> get bufferFields;
  List<Object?> get bufferValues;
  List<int> toBuffer() {
    final bufferFields = this.bufferFields;
    final bufferValues = this.bufferValues;
    if (bufferFields.length != bufferValues.length) {
      throw ProtocolBufferException(
        'Number of fields does not match number of values.',
      );
    }
    return bufferValues.indexed
        .where((e) => e.$2 != null)
        .map((e) {
          return ProtocolBufferEncoder.encode(
            e.$2!,
            bufferFields.elementAt(e.$1),
          );
        })
        .expand((e) => e)
        .toList();
  }
}

abstract mixin class ProtobufEnumVariant {
  abstract final int protoValue;
}

enum ProtobufListEncodingType { packed, unpacked }

/// Protobuf wire types as defined by the Protocol Buffers binary format.
enum WireType {
  /// 0: Varint (variable-length integer)
  /// Used for: int32, int64, uint32, uint64, sint32, sint64, bool, enum
  varint(0),

  /// 1: 64-bit fixed-length
  /// Used for: fixed64, sfixed64, double
  fixed64(1),

  /// 2: Length-delimited
  /// Used for: string, bytes, embedded messages, packed repeated fields
  lengthDelimited(2),

  /// 5: 32-bit fixed-length
  /// Used for: fixed32, sfixed32, float
  fixed32(5);

  final int value;
  const WireType(this.value);
  static WireType fromValue(int type) {
    return values.firstWhere(
      (e) => e.value == type,
      orElse:
          () =>
              throw ProtocolBufferException(
                "Invalid or unsupported wire type.",
                details: {"wiretype": type},
              ),
    );
  }

  List<int> encode(int tag) {
    int value = (tag.asU32 << 3) | this.value;
    return ProtocolBufferEncoder.encodeVarint32(value);
  }

  int skip(List<int> data, int offset) {
    switch (this) {
      case fixed32:
        return 4;
      case fixed64:
        return 8;
      case lengthDelimited:
        final decode = ProtocolBufferDecoder.decodeVarint32(data, offset);
        return decode.consumed + decode.value;
      default:
        final decode = ProtocolBufferDecoder.decodeVarint32(data, offset);
        return decode.consumed;
    }
  }

  static (WireType, int, int) decode(
    List<int> data,
    int offset, {
    WireType? expected,
    int? expectedTag,
  }) {
    final decode = ProtocolBufferDecoder.decodeVarint32(data, offset);
    final int tag = decode.value;
    final int fieldId = tag >> 3;
    final int wireType = tag & 0x07;
    final type = WireType.fromValue(wireType);
    if (expected != null && type != expected) {
      throw ProtocolBufferException(
        "Mismatch wire type.",
        details: {"expected": expected.value, "wiretype": wireType},
      );
    }
    if (expectedTag != null && fieldId != expectedTag) {
      throw ProtocolBufferException(
        "Mismatch tag.",
        details: {"expected": expectedTag, "tag": fieldId},
      );
    }
    return (type, fieldId, decode.consumed);
  }
}

enum ProtoFieldType {
  int32,
  int64,
  uint32,
  uint64,
  sint32,
  sint64,
  fixed32,
  fixed64,
  float,
  double,
  bool,
  string,
  bytes,
  enumType,
  message,
  map,
  repeated,
  sFixed32,
  sFixed64;

  static List<ProtoFieldType> get numericFields => [
    int32,
    int64,
    sint32,
    sint64,
    fixed32,
    fixed64,
    float,
    double,
    enumType,
    uint32,
    uint64,
    sFixed32,
    sFixed64,
  ];
}

enum ProtoRepeatedEncoding { packed, unpacked }

class ProtoFieldConfig {
  final int fieldNumber;
  final ProtoFieldType fieldType;

  final ProtoRepeatedEncoding repeatedEncoding;
  final ProtoFieldType? repeatedType;
  final ProtoFieldType? mapKeyType;
  final ProtoFieldType? mapValueType;
  factory ProtoFieldConfig.internal(
    int fieldNumber,
    ProtoFieldType fieldType,
  ) => ProtoFieldConfig._(fieldNumber: fieldNumber, fieldType: fieldType);

  const ProtoFieldConfig._({
    required this.fieldNumber,
    required this.fieldType,
    this.repeatedEncoding = ProtoRepeatedEncoding.packed,
    this.repeatedType,
    this.mapKeyType,
    this.mapValueType,
  });

  // ---------- Base field ----------
  factory ProtoFieldConfig.field(int fieldNumber, ProtoFieldType type) {
    return ProtoFieldConfig._(fieldNumber: fieldNumber, fieldType: type);
  }

  // ---------- Repeated field ----------
  factory ProtoFieldConfig.repeated({
    required int fieldNumber,
    required ProtoFieldType elementType,
    ProtoRepeatedEncoding? encoding,
  }) {
    if (elementType == ProtoFieldType.repeated ||
        elementType == ProtoFieldType.map) {
      throw ArgumentException.invalidOperationArguments(
        "ProtoFieldConfig",
        reason: "Repeated fields cannot contain $elementType.",
      );
    }
    switch (elementType) {
      case ProtoFieldType.string:
      case ProtoFieldType.bytes:
      case ProtoFieldType.message:
        if (encoding == ProtoRepeatedEncoding.packed) {
          throw ArgumentException.invalidOperationArguments(
            "ProtoFieldConfig",
            reason: "Packed encoding is not allowed for $elementType fields.",
          );
        }
        encoding ??= ProtoRepeatedEncoding.unpacked;

      default:
        encoding ??= ProtoRepeatedEncoding.packed;
        break;
    }

    return ProtoFieldConfig._(
      fieldNumber: fieldNumber,
      fieldType: ProtoFieldType.repeated,
      repeatedEncoding: encoding,
      repeatedType: elementType,
    );
  }

  // ---------- Map field ----------
  factory ProtoFieldConfig.map({
    required int fieldNumber,
    required ProtoFieldType keyType,
    required ProtoFieldType valueType,
  }) {
    return ProtoFieldConfig._(
      fieldNumber: fieldNumber,
      fieldType: ProtoFieldType.map,
      mapKeyType: keyType,
      mapValueType: valueType,
    );
  }

  // ---------- Convenience factories ----------

  factory ProtoFieldConfig.fixed32(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.fixed32);

  factory ProtoFieldConfig.fixed64(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.fixed64);
  factory ProtoFieldConfig.sFixed32(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.sFixed32);

  factory ProtoFieldConfig.sFixed64(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.sFixed64);

  factory ProtoFieldConfig.int32(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.int32);

  factory ProtoFieldConfig.int64(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.int64);
  factory ProtoFieldConfig.uint32(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.uint32);

  factory ProtoFieldConfig.uint64(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.uint64);

  factory ProtoFieldConfig.sint32(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.sint32);

  factory ProtoFieldConfig.sint64(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.sint64);

  factory ProtoFieldConfig.bool(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.bool);

  factory ProtoFieldConfig.float(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.float);

  factory ProtoFieldConfig.double(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.double);

  factory ProtoFieldConfig.string(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.string);
  factory ProtoFieldConfig.enumType(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.enumType);

  factory ProtoFieldConfig.bytes(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.bytes);

  factory ProtoFieldConfig.message(int fieldNumber) =>
      ProtoFieldConfig.field(fieldNumber, ProtoFieldType.message);

  List<int> encodeKey(WireType wireType) => wireType.encode(fieldNumber);
}
