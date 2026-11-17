import 'package:blockchain_utils/encoding/proto/codec/decoder.dart';
import 'package:blockchain_utils/encoding/proto/types/types.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// `google.protobuf.NullValue` (only `NULL_VALUE = 0` exists).
enum ProtoGoogleNullValue implements ProtoEnumVariant {
  nullValue(0, 'NULL_VALUE');

  const ProtoGoogleNullValue(this.value, this.protoName);

  @override
  final int value;

  @override
  final String protoName;

  static ProtoGoogleNullValue fromValue(int? value) {
    return ProtoGoogleNullValue.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProtoGoogleNullValue.nullValue,
    );
  }
}

/// `google.protobuf.Value`: a dynamically typed JSON-like value.
/// Canonical JSON mapping is the raw value itself.
class ProtoGoogleValue extends IProtoMessage {
  final ProtoGoogleNullValue? nullValue;
  final double? numberValue;
  final String? stringValue;
  final bool? boolValue;
  final ProtoGoogleStruct? structValue;
  final ProtoGoogleListValue? listValue;

  const ProtoGoogleValue({
    this.nullValue,
    this.numberValue,
    this.stringValue,
    this.boolValue,
    this.structValue,
    this.listValue,
  });

  factory ProtoGoogleValue.fromDynamic(Object? value) {
    if (value == null) {
      return const ProtoGoogleValue(nullValue: ProtoGoogleNullValue.nullValue);
    }
    if (value is bool) return ProtoGoogleValue(boolValue: value);
    if (value is num) return ProtoGoogleValue(numberValue: value.toDouble());
    if (value is String) return ProtoGoogleValue(stringValue: value);
    if (value is List) {
      return ProtoGoogleValue(
        listValue: ProtoGoogleListValue(
          values: [for (final e in value) ProtoGoogleValue.fromDynamic(e)],
        ),
      );
    }
    if (value is Map) {
      return ProtoGoogleValue(
        structValue: ProtoGoogleStruct.fromJson(
          (value).cast<String, dynamic>(),
        ),
      );
    }
    throw BuError(
      DefaultErrorType.unsupported,
      "Unsupported google.protobuf.Value: $value.",
    );
  }

  Object? toDynamic() {
    if (numberValue != null) return numberValue;
    if (stringValue != null) return stringValue;
    if (boolValue != null) return boolValue;
    if (structValue != null) {
      return structValue!.toJson();
    }
    if (listValue != null) {
      return [for (final e in listValue!.values) e.toDynamic()];
    }
    return null;
  }

  @override
  ProtoMessageConfig protoConfig() => protoConfigStatic();

  static ProtoMessageConfig protoConfigStatic() {
    return ProtoMessageConfig(
      syntax: ProtoSyntax.v3,
      options: const [],
      fields: [
        ProtoFieldConfig.enumType(1),
        ProtoFieldConfig.double(2),
        ProtoFieldConfig.string(3),
        ProtoFieldConfig.bool(4),
        ProtoFieldConfig.message(5),
        ProtoFieldConfig.message(6),
      ],
    );
  }

  @override
  List<Object?> get protoValues => [
    nullValue,
    numberValue,
    stringValue,
    boolValue,
    structValue,
    listValue,
  ];

  @override
  Map<String, dynamic> toJson({
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return {
      'null_value': nullValue?.protoName,
      'number_value': numberValue,
      'string_value': stringValue,
      'bool_value': boolValue,
      'struct_value': structValue?.toJson(),
      'list_value': listValue?.toJson(),
    };
  }

  /// Canonical JSON is the raw value itself.
  Object? toJsonValue() => toDynamic();

  factory ProtoGoogleValue.fromJson(
    Map<String, dynamic> json, {
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return ProtoGoogleValue(
      nullValue:
          json['null_value'] == null
              ? null
              : ProtoGoogleNullValue.fromValue(
                json['null_value'] is int ? json['null_value'] : 0,
              ),
      numberValue: (json['number_value'] as num?)?.toDouble(),
      stringValue: json['string_value'],
      boolValue: json['bool_value'],
      structValue:
          json['struct_value'] == null
              ? null
              : ProtoGoogleStruct.fromJson(
                (json['struct_value'] as Map).cast<String, dynamic>(),
              ),
      listValue:
          json['list_value'] == null
              ? null
              : ProtoGoogleListValue.fromJson(
                (json['list_value'] as Map).cast<String, dynamic>(),
              ),
    );
  }

  /// Parses either the field map or the canonical raw-value form.
  factory ProtoGoogleValue.fromDynamicJson(Object? json) {
    if (json is Map && json.containsKey('number_value')) {
      return ProtoGoogleValue.fromJson(json.cast<String, dynamic>());
    }
    if (json is Map &&
        (json.containsKey('null_value') ||
            json.containsKey('string_value') ||
            json.containsKey('bool_value') ||
            json.containsKey('struct_value') ||
            json.containsKey('list_value'))) {
      return ProtoGoogleValue.fromJson(json.cast<String, dynamic>());
    }
    return ProtoGoogleValue.fromDynamic(json);
  }

  factory ProtoGoogleValue.deserialize(List<int> bytes) {
    final decode = ProtoBufferDecoder.decode(
      bytes: bytes,
      messageConfig: protoConfigStatic(),
    );
    return ProtoGoogleValue(
      nullValue: decode.getEnum<ProtoGoogleNullValue?>(
        1,
        ProtoGoogleNullValue.values,
      ),
      numberValue: decode.getDouble<double?>(2),
      stringValue: decode.getString<String?>(3),
      boolValue: decode.getBool<bool?>(4),
      structValue: decode.messageTo<ProtoGoogleStruct?>(
        5,
        (b) => ProtoGoogleStruct.deserialize(b),
      ),
      listValue: decode.messageTo<ProtoGoogleListValue?>(
        6,
        (b) => ProtoGoogleListValue.deserialize(b),
      ),
    );
  }
}

/// `google.protobuf.ListValue`: `repeated Value values = 1`.
class ProtoGoogleListValue extends IProtoMessage {
  final List<ProtoGoogleValue> values;

  const ProtoGoogleListValue({this.values = const []});

  @override
  ProtoMessageConfig protoConfig() => protoConfigStatic();

  static ProtoMessageConfig protoConfigStatic() {
    return ProtoMessageConfig(
      syntax: ProtoSyntax.v3,
      options: const [],
      fields: [ProtoFieldConfig.message(1)],
    );
  }

  @override
  List<Object?> get protoValues => [values];

  @override
  Map<String, dynamic> toJson({
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return {
      'values': [for (final e in values) e.toJson()],
    };
  }

  /// Canonical JSON is the raw list itself.
  List<Object?> toJsonValue() => [for (final e in values) e.toDynamic()];

  factory ProtoGoogleListValue.fromJson(
    Map<String, dynamic> json, {
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return ProtoGoogleListValue(
      values: [
        for (final e in (json['values'] as List? ?? []))
          ProtoGoogleValue.fromDynamicJson(e),
      ],
    );
  }

  /// Parses either the field map or the canonical raw-list form.
  factory ProtoGoogleListValue.fromDynamic(Object? json) {
    if (json is List) {
      return ProtoGoogleListValue(
        values: [for (final e in json) ProtoGoogleValue.fromDynamic(e)],
      );
    }
    return ProtoGoogleListValue.fromJson((json as Map).cast<String, dynamic>());
  }

  factory ProtoGoogleListValue.deserialize(List<int> bytes) {
    final decode = ProtoBufferDecoder.decode(
      bytes: bytes,
      messageConfig: protoConfigStatic(),
    );
    return ProtoGoogleListValue(
      values:
          decode
              .getListOrNull<List<int>>(1)
              ?.map((b) => ProtoGoogleValue.deserialize(b))
              .toList() ??
          [],
    );
  }
}

/// `google.protobuf.Struct`: `map<string, Value> fields = 1`.
/// Canonical JSON mapping is the raw object itself.
class ProtoGoogleStruct extends IProtoMessage {
  final Map<String, ProtoGoogleValue> fields;

  const ProtoGoogleStruct({this.fields = const {}});

  @override
  ProtoMessageConfig protoConfig() => protoConfigStatic();

  static ProtoMessageConfig protoConfigStatic() {
    return ProtoMessageConfig(
      syntax: ProtoSyntax.v3,
      options: const [],
      fields: [
        ProtoFieldConfig.map(
          fieldNumber: 1,
          keyType: ProtoFieldType.string,
          valueType: ProtoFieldType.message,
        ),
      ],
    );
  }

  @override
  List<Object?> get protoValues => [fields];

  @override
  Map<String, dynamic> toJson({
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return {'fields': fields.map((k, v) => MapEntry(k, v.toJson()))};
  }

  /// Canonical JSON is the raw object itself.
  Map<String, Object?> toJsonValue() {
    return fields.map((k, v) => MapEntry(k, v.toDynamic()));
  }

  factory ProtoGoogleStruct.fromJson(
    Map<String, dynamic> json, {
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    final fields = json['fields'];
    if (fields is Map) {
      return ProtoGoogleStruct(
        fields: fields.map(
          (k, v) => MapEntry(k.toString(), ProtoGoogleValue.fromDynamicJson(v)),
        ),
      );
    }
    return const ProtoGoogleStruct();
  }

  /// Parses either the field map or the canonical raw-object form.
  factory ProtoGoogleStruct.fromDynamic(Object? json) {
    if (json is Map && !json.containsKey('fields')) {
      return ProtoGoogleStruct(
        fields: (json).cast<String, dynamic>().map(
          (k, v) => MapEntry(k, ProtoGoogleValue.fromDynamic(v)),
        ),
      );
    }
    return ProtoGoogleStruct.fromJson((json as Map).cast<String, dynamic>());
  }

  factory ProtoGoogleStruct.deserialize(List<int> bytes) {
    final decode = ProtoBufferDecoder.decode(
      bytes: bytes,
      messageConfig: protoConfigStatic(),
    );
    return ProtoGoogleStruct(
      fields: decode.getMapField<String, ProtoGoogleValue>(
        fieldNumber: 1,
        keyMapper: (k) => k.toString(),
        valueMapper: (v) => ProtoGoogleValue.deserialize((v as List<int>)),
      ),
    );
  }
}
