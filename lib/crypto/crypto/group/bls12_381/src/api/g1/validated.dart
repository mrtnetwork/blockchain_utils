import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// G1 with validation.
class ValidatedG1ProjectiveCurveApi extends ValidatedCurveApi
    implements G1ProjectiveCurveApi {
  ValidatedG1ProjectiveCurveApi(G1ProjectiveCurveApi super.inner)
    : super(tag: 'G1');

  G1ProjectiveCurveApi get _api => inner as G1ProjectiveCurveApi;

  void _validateAnyPoint(List<int> p, String op) {
    if (p.length != pointLen && p.length != uncompressedLen) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'point',
        reason: 'expected $pointLen or $uncompressedLen bytes, got ${p.length}',
      );
    }
  }

  @override
  int get uncompressedLen => 96;

  @override
  BuBytes compress(List<int> point) {
    _validateAnyPoint(point, 'G1.compress');
    return call('compress', () => _api.compress(point));
  }

  @override
  BuBytes uncompress(List<int> point) {
    _validateAnyPoint(point, 'G1.uncompress');
    return call('uncompress', () => _api.uncompress(point));
  }
}
