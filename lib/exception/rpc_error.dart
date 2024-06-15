import 'exception.dart';

/// An exception class representing errors that occur during RPC (Remote Procedure Call) communication.
class RPCError implements BlockchainUtilsException {
  /// Creates an instance of [RPCError].
  ///
  /// The [errorCode] parameter represents the error code associated with the RPC error.
  /// The [message] parameter provides a human-readable description of the error.
  /// The [data] parameter contains additional data associated with the error.
  /// The optional [request] parameter holds the details of the RPC request that resulted in the error.
  const RPCError(
      {required this.message,
      required this.errorCode,
      required this.data,
      required this.request,
      this.details});

  /// The error code associated with the RPC error.
  final int errorCode;

  /// A human-readable description of the RPC error.
  @override
  final String message;

  /// Additional data associated with the RPC error.
  final dynamic data;

  /// Details of the RPC request that resulted in the error.
  final Map<String, dynamic> request;

  @override
  final Map<String, dynamic>? details;

  /// Returns a string representation of the RPCError.
  ///
  /// The string includes the error code, error message, and the request details if available.
  @override
  String toString() {
    return 'RPCError: got code $errorCode with msg "$message". ${data ?? ''}';
  }
}
