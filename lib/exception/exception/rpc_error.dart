import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/networks/types/network.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'exception.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

/// An exception class representing errors that occur during RPC (Remote Procedure Call) communication.
class RPCError extends IException {
  @override
  final BlockchainNetwork? relatedNetwork;

  /// The error code associated with the RPC error.
  final int? errorCode;

  /// Details of the RPC request that resulted in the error.
  final Map<String, dynamic>? request;

  /// Details of the Json rpc error.
  final Map<String, dynamic>? jsonRpcErrpr;

  final int? statusCode;

  /// Creates an instance of [RPCError].
  ///
  /// The [errorCode] parameter represents the error code associated with the RPC error.
  /// The [message] parameter provides a human-readable description of the error.
  /// The optional [request] parameter holds the details of the RPC request that resulted in the error.
  const RPCError({
    required String message,
    this.relatedNetwork,
    this.errorCode,
    this.request,
    this.jsonRpcErrpr,
    Map<String, String?>? details,

    this.statusCode,
  }) : super(message, details: details);

  factory RPCError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.rpcError,
      cborBytes: bytes,
      cborObject: object,
    );
    return RPCError(
      message: values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
      errorCode: values.rawValueAt(2),
      request: values.maybeRawValueAt<Map<String, dynamic>, String>(
        3,
        (e) => StringUtils.toJson(e),
      ),
      jsonRpcErrpr: values.maybeRawValueAt<Map<String, dynamic>, String>(
        4,
        (e) => StringUtils.toJson(e),
      ),
      relatedNetwork: values.maybeRawValueAt<BlockchainNetwork, int>(
        5,
        (e) => BlockchainNetwork.fromIdentifier(e),
      ),
      statusCode: values.rawValueAt(6),
    );
  }

  @override
  String toString() {
    final infos = Map<String, dynamic>.fromEntries(
      details?.entries.where((element) => element.value != null) ?? [],
    );
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

  @override
  SerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.rpcError;

  @override
  List<CborObject?> get serializationItems => [
    ...super.serializationItems,
    errorCode?.toCbor(),
    switch (request) {
      null => CborNullValue(),
      Map<String, dynamic> request => StringUtils.fromJson(request).toCbor(),
    },
    switch (jsonRpcErrpr) {
      null => CborNullValue(),
      Map<String, dynamic> request => StringUtils.fromJson(request).toCbor(),
    },
    relatedNetwork?.identifier.id.toCbor(),
    statusCode?.toCbor(),
  ];
  @override
  List<dynamic> get variables => [
    message,
    details,
    errorCode,
    request,
    relatedNetwork,
  ];
}
