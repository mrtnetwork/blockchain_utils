import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [ValidatedCurveApi] wrapper for a [JubJubCurveApi] implementation.
class ValidatedJubJubCurveApi extends ValidatedCurveApi
    implements JubJubCurveApi {
  ValidatedJubJubCurveApi(this._j) : super(_j, tag: 'JubJub');
  final JubJubCurveApi _j;

  @override
  BuBytes scReduce64(List<int> s) {
    ApiValidate.length(s, 64, operation: 'JubJub.scReduce64', name: 'scalar');
    return call('scReduce64', () => _j.scReduce64(s));
  }

  @override
  BuBytes? clearCofactor(List<int> point) {
    ApiValidate.length(
      point,
      32,
      operation: 'JubJub.clearCofactor',
      name: 'point',
    );
    return call('clearCofactor', () => _j.clearCofactor(point));
  }
}
