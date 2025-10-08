import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// A utility class providing helper methods for handling HTTP responses,
/// building JSON-RPC requests, and parsing responses in a service-oriented architecture.
class ServiceProviderUtils {
  /// Finds an error message from the response based on the status code and object type.
  ///
  /// If the status code is `401` or `403` and the object is a list of bytes or a string,
  /// it attempts to decode the error message.
  /// Returns: A decoded error message if applicable, otherwise `null`.
  static String? findError(
      {Object? object, required int statusCode, List<int>? allowStatusCode}) {
    String? error;
    if (object is List<int>) {
      error = StringUtils.tryDecode(object);
    } else if (object is String) {
      error = object;
    }
    if (allowStatusCode != null && allowStatusCode.contains(statusCode)) {
      return error;
    } else if (statusCode == 401 || statusCode == 403) {
      return error;
    }
    return null;
  }

  /// Extracts detailed error information from the response.
  ///
  /// Similar to [findError], but includes additional details such as JSON parsing.
  ///
  /// Returns: A map containing the status code and an error message (if any).
  static Map<String, dynamic> findErrorDetails(
      {Object? object, required int statusCode, List<int>? errorStatusCodes}) {
    String? error;
    if ((errorStatusCodes != null && errorStatusCodes.contains(statusCode)) &&
            statusCode == 401 ||
        statusCode == 403) {
      if (object is List<int>) {
        error = StringUtils.tryDecode(object);
      } else if (object is String) {
        error = object;
      } else if (object is Map) {
        error = StringUtils.tryFromJson(object);
      }
    }
    return {"statusCode": statusCode, if (error != null) "error": error};
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
      "id": requestId
    };
  }

  /// Checks if the given HTTP status code indicates a successful response.
  ///
  /// - [statusCode]: The HTTP status code to check.
  ///
  /// Returns: `true` if the status code is in the range 200–299, otherwise `false`.
  static bool isSuccessStatusCode(int statusCode,
      {List<int>? allowSuccessStatusCodes}) {
    if (allowSuccessStatusCodes != null) {
      return allowSuccessStatusCodes.contains(statusCode);
    }
    return statusCode >= 200 && statusCode < 300;
  }

  /// Converts a list of bytes into a result of type `T`.
  ///
  /// Handles various types of conversions, including JSON decoding,
  /// byte lists, and casting to other types.
  ///
  /// - [bytes]: The response body as a list of bytes.
  ///
  /// Returns: The parsed response as an object of type `T`.
  static T toResult<T extends Object?>(List<int> bytes) {
    if (bytes.isEmpty && null is T) {
      return null as T;
    }
    if (dynamic is T) {
      return StringUtils.toJson<T>(StringUtils.decode(bytes));
    }
    if (<dynamic>[] is T) {
      return StringUtils.toJson<T>(StringUtils.decode(bytes));
    }
    if (<int>[] is T) {
      return bytes as T;
    }
    final resultString = StringUtils.decode(bytes);
    if (<String>[] is T) {
      return StringUtils.toJson<List>(resultString).cast<String>() as T;
    }
    if (<bool>[] is T) {
      return StringUtils.toJson<List>(resultString).cast<bool>() as T;
    }
    if (0 is T) {
      return IntUtils.parse(resultString) as T;
    }
    if (BigInt.zero is T) {
      return BigintUtils.parse(resultString) as T;
    }
    if (<String, dynamic>{} is T) {
      return StringUtils.toJson(resultString);
    }
    if (<Map<String, dynamic>>[] is T) {
      return StringUtils.toJson<List>(resultString)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList() as T;
    }
    return resultString as T;
  }

  /// Parses a response object into a result of type `T`.
  ///
  /// Handles various input types, including strings, maps, lists, and bytes,
  /// performing necessary conversions or JSON decoding.
  ///
  /// Throws: [RPCError] if parsing fails.
  ///
  /// Returns: The parsed response as an object of type `T`.
  static T parseResponse<T>(
      {required Object? object, required BaseServiceRequestParams params}) {
    try {
      if (object is T) return object;
      if (object == null && null is T) {
        return null as T;
      }
      if (dynamic is T) {
        return object as T;
      }
      if (<String, dynamic>{} is T) {
        if (object is Map) return object.cast<String, dynamic>() as T;
        if (object is String) {
          return StringUtils.toJson<Map<String, dynamic>>(object) as T;
        }
      }
      if (<Map<String, dynamic>>[] is T) {
        if (object is String) {
          return StringUtils.toJson<List>(object)
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList() as T;
        }
        return (object as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList() as T;
      }
      if (<int>[] is T) {
        if (object is List<int>) {
          return StringUtils.encode(object as String) as T;
        }
        return (Object as List).cast<int>() as T;
      }
      return object as T;
    } catch (e) {
      throw RPCError(
          message: "Parsing response failed.",
          request: params.toJson(),
          details: {"error": e.toString(), "excepted": "$T"});
    }
  }
}
