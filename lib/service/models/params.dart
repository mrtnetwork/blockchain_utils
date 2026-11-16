import 'dart:async';

import 'package:blockchain_utils/encoding/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/chain/types/network.dart';
import 'package:blockchain_utils/serialization/identifier.dart';
import 'package:blockchain_utils/service/utils/utils.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Supported HTTP verbs as they appear inside `option (google.api.http) = { ... }`.
enum RequestMethod {
  post(0, "POST"),
  get(1, "GET"),
  put(2, "PUT"),
  patch(3, "PATCH"),
  delete(4, "DELETE"),
  custom(5, "CUSTOM");

  final int value;
  final String methodName;
  const RequestMethod(this.value, this.methodName);
  bool get isGet => this == get;
  bool get isPost => this == post;
  static RequestMethod fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse: () => RequestMethod.custom,
    );
  }

  static RequestMethod fromMethodName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse:
          () => throw BuError(DefaultErrorType.notFound, "No matching RequestMethod found for the given value. $name", details: {"name": "RequestMethod", "value": name?.toString()}),
    );
  }

  static RequestMethod fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse:
          () =>
              throw BuError(DefaultErrorType.notFound, "No matching RequestMethod found for the given value. $value", details: {"name": "RequestMethod", "value": value?.toString()}),
    );
  }
}

/// Enum representing the types of responses that a service can return.
enum ServiceResponseType {
  /// Indicates that the service response is an error.
  error(0),

  /// Indicates that the service response is successful.
  success(1);

  final int value;
  const ServiceResponseType(this.value);

  static ServiceResponseType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw BuError(DefaultErrorType.notFound, "No matching ServiceResponseType found for the given value. null"),
    );
  }
}

sealed class BaseServiceResponse {
  final int statusCode;
  final ServiceResponseType type;
  const BaseServiceResponse({required this.statusCode, required this.type});
  E cast<E extends BaseServiceResponse>() {
    if (this is! E) {
      throw BuError(DefaultErrorType.castFailed, "Failed to cast value", details: {"expected": "E", "value": runtimeType.toString()});
    }
    return this as E;
  }
}

abstract class BaseServiceSuccessRespose extends BaseServiceResponse {
  const BaseServiceSuccessRespose({super.statusCode = 200})
    : super(type: ServiceResponseType.success);
  T toEncodingResponse<T>(
    ServiceReponseEncoding encoding, {
    CbEncodingErr<T>? onErr,
  });

  Map<String, dynamic>? tryToJson() {
    try {
      return toEncodingResponse<Map<String, dynamic>>(
        ServiceReponseEncoding.map,
      );
    } catch (e) {
      return null;
    }
  }
}

typedef CbEncodingErr<T> =
    T? Function(Object? response, ServiceReponseEncoding encoding);

class ServiceSuccessRespose extends BaseServiceSuccessRespose {
  final Object? response;
  final ServiceReponseEncoding? encoding;
  const ServiceSuccessRespose({
    super.statusCode = 200,
    required this.response,
    this.encoding,
  });

  @override
  T toEncodingResponse<T>(
    ServiceReponseEncoding encoding, {
    CbEncodingErr<T>? onErr,
  }) {
    try {
      if (encoding == this.encoding) {
        return JsonParser.valueAs<T>(response);
      }
      final encode = ServiceProviderUtils.ecodeResponse(
        body: response,
        encoding: encoding,
      );
      return JsonParser.valueAs<T>(encode);
    } catch (_) {
      if (onErr != null) {
        final response = onErr(this.response, encoding);
        if (response != null) return response;
      }

      rethrow;
    }
  }
}

abstract class BaseServiceErrorResponse extends BaseServiceResponse {
  final bool validate;
  const BaseServiceErrorResponse({
    required super.statusCode,
    required this.validate,
  }) : super(type: ServiceResponseType.error);
  Object? getError();

  Map<String, dynamic>? tryToJson() {
    final error = getError();
    if (error == null) return null;
    try {
      return JsonParser.valueEnsureAsMap<String, dynamic>(
        ServiceProviderUtils.ecodeResponse(
          body: error,
          encoding: ServiceReponseEncoding.map,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  String? tryAsString() {
    final error = getError();
    if (error == null) return null;
    try {
      return JsonParser.valueAsString<String>(
        ServiceProviderUtils.ecodeResponse(
          body: error,
          encoding: ServiceReponseEncoding.string,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  String? tryFindErrorMessage();
  String findErrorMessage();
  int? tryFineErrorCode();
  RPCError defaultError();
}

class ServiceErrorResponse extends BaseServiceErrorResponse {
  final String? error;
  final Map<String, dynamic>? jsonError;

  const ServiceErrorResponse({
    required super.statusCode,
    required this.error,
    required super.validate,
    required this.jsonError,
  }) : super();

  @override
  Object? getError() {
    return error;
  }

  @override
  String? tryAsString() {
    return error;
  }

  @override
  Map<String, dynamic>? tryToJson() {
    return jsonError;
  }

  String? _findError(Object? v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) {
      final error = v["error"];
      final message = v["message"];
      if (error is String) return error;
      if (message is String) return message;
    }
    return null;
  }

  int? _findErrorCode(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is Map) {
      final error = v["code"];
      if (error is int) return error;
    }
    return null;
  }

  @override
  int? tryFineErrorCode() {
    final jsonError = this.jsonError;
    if (jsonError != null) {
      return _findErrorCode(jsonError) ?? _findErrorCode(jsonError["message"]);
    }
    return null;
  }

  @override
  String? tryFindErrorMessage() {
    final jsonError = this.jsonError;
    if (jsonError != null) {
      return _findError(jsonError["error"]) ?? _findError(jsonError["message"]);
    }
    return tryAsString();
  }

  @override
  String findErrorMessage() {
    final error = tryFindErrorMessage();
    if (error != null) return error;

    return ServiceProviderUtils.getDefaultError(statusCode);
  }

  @override
  RPCError defaultError({BaseServiceRequestParams? request}) {
    return RPCError(
      message: findErrorMessage(),
      errorCode: tryFineErrorCode(),
      request: request?.toJson(),
      jsonRpcErrpr: jsonError,
      relatedNetwork: request?.network,
      statusCode: statusCode,
    );
  }
}

enum ServiceReponseEncoding {
  binary(0),
  map(1),
  string(2),
  listOfMap(3),
  json(4);

  static ServiceReponseEncoding fromType<T>() {
    if (JsonParser.isDynamic<T>()) return ServiceReponseEncoding.json;
    if (JsonParser.isString<T>()) return ServiceReponseEncoding.string;
    if (JsonParser.isMap<T>() || JsonParser.isList<T>()) {
      return ServiceReponseEncoding.json;
    }
    if (JsonParser.isMapStringDynamic<T>()) return ServiceReponseEncoding.map;
    if (JsonParser.isListOfMapStringDynamic<T>()) {
      return ServiceReponseEncoding.listOfMap;
    }
    return ServiceReponseEncoding.json;
  }

  final int value;
  const ServiceReponseEncoding(this.value);

  static ServiceReponseEncoding fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw BuError(DefaultErrorType.notFound, "No matching ServiceReponseEncoding found for the given value. null"),
    );
  }
}

abstract class IServiceRequestParams with CborTagSerializable {
  const IServiceRequestParams();

  /// Builds the final request URI.
  ///
  /// Implementations may append path segments, query parameters,
  /// or perform any other request-specific URL transformations.
  /// The returned URI is the exact endpoint to which the request
  /// should be sent.
  Uri encodeUrl(String url);
}

abstract class BaseServiceRequestParams extends IServiceRequestParams {
  final Map<String, String> headers;
  final RequestMethod requestMethod;
  final int requestID;
  final List<int>? successStatusCodes;
  final List<int>? errorStatusCodes;
  final ServiceReponseEncoding responseEncoding;
  final List<int>? bodyBytes;
  final String? bodyString;
  final String? path;
  final BlockchainNetwork? network;

  const BaseServiceRequestParams({
    required this.headers,
    required this.requestMethod,
    required this.requestID,
    required this.responseEncoding,
    required this.bodyBytes,
    required this.bodyString,
    this.path,
    this.successStatusCodes,
    this.errorStatusCodes,
    this.network,
  });

  Map<String, dynamic> toJson();

  /// Encodes the request payload into bytes.
  ///
  /// For HTTP requests, the returned bytes are used as the request body.
  /// For socket-based protocols (e.g. WebSocket), the returned bytes
  /// represent the message payload to be sent through the connection.
  ///
  /// By default, this method returns [bodyBytes] if available; otherwise
  /// it encodes [bodyString] as UTF-8 bytes.
  List<int>? encodeBody({ServiceProtocol protocol = ServiceProtocol.http}) {
    final bytes = bodyBytes;
    if (bytes != null) return bytes;
    final str = bodyString;
    if (str != null) return StringUtils.toBytes(str);
    return null;
  }

  /// Decodes a raw service response into a [BaseServiceResponse].
  ///
  /// The [response] may be a string, byte array, map, or any other
  /// protocol-specific payload. The response is decoded according to
  /// the configured response encoding type.
  ///
  /// If [statusCode] indicates a failure (outside the 2xx range),
  /// a [ServiceErrorResponse] is returned.
  ///
  /// For socket-based protocols, ensure that a successful operation
  /// provides a status code in the range `200..299`.
  ///
  /// throw [RPCError] if decoding failed.
  BaseServiceResponse toResponse(Object? response, {int statusCode = 200}) {
    if (!ServiceProviderUtils.isSuccessStatusCode(
      statusCode,
      allowSuccessStatusCodes: successStatusCodes,
    )) {
      return ServiceProviderUtils.findError(
        statusCode: statusCode,
        allowStatusCode: errorStatusCodes,
        object: response,
      );
    }
    try {
      return ServiceSuccessRespose(
        statusCode: statusCode,
        response: ServiceProviderUtils.ecodeResponse(
          body: response,
          encoding: responseEncoding,
        ),
        encoding: responseEncoding,
      );
    } catch (e) {
      throw RPCError(
        message: "Unexpected service response.",
        request: toJson(),
        relatedNetwork: network,
        statusCode: statusCode,
        details: {"encoding": responseEncoding.name, "error": e.toString()},
      );
    }
  }

  RPCError _error(BaseServiceErrorResponse response) {
    return RPCError(
      message: response.findErrorMessage(),
      errorCode: null,
      request: toJson(),
      relatedNetwork: network,
      statusCode: response.statusCode,
    );
  }

  /// Converts a [BaseServiceResponse] into the specified encoding type.
  ///
  /// The target encoding can be provided via [encoding] or inferred
  /// from the [responseEncoding]. Common output types include bytes,
  /// strings, maps, and arrays.
  T toEncodingResponse<T>(
    BaseServiceResponse response, {
    ServiceReponseEncoding? encoding,
    CbEncodingErr<T>? onEncodingErr,
  }) {
    return switch (response) {
      BaseServiceErrorResponse() => throw _error(response),
      BaseServiceSuccessRespose() => () {
        try {
          return response.toEncodingResponse(
            encoding ?? responseEncoding,
            onErr: onEncodingErr,
          );
        } catch (e) {
          throw RPCError(
            message: "Parsing response failed.",
            request: toJson(),
            relatedNetwork: network,
            statusCode: response.statusCode,
            details: {
              "encoding": encoding?.name ?? responseEncoding.name,
              "response": response.runtimeType.toString(),
            },
          );
        }
      }(),
    };
  }

  /// Attempts to convert a successful response to the requested
  /// encoding type.
  ///
  /// Unlike [toEncodingResponse], this method returns `null` if the
  /// conversion fails instead of throwing an exception.
  ///
  /// If [response] represents an error response, the corresponding
  /// service exception is still thrown.
  T? tryEncodingResponse<T>(
    BaseServiceResponse response, {
    ServiceReponseEncoding? encoding,
  }) {
    return switch (response) {
      BaseServiceErrorResponse() => throw _error(response),
      BaseServiceSuccessRespose() => () {
        try {
          return response.toEncodingResponse(encoding ?? responseEncoding);
        } catch (_) {
          return null;
        }
      }(),
    };
  }
}

abstract class BaseSubscribtionEvent<IDENTIFIER> extends CborTagSerializable {
  IDENTIFIER get id;
}

/// Ad-hoc request params for custom service calls.
///
/// Unlike [BaseServiceRequestParams] (built for chain JSON-RPC providers
/// with response decoding, status codes and CBOR persistence), this is a
/// plain holder for one-off calls such as prover / JWT-issuer endpoints or
/// any custom per-chain call: a [Uri] endpoint, HTTP [headers], a
/// [RequestMethod] and an optional raw [BuBytes] body.
class CustomServiceParams with CborTagSerializable {
  final Map<String, String> headers;
  final RequestMethod requestMethod;
  final BuBytes? body;
  final Uri path;
  final ServiceReponseEncoding responseEncoding;
  CustomServiceParams({
    required this.path,
    required this.responseEncoding,
    this.headers = const {},
    this.requestMethod = RequestMethod.post,
    this.body,
  });

  factory CustomServiceParams.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.customServiceParams,
      cborBytes: bytes,
      cborObject: obj,
    );
    final body = values.rawValueAt<List<int>?>(2);
    return CustomServiceParams(
      headers: values
          .mapAt<CborStringValue, CborStringValue>(0)
          .map((k, v) => MapEntry(k.value, v.value)),
      requestMethod: RequestMethod.fromValue(values.rawValueAt(1)),
      body: body == null ? null : BuBytes.immutable(body),
      path: Uri.parse(values.rawValueAt<String>(3)),
      responseEncoding: ServiceReponseEncoding.fromValue(values.rawValueAt(4)),
    );
  }

  CustomServiceParams copyWith({
    Map<String, String>? headers,
    RequestMethod? requestMethod,
    BuBytes? body,
    Uri? path,
  }) {
    return CustomServiceParams(
      headers: headers ?? this.headers,
      requestMethod: requestMethod ?? this.requestMethod,
      body: body ?? this.body,
      path: path ?? this.path,
      responseEncoding: responseEncoding,
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.customServiceParams;

  @override
  List<CborObject?> get serializationItems => [
    CborMapValue.definite(
      headers.map((k, v) => MapEntry(CborStringValue(k), CborStringValue(v))),
    ),
    requestMethod.value.toCbor(),
    body?.toCborBytes(),
    path.toString().toCbor(),
    responseEncoding.value.toCbor(),
  ];
}

abstract class BaseServiceSubscribtionRequest<
  IDENTIFIER,
  SERVICERESPONSE,
  EVENT extends BaseSubscribtionEvent<IDENTIFIER>,
  PARAMS extends BaseServiceRequestParams
>
    extends BaseServiceRequest<IDENTIFIER, SERVICERESPONSE, PARAMS>
    with CborTagSerializable {
  EVENT? toEvent(IDENTIFIER identifier, Object event);

  IDENTIFIER? toIdentifier(BaseServiceResponse response);
  PARAMS buildUnsubscribeRequest(IDENTIFIER identifier, int requestID);

  EVENT deserializeEvent(List<int> bytes);
}

abstract class IServiceRequest<
  RESULT,
  SERVICERESPONSE,
  PARAMS extends IServiceRequestParams
> {
  FutureOr<PARAMS> buildRequest(int requestID);
  RESULT onResponse(SERVICERESPONSE result);
}

abstract class BaseServiceRequest<
  RESULT,
  SERVICERESPONSE,
  PARAMS extends BaseServiceRequestParams
>
    implements IServiceRequest<RESULT, SERVICERESPONSE, PARAMS> {
  const BaseServiceRequest();
  abstract final RequestMethod requestMethod;
  @override
  RESULT onResponse(SERVICERESPONSE result) {
    return JsonParser.valueAs<RESULT>(result);
  }
}

abstract class IGRPCServiceRequest<
  RESULT,
  PARAMS extends BaseGRPCServiceRequestParams
>
    implements IServiceRequest<RESULT, List<int>, PARAMS> {
  const IGRPCServiceRequest();
  @override
  RESULT onResponse(List<int> result);
}

enum ServiceProtocol {
  http("HTTP", 0),
  ssl("SSL", 1),
  tcp("TCP", 2),
  websocket("WebSocket", 3),
  grpc("Grpc", 4);

  const ServiceProtocol(this.value, this.id);
  final String value;
  final int id;

  bool get isHttp => this == http;
  bool get isSocket => this == ssl || this == tcp || this == websocket;
  bool get isGrpc => this == grpc;
  static ServiceProtocol fromValue(int? value) {
    return values.firstWhere(
      (e) => e.id == value,
      orElse: () => throw BuError(DefaultErrorType.notFound, "No matching item found for the given value. null"),
    );
  }

  @override
  String toString() {
    return value;
  }
}

abstract class IProvider<
  SERVICE extends IServiceProvider,
  PARAMS extends IServiceRequestParams
> {
  SERVICE get service;
  Future<RESULT> request<RESULT, SERVICERESPONSE>(
    IServiceRequest<RESULT, SERVICERESPONSE, PARAMS> request, {
    Duration? timeout,
  });

  Future<SERVICERESPONSE> requestDynamic<RESULT, SERVICERESPONSE>(
    IServiceRequest<RESULT, SERVICERESPONSE, PARAMS> request, {
    Duration? timeout,
  });
}

abstract class ISubscribtionProvider<
  SERVICE extends IServiceProvider,
  PARAMS extends BaseServiceRequestParams
>
    implements IProvider<SERVICE, PARAMS> {
  Future<BaseSubscribtionRequestResponse<IDENTIFIER, EVENT>>
  requestSubscribtion<
    IDENTIFIER,
    EVENT extends BaseSubscribtionEvent<IDENTIFIER>,
    SERVICERESPONSE
  >(
    BaseServiceSubscribtionRequest<IDENTIFIER, SERVICERESPONSE, EVENT, PARAMS>
    request, {
    Duration? timeout,
  });
}

abstract class IGrpcProvider<
  SERVICE extends IServiceProvider,
  PARAMS extends IServiceRequestParams,
  GRPCPARAMS extends BaseGRPCServiceRequestParams
>
    implements IProvider<SERVICE, PARAMS> {
  Stream<RESULT> requestStream<RESULT>(
    IGRPCServiceRequest<RESULT, GRPCPARAMS> request, {
    Duration? timeout,
  });
  Future<List<RESULT>> requestOnce<RESULT>(
    IGRPCServiceRequest<RESULT, GRPCPARAMS> request, {
    Duration? timeout,
  });
  Future<Stream<RESULT>> requestStreamAsync<RESULT>(
    IGRPCServiceRequest<RESULT, GRPCPARAMS> request, {
    Duration? timeout,
  });
  Future<List<RESULT>> requestOnceAsync<RESULT>(
    IGRPCServiceRequest<RESULT, GRPCPARAMS> request, {
    Duration? timeout,
  });
}

abstract class BaseSubscribtionRequestResponse<
  IDENTIFIER,
  EVENT extends CborTagSerializable
> {
  IDENTIFIER get identifier;
  Stream<EVENT> get stream;
}

class DefaultSubscribtionRequestResponse<
  IDENTIFIER,
  EVENT extends CborTagSerializable
>
    implements BaseSubscribtionRequestResponse<IDENTIFIER, EVENT> {
  @override
  final IDENTIFIER identifier;
  @override
  final Stream<EVENT> stream;
  const DefaultSubscribtionRequestResponse({
    required this.identifier,
    required this.stream,
  });
}

abstract class BaseServiceSubscribtionResponse {
  BaseServiceResponse get response;
  Stream<BaseSubscribtionEvent> get stream;
}

class DefaultServiceSubscribtionResponse
    implements BaseServiceSubscribtionResponse {
  @override
  final BaseServiceResponse response;
  @override
  final Stream<BaseSubscribtionEvent> stream;
  const DefaultServiceSubscribtionResponse({
    required this.response,
    required this.stream,
  });
}

abstract mixin class IServiceProvider<
  HTTPWEBSOCKETPARAMS extends BaseServiceRequestParams,
  GRPCPARAM extends BaseGRPCServiceRequestParams
> {
  Future<BaseServiceResponse> doRequest(
    HTTPWEBSOCKETPARAMS params, {
    Duration? timeout,
  });
  Future<BaseServiceSubscribtionResponse> doSubscribtionRequest({
    required HTTPWEBSOCKETPARAMS params,
    required BaseServiceSubscribtionRequest<
      dynamic,
      dynamic,
      BaseSubscribtionEvent,
      HTTPWEBSOCKETPARAMS
    >
    request,
    Duration? timeout,
  });

  Future<List<int>> doGrpcRequest(GRPCPARAM params, {Duration? timeout});
  Stream<List<int>> doGrpcRequestStream(GRPCPARAM params, {Duration? timeout});
  Future<Stream<List<int>>> doGrpcRequestStreamAsync(
    GRPCPARAM params, {
    Duration? timeout,
  });

  // Future<BaseServiceSuccessRespose> onCustomRequest(
  //   CustomServiceParams params, {
  //   Duration? timeout,
  // }) {
  //   throw UnimplementedError();
  // }
}

abstract class BaseGRPCServiceRequestParams extends IServiceRequestParams {
  const BaseGRPCServiceRequestParams();
  List<int> toBuffer();
  String method();
}
