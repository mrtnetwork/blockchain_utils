import 'package:blockchain_utils/blockchain_utils.dart';

/// One path segment of a `google.api.http` path template.
///
/// Templates look like:
///   /v1/{name}
///   /v1/{name=shelves/*}
///   /v1/{name=shelves/**}
///   /cosmos/tx/v1beta1/{tx_hash}
///   /cosmos/base/tendermint/v1beta1/blocks/{height}
///
/// A "variable" segment binds a (possibly nested, dotted) field path from the
/// request message, e.g. `{user.address.city}`, to a part of the URL path.
/// The optional `=pattern` after `=` constrains what it can match; for our
/// purposes the only thing that matters is whether the pattern contains `**`
/// (multi-segment / greedy wildcard) or `*` (single segment wildcard) — both
/// just mean "take the field's string value and put it here", the wildcard
/// only affects how *literal* templates would match incoming requests, not
/// how we *build* outgoing requests.
class PathSegment {
  final bool isVariable;
  final String literal;

  /// Dotted field path, e.g. `user.address.city`, only set if [isVariable].
  final String? fieldPath;

  /// Raw pattern after `=`, e.g. `shelves/*` or `**`. Null if there was none
  /// (bare `{field}`), meaning it behaves like a single-segment capture.
  final String? pattern;

  const PathSegment.literal(this.literal)
    : isVariable = false,
      fieldPath = null,
      pattern = null;

  const PathSegment.variable(this.fieldPath, {this.pattern})
    : isVariable = true,
      literal = '';

  bool get isGreedy => pattern != null && pattern!.contains('**');

  @override
  String toString() =>
      isVariable
          ? '{$fieldPath${pattern != null ? '=$pattern' : ''}}'
          : literal;
}

/// A fully parsed `google.api.http` rule: method + path template (+ optional
/// additional bindings, which are just more HttpRules).
class HttpRule {
  final RequestMethod method;

  /// Raw path template string, e.g. "/cosmos/tx/v1beta1/{tx_hash}".
  final String pathTemplate;

  /// Parsed segments of [pathTemplate], split on '/'.
  final List<PathSegment> segments;

  /// `body` option value: null (no body / GET-like), "*" (whole message is
  /// the body), or a field name (only that field is the body).
  final String? body;

  HttpRule({
    required this.method,
    required this.pathTemplate,
    required this.segments,
    this.body,
    List<HttpRule>? additionalBindings,
  });

  /// All field names referenced by path variables, flattened (top-level
  /// name only, e.g. "user" for "user.address.city") — used to know which
  /// top-level fields must NOT be treated as query params even when the
  /// nested value used in the path is a child of them.
  Set<String> get pathFieldTopLevelNames =>
      segments
          .where((s) => s.isVariable)
          .map((s) => s.fieldPath!.split('.').first)
          .toSet();

  /// All full dotted field paths used as path variables.
  Set<String> get pathFieldPaths =>
      segments.where((s) => s.isVariable).map((s) => s.fieldPath!).toSet();

  static HttpRule parse(String template, RequestMethod method, {String? body}) {
    return HttpRule(
      method: method,
      pathTemplate: template,
      segments: _parsePathTemplate(template),
      body: body,
    );
  }

  static List<PathSegment> _parsePathTemplate(String template) {
    final segments = <PathSegment>[];
    // Split on '/' but keep variable groups `{...}` intact even if they
    // (unusually) contained a literal '/' inside the pattern — they normally
    // don't for these proto files, but we guard for it anyway by scanning
    // char by char instead of a naive String.split('/').
    final buffer = StringBuffer();
    var depth = 0;
    final rawParts = <String>[];
    for (final ch in template.split('')) {
      if (ch == '{') depth++;
      if (ch == '}') depth--;
      if (ch == '/' && depth == 0) {
        rawParts.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    rawParts.add(buffer.toString());

    for (final part in rawParts) {
      if (part.isEmpty) continue;
      if (part.startsWith('{') && part.endsWith('}')) {
        final inner = part.substring(1, part.length - 1);
        final eqIdx = inner.indexOf('=');
        if (eqIdx == -1) {
          segments.add(PathSegment.variable(inner));
        } else {
          segments.add(
            PathSegment.variable(
              inner.substring(0, eqIdx),
              pattern: inner.substring(eqIdx + 1),
            ),
          );
        }
      } else {
        segments.add(PathSegment.literal(part));
      }
    }
    return segments;
  }

  @override
  String toString() =>
      '${method.methodName} $pathTemplate${body != null ? ' (body: $body)' : ''}';
}
