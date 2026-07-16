import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';

const int _signMask = -0x8000000000000000;
const int _mask32 = 0xFFFFFFFF;

int _pack(Uint64 v) => (v.hi << 32) | v.lo;
Uint64 _unpack(int v) => Uint64.fromParts((v >>> 32) & _mask32, v & _mask32);
int _ucmp(int a, int b) => (a ^ _signMask).compareTo(b ^ _signMask);

(Uint64 hi, Uint64 lo) widenMulImpl(Uint64 a, Uint64 b) {
  final aLo = a.lo, aHi = a.hi, bLo = b.lo, bHi = b.hi;
  final p0 = aLo * bLo, p1 = aLo * bHi, p2 = aHi * bLo, p3 = aHi * bHi;
  final mid = (p0 >>> 32) + (p1 & _mask32) + (p2 & _mask32);
  final loVal = ((mid & _mask32) << 32) + (p0 & _mask32);
  final hiVal = p3 + (p1 >>> 32) + (p2 >>> 32) + (mid >>> 32);
  return (_unpack(hiVal), _unpack(loVal));
}

({Uint64 quotient, Uint64 remainder}) divModImpl(Uint64 a, Uint64 b) {
  final n = _pack(a);
  final d = _pack(b);
  if (d == 0) throw IntegerError.divisionByZero;
  int q, r;
  if (d < 0) {
    if (_ucmp(n, d) < 0) {
      q = 0;
      r = n;
    } else {
      q = 1;
      r = n - d;
    }
  } else if (n >= 0) {
    q = n ~/ d;
    r = n - q * d;
  } else {
    q = ((n >>> 1) ~/ d) * 2;
    r = n - q * d;
    if (_ucmp(r, d) >= 0) {
      q += 1;
      r -= d;
    }
  }
  return (quotient: _unpack(q), remainder: _unpack(r));
}
