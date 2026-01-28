import 'package:blockchain_utils/crypto/crypto/ec/cdsa.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class PastaUtils {
  static (List<int>, List<int>) hashToFiled({
    required String curveId,
    required String domainPrefix,
    required List<int> message,
  }) {
    final List<int> domainBytes = StringUtils.encode(domainPrefix);
    final List<int> curveIdBytes = StringUtils.encode(curveId);
    const int chunkLen = 64;
    final totalLength = 22 + curveId.length + domainPrefix.length;
    List<int> hash(List<List<int>> values) {
      final b = BLAKE2b(
        digestLength: chunkLen,
        config: Blake2bConfig(personalization: List<int>.filled(16, 0)),
      );
      for (final i in values) {
        b.update(i);
      }
      return b.digest();
    }

    final b0 = hash([
      List<int>.filled(128, 0),
      message,
      [0, chunkLen * 2, 0],
      domainBytes,
      "-".codeUnits,
      curveIdBytes,
      "_XMD:BLAKE2b_SSWU_RO_".codeUnits,
      [totalLength],
    ]);
    final b1 = hash([
      b0,
      [1],
      domainBytes,
      "-".codeUnits,
      curveIdBytes,
      "_XMD:BLAKE2b_SSWU_RO_".codeUnits,
      [totalLength],
    ]);
    final b2 = hash([
      ...List.generate(b0.length, (index) => [b0[index] ^ b1[index]]),
      [2],
      domainBytes,
      "-".codeUnits,
      curveIdBytes,
      "_XMD:BLAKE2b_SSWU_RO_".codeUnits,
      [totalLength],
    ]);
    return (b1.reversed.toList(), b2.reversed.toList());
  }

  static (F, F, F) mapToCurveSimpleSwu<F extends PastaFieldElement<F>>({
    required F u,
    required F theta,
    required F z,
    required F r,
    required PastaCurveParams<F> isogenyParams,
  }) {
    final a = isogenyParams.a;
    final b = isogenyParams.b;

    final zU2 = z * u.square();

    final ta = zU2.square() + zU2;
    F conditionalSelect(F a, F b, bool choice) {
      return a.conditionalSelect(a, b, choice);
    }

    FieldSqrtResult<F> sqrtRatio(F a, F b) {
      return a.sRatio(a, b);
    }

    final numX1 = b * (ta + r);

    final div = a * conditionalSelect(-ta, z, ta.isZero());

    final num2X1 = numX1.square();
    final div2 = div.square();
    final div3 = div2 * div;

    final numGx1 = (num2X1 + a * div2) * numX1 + b * div3;

    // x2 = Z * u^2 * x1   (same divisor "div")
    final numX2 = zU2 * numX1;

    // sqrt_ratio(num_gx1, div3) → (isSquare(gx1), y1)
    final sqrtResult = sqrtRatio(numGx1, div3);
    final gx1Square = sqrtResult.isSquare; // CtBool
    final y1 = sqrtResult.result; // F element (sqrt(h * gx1) or sqrt(gx1))

    // y2 = theta * z_u2 * u * y1
    final y2 = theta * zU2 * u * y1;

    // x = conditional_select(x2, x1, gx1_square)
    final numX = conditionalSelect(
      numX2, // x2
      numX1, // x1
      gx1Square,
    );

    F y = conditionalSelect(
      y2, // y2 when gx1 is nonsquare
      y1, // y1 when gx1 is square
      gx1Square,
    );
    y = conditionalSelect(-y, y, u.isOdd() == y.isOdd());
    return (numX * div, y * div3, div);
  }

  static (F, F, F) isoMap<F extends PastaFieldElement<F>>({
    required (F, F, F) p,
    required List<F> iso,
  }) {
    final x = p.$1;
    final z = p.$3;
    final y = p.$2;
    final z2 = z.square();
    final z3 = z2 * z;
    final z4 = z2.square();
    final z6 = z3.square();

    final numX =
        ((iso[0] * x + iso[1] * z2) * x + iso[2] * z4) * x + iso[3] * z6;
    final divX = (z2 * x + iso[4] * z4) * x + iso[5] * z6;

    final numY =
        (((iso[6] * x + iso[7] * z2) * x + iso[8] * z4) * x + iso[9] * z6) * y;
    final divY =
        (((x + iso[10] * z2) * x + iso[11] * z4) * x + iso[12] * z6) * z3;

    final zo = divX * divY;
    final xo = numX * divY * zo;
    final yo = numY * divX * zo.square();
    return (xo, yo, zo);
  }

  static FieldSqrtResult<F> sqrtTonelliShanks<F extends CryptoField<F>>({
    required F f,
    required F fPowTm1d2,
    required F rootOfUnity,
    required F one,
    required F Function(F a, F b, bool choice) conditionalSelect,
    int s = 32,
  }) {
    // w = f^((t - 1) // 2)
    final F w = fPowTm1d2;

    // v = 2^S
    int v = JubJubFqConst.S;
    F x = w * f;
    F b = x * w;

    // Initialize z as the 2^S root of unity.
    F z = rootOfUnity;
    final r = one;

    // for max_v in (1..=JubJubFq::S).rev()
    for (int maxV = JubJubFqConst.S; maxV >= 1; maxV--) {
      int k = 1;
      F b2k = b.square();
      bool jLessThanV = true; // Choice = 1.into() in Rust corresponds to "true"

      // Inner loop: j runs 2..max_v (exclusive of max_v)
      // (Rust's for j in 2..max_v)
      for (int j = 2; j < maxV; j++) {
        final bool b2kIsOne = b2k == r;

        final F squared = conditionalSelect(b2k, z, b2kIsOne).square();
        // b2k = b2kIsOne ? squared : b2k  (constant-time select)
        b2k = conditionalSelect(squared, b2k, b2kIsOne);
        final F newZ = conditionalSelect(z, squared, b2kIsOne);

        // j_less_than_v &= !j.ct_eq(&v);
        // Rust used a constant-time compare; we approximate with normal compare here.
        // If you need constant-time, make `ctEqInt(j, v)` available.
        jLessThanV = jLessThanV & (j != v);

        // k = u32::conditional_select(&j, &k, b2k_is_one);
        // conditional_select chooses j when b2k_is_one, else k.
        k = IntUtils.ctSelectInt(j, k, b2kIsOne);

        // z = JubJubFq::conditional_select(&z, &new_z, j_less_than_v);
        z = conditionalSelect(z, newZ, jLessThanV);
      }

      final F result = x * z;
      // x = conditional_select(result, x, b.ct_eq(&JubJubFq::ONE));
      x = conditionalSelect(result, x, b == r);
      z = z.square();
      b = b * z;
      v = k;
    }

    final bool ok = (x * x) == f;
    return FieldSqrtResult(x, ok);
  }

  static FieldSqrtResult<F> sqrtRatioGeneric<F extends CryptoField<F>>({
    required F num,
    required F div,
    required F zero,
    required F rootOfUnity,
  }) {
    // a = num * inv0(div)
    // inv0(div) = 0 if div == 0
    F a;
    final F? inv = div.invert();
    if (inv == null) {
      a = zero;
    } else {
      a = inv * num;
    }

    // b = a * ROOT_OF_UNITY
    final F b = a * rootOfUnity;

    // sqrt candidates
    final sqrtA = a.sqrt(); // returns null if a is nonsquare
    final sqrtB = b.sqrt(); // returns null if b is nonsquare

    final bool numIsZero = num.isZero();
    final bool divIsZero = div.isZero();
    final bool isSquare = sqrtA.isSquare;
    final bool isNonSquare = sqrtB.isSquare;

    // Safety check from Rust:
    // num == 0  OR div == 0  OR exactly one of a,b is square.
    assert(numIsZero || divIsZero || (isSquare != isNonSquare));

    // Boolean condition:
    // is_square & (num_is_zero || !div_is_zero)
    final bool resultIsSquare = isSquare && (numIsZero || !divIsZero);

    // Pick sqrt: if a is square, pick sqrtA, else pick sqrtB
    final F chosen = isSquare ? sqrtA.result : sqrtB.result;
    return FieldSqrtResult(chosen, resultIsSquare);
  }
}

class FieldSqrtResult<F extends CryptoField<F>> with Equality {
  final F result;
  final bool isSquare;
  const FieldSqrtResult(this.result, this.isSquare);

  /// Returns the square root if this element is a quadratic residue,
  /// otherwise returns null.
  F? sqrtOrNull() {
    return isSquare ? result : null;
  }

  @override
  List<dynamic> get variables => [result, isSquare];
}
