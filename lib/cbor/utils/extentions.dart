/// Extension on the DateTime class to format a DateTime object as an RFC3339 string
extension RFC3339 on DateTime {
  /// Convert the DateTime to an RFC3339 formatted string with time zone information.
  String toRFC3339WithTimeZone() {
    final String year = this.year.toString().padLeft(4, '0');
    final String month = this.month.toString().padLeft(2, '0');
    final String day = this.day.toString().padLeft(2, '0');
    final String hour = this.hour.toString().padLeft(2, '0');
    final String minute = this.minute.toString().padLeft(2, '0');
    final String second = this.second.toString().padLeft(2, '0');
    final String millisecond = this
        .millisecond
        .toString()
        .padLeft(3, '0')
        .replaceAll(RegExp(r'0*$'), '');

    final Duration timeZoneOffset = isUtc ? Duration.zero : this.timeZoneOffset;

    final String timeZoneOffsetSign = timeZoneOffset.isNegative ? '-' : '+';
    final int timeZoneOffsetHours = timeZoneOffset.inHours.abs();
    final int timeZoneOffsetMinutes = timeZoneOffset.inMinutes.abs() % 60;

    final String timeZoneOffsetFormatted = isUtc
        ? "Z"
        : '$timeZoneOffsetSign${timeZoneOffsetHours.toString().padLeft(2, '0')}:${timeZoneOffsetMinutes.toString().padLeft(2, '0')}';

    return '$year-$month-${day}T$hour:$minute:$second.$millisecond$timeZoneOffsetFormatted';
  }
}
