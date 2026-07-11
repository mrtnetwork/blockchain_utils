import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/proto/codec/decoder.dart';
import 'package:blockchain_utils/proto/codec/encoder.dart';
import 'package:blockchain_utils/proto/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';

abstract mixin class ProtoEnumVariant {
  abstract final int value;
  abstract final String protoName;
}

enum ProtoListEncodingType { packed, unpacked }

/// Protobuf wire types as defined by the Protocol Buffers binary format.
enum ProtoWireType {
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
  const ProtoWireType(this.value);
  static ProtoWireType fromValue(int type) {
    return values.firstWhere(
      (e) => e.value == type,
      orElse:
          () =>
              throw ProtoException(
                "Invalid or unsupported wire type.",
                details: {"wiretype": type.toString()},
              ),
    );
  }

  List<int> encode(int tag) {
    int value = (tag.asU32 << 3) | this.value;
    return ProtoBufferEncoder.encodeVarint32(value);
  }

  int skip(List<int> data, int offset) {
    switch (this) {
      case fixed32:
        return 4;
      case fixed64:
        return 8;
      case lengthDelimited:
        final decode = ProtoBufferDecoder.decodeVarint32(data, offset);
        return decode.consumed + decode.value;
      default:
        final decode = ProtoBufferDecoder.decodeVarint64(
          data,
          ProtoFieldConfig.uint64(1),
          offset: offset,
        );
        return decode.consumed;
    }
  }

  static (ProtoWireType, int, int) decode(
    List<int> data,
    int offset, {
    ProtoWireType? expected,
    int? expectedTag,
  }) {
    final decode = ProtoBufferDecoder.decodeVarint32(data, offset);
    final int tag = decode.value;
    final int fieldId = tag >> 3;
    final int wireType = tag & 0x07;
    final type = ProtoWireType.fromValue(wireType);
    if (expected != null && type != expected) {
      throw ProtoException(
        "Mismatch wire type.",
        details: {
          "expected": expected.value.toString(),
          "wiretype": wireType.toString(),
        },
      );
    }
    if (expectedTag != null && fieldId != expectedTag) {
      throw ProtoException(
        "Mismatch tag.",
        details: {
          "expected": expectedTag.toString(),
          "tag": fieldId.toString(),
        },
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
  final List<ProtoOption> options;
  final bool hasOptionalFalg;
  factory ProtoFieldConfig.internal(
    int fieldNumber,
    ProtoFieldType fieldType, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlag = false,
  }) => ProtoFieldConfig._(
    fieldNumber: fieldNumber,
    fieldType: fieldType,
    options: options,
    hasOptionalFalg: hasOptionalFlag,
  );

  const ProtoFieldConfig._({
    required this.fieldNumber,
    required this.fieldType,
    required this.options,
    required this.hasOptionalFalg,
    this.repeatedEncoding = ProtoRepeatedEncoding.packed,
    this.repeatedType,
    this.mapKeyType,
    this.mapValueType,
  });

  // ---------- Base field ----------
  factory ProtoFieldConfig.field(
    int fieldNumber,
    ProtoFieldType type, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) {
    return ProtoFieldConfig._(
      fieldNumber: fieldNumber,
      fieldType: type,
      options: options,
      hasOptionalFalg: hasOptionalFlags,
    );
  }

  // ---------- Repeated field ----------
  factory ProtoFieldConfig.repeated({
    required int fieldNumber,
    required ProtoFieldType elementType,
    ProtoRepeatedEncoding? encoding,
    bool hasOptionalFlags = false,
    List<ProtoOption> options = const [],
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
      options: options,
      hasOptionalFalg: hasOptionalFlags,
    );
  }

  // ---------- Map field ----------
  factory ProtoFieldConfig.map({
    required int fieldNumber,
    required ProtoFieldType keyType,
    required ProtoFieldType valueType,
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) {
    return ProtoFieldConfig._(
      fieldNumber: fieldNumber,
      fieldType: ProtoFieldType.map,
      mapKeyType: keyType,
      mapValueType: valueType,
      options: options,
      hasOptionalFalg: hasOptionalFlags,
    );
  }

  // ---------- Convenience factories ----------

  factory ProtoFieldConfig.fixed32(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.fixed32,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.fixed64(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.fixed64,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );
  factory ProtoFieldConfig.sFixed32(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.sFixed32,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.sFixed64(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.sFixed64,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.int32(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.int32,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.int64(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.int64,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );
  factory ProtoFieldConfig.uint32(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.uint32,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.uint64(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.uint64,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.sint32(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.sint32,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.sint64(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.sint64,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.bool(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.bool,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.float(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.float,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.double(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.double,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.string(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.string,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );
  factory ProtoFieldConfig.enumType(
    int fieldNumber, {
    bool hasOptionalFlags = false,
    List<ProtoOption> options = const [],
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.enumType,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.bytes(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.bytes,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  factory ProtoFieldConfig.message(
    int fieldNumber, {
    List<ProtoOption> options = const [],
    bool hasOptionalFlags = false,
  }) => ProtoFieldConfig.field(
    fieldNumber,
    ProtoFieldType.message,
    options: options,
    hasOptionalFlags: hasOptionalFlags,
  );

  List<int> encodeKey(ProtoWireType wireType) => wireType.encode(fieldNumber);
}

enum ProtoSyntax {
  v2("proto2"),
  v3("proto3");

  final String syntax;
  const ProtoSyntax(this.syntax);

  static ProtoSyntax fromSyntax(String? value) {
    return values.firstWhere(
      (e) => e.syntax == value,
      orElse:
          () =>
              throw ProtoException(
                "Unsupported proto syntax.",
                details: {"syntax": value},
              ),
    );
  }

  bool get isV3 => this == v3;
}

class ProtoMessageConfig {
  final ProtoSyntax syntax;
  final List<ProtoOption> options;
  final List<ProtoFieldConfig> fields;
  const ProtoMessageConfig({
    this.syntax = ProtoSyntax.v3,
    this.options = const [],
    this.fields = const [],
  });
}

abstract class IProtoMessage {
  const IProtoMessage();
  ProtoMessageConfig protoConfig();
  List<Object?> get protoValues;
  static ProtoBufferDecoderResult deserialize(
    List<int> bytes,
    ProtoMessageConfig config,
  ) {
    return ProtoBufferDecoder.decode(bytes: bytes, messageConfig: config);
  }

  List<int> toBuffer() {
    return ProtoBufferEncoder.encode(
      config: protoConfig(),
      protoValues: protoValues,
    );
  }
}

abstract class ProtoOption with Equality {
  final String name;
  Object? get value;
  const ProtoOption({required this.name});
  factory ProtoOption.parse({required String name, Object? value}) {
    try {
      if (name.contains("google.api.http")) {
        return ProtoOptionHttp.parse(name, value);
      }
      switch (value) {
        case null:
          return ProtoOptionNull(name: name);
        case Map():
          return ProtoOptionMap(
            name: name,
            value: JsonParser.valueAsMap(value),
          );
        case int():
          return ProtoOptionInt(name: name, value: value);
        case double():
          return ProtoOptionDouble(name: name, value: value);
        case bool():
          return ProtoOptionBool(name: name, value: value);
        case String():
          return ProtoOptionString(name: name, value: value);
        default:
          throw ProtoException(
            "Unsported google http proto option.",
            details: {"name": name},
          );
      }
    } catch (e) {
      throw ProtoException(
        "Failed to google http proto option.",
        details: {"name": name, "value": value?.runtimeType.toString()},
      );
    }
  }

  @override
  List<dynamic> get variables => [name];

  Map<String, dynamic> toJson() {
    return {"name": name};
  }

  String stringify();
}

class ProtoOptionInt extends ProtoOption {
  @override
  final int value;
  const ProtoOptionInt({required super.name, required this.value});

  @override
  List<dynamic> get variables => [name, value];

  @override
  String stringify() {
    return 'ProtoOptionInt(name: "$name", value: $value)';
  }
}

class ProtoOptionDouble extends ProtoOption {
  @override
  final double value;
  const ProtoOptionDouble({required super.name, required this.value});

  @override
  List<dynamic> get variables => [name, value];

  @override
  String stringify() {
    return 'ProtoOptionDouble(name: "$name", value: $value)';
  }
}

class ProtoOptionBool extends ProtoOption {
  @override
  final bool value;
  const ProtoOptionBool({required super.name, required this.value});

  @override
  List<dynamic> get variables => [name, value];

  @override
  String stringify() {
    return 'ProtoOptionBool(name: "$name", value: $value)';
  }
}

class ProtoOptionString extends ProtoOption {
  @override
  final String value;
  const ProtoOptionString({required super.name, required this.value});

  @override
  List<dynamic> get variables => [name, value];

  @override
  String stringify() {
    return 'ProtoOptionString(name: "$name", value: "$value")';
  }
}

class ProtoOptionMap extends ProtoOption {
  @override
  final Map<String, dynamic> value;
  const ProtoOptionMap({required super.name, required this.value});

  @override
  List<dynamic> get variables => [name, value];
  static Map<String, dynamic> stringifyMap(Map value) {
    return value.map(
      (k, v) => MapEntry('"$k"', switch (v) {
        String() => '"$v"',
        Map() => stringifyMap(v),
        _ => v,
      }),
    );
  }

  @override
  String stringify() {
    return 'ProtoOptionMap(name: "$name", value: ${stringifyMap(value)})';
  }
}

class ProtoOptionNull extends ProtoOption {
  const ProtoOptionNull({required super.name});

  @override
  List<dynamic> get variables => [name];

  @override
  String stringify() {
    return 'ProtoOptionNull(name: "$name")';
  }

  @override
  Object? get value => null;
}

class ProtoOptionHttp extends ProtoOption {
  final RequestMethod method;
  final String path;
  final String? bodyField;
  const ProtoOptionHttp({
    required super.name,
    required this.method,
    required this.path,
    this.bodyField,
  });
  factory ProtoOptionHttp.parse(String name, Object? value) {
    if (name.endsWith("get") || name.endsWith("post")) {
      return ProtoOptionHttp(
        name: name,
        method: name.endsWith("post") ? RequestMethod.post : RequestMethod.get,
        path: JsonParser.valueAsString(value),
      );
    }
    final data = JsonParser.valueEnsureAsMap<String, dynamic>(value);
    if (data.hasValue("post")) {
      final body = data.valueAs<String?>("body");
      return ProtoOptionHttp(
        name: name,
        method: RequestMethod.post,
        path: data.valueAs("post"),
        bodyField: body == null ? null : (body == "*" ? null : body),
      );
    }
    if (data.hasValue("get")) {
      return ProtoOptionHttp(
        name: name,
        method: RequestMethod.get,
        path: data.valueAs("get"),
      );
    }
    throw ProtoException("Unexpeted google http option params.");
  }

  @override
  List<dynamic> get variables => [name, method, path, bodyField];

  @override
  String stringify() {
    return 'ProtoOptionHttp(name: "$name", method: RequestMethod.${method.name}, path: "$path", ${!method.isGet && bodyField != null ? 'bodyField: "${bodyField ?? '*'}"' : ''} )';
  }

  @override
  Object? get value => bodyField;
}
