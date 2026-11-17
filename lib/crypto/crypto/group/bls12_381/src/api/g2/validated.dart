import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// G2 with validation.
class ValidatedG2ProjectiveCurveApi extends ValidatedCurveApi
    implements G2ProjectiveCurveApi {
  ValidatedG2ProjectiveCurveApi(G2ProjectiveCurveApi super.inner)
    : super(tag: 'G2');

  G2ProjectiveCurveApi get _api => inner as G2ProjectiveCurveApi;

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
  int get uncompressedLen => 192;

  @override
  BuBytes compress(List<int> point) {
    _validateAnyPoint(point, 'G2.compress');
    return call('compress', () => _api.compress(point));
  }

  @override
  BuBytes uncompress(List<int> point) {
    _validateAnyPoint(point, 'G2.uncompress');
    return call('uncompress', () => _api.uncompress(point));
  }
}
