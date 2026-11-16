// DKLs23 curve abstraction: secp256k1 (K1) and secp256r1 (R1).
//
// Both suites expose 33-byte compressed points and 32-byte big-endian
// scalars. Scalar math runs on the suites' Montgomery-limb fields
// ([Secp256k1Fr]/[Secp256r1Fr]); points are the matching
// [Secp256k1Point]/[Secp256r1Point] types.
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

enum DklsProtocolCurve { k1, r1 }

extension DklsProtocolCurveX on DklsProtocolCurve {
  int get id => this == DklsProtocolCurve.k1 ? 0 : 1;

  String get name => this == DklsProtocolCurve.k1 ? 'secp256k1' : 'secp256r1';

  static DklsProtocolCurve fromId(int id) {
    if (id == 0) return DklsProtocolCurve.k1;
    if (id == 1) return DklsProtocolCurve.r1;
    throw CoreErrors.invalidOperationArguments(
      'DklsUtils.fromId',
      name: 'curve',
      reason: 'unknown DKLs23 curve id $id.',
    );
  }
}
