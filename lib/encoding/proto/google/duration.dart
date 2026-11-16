import 'package:blockchain_utils/encoding/proto/codec/decoder.dart';
import 'package:blockchain_utils/encoding/proto/types/types.dart';
import 'package:blockchain_utils/utils/json/json.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// `google.protobuf.Duration` runtime.
///
/// Canonical JSON mapping is the `"3.000001s"` string form.
class ProtoGoogleDuration extends IProtoMessage {
  /// Signed seconds of the span of time.
  final BigInt? seconds;

  /// Signed fractions of a second at nanosecond resolution.
  final int? nanos;

  const ProtoGoogleDuration({this.seconds, this.nanos});

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

  /// Formats seconds/nanos the canonical `"3.000001s"` way.
  static String formatDuration(BigInt? seconds, int? nanos) {
    final s = seconds ?? BigInt.zero;
    final n = nanos ?? 0;
    if (n == 0) return '${s}s';
    final frac =
        n.abs().toString().padLeft(9, '0').replaceAll(RegExp(r'0+$'), '');
    final sign = (s.isNegative || n < 0) ? '-' : '';
    return '$sign${s.abs()}.$frac'
        's';
  }

  /// Parses the canonical `"3.000001s"` form into `(seconds, nanos)`.
  static ({BigInt seconds, int nanos}) parseDurationString(Object? value) {
    if (value == null) {
      throw BuError(DefaultErrorType.invalidArgument,"Cannot parse null duration string.");
    }
    var text = (value as String).trim();
    if (text.endsWith('s')) text = text.substring(0, text.length - 1);
    final negative = text.startsWith('-');
    if (negative) text = text.substring(1);
    final parts = text.split('.');
    final seconds = BigInt.parse(parts[0].isEmpty ? '0' : parts[0]);
    var nanos = 0;
    if (parts.length > 1) {
      nanos = int.parse(parts[1].padRight(9, '0').substring(0, 9));
    }
    return (
      seconds: negative ? -seconds : seconds,
      nanos: negative ? -nanos : nanos,
    );
  }

  /// Canonical `"3.000001s"` string form (`null` when empty).
  /// `asNanos` is accepted for generator compatibility and ignored.
  String? encodeString({bool asNanos = false}) {
    if (seconds == null && nanos == null) return null;
    return formatDuration(seconds, nanos);
  }

  static ProtoGoogleDuration fromString(Object? value) {
    final parsed = parseDurationString(value);
    return ProtoGoogleDuration(
      seconds: parsed.seconds,
      nanos: parsed.nanos,
    );
  }

  @override
  Map<String, dynamic> toJson({
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    return {'seconds': seconds?.toString(), 'nanos': nanos};
  }

  /// Canonical JSON is the `"3.000001s"` string form.
  String? toJsonString() => encodeString();

  factory ProtoGoogleDuration.fromJson(
    Map<String, dynamic> json, {
    ProtoJsonConfig config = DefaultProtoJsonConfig.defaultConfig,
  }) {
    final seconds = json['seconds'];
    return ProtoGoogleDuration(
      seconds:
          seconds == null ? null : BigInt.parse(seconds.toString()),
      nanos: JsonParser.valueAsInt<int?>(json['nanos']),
    );
  }

  /// Parses either the field map or the canonical `"3.000001s"` string form.
  factory ProtoGoogleDuration.fromDynamic(Object? json) {
    if (json is String) return ProtoGoogleDuration.fromString(json);
    return ProtoGoogleDuration.fromJson(
      (json as Map).cast<String, dynamic>(),
    );
  }

  factory ProtoGoogleDuration.deserialize(List<int> bytes) {
    final decode = ProtoBufferDecoder.decode(
      bytes: bytes,
      messageConfig: protoConfigStatic(),
    );
    return ProtoGoogleDuration(
      seconds: decode.getBigInt<BigInt?>(1),
      nanos: decode.getInt<int?>(2),
    );
  }
}
