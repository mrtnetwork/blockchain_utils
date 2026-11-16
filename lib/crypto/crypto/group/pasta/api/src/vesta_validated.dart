import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [ValidatedCurveApi] wrapper for a [VestaCurveApi] implementation.
class ValidatedVestaCurveApi extends ValidatedCurveApi
    implements VestaCurveApi {
  ValidatedVestaCurveApi(this._v) : super(_v, tag: 'Vesta');
  final VestaCurveApi _v;

  @override
  BuBytes scReduce64(List<int> s) {
    return call('scReduce64', () => _v.scReduce64(s));
  }

  @override
  BuBytes hashToCurve(List<int> msg, {List<int>? dst}) {
    return call('hashToCurve', () => _v.hashToCurve(msg, dst: dst));
  }
}
