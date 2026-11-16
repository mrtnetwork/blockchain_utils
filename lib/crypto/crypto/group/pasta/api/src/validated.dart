import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [ValidatedCurveApi] wrapper for a [PallasCurveApi] implementation.
class ValidatedPallasCurveApi extends ValidatedCurveApi
    implements PallasCurveApi {
  ValidatedPallasCurveApi(this._p) : super(_p, tag: 'Pallas');
  final PallasCurveApi _p;

  @override
  BuBytes scReduce64(List<int> s) {
    ApiValidate.length(s, 64, operation: 'Pallas.scReduce64', name: 'scalar');
    return call('scReduce64', () => _p.scReduce64(s));
  }

  @override
  BuBytes hashToCurve(List<int> msg, {List<int>? dst}) {
    return call('hashToCurve', () => _p.hashToCurve(msg, dst: dst));
  }

  @override
  BuBytes hashToCurvePasta({
    required String domainPrefix,
    required List<int> message,
  }) {
    return call(
      'hashToCurvePasta',
      () => _p.hashToCurvePasta(domainPrefix: domainPrefix, message: message),
    );
  }
}
