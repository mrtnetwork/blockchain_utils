import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';

/// Bn254G1 with validation.
class ValidatedBn254G1CurveApi extends ValidatedCurveApi
    implements Bn254G1CurveApi {
  ValidatedBn254G1CurveApi(Bn254G1CurveApi super.inner) : super(tag: 'Bn254G1');
}

/// Bn254G2 with validation.
class ValidatedBn254G2CurveApi extends ValidatedCurveApi
    implements Bn254G2CurveApi {
  ValidatedBn254G2CurveApi(Bn254G2CurveApi super.inner) : super(tag: 'Bn254G2');
}
