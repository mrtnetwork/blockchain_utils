import 'exception.dart';

/// An exception class representing errors that occur during RPC (Remote Procedure Call) communication.
class RPCError extends BlockchainUtilsException {
  /// Creates an instance of [RPCError].
  ///
  /// The [errorCode] parameter represents the error code associated with the RPC error.
  /// The [message] parameter provides a human-readable description of the error.
  /// The optional [request] parameter holds the details of the RPC request that resulted in the error.
  const RPCError(
      {required String message,
      this.errorCode,
      this.request,
      Map<String, dynamic>? details})
      : super(message, details: details);

  /// The error code associated with the RPC error.
  final int? errorCode;

  /// Details of the RPC request that resulted in the error.
  final Map<String, dynamic>? request;

  int? get statusCode => request?["statusCode"];

  @override
  String toString() {
    final infos = Map<String, dynamic>.fromEntries(
        details?.entries.where((element) => element.value != null) ?? []);
    if (infos.isEmpty) {
      if (errorCode == null) {
        return 'RPCError: $message';
      }
      return 'RPCError: got code $errorCode with message "$message".';
    }
    final String msg =
        "$message ${infos.entries.map((e) => "${e.key}: ${e.value}").join(", ")}";
    if (errorCode == null) {
      return 'RPCError: $msg';
    }
    return 'RPCError: got code $errorCode with message "$msg".';
  }
}
