import 'package:blockchain_utils/numbers/src/u256/u256.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';

const int _mask32 = 0xFFFFFFFF;
const int _signMask = -0x8000000000000000;

// Pack/unpack a Uint64 limb to/from a single raw 64-bit int. Only safe
// where `int` is a real 64-bit value (this file is only ever selected
// via `if (dart.library.io)`, i.e. never on dart2js) — mirrors
// word_math_native.dart's `_pack`/`_unpack`, duplicated locally to
// avoid exposing them outside that file.
@pragma('vm:prefer-inline')
int _pack(Uint64 v) => (v.hi << 32) | v.lo;
@pragma('vm:prefer-inline')
Uint64 _unpack(int v) => Uint64.fromParts((v >>> 32) & _mask32, v & _mask32);

/// Full 128-bit product of two raw 64-bit limbs, as (hi, lo) raw ints.
/// Identical formula to `widenMulImpl` in word_math_native.dart —
/// duplicated locally (rather than imported) to stay on raw ints
/// end-to-end instead of round-tripping through `Uint64` per pair.
///
/// `@pragma('vm:prefer-inline')`: a CPU profile showed this call
/// (together with `_ult` below) accounting for over half of *all*
/// samples across a benchmark run — neither was being inlined by
/// default. A first attempt fixed that by manually flattening the
/// entire 10-term multiply into one ~200-line function body; that
/// backfired, because a function that large runs past the VM's size
/// threshold for JIT optimization and gets stuck running unoptimized
/// indefinitely instead. This pragma gets the same "no call overhead"
/// result the manual flattening was after, without blowing up
/// `mulImpl`'s own function size — keep it, and keep this function
/// small, if you're ever tempted to inline more by hand here.
@pragma('vm:prefer-inline')
(int hi, int lo) _widenMulRaw(int a, int b) {
  final aLo = a & _mask32, aHi = (a >>> 32) & _mask32;
  final bLo = b & _mask32, bHi = (b >>> 32) & _mask32;
  final p0 = aLo * bLo, p1 = aLo * bHi, p2 = aHi * bLo, p3 = aHi * bHi;
  final mid = (p0 >>> 32) + (p1 & _mask32) + (p2 & _mask32);
  final loVal = ((mid & _mask32) << 32) + (p0 & _mask32);
  final hiVal = p3 + (p1 >>> 32) + (p2 >>> 32) + (mid >>> 32);
  return (hiVal, loVal);
}

/// Unsigned less-than on raw two's-complement ints — same sign-flip
/// trick as word_math_native.dart's `_ucmp`. This was the single
/// hottest self-time frame in the profile (a one-line function costing
/// almost as much as the multiply itself) purely from not being
/// inlined — `@pragma('vm:prefer-inline')` fixes exactly that.
@pragma('vm:prefer-inline')
bool _ult(int a, int b) => (a ^ _signMask) < (b ^ _signMask);

/// Raw-int equivalent of `Uint64.mac`: `acc + a*b + carry` as a full
/// 128-bit value, returned as (result, carryOut). Same three-step
/// carry derivation as the `Uint64` version, just on raw ints so
/// nothing is heap-allocated — and, with the pragma, no call overhead
/// either, since `mulImpl` below stays small enough for the VM to
/// actually optimize and this then inlines cleanly into it.
@pragma('vm:prefer-inline')
(int result, int carryOut) _macRaw(int acc, int a, int b, int carry) {
  final (hi0, lo0) = _widenMulRaw(a, b);
  final lo1 = lo0 + acc;
  final c1 = _ult(lo1, lo0) ? 1 : 0;
  final lo2 = lo1 + carry;
  final c2 = _ult(lo2, lo1) ? 1 : 0;
  return (lo2, hi0 + c1 + c2);
}

/// Full 256x256->256 wrapping multiply, native-only. Every limb is
/// packed into a single raw 64-bit int and the row-scanning
/// accumulation runs through `_macRaw`/`_widenMulRaw`/`_ult` — kept as
/// separate small functions (deliberately *not* hand-flattened into
/// one body — see `_widenMulRaw`'s doc comment for why that regressed)
/// and forced to inline via pragma instead. No `Uint64` is allocated
/// until the four output limbs are packed back at the end.
///
/// Row-scanning order preserved deliberately: see u256_math_web.dart's
/// doc comment for why the Comba (column-summing) layout is unsafe
/// here — a prior version of this multiply got exactly that wrong.
@pragma('vm:prefer-inline')
Uint256 mulImpl(Uint256 a, Uint256 b) {
  final a0 = _pack(a.d0), a1 = _pack(a.d1), a2 = _pack(a.d2), a3 = _pack(a.d3);
  final b0 = _pack(b.d0), b1 = _pack(b.d1), b2 = _pack(b.d2), b3 = _pack(b.d3);

  var c0 = 0, c1 = 0, c2 = 0, c3 = 0;
  int carry;

  // i = 0
  (c0, carry) = _macRaw(c0, a0, b0, 0);
  (c1, carry) = _macRaw(c1, a0, b1, carry);
  (c2, carry) = _macRaw(c2, a0, b2, carry);
  (c3, _) = _macRaw(c3, a0, b3, carry); // carry past limb 3: dropped

  // i = 1
  (c1, carry) = _macRaw(c1, a1, b0, 0);
  (c2, carry) = _macRaw(c2, a1, b1, carry);
  (c3, _) = _macRaw(c3, a1, b2, carry); // carry past limb 3: dropped

  // i = 2
  (c2, carry) = _macRaw(c2, a2, b0, 0);
  (c3, _) = _macRaw(c3, a2, b1, carry); // carry past limb 3: dropped

  // i = 3
  (c3, _) = _macRaw(c3, a3, b0, 0); // carry past limb 3: dropped

  return Uint256.unsafe(_unpack(c3), _unpack(c2), _unpack(c1), _unpack(c0));
}
