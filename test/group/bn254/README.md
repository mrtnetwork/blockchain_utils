# BN254 (alt_bn128) prototype

Implementation lives in `lib/crypto/crypto/group/bn254/src/`
(`fp/fp2/fp6/fp12/fr/g1/g2/pairing.dart`), wired as the pure-Dart backend
(`api/src/dart.dart`). Branchless / straight-line port mirroring
`lib/crypto/crypto/group/bls12_381`.

## Curve

- `p = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47`
- `r = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001`
- G1: `y² = x³ + 3`, `G = (1, 2)`, `h = 1` (on-curve ⇒ in-subgroup).
- Fp2 = `Fp[u]/(u²+1)`; G2: `y² = x³ + B₂`, `B₂ = 3/(u+9)`.
- G2 generator (affine, `c0 + c1·u`):
  `x = (10857046999023057135944570762232829481370756359578518086990519993285655852781,
        11559732032986387107991004021392285783925812861821192530917403151452391805634)`
  `y = (8495653923123431417604973247489272438418207987263600148770280649306958101930,
        4082367875863433681332203403145435568316851327593401208105741076214120093531)`.
- Encoding is EIP-197: G1 `x||y` (64 B), G2 `x1||x0||y1||y0` (128 B),
  all-zero = infinity (affine dummies are `(0,1)`, mirroring BLS, so the
  projective lift of infinity is the valid `(0:1:0)`). No BLS compression flags.
- Tower: Fp2 = `Fp[u]/(u²+1)`, Fp6 = `Fp2[v]/(v³-xi)`, Fp12 = `Fp6[w]/(w²-v)`,
  `xi = 9+u` (`Fp2.mulByNonresidue` multiplies by `xi`, not `u+1`).
  Ate loop `T = 6x+2`, `x = 4965661367192848881` (divisive twist).

## Files (lib)

- `src/fp.dart` — 4×64 Montgomery field, CIOS reduce, `conditionalSelect(Mask)`,
  `sqrt` via `(p+1)/4` (`p % 4 == 3`).
- `src/fr.dart` — scalar field (same machine, `r` modulus) for order checks.
- `src/fp2.dart` — Karatsuba `Fp2`, `fp4Square` for cyclotomic squaring.
- `src/g1.dart` / `src/g2.dart` — projective `(x:y:z)` + affine `(x,y,inf)`,
  Renes-Costello-Batina complete addition, dedicated doubling,
  `double-and-add` with `Uint64` mask (`conditionalSelectMask`),
  `isOnCurve`, `isTorsionFree` (`[r]P == 0`; G1 short-circuits via `h = 1`).
- `src/fp6.dart` — naive noble-tower formulas, `frobeniusMap` with
  `xi^((p^j-1)/3)` tables.
- `src/fp12.dart` — divisive `mulBy034`, `frobeniusMap` with
  `xi^((p^j-1)/6)` tables, `cyclotomicSquare`, `powVarTime`.
- `src/pairing.dart` — NAF Miller loop + BN extras folded into last group,
  `lineEval` via `mulBy034`, noble-style final exponentiation.
- `api/src/dart.dart` — `DartBn254G1CurveApi` (64-B points) /
  `DartBn254G2CurveApi` (128-B points), 32-B BE scalars `< r`.

## Tests

- `test/group/bn254/bn254_test.dart` — Fp round-trip, `2*G1` KAT
  (`x = 0x3064...cfd3`, `y = 0x15ed...2c4`), scalar-mul/add agreement,
  EIP-197 zero codecs, G2 on-curve + `[r]P == 0`, `r*G1 == 0`.
- `test/group/bn254/pairing_test.dart` — `e(G1,G2) != 1`, `e^r == 1`,
  `e(5P,Q) == e(P,5Q)`, identity/batch.
- `test/group/api/bn254_test.dart` — Dart-vs-Rust comparison: every
  `CurveTest` op runs on `[DartBn254G1CurveApi(), api.bn254G1]` (and G2)
  and must agree, plus both backends match the py_ecc oracle vectors.

```sh
dart test test/group/bn254/bn254_test.dart test/group/bn254/pairing_test.dart
BU_BACKEND=dart dart test test/group/api/bn254_test.dart   # Dart backend
dart test test/group/api/bn254_test.dart                   # Rust backend (default ffi)
```

Miller outputs, `frobeniusMap(1/2)`, `cyclotomicSquare`, and final
`e(G1,G2)` were verified limb-for-limb against `@noble/curves@1.9.7`.
