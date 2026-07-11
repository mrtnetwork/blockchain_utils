/// A utility class that defines constants commonly used in HTTP services.
///
/// This class centralizes HTTP-related constants, including status codes,
/// default headers, error messages, and common HTTP error descriptions.
class ServiceConst {
  /// HTTP status code for "Success".
  static const int successStatucCode = 200;

  /// A default error message for unknown errors.
  static const String defaultError =
      'Unknown Error: An unexpected error occurred.';

  /// Default headers for HTTP POST requests, indicating JSON content.
  static const Map<String, String> defaultPostHeaders = {
    'Content-Type': 'application/json',
  };
}
