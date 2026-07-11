import 'package:blockchain_utils/blockchain_utils.dart';

class ProtoUtils {
  /// Converts a protobuf Duration to its JSON representation.
  ///
  /// Examples:
  ///   seconds=3, nanos=0         -> "3s"
  ///   seconds=3, nanos=1         -> "3.000000001s"
  ///   seconds=3, nanos=1000      -> "3.000001s"
  ///   seconds=-3, nanos=-500000000 -> "-3.5s"
  static String googleDurationToJson(
    BigInt seconds,
    int nanos, {
    bool asNanos = false,
  }) {
    if (asNanos) {
      final billion = BigInt.from(1000000000);
      final totalNanos = seconds * billion + BigInt.from(nanos);
      return totalNanos.toString();
    }
    if (nanos == 0) {
      return '${seconds}s';
    }

    final fraction = nanos.abs().toString().padLeft(9, '0');
    final trimmed = fraction.replaceFirst(RegExp(r'0+$'), '');

    return '$seconds.$trimmed'
        's';
  }

  static ({BigInt seconds, int nanos}) googleDurationFromJson(String value) {
    final totalNanos = BigInt.tryParse(value);
    if (totalNanos != null) {
      final billion = BigInt.from(1000000000);
      return (
        seconds: totalNanos ~/ billion,
        nanos: (totalNanos % billion).toInt(),
      );
    }

    final match = RegExp(r'^(-)?(\d+)(?:\.(\d{1,9}))?s$').firstMatch(value);
    final negative = match?.group(1) != null;
    final seconds = BigInt.tryParse(match?.group(2) ?? "");
    if (match == null || seconds == null) {
      throw ArgumentException.invalidOperationArguments(
        "googleDurationFromJson",
        reason: "Invalid protobuf duration: $value",
      );
    }

    var nanos = 0;
    if (match.group(3) != null) {
      nanos = int.parse(match.group(3)!.padRight(9, '0'));
    }
    return (
      seconds: negative ? -seconds : seconds,
      nanos: negative ? -nanos : nanos,
    );
  }

  static ({int seconds, int nanos}) timestampFromRfc3339(String input) {
    final re = RegExp(
      r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(?:\.(\d{1,9}))?(Z|[+-]\d{2}:\d{2})$',
    );

    final match = re.firstMatch(input);
    if (match == null) {
      throw ArgumentException.invalidOperationArguments(
        "timestampFromRfc3339",
        reason: 'Invalid RFC3339 timestamp',
      );
    }

    final fraction = match.group(2);

    int nanos = 0;
    if (fraction != null) {
      nanos = int.parse(fraction.padRight(9, '0'));
    }

    // Parse without the fractional part to preserve nanoseconds.
    final dt = DateTime.parse('${match.group(1)}${match.group(3)}').toUtc();

    return (seconds: dt.millisecondsSinceEpoch ~/ 1000, nanos: nanos);
  }

  static String timestampToRfc3339(int seconds, int nanos) {
    if (nanos < 0 || nanos > 999999999) {
      throw ArgumentException.invalidOperationArguments(
        "timestampToRfc3339",
        reason: 'nanos must be between 0 and 999999999',
      );
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    String two(int n) => n.toString().padLeft(2, '0');
    String four(int n) => n.toString().padLeft(4, '0');
    final buffer =
        StringBuffer()
          ..write(four(dt.year))
          ..write('-')
          ..write(two(dt.month))
          ..write('-')
          ..write(two(dt.day))
          ..write('T')
          ..write(two(dt.hour))
          ..write(':')
          ..write(two(dt.minute))
          ..write(':')
          ..write(two(dt.second));

    if (nanos != 0) {
      var frac = nanos.toString().padLeft(9, '0');

      // RFC3339 / protobuf JSON:
      // remove trailing zeros
      frac = frac.replaceFirst(RegExp(r'0+$'), '');

      buffer
        ..write('.')
        ..write(frac);
    }

    buffer.write('Z');

    return buffer.toString();
  }
}
