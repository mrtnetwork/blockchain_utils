import 'package:blockchain_utils/crypto/crypto/group/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [ValidatedCurveApi] wrapper for a [Secp256k1CurveApi] implementation.
class ValidatedSecp256k1CurveApi extends ValidatedCurveApi
    implements Secp256k1CurveApi {
  ValidatedSecp256k1CurveApi(Secp256k1CurveApi super.inner)
    : super(tag: 'Secp256k1');

  Secp256k1CurveApi get _api => inner as Secp256k1CurveApi;

  void _validateAnyPoint(List<int> p, String op) {
    if (p.length != pointLen && p.length != uncompressedLen) {
      throw CoreErrors.invalidOperationArguments(
        op,
        name: 'point',
        reason:
            'expected $pointLen or $uncompressedLen bytes, got ${p.length}',
      );
    }
  }

  @override
  int get uncompressedLen => 65;

  @override
  BuBytes compress(List<int> point) {
    _validateAnyPoint(point, 'Secp256k1.compress');
    return call('compress', () => _api.compress(point));
  }

  @override
  BuBytes uncompress(List<int> point) {
    _validateAnyPoint(point, 'Secp256k1.uncompress');
    return call('uncompress', () => _api.uncompress(point));
  }
}
