import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'word_math_native.dart' as native;

const bool useNativeWordMath = bool.fromEnvironment(
  "BLOCKCHAIN_UTILS_NATIVE_MATH",
  defaultValue: true,
);
(Uint64 hi, Uint64 lo) widenMulImpl(Uint64 a, Uint64 b) {
  if (useNativeWordMath) return native.widenMulImpl(a, b);
  return Uint64.widenMulPortable(a, b);
}

({Uint64 quotient, Uint64 remainder}) divModImpl(Uint64 a, Uint64 b) {
  if (useNativeWordMath) return native.divModImpl(a, b);
  if (b.isZero) throw IntegerError.divisionByZero;
  if (a.compareTo(b) < 0) return (quotient: Uint64.zero, remainder: a);
  var quotient = Uint64.zero;
  var remainder = Uint64.zero;
  final startBit = a.hi != 0 ? 32 + a.hi.bitLength - 1 : a.lo.bitLength - 1;
  for (var i = startBit; i >= 0; i--) {
    remainder = remainder << 1;
    if ((a >> i) & Uint64.one != Uint64.zero) {
      remainder = remainder | Uint64.one;
    }
    if (remainder.compareTo(b) >= 0) {
      remainder = remainder - b;
      quotient = quotient | (Uint64.one << i);
    }
  }
  return (quotient: quotient, remainder: remainder);
}
