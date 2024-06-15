import 'package:blockchain_utils/exception/exceptions.dart';

class LayoutException implements BlockchainUtilsException {
  LayoutException(this.message, {this.trace, Map<String, dynamic>? details})
      : details = details == null
            ? null
            : Map.unmodifiable(
                details..removeWhere((key, value) => value == null));
  @override
  final String message;
  final StackTrace? trace;
  @override
  final Map<String, dynamic>? details;

  @override
  String toString() {
    final detaillsValues =
        details?.keys.map((e) => "$e: ${details![e]}").join(", ") ?? "";
    return "LayoutException: $message${detaillsValues.isEmpty ? '' : ' $detaillsValues'}";
  }
}
