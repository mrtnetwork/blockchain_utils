import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/service/const/constant.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// A utility class providing helper methods for handling HTTP responses,
/// building JSON-RPC requests, and parsing responses in a service-oriented architecture.
class ServiceProviderUtils {
  /// Finds an error message from the response based on the status code and object type.
  ///
  /// If the status code is `401` or `403` and the object is a list of bytes or a string,
  /// it attempts to decode the error message.
  /// Returns: A decoded error message if applicable, otherwise `null`.
  static ServiceErrorResponse findError({
    Object? object,
    required int statusCode,
    List<int>? allowStatusCode,
  }) {
    bool isValidStatusCode() {
      return (allowStatusCode?.contains(statusCode) ?? false);
    }

    String? error = () {
      try {
        return JsonParser.valueAsString(
          ecodeResponse(body: object, encoding: ServiceReponseEncoding.string),
        );
      } catch (_) {
        return null;
      }
    }();
    final htmlReg = RegExp(
      r'<(html|head|body|title|h1|h2|h3|h4|h5|h6|p|div|span|a|form|table|img)[^>]*>',
      caseSensitive: false,
    );
    if (error != null && (htmlReg.hasMatch(error) || error.isEmpty)) {
      error = null;
    }

    return ServiceErrorResponse(
      statusCode: statusCode,
      error: error,
      validate: isValidStatusCode(),
      jsonError: error == null ? null : StringUtils.tryToJson(error),
    );
  }

  /// Builds a JSON-RPC request object.
  ///
  /// - [requestId]: The ID of the request.
  /// - [method]: The RPC method being called.
  /// - [params]: Optional parameters for the RPC call.
  ///
  /// Returns: A map representing the JSON-RPC request.
  static Map<String, dynamic> buildJsonRPCParams({
    required int requestId,
    required String method,
    Object? params,
  }) {
    return {
      "jsonrpc": "2.0",
      "method": method,
      "params": params,
      "id": requestId,
    };
  }

  /// Checks if the given HTTP status code indicates a successful response.
  ///
  /// - [statusCode]: The HTTP status code to check.
  ///
  /// Returns: `true` if the status code is in the range 200–299, otherwise `false`.
  static bool isSuccessStatusCode(
    int statusCode, {
    List<int>? allowSuccessStatusCodes,
  }) {
    if (allowSuccessStatusCodes != null) {
      return allowSuccessStatusCodes.contains(statusCode);
    }
    return statusCode >= 200 && statusCode < 300;
  }

  /// Parses a response object into a result of type `T`.
  ///
  /// Handles various input types, including strings, maps, lists, and bytes,
  /// performing necessary conversions or JSON decoding.
  ///
  /// Throws: [RPCError] if parsing fails.
  ///
  /// Returns: The parsed response as an object of type `T`.
  static T toResponse<T>({
    required Object? object,
    required BaseServiceRequestParams params,
  }) {
    try {
      return JsonParser.valueAs<T>(object);
    } catch (e) {
      throw RPCError(
        message: "Parsing response failed.",
        relatedNetwork: params.network,
        request: params.toJson(),
        details: {"error": e.toString(), "excepted": "$T"},
      );
    }
  }

  /// Parses a response bytes into a result of type `T`.
  static Object? encodeBytesResponse({
    required List<int> bytes,
    required ServiceReponseEncoding encoding,
  }) {
    switch (encoding) {
      case ServiceReponseEncoding.binary:
        return bytes;
      default:
        return ecodeStringResponse(
          body: StringUtils.decode(bytes),
          encoding: encoding,
        );
    }
  }

  /// Parses a response string into a result of type `T`.
  static Object? ecodeStringResponse({
    required String body,
    required ServiceReponseEncoding encoding,
  }) {
    switch (encoding) {
      case ServiceReponseEncoding.binary:
        return StringUtils.encode(body);
      case ServiceReponseEncoding.string:
        return body;
      case ServiceReponseEncoding.map:
        return StringUtils.toJson<Map<String, dynamic>>(body);
      case ServiceReponseEncoding.listOfMap:
        return StringUtils.toJson<List<Map<String, dynamic>>>(body);
      case ServiceReponseEncoding.json:
        return StringUtils.toJson(body);
    }
  }

  /// Parses a response string into a result of type `T`.
  static Object? ecodeResponse({
    required Object? body,
    required ServiceReponseEncoding encoding,
  }) {
    switch (body) {
      case List<int> bytes:
        return encodeBytesResponse(bytes: bytes, encoding: encoding);
      case String body:
        return ecodeStringResponse(body: body, encoding: encoding);
      default:
        switch (encoding) {
          case ServiceReponseEncoding.binary:
            return JsonParser.valueAsBytes<List<int>?>(body, allowJson: true);
          case ServiceReponseEncoding.string:
            return JsonParser.valueAsString<String?>(body, allowJson: true);
          case ServiceReponseEncoding.map:
            return JsonParser.valueAsMap<Map<String, dynamic>?>(body);
          case ServiceReponseEncoding.listOfMap:
            return JsonParser.valueAsList<List<Map<String, dynamic>>?>(body);
          case ServiceReponseEncoding.json:
            return body;
        }
    }
  }

  static String getDefaultError(int statusCode) {
    if (isSuccessStatusCode(statusCode)) {
      return ServiceConst.defaultError;
    }
    return "The request failed with status code $statusCode.";
  }
}
