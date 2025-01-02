import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/service/const/constant.dart';
import 'package:blockchain_utils/service/utils/utils.dart';

/// Enum representing the types of HTTP requests supported by the service.
enum RequestServiceType {
  /// Represents an HTTP POST request.
  post,

  /// Represents an HTTP GET request.
  get;

  /// Checks if the current request type is a POST request.
  ///
  /// Returns `true` if the request type is `post`, otherwise `false`.
  bool get isPostRequest => this == post;
}

/// Enum representing the types of responses that a service can return.
enum ServiceResponseType {
  /// Indicates that the service response is an error.
  error,

  /// Indicates that the service response is successful.
  success
}

abstract class BaseServiceResponse<T> {
  final int statusCode;
  final ServiceResponseType type;
  const BaseServiceResponse({required this.statusCode, required this.type});
  E cast<E extends BaseServiceResponse>() {
    if (this is! E) {
      throw ArgumentException("BaseServiceResponse casting faild.",
          details: {"excepted": "$T", "type": type.name});
    }
    return this as E;
  }

  T getResult(BaseServiceRequestParams params) {
    return switch (type) {
      ServiceResponseType.error => throw RPCError(
          message: ServiceConst.httpErrorMessages[statusCode] ??
              "Unknown Error${statusCode == 200 ? '' : ' $statusCode'}: An unexpected error occurred.",
          errorCode: null,
          request: params.toJson(),
          details: ServiceProviderUtils.findErrorDetails(
              statusCode: statusCode,
              object: cast<ServiceErrorResponse>().error)),
      ServiceResponseType.success => cast<ServiceSuccessRespose<T>>().response
    };
  }
}

class ServiceSuccessRespose<T> extends BaseServiceResponse<T> {
  final T response;
  const ServiceSuccessRespose(
      {required super.statusCode, required this.response})
      : super(type: ServiceResponseType.success);
}

class ServiceErrorResponse<T> extends BaseServiceResponse<T> {
  final String? error;
  const ServiceErrorResponse({required super.statusCode, required this.error})
      : super(type: ServiceResponseType.error);
}

abstract class BaseServiceRequestParams {
  final Map<String, String> headers;
  final RequestServiceType type;
  final int requestID;
  const BaseServiceRequestParams(
      {required this.headers, required this.type, required this.requestID});
  Uri toUri(String uri);
  List<int>? body();
  Map<String, dynamic> toJson();
  BaseServiceResponse<T> toResponse<T>(Object? body, [int? statusCode]) {
    statusCode ??= 200;
    if (!ServiceProviderUtils.isSuccessStatusCode(statusCode)) {
      return ServiceErrorResponse(
          statusCode: statusCode,
          error: ServiceProviderUtils.findError(
              object: body, statusCode: statusCode));
    }
    try {
      T response;
      if (body is List<int>) {
        response = ServiceProviderUtils.toResult<T>(body);
      } else {
        response =
            ServiceProviderUtils.parseResponse<T>(object: body, params: this);
      }
      return ServiceSuccessRespose<T>(
          statusCode: statusCode, response: response);
    } catch (_) {}

    throw RPCError(
        message: "Parsing response failed.",
        request: toJson(),
        details: {"excepted": "$T"});
  }
}

abstract class BaseServiceRequest<RESULT, SERVICERESPONSE,
    PARAMS extends BaseServiceRequestParams> {
  const BaseServiceRequest();
  abstract final RequestServiceType requestType;
  RESULT onResonse(SERVICERESPONSE result) {
    return result as RESULT;
  }

  PARAMS buildRequest(int requestID);
}

abstract class BaseProvider<PARAMS extends BaseServiceRequestParams> {
  Future<SERVICERESPONSE> requestDynamic<RESULT, SERVICERESPONSE>(
      BaseServiceRequest<RESULT, SERVICERESPONSE, PARAMS> request,
      {Duration? timeout});

  Future<RESULT> request<RESULT, SERVICERESPONSE>(
      BaseServiceRequest<RESULT, SERVICERESPONSE, PARAMS> request,
      {Duration? timeout});
}

mixin BaseServiceProvider<PARAMS extends BaseServiceRequestParams> {
  Future<BaseServiceResponse<T>> doRequest<T>(PARAMS params,
      {Duration? timeout});
}
