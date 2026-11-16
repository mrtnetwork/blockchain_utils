import 'package:blockchain_utils/encoding/proto/codec/decoder.dart';
import 'package:blockchain_utils/encoding/proto/types/types.dart';
import 'package:blockchain_utils/encoding/proto/utils/utils.dart';
import 'package:blockchain_utils/utils/json/json.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// `google.protobuf.Timestamp` runtime (see also the generated `SuiTimestamp`
/// shape in sui-apis consumers).
///
/// Canonical JSON mapping is RFC 3339 (`1972-01-01T10:00:20.021Z`).
class ProtoGoogleTimestamp extends IProtoMessage {
  /// Seconds of UTC time since Unix epoch.
  final BigInt? seconds;

  /// Non-negative fractions of a second at nanosecond resolution.
  final int? nanos;

  const ProtoGoogleTimestamp({this.seconds, this.nanos});

  @override
  ProtoMessageConfig protoConfig() => protoConfigStatic();

  static ProtoMessageConfig protoConfigStatic() {
    return ProtoMessageConfig(
      syntax: ProtoSyntax.v3,
      options: const [],
      fields: [ProtoFieldConfig.int64(1), ProtoFieldConfig.int32(2)],
    );
  }

  @override
  List<Object?> get protoValues => [seconds, nanos];

  /// RFC 3339 string (`null` when seconds are missing).
  String? toRfc3339() {
    final s = seconds;
    if (s == null) return null;
    return ProtoUtils.timestampToRfc3339(s.toInt(), nanos ?? 0);
  }

  static ProtoGoogleTimestamp fromRfc3339(Object? value) {
    if (value == null) {
      throw BuError(DefaultErrorType.invalidArgument,"Cannot parse null RFC3339 timestamp.");
    }
    final parsed = ProtoUtils.timestampFromRfc3339(value as String);
    return ProtoGoogleTimestamp(
      seconds: BigInt.from(parsed.seconds),
      nanos: parsed.nanos,
    );
  }

  @override
  Map<String, dynamic> toJson({
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return {'seconds': seconds?.toString(), 'nanos': nanos};
  }

  /// Canonical JSON is the RFC 3339 string form.
  String? toJsonString() => toRfc3339();

  factory ProtoGoogleTimestamp.fromJson(
    Map<String, dynamic> json, {
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    final seconds = json['seconds'];
    return ProtoGoogleTimestamp(
      seconds:
          seconds == null ? null : BigInt.parse(seconds.toString()),
      nanos: JsonParser.valueAsInt<int?>(json['nanos']),
    );
  }

  /// Parses either the field map or the canonical RFC 3339 string form.
  factory ProtoGoogleTimestamp.fromDynamic(Object? json) {
    if (json is String) return ProtoGoogleTimestamp.fromRfc3339(json);
    return ProtoGoogleTimestamp.fromJson(
      (json as Map).cast<String, dynamic>(),
    );
  }

  factory ProtoGoogleTimestamp.deserialize(List<int> bytes) {
    final decode = ProtoBufferDecoder.decode(
      bytes: bytes,
      messageConfig: protoConfigStatic(),
    );
    return ProtoGoogleTimestamp(
      seconds: decode.getBigInt<BigInt?>(1),
      nanos: decode.getInt<int?>(2),
    );
  }
}
