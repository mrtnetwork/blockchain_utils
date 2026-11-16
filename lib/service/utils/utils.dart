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
      } catch (e) {
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

  /// Attempts JSON decode. Never throws — reports success/failure explicitly
  /// so callers don't have to infer "was this real JSON" from exceptions.
  static ({bool ok, Object? value}) _tryJsonDecode(String body) {
    try {
      return (ok: true, value: StringUtils.toJson(body));
    } catch (_) {
      return (ok: false, value: null);
    }
  }

  /// For `.string` encoding: guarantees a `String` comes out, always.
  /// - If [raw] is a JSON string literal (e.g. `"hi"` or `"\"nested\""`),
  ///   unwrap it to the plain Dart string.
  /// - Otherwise, or if decode produced a non-String (num/bool/map/list),
  ///   return [raw] untouched — never leak a non-string type here.
  static String _asStringResult(String raw) {
    final decoded = _tryJsonDecode(raw);
    if (decoded.ok && decoded.value is String) {
      return decoded.value as String;
    }
    return raw;
  }

  /// Parses a response bytes into a result of type `T`.
  static Object? _encodeBytesResponse({
    required List<int> bytes,
    required ServiceReponseEncoding encoding,
  }) {
    switch (encoding) {
      case ServiceReponseEncoding.binary:
        return bytes;
      case ServiceReponseEncoding.string:
        return _asStringResult(StringUtils.decode(bytes)); // same guarantee
      default:
        final decode = StringUtils.decodeJson(bytes);
        switch (encoding) {
          case ServiceReponseEncoding.map:
            return JsonParser.valueAsMap<Map<String, dynamic>?>(decode);
          case ServiceReponseEncoding.listOfMap:
            return JsonParser.valueAsList<List<Map<String, dynamic>>?>(decode);
          default:
            return decode;
        }
    }
  }

  /// Parses a response string into a result of type `T`.
  static Object? _ecodeStringResponse({
    required String body,
    required ServiceReponseEncoding encoding,
  }) {
    switch (encoding) {
      case ServiceReponseEncoding.binary:
        return StringUtils.encode(body);

      case ServiceReponseEncoding.string:
        return _asStringResult(body); // ALWAYS a String, never StringJson

      case ServiceReponseEncoding.json:
        final decoded = _tryJsonDecode(body);
        return decoded.ok ? decoded.value : body;

      case ServiceReponseEncoding.map:
        final decoded = _tryJsonDecode(body);
        return JsonParser.valueAsMap<Map<String, dynamic>?>(decoded.value);
      case ServiceReponseEncoding.listOfMap:
        final decoded = _tryJsonDecode(body);
        return JsonParser.valueAsList<List<Map<String, dynamic>>?>(
          decoded.value,
        );
    }
  }

  /// Parses a response string into a result of type `T`.
  static Object? ecodeResponse({
    required Object? body,
    required ServiceReponseEncoding encoding,
  }) {
    switch (body) {
      case List<int> bytes:
        return _encodeBytesResponse(bytes: bytes, encoding: encoding);
      case String body:
        return _ecodeStringResponse(body: body, encoding: encoding);
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

  static String joinPathWithRoot(List<String> parts, {String separator = '/'}) {
    if (parts.isEmpty) return '';

    final isAbsolute = RegExp(r'^[\\/]').hasMatch(parts.first);

    final normalized = parts
        .where((e) => e.trim().isNotEmpty)
        .map(
          (e) => e
              .replaceAll(RegExp(r'[\\/]'), separator)
              .replaceAll(
                RegExp(
                  '^${RegExp.escape(separator)}+|${RegExp.escape(separator)}+\$',
                ),
                '',
              ),
        )
        .join(separator);

    return isAbsolute ? '$separator$normalized' : normalized;
  }
}
