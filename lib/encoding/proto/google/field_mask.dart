import 'package:blockchain_utils/encoding/proto/codec/decoder.dart';
import 'package:blockchain_utils/encoding/proto/types/types.dart';

/// `google.protobuf.FieldMask` runtime.
///
/// Canonical JSON mapping is a single comma-joined string
/// (`"user.displayName,photo"`); a list of paths is accepted on parse.
class ProtoGoogleFieldMask extends IProtoMessage {
  final List<String> paths;

  const ProtoGoogleFieldMask({this.paths = const []});

  @override
  ProtoMessageConfig protoConfig() => protoConfigStatic();

  static ProtoMessageConfig protoConfigStatic() {
    return ProtoMessageConfig(
      syntax: ProtoSyntax.v3,
      options: const [],
      fields: [ProtoFieldConfig.string(1)],
    );
  }

  @override
  List<Object?> get protoValues => [paths];

  @override
  Map<String, dynamic> toJson({
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return {
      'paths': [for (final e in paths) e],
    };
  }

  /// Canonical JSON is the comma-joined paths string.
  String toJsonString() => paths.join(',');

  factory ProtoGoogleFieldMask.fromJson(
    Map<String, dynamic> json, {
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return ProtoGoogleFieldMask(
      paths: [
        for (final e in (json['paths'] as List? ?? [])) e.toString(),
      ],
    );
  }

  /// Parses either the field map or the canonical comma-joined string form.
  factory ProtoGoogleFieldMask.fromDynamic(Object? json) {
    if (json is String) {
      return ProtoGoogleFieldMask(
        paths: json.isEmpty ? const [] : json.split(','),
      );
    }
    return ProtoGoogleFieldMask.fromJson(
      (json as Map).cast<String, dynamic>(),
    );
  }

  factory ProtoGoogleFieldMask.deserialize(List<int> bytes) {
    final decode = ProtoBufferDecoder.decode(
      bytes: bytes,
      messageConfig: protoConfigStatic(),
    );
    return ProtoGoogleFieldMask(
      paths: decode.getListOrEmpty<String>(1),
    );
  }
}
