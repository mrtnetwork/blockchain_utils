import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [ValidatedCurveApi] wrapper for a [RistrettoCurveApi] implementation.
class ValidatedRistrettoCurveApi extends ValidatedCurveApi
    implements RistrettoCurveApi {
  ValidatedRistrettoCurveApi(this._ed) : super(_ed, tag: 'Ristretto');
  final RistrettoCurveApi _ed;

  @override
  BuBytes pointFromEdwardBytes(List<int> edwards32) {
    validatePoint(edwards32, "pointFromEdwardBytes");
    return _ed.pointFromEdwardBytes(edwards32);
  }

  @override
  BuBytes scMulAdd(List<int> a, List<int> b, List<int> c) {
    validateScalar(a, "scMulAdd");
    validateScalar(b, "scMulAdd");
    validateScalar(c, "scMulAdd");
    return _ed.scMulAdd(a, b, c);
  }

  @override
  BuBytes scMulSub(List<int> a, List<int> b, List<int> c) {
    validateScalar(a, "scMulSub");
    validateScalar(b, "scMulSub");
    validateScalar(c, "scMulSub");
    return _ed.scMulSub(a, b, c);
  }

  @override
  BuBytes scReduce64(List<int> s) {
    ApiValidate.length(s, 64, operation: '$tag.scReduce64', name: 'scalar');
    return _ed.scReduce64(s);
  }

  @override
  BuBytes toEdwardBytes(List<int> ristretto32) {
    validatePoint(ristretto32, "toEdwardBytes");
    return _ed.toEdwardBytes(ristretto32);
  }
}
