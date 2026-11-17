import 'package:blockchain_utils/encoding/proto/codec/decoder.dart';
import 'package:blockchain_utils/encoding/proto/google/any.dart';
import 'package:blockchain_utils/encoding/proto/types/types.dart';
import 'package:blockchain_utils/utils/json/json.dart';

/// `google.rpc.Status` runtime (used by `sui.rpc.v2` error responses).
class ProtoGoogleRpcStatus extends IProtoMessage {
  /// Status code (see `google.rpc.Code`).
  final int? code;

  /// Error message.
  final String? message;

  /// Additional error details (`google.protobuf.Any` list).
  final List<ProtoGoogleAny> details;

  const ProtoGoogleRpcStatus({
    this.code,
    this.message,
    this.details = const [],
  });

  @override
  ProtoMessageConfig protoConfig() => protoConfigStatic();

  static ProtoMessageConfig protoConfigStatic() {
    return ProtoMessageConfig(
      syntax: ProtoSyntax.v3,
      options: const [],
      fields: [
        ProtoFieldConfig.int32(1),
        ProtoFieldConfig.string(2),
        ProtoFieldConfig.message(3),
      ],
    );
  }

  @override
  List<Object?> get protoValues => [code, message, details];

  @override
  Map<String, dynamic> toJson({
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return {
      'code': code,
      'message': message,
      'details': [for (final e in details) e.toJson(config: config)],
    };
  }

  factory ProtoGoogleRpcStatus.fromJson(
    Map<String, dynamic> json, {
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return ProtoGoogleRpcStatus(
      code: JsonParser.valueAsInt<int?>(json['code']),
      message: JsonParser.valueAsString<String?>(json['message']),
      details: [
        for (final e in (json['details'] as List? ?? []))
          ProtoGoogleAny.fromJson(
            (e as Map).cast<String, dynamic>(),
            config: config,
          ),
      ],
    );
  }

  factory ProtoGoogleRpcStatus.deserialize(List<int> bytes) {
    final decode = ProtoBufferDecoder.decode(
      bytes: bytes,
      messageConfig: protoConfigStatic(),
    );
    return ProtoGoogleRpcStatus(
      code: decode.getInt<int?>(1),
      message: decode.getString<String?>(2),
      details:
          decode
              .getListOrNull<List<int>>(3)
              ?.map((b) => ProtoGoogleAny.deserialize(b))
              .toList() ??
          [],
    );
  }
}
