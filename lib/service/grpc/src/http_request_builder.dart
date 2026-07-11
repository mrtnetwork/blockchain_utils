import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'grpc_rpc_option.dart';

/// The resolved request.
class HttpRequestSpec {
  final RequestMethod method;
  final String path;
  final Map<String, dynamic> queryParameters;

  /// JSON-encodable body, or null if this request has no body (typical for
  /// GET / DELETE bindings).
  final Map<String, dynamic>? jsonBody;

  HttpRequestSpec({
    required this.method,
    required this.path,
    required this.queryParameters,
    this.jsonBody,
  });

  @override
  String toString() =>
      '${method.methodName} $path'
      '${jsonBody != null ? '\nbody: $jsonBody' : ''}';

  Uri encode(String baseUrl) {
    final base = Uri.parse(baseUrl);
    return base.replace(path: path, queryParameters: queryParameters);
  }
}

/// Builds an [HttpRequestSpec] from a [HttpRule] (parsed from
/// `google.api.http`), a [baseUrl], and the request message represented as
/// a JSON-like `Map<String, dynamic>`.
///
/// Field-handling rules (mirroring the official google.api.http semantics):
///   1. Every field referenced by a `{field}` or `{field=pattern}` path
///      variable is removed from the "remaining" field set and substituted
///      into the URL, URL-encoded. Nested fields use dotted paths
///      (`{user.address.city}`) resolved against nested maps. Wildcard
///      patterns (`*`, `**`) only affect how many literal slashes the
///      substituted value is allowed to contain conceptually — for request
///      building we simply insert the value, optionally re-splitting on '/'
///      for `**` so existing slash-separated values aren't double-encoded.
///   2. If `body` is `"*"`, every field NOT used in the path becomes part of
///      the JSON body, and there are no query params.
///   3. If `body` is a specific field name, that single field's value (after
///      removing path fields from *it*, if it's a nested message — rare in
///      practice) becomes the JSON body, and all *other* remaining fields
///      become query parameters.
///   4. If `body` is null/absent (typical for GET/DELETE), there is no body;
///      every remaining field becomes a query parameter. Nested
///      message/map fields are flattened using dotted notation
///      (`filter.name=foo`) the same way google.api.http does for query
///      params; repeated fields produce repeated `key=value` pairs.
class HttpRequestBuilder {
  static HttpRequestSpec build({
    required HttpRule rule,
    required Map<String, dynamic> message,
  }) {
    // Work on a shallow copy of top-level keys we can remove from as we
    // consume fields for the path/body, without mutating the caller's map.
    final remaining = _deepCopy(message);

    final pathString = _buildPath(rule, remaining);

    Map<String, dynamic>? jsonBody;
    final query = <String, dynamic>{};
    bool hasBody = !rule.method.isGet;
    final String bodyField = rule.body ?? "*";
    if (hasBody && bodyField == "*") {
      jsonBody = remaining;
    } else if (hasBody) {
      final bodyFieldValue = remaining.remove(bodyField);
      if (bodyFieldValue is Map<String, dynamic>) {
        jsonBody = bodyFieldValue;
      } else if (bodyFieldValue != null) {
        // Non-message body field (unusual, but technically legal proto3
        // JSON if the field is itself a message type at the wire level;
        // for scalar/bad input we just wrap it).
        jsonBody = {bodyField: bodyFieldValue};
      }
      query.addAll(_flattenForQuery(remaining));
    } else {
      query.addAll(_flattenForQuery(remaining));
    }

    // final base = Uri.parse(baseUrl);
    final fullPath = _joinPaths(pathString);

    return HttpRequestSpec(
      method: rule.method,
      path: fullPath,
      jsonBody: jsonBody,
      queryParameters: query.isEmpty ? {} : _stringifyQuery(query),
    );
  }

  // ---- path building ----

  static String _buildPath(HttpRule rule, Map<String, dynamic> remaining) {
    final parts = <String>[];
    for (final seg in rule.segments) {
      if (!seg.isVariable) {
        parts.add(seg.literal);
        continue;
      }
      final fieldPath = seg.fieldPath!;
      final value = _extractAndRemove(remaining, fieldPath);
      if (value == null) {
        throw ArgumentException.invalidOperationArguments(
          "HttpRequestBuilder.build",
          reason:
              'Path template requires field "$fieldPath" but it was not found '
              'in the provided message (or was null).',
        );
      }
      final stringValue = _scalarToString(value);
      if (seg.isGreedy) {
        // `**` may itself contain literal '/' that should NOT be
        // re-encoded into %2F — split and re-join as separate path segments.
        parts.addAll(stringValue.split('/').map(Uri.encodeComponent));
      } else {
        parts.add(Uri.encodeComponent(stringValue));
      }
    }
    return parts.join('/');
  }

  /// Resolves a dotted field path like "user.address.city" against
  /// [message], REMOVING the top-level field from [message] once fully
  /// consumed (so it isn't later treated as a body/query field too).
  ///
  /// Note: per google.api.http semantics, once any part of a top-level
  /// field is bound to the path, the *entire* top-level field is excluded
  /// from body/query — not just the nested leaf. This matches the spec's
  /// behavior (path-bound fields are removed wholesale from the
  /// "remaining fields" set used for body/query).
  static dynamic _extractAndRemove(
    Map<String, dynamic> message,
    String dottedPath,
  ) {
    final parts = dottedPath.split('.');
    dynamic current = message[parts.first];
    for (var i = 1; i < parts.length; i++) {
      if (current is Map<String, dynamic>) {
        current = current[parts[i]];
      } else {
        current = null;
        break;
      }
    }
    // Remove the whole top-level field, regardless of nesting depth.
    message.remove(parts.first);
    return current;
  }

  // ---- query building ----

  /// Flattens a map of remaining fields into dotted-key query parameters,
  /// e.g. {"pagination": {"limit": 10}} -> {"pagination.limit": "10"}.
  /// Repeated (List) fields produce a List value so multiple `key=value`
  /// pairs are emitted by [_stringifyQuery]; null/empty values are dropped
  /// (proto3 default values are typically omitted from query strings).
  static Map<String, dynamic> _flattenForQuery(
    Map<String, dynamic> fields, [
    String prefix = '',
  ]) {
    final result = <String, dynamic>{};
    fields.forEach((key, value) {
      final qualifiedKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value == null) return;
      if (value is Map<String, dynamic>) {
        if (value.isEmpty) return;
        result.addAll(_flattenForQuery(value, qualifiedKey));
      } else if (value is List) {
        if (value.isEmpty) return;
        result[qualifiedKey] = value.map(_scalarToString).toList();
      } else {
        result[qualifiedKey] = _scalarToString(value);
      }
    });
    return result;
  }

  /// Converts the flattened query map into the
  /// `Map<String, dynamic /* String | Iterable<String> */>` shape that
  /// [Uri.replace]'s `queryParameters` expects.
  static Map<String, dynamic> _stringifyQuery(Map<String, dynamic> flattened) {
    final out = <String, dynamic>{};
    flattened.forEach((k, v) {
      out[k] = v is List ? v.map((e) => e.toString()).toList() : v.toString();
    });
    return out;
  }

  // ---- helpers ----

  static String _scalarToString(dynamic value) {
    if (value is bool) return value ? 'true' : 'false';
    if (value is double) {
      // Avoid "10.0" for whole-number doubles where it reads oddly; harmless
      // either way for query/path strings, but cleaner output.
      if (value == value.roundToDouble()) return value.toInt().toString();
      return value.toString();
    }
    return value.toString();
  }

  static Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    final copy = <String, dynamic>{};
    source.forEach((key, value) {
      copy[key] = _deepCopyValue(value);
    });
    return copy;
  }

  static dynamic _deepCopyValue(dynamic value) {
    if (value is Map<String, dynamic>) return _deepCopy(value);
    if (value is List) return value.map(_deepCopyValue).toList();
    return value;
  }

  static String _joinPaths(String resolvedTemplatePath) {
    return resolvedTemplatePath.startsWith('/')
        ? resolvedTemplatePath
        : '/$resolvedTemplatePath';
  }
}
