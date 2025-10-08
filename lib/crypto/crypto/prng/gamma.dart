import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

class GammaDistribution {
  final double shape; // alpha (k)
  final double scale; // beta (θ)
  int randomIndex(int upperLimit) {
    return QuickCrypto.prng.nextInt(upperLimit);
  }

  GammaDistribution(this.shape, this.scale);

  double nextDouble() {
    if (shape < 1) {
      // Use Johnk's algorithm if shape < 1
      return _gammaLessThanOne();
    } else {
      // Use Marsaglia and Tsang's method for shape >= 1
      return _gammaGreaterThanEqualOne();
    }
  }

  double _gammaLessThanOne() {
    final d = shape + (1.0 / 3.0) - 1;
    final c = 1 / IntUtils.sqrt(9 * d);
    while (true) {
      final x = _nextGaussian();
      final v = IntUtils.pow((1 + c * x), 3);
      final u = QuickCrypto.prng.nextDouble;
      if (u < 1 - 0.0331 * IntUtils.pow(x, 4)) return scale * d * v;
      if (IntUtils.log(u) <
          0.5 * IntUtils.pow(x, 2) + d * (1 - v + IntUtils.log(v))) {
        return scale * d * v;
      }
    }
  }

  double _gammaGreaterThanEqualOne() {
    final d = shape - 1 / 3;
    final c = 1 / IntUtils.sqrt(9 * d);
    while (true) {
      final x = _nextGaussian();
      final v = IntUtils.pow((1 + c * x), 3);
      final u = _nextGaussian();
      if (u < 1 - 0.0331 * IntUtils.pow(x, 4)) return scale * d * v;
      if (IntUtils.log(u) <
          0.5 * IntUtils.pow(x, 2) + d * (1 - v + IntUtils.log(v))) {
        return scale * d * v;
      }
    }
  }

  /// Box-Muller transform for generating a Gaussian (normal) random value
  double _nextGaussian() {
    final u1 = QuickCrypto.prng.nextDouble;
    final u2 = QuickCrypto.prng.nextDouble;
    return IntUtils.sqrt(-2 * IntUtils.log(u1)) *
        IntUtils.cos(2 * IntUtils.pi * u2);
  }
}
