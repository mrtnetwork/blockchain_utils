import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

/// Samples from a Gamma(shape, scale) distribution via Marsaglia and
/// Tsang's method (shape >= 1) or Johnk's algorithm (shape < 1).
class GammaDistribution {
  /// Shape parameter (alpha / k).
  final double shape;

  /// Scale parameter (beta / theta).
  final double scale;

  /// A uniform random index in `[0, upperLimit)`.
  int randomIndex(int upperLimit) {
    return QuickCrypto.prng.nextInt(upperLimit);
  }

  const GammaDistribution(this.shape, this.scale);

  /// Draws the next sample from this distribution.
  double nextDouble() {
    if (shape < 1) {
      // Use Johnk's algorithm if shape < 1
      return _gammaLessThanOne();
    } else {
      // Use Marsaglia and Tsang's method for shape >= 1
      return _gammaGreaterThanEqualOne();
    }
  }

  /// Johnk's algorithm, for `shape < 1`.
  double _gammaLessThanOne() {
    final d = shape + (1.0 / 3.0) - 1;
    final c = 1 / IntUtils.sqrt(9 * d);
    while (true) {
      final x = _nextGaussian();
      final v = IntUtils.pow((1 + c * x), 3);
      final u = QuickCrypto.prng.nextDouble();
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

      // BUG FIX: this used to draw `u` from _nextGaussian(), but the
      // Marsaglia-Tsang acceptance test needs a *uniform* (0,1) variate
      // here (as the sibling _gammaLessThanOne() correctly does) — a
      // Gaussian can be negative or exceed 1, which is invalid for this
      // test and can even feed a negative value into IntUtils.log below.
      final u = QuickCrypto.prng.nextDouble();
      if (u < 1 - 0.0331 * IntUtils.pow(x, 4)) return scale * d * v;
      if (IntUtils.log(u) <
          0.5 * IntUtils.pow(x, 2) + d * (1 - v + IntUtils.log(v))) {
        return scale * d * v;
      }
    }
  }

  /// Box-Muller transform for generating a Gaussian (normal) random value
  double _nextGaussian() {
    final u1 = QuickCrypto.prng.nextDouble();
    final u2 = QuickCrypto.prng.nextDouble();
    return IntUtils.sqrt(-2 * IntUtils.log(u1)) *
        IntUtils.cos(2 * IntUtils.pi * u2);
  }
}
