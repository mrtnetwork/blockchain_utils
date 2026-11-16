import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/log.dart';

void main() {
  final e = List.generate(
    100,
    (i) => Ed25519Fr.fromBytesUnchecked(QuickCrypto.generateRandom()),
  );
  Logg.def(
    () => List.generate(100, (i) => EdwardsLimbPoint.generator_ * e[i]),
    'text',
  );
}
