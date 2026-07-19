import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'g1_native_test.dart';

void main() {
  test("BLS12/Pairing", () {
    _trickingMillerLoopResult();
    _testMultiMillerLoop();
    _testUnitary();
    _testBilinearity();
    _testGenerator();
  });
}

void _trickingMillerLoopResult() {
  final addr = MultiMillerLoopBls12();
  // identity × generator → 1
  expect(
    addr.multiMillerLoop([
      (
        G1NativeAffinePoint.identity(),
        G2NativePrepared.fromG2(G2NativeAffinePoint.generator()),
      ),
    ]).inner,
    Bls12NativeFp12.one(),
  );

  // generator × identity → 1
  expect(
    addr.multiMillerLoop([
      (
        G1NativeAffinePoint.generator(),
        G2NativePrepared.fromG2(G2NativeAffinePoint.identity()),
      ),
    ]).inner,
    Bls12NativeFp12.one(),
  );

  // g + (-g) BEFORE final exponentiation ≠ 1
  expect(
    addr.multiMillerLoop([
          (
            G1NativeAffinePoint.generator(),
            G2NativePrepared.fromG2(G2NativeAffinePoint.generator()),
          ),
          (
            -G1NativeAffinePoint.generator(),
            G2NativePrepared.fromG2(G2NativeAffinePoint.generator()),
          ),
        ]).inner !=
        Bls12NativeFp12.one(),
    true,
  );

  // g + (-g) AFTER final exponentiation = identity
  expect(
    addr.multiMillerLoop([
      (
        G1NativeAffinePoint.generator(),
        G2NativePrepared.fromG2(G2NativeAffinePoint.generator()),
      ),
      (
        -G1NativeAffinePoint.generator(),
        G2NativePrepared.fromG2(G2NativeAffinePoint.generator()),
      ),
    ]).finalExponentiation(),
    GtNative.identity(),
  );
}

void _testMultiMillerLoop() {
  final a1 = G1NativeAffinePoint.generator();
  final b1 = G2NativeAffinePoint.generator();

  final a2 = G1NativeAffinePoint.fromProjective(
    G1NativeAffinePoint.generator() *
        JubJubFq.fromRaw([1, 2, 3, 4].toBigInt()).toNative().invert()!.square(),
  );
  final b2 = G2NativeAffinePoint.fromProjective(
    G2NativeAffinePoint.generator() *
        JubJubFq.fromRaw([4, 2, 2, 4].toBigInt()).toNative().invert()!.square(),
  );

  final a3 = G1NativeAffinePoint.identity();
  final b3 = G2NativeAffinePoint.fromProjective(
    G2NativeAffinePoint.generator() *
        JubJubFq.fromRaw([9, 2, 2, 4].toBigInt()).toNative().invert()!.square(),
  );

  final a4 = G1NativeAffinePoint.fromProjective(
    G1NativeAffinePoint.generator() *
        JubJubFq.fromRaw([5, 5, 5, 5].toBigInt()).toNative().invert()!.square(),
  );
  final b4 = G2NativeAffinePoint.identity();

  final a5 = G1NativeAffinePoint.fromProjective(
    G1NativeAffinePoint.generator() *
        JubJubFq.fromRaw([323, 32, 3, 1].toBigInt()).toNative().invert()!.square(),
  );
  final b5 = G2NativeAffinePoint.fromProjective(
    G2NativeAffinePoint.generator() *
        JubJubFq.fromRaw([4, 2, 2, 9099].toBigInt()).toNative().invert()!.square(),
  );

  final b1Prepared = G2NativePrepared.fromG2(b1);
  final b2Prepared = G2NativePrepared.fromG2(b2);
  final b3Prepared = G2NativePrepared.fromG2(b3);
  final b4Prepared = G2NativePrepared.fromG2(b4);
  final b5Prepared = G2NativePrepared.fromG2(b5);

  final expected =
      Bls12PairingUtils.pairing(a1, b1) +
      Bls12PairingUtils.pairing(a2, b2) +
      Bls12PairingUtils.pairing(a3, b3) +
      Bls12PairingUtils.pairing(a4, b4) +
      Bls12PairingUtils.pairing(a5, b5);
  final test =
      MultiMillerLoopBls12().multiMillerLoop([
        (a1, b1Prepared),
        (a2, b2Prepared),
        (a3, b3Prepared),
        (a4, b4Prepared),
        (a5, b5Prepared),
      ]).finalExponentiation();

  expect(expected, test);
}

void _testUnitary() {
  final g = G1NativeAffinePoint.generator();
  final h = G2NativeAffinePoint.generator();

  final p = -Bls12PairingUtils.pairing(g, h);
  final q = Bls12PairingUtils.pairing(g, -h);
  final r = Bls12PairingUtils.pairing(-g, h);

  expect(p, q);
  expect(q, r);
}

void _testBilinearity() {
  // Scalars
  final a =
      JubJubFq.fromRaw([
        Uint64.one,
        Uint64(2),
        Uint64(3),
        Uint64(4),
      ]).toNative().invert()!.square();

  final b =
      JubJubFq.fromRaw([
        Uint64(5),
        Uint64(6),
        Uint64(7),
        Uint64(8),
      ]).toNative().invert()!.square();

  final c = a * b;

  // Group elements
  final g = G1NativeAffinePoint.fromProjective(G1NativeAffinePoint.generator() * a);
  final h = G2NativeAffinePoint.fromProjective(G2NativeAffinePoint.generator() * b);

  final p = Bls12PairingUtils.pairing(g, h);

  // p != identity
  expect(p != GtNative.identity(), true);

  // Expected value
  final expected = G1NativeAffinePoint.fromProjective(
    G1NativeAffinePoint.generator() * c,
  );

  // Bilinearity checks
  expect(p, Bls12PairingUtils.pairing(expected, G2NativeAffinePoint.generator()));
  expect(
    p,
    (Bls12PairingUtils.pairing(
          G1NativeAffinePoint.generator(),
          G2NativeAffinePoint.generator(),
        )) *
        c,
  );
}

void _testGenerator() {
  final r = Bls12PairingUtils.pairing(
    G1NativeAffinePoint.generator(),
    G2NativeAffinePoint.generator(),
  );
  expect(r, GtNative.generator());
}

extension _TOBIG on List<int> {
  List<Uint64> toBigInt() => map((e) => Uint64(e)).toList();
}
