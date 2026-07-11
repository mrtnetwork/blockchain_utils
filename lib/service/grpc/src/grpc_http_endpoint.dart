import 'grpc_rpc_option.dart';
import 'http_request_builder.dart';

export 'grpc_rpc_option.dart';
export 'http_request_builder.dart';

class GrpcHttpEndpoint {
  final HttpRule httpRule;
  GrpcHttpEndpoint({required this.httpRule});

  HttpRequestSpec buildRequest(Map<String, dynamic> message) {
    return HttpRequestBuilder.build(rule: httpRule, message: message);
  }
}
