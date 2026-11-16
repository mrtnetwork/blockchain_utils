import 'package:blockchain_utils/service/grpc/src/grpc_rpc_option.dart';
import 'package:blockchain_utils/service/grpc/src/http_request_builder.dart';

export 'package:blockchain_utils/service/grpc/src/grpc_rpc_option.dart';
export 'package:blockchain_utils/service/grpc/src/http_request_builder.dart';

class GrpcHttpEndpoint {
  final HttpRule httpRule;
  GrpcHttpEndpoint({required this.httpRule});

  HttpRequestSpec buildRequest(Map<String, dynamic> message) {
    return HttpRequestBuilder.build(rule: httpRule, message: message);
  }
}
