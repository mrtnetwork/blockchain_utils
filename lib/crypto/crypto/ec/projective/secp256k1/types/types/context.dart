import 'fe.dart';
import 'ge.dart';
import 'scalar.dart';

class Secp256k1ECmultGenContext {
  final Secp256k1Scalar scalarOffset = Secp256k1Scalar();
  final Secp256k1Ge geOffset = Secp256k1Ge();
  final Secp256k1Fe projBlind = Secp256k1Fe();

  void clean() {
    scalarOffset.fillZero();
    geOffset.fillWithInfinity();
    geOffset.setInfinity(0);
    projBlind.fillZero();
  }

  void fillBlindFe(BaseSecp256k1Fe fe) {
    projBlind.fill(fe);
  }
}
