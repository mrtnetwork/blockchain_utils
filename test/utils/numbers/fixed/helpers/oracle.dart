import 'dart:math';

/// Canonical unsigned representative of [value] in `[0, 2^bits)`.
/// `BigInt.toUnsigned` treats negative inputs as infinite two's
/// complement, so this is correct for any sign of [value].
BigInt wrapUnsigned(BigInt value, int bits) => value.toUnsigned(bits);

/// Canonical signed (two's complement) representative of [value] for a
/// [bits]-wide signed type.
BigInt wrapSigned(BigInt value, int bits) => value.toSigned(bits);

BigInt maxUnsigned(int bits) => (BigInt.one << bits) - BigInt.one;
BigInt maxSigned(int bits) => (BigInt.one << (bits - 1)) - BigInt.one;
BigInt minSigned(int bits) => -(BigInt.one << (bits - 1));

/// Uniform random value in `[0, 2^bits)`. Built from 16-bit chunks so it
/// never asks [Random.nextInt] for a range larger than it supports.
BigInt randomUnsigned(Random rnd, int bits) {
  var v = BigInt.zero;
  var remaining = bits;
  while (remaining > 0) {
    final chunk = remaining >= 16 ? 16 : remaining;
    v = (v << chunk) | BigInt.from(rnd.nextInt(1 << chunk));
    remaining -= chunk;
  }
  return v;
}

/// Uniform random value in `[minSigned(bits), maxSigned(bits)]`.
BigInt randomSigned(Random rnd, int bits) =>
    wrapSigned(randomUnsigned(rnd, bits), bits);

/// A handful of "interesting" bit patterns fixed-width arithmetic tends
/// to get wrong first: 0, 1, all-ones, half-set, alternating bits, and a
/// single set/clear bit at every position (limb-boundary crossings).
List<BigInt> interestingUnsigned(int bits) {
  final out = <BigInt>{
    BigInt.zero,
    BigInt.one,
    BigInt.two,
    maxUnsigned(bits),
    maxUnsigned(bits) - BigInt.one,
    maxUnsigned(bits) ~/ BigInt.two,
    wrapUnsigned(BigInt.parse('5' * ((bits ~/ 4) + 1), radix: 16), bits),
    wrapUnsigned(BigInt.parse('A' * ((bits ~/ 4) + 1), radix: 16), bits),
  };
  // Every limb boundary (multiples of 16, since Uint32/Int32 decompose
  // into 16-bit limbs and everything wider is built from 32/64-bit
  // limbs — all multiples of 16) plus the bit right before/after it,
  // rather than every single bit position: keeps 128/256-bit pairwise
  // tests fast while still hitting every carry/borrow boundary.
  final positions = <int>{0, 1, 2, bits - 1, bits - 2};
  if (bits <= 32) {
    // Cheap enough to just enumerate every bit position directly.
    positions.addAll(List<int>.generate(bits, (i) => i));
  } else {
    for (var m = 16; m < bits; m += 16) {
      positions.addAll([m - 1, m, m + 1]);
    }
  }
  for (final i in positions) {
    if (i < 0 || i >= bits) continue;
    out.add(BigInt.one << i); // single bit set
    out.add(maxUnsigned(bits) - (BigInt.one << i)); // single bit clear
  }
  return out.toList(growable: false);
}

/// Signed counterpart of [interestingUnsigned]: every interesting bit
/// pattern reinterpreted as signed, plus the signed-specific boundaries
/// (min/max, and the values right next to them).
List<BigInt> interestingSigned(int bits) {
  final out = <BigInt>{
    BigInt.zero,
    BigInt.one,
    -BigInt.one,
    BigInt.two,
    -BigInt.two,
    maxSigned(bits),
    minSigned(bits),
    maxSigned(bits) - BigInt.one,
    minSigned(bits) + BigInt.one,
  };
  for (final u in interestingUnsigned(bits)) {
    out.add(wrapSigned(u, bits));
  }
  return out.toList(growable: false);
}

/// All pairs `(a, b)` from the cartesian product of two interesting-value
/// lists — cheap enough at these list sizes, and pairwise interactions
/// (e.g. add-with-carry across every limb boundary) are exactly where
/// carry-chain bugs hide.
Iterable<(BigInt, BigInt)> pairs(List<BigInt> a, List<BigInt> b) sync* {
  for (final x in a) {
    for (final y in b) {
      yield (x, y);
    }
  }
}
