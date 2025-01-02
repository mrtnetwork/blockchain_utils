/// A utility class that defines constants commonly used in HTTP services.
///
/// This class centralizes HTTP-related constants, including status codes,
/// default headers, error messages, and common HTTP error descriptions.
class ServiceConst {
  /// HTTP status code for "Not Found".
  static const int notFoundStatusCode = 404;

  /// HTTP status code for "Success".
  static const int successStatucCode = 200;

  /// A default error message for unknown errors.
  static const String defaultError =
      'Unknown Error: An unexpected error occurred.';

  /// Default headers for HTTP POST requests, indicating JSON content.
  static const Map<String, String> defaultPostHeaders = {
    'Content-Type': 'application/json'
  };

  /// A map of common HTTP status codes to their corresponding error messages.
  ///
  /// Provides detailed descriptions for various client and server-side errors,
  /// helping in debugging and user feedback.
  static const Map<int, String> httpErrorMessages = {
    400:
        "Bad Request: The server could not understand the request due to invalid syntax.",
    401: "Unauthorized: Authentication is required or has failed.",
    403: "Forbidden: You do not have permission to access this resource.",
    404: "Not Found: The requested resource could not be found.",
    405:
        "Method Not Allowed: The HTTP method used is not supported for this resource.",
    409:
        "Conflict: The request could not be processed due to a conflict with the current state of the resource.",
    422:
        "Unprocessable Entity: The request was well-formed but could not be processed.",
    500:
        "Internal Server Error: The server encountered an unexpected condition.",
    502:
        "Bad Gateway: The server received an invalid response from the upstream server.",
    503:
        "Service Unavailable: The server is temporarily unable to handle the request.",
    504:
        "Gateway Timeout: The server did not receive a timely response from the upstream server."
  };
}
