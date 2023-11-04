/// Extension on the DateTime class to format a DateTime object as an RFC3339 string
extension RFC3339 on DateTime {
  /// Convert the DateTime to an RFC3339 formatted string with time zone information.
  String toRFC3339WithTimeZone() {
    String year = this.year.toString().padLeft(4, '0');
    String month = this.month.toString().padLeft(2, '0');
    String day = this.day.toString().padLeft(2, '0');
    String hour = this.hour.toString().padLeft(2, '0');
    String minute = this.minute.toString().padLeft(2, '0');
    String second = this.second.toString().padLeft(2, '0');
    String millisecond = this
        .millisecond
        .toString()
        .padLeft(3, '0')
        .replaceAll(RegExp(r'0*$'), '');

    Duration timeZoneOffset = isUtc ? Duration.zero : this.timeZoneOffset;

    String timeZoneOffsetSign = timeZoneOffset.isNegative ? '-' : '+';
    int timeZoneOffsetHours = timeZoneOffset.inHours.abs();
    int timeZoneOffsetMinutes = timeZoneOffset.inMinutes.abs() % 60;

    String timeZoneOffsetFormatted = isUtc
        ? "Z"
        : '$timeZoneOffsetSign${timeZoneOffsetHours.toString().padLeft(2, '0')}:${timeZoneOffsetMinutes.toString().padLeft(2, '0')}';

    return '$year-$month-${day}T$hour:$minute:$second.$millisecond$timeZoneOffsetFormatted';
  }
}
