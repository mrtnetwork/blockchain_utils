import 'package:blockchain_utils/encoding/proto/codec/decoder.dart';
import 'package:blockchain_utils/encoding/proto/types/types.dart';

/// `google.protobuf.Empty` runtime. Canonical JSON mapping is `{}`.
class ProtoGoogleEmpty extends IProtoMessage {
  const ProtoGoogleEmpty();

  @override
  ProtoMessageConfig protoConfig() => protoConfigStatic();

  static ProtoMessageConfig protoConfigStatic() {
    return const ProtoMessageConfig(
      syntax: ProtoSyntax.v3,
      options: [],
      fields: [],
    );
  }

  @override
  List<Object?> get protoValues => const [];

  @override
  Map<String, dynamic> toJson({
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return {};
  }

  factory ProtoGoogleEmpty.fromJson(
    Map<String, dynamic> json, {
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return const ProtoGoogleEmpty();
  }

  factory ProtoGoogleEmpty.deserialize(List<int> bytes) {
    ProtoBufferDecoder.decode(
      bytes: bytes,
      messageConfig: protoConfigStatic(),
    );
    return const ProtoGoogleEmpty();
  }
}
