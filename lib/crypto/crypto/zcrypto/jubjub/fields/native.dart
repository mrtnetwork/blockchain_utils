import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/constants/constants.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class JubJubNativeConst {
  static final BigInt qJ = BigInt.parse(
    '52435875175126190479447740508185965837690552500527637822603658699938581184513',
  );

  static final BigInt rJ = BigInt.parse(
    '6554484396890773809930967563523245729705921265872317281365359162392183254199',
  );
}

abstract class JubJubNativeFieldElement<F extends JubJubNativeFieldElement<F>>
    extends CryptoField<F>
    implements JubJubPrimeField<F> {
  final BigInt v;
  BigInt get p;
  const JubJubNativeFieldElement(this.v);
  F identity();
  @override
  List<bool> toBits() {
    final toBytes = this.toBytes();
    final tmpLimbs = List<BigInt>.generate(4, (i) {
      return BigintUtils.fromBytes(
        toBytes.sublist(i * 8, (i * 8) + 8),
        byteOrder: Endian.little,
      );
    });
    return tmpLimbs
        .map((e) => BigintUtils.toBinaryBool(e, bitLength: 64))
        .expand((e) => e)
        .toList();
  }

  @override
  List<bool> charBits() {
    return BigintUtils.toBinaryBool(p, bitLength: 256);
  }
}

/// Element of the JubJub field Fq.
class JubJubNativeFq extends JubJubNativeFieldElement<JubJubNativeFq>
    with Equality
    implements JubJubField<JubJubNativeFq> {
  @override
  BigInt get p => JubJubNativeConst.qJ;
  JubJubNativeFq(BigInt v) : super(v % JubJubNativeConst.qJ);

  /// Creates a field element assuming v is already in canonical form.
  JubJubNativeFq.nP(super.v) : assert(v < JubJubNativeConst.qJ);
  factory JubJubNativeFq.from(int v) {
    if (v.isNegative) return JubJubNativeFq(BigInt.from(v));
    return JubJubNativeFq.nP(BigInt.from(v));
  }
  factory JubJubNativeFq.random() {
    return JubJubNativeFq.fromBytes64(QuickCrypto.generateRandom(64));
  }
  factory JubJubNativeFq.fromBytes64(List<int> bytes) {
    return JubJubNativeFq(
      BigintUtils.fromBytes(
        bytes.exc(
          length: 64,
          operation: "fromBytes64",
          reason: "Invalid bytes length.",
        ),
        byteOrder: Endian.little,
      ),
    );
  }
  factory JubJubNativeFq.fromBytes(List<int> bytes) {
    final toBig = BigintUtils.fromBytes(
      bytes.exc(length: 32, operation: "Invalid field bytes encoding length"),
      byteOrder: Endian.little,
    );
    if (toBig >= JubJubNativeConst.qJ) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes64",
        reason: "Invalid field bytes encoding.",
      );
    }
    return JubJubNativeFq.nP(toBig);
  }

  factory JubJubNativeFq.rootOfUnity() => JubJubNativeFq.nP(
    BigInt.parse(
      "10238227357739495823651030575849232062558860180284477541189508159991286009131",
    ),
  );
  factory JubJubNativeFq.edwardsD() => JubJubNativeFq.nP(
    BigInt.parse(
      "19257038036680949359750312669786877991949435402254120286184196891950884077233",
    ),
  );

  factory JubJubNativeFq.edwardsD2() => JubJubNativeFq.nP(
    BigInt.parse(
      "38514076073361898719500625339573755983898870804508240572368393783901768154466",
    ),
  );
  factory JubJubNativeFq.montgomeryA() => JubJubNativeFq.from(40962);
  factory JubJubNativeFq.montgomeryScale() => JubJubNativeFq.nP(
    BigInt.parse(
      "17814886934372412843466061268024708274627479829237077604635722030778476050649",
    ),
  );

  factory JubJubNativeFq.generator() => JubJubNativeFq.nP(BigInt.from(7));

  static final _zero = JubJubNativeFq(BigInt.zero);
  static final _one = JubJubNativeFq(BigInt.one);
  factory JubJubNativeFq.zero() => _zero;
  factory JubJubNativeFq.one() => _one;
  factory JubJubNativeFq.minusOne() => JubJubNativeFq(-BigInt.one);
  JubJubNativeFq _exp(BigInt e) {
    var result = identity();
    var base = this;
    var k = e;

    while (k > BigInt.zero) {
      if (k.isOdd) result = result * base;
      base = base * base;
      k >>= 1;
    }
    return result;
  }

  @override
  JubJubNativeFq double() => this + this;

  @override
  FieldSqrtResult<JubJubNativeFq> sqrt() {
    return PastaUtils.sqrtTonelliShanks(
      f: this,
      fPowTm1d2: pow(
        BigInt.parse(
          "6104339283789297388802252303364915521546564123189034618274734669823",
        ),
      ),
      rootOfUnity: JubJubNativeFq.rootOfUnity(),
      one: JubJubNativeFq.one(),
      s: JubJubFqConst.S,
      conditionalSelect: (a, b, choice) {
        return choice ? b : a;
      },
    );
  }

  @override
  JubJubNativeFq? invert() {
    if (isZero()) return null;
    return _exp(p - BigInt.two);
  }

  @override
  JubJubNativeFq operator *(JubJubNativeFq other) {
    return JubJubNativeFq(v * other.v);
  }

  @override
  JubJubNativeFq operator +(JubJubNativeFq other) {
    final BigInt sum = v + other.v;
    return JubJubNativeFq.nP(sum >= p ? sum - p : sum);
  }

  @override
  JubJubNativeFq operator -(JubJubNativeFq other) {
    final BigInt diff = v - other.v;
    return JubJubNativeFq.nP(diff.isNegative ? diff + p : diff);
  }

  @override
  bool isZero() {
    return this == JubJubNativeFq.zero();
  }

  @override
  List<int> toBytes() {
    return v.toU256LeBytes();
  }

  @override
  JubJubNativeFq operator -() {
    return JubJubNativeFq(-v);
  }

  @override
  JubJubNativeFq square() {
    final x = v;
    return JubJubNativeFq(x * x);
  }

  bool isOdd() => v.isOdd;

  @override
  JubJubNativeFq identity() {
    return JubJubNativeFq(BigInt.one);
  }

  JubJubNativeFq pow(BigInt v) => _exp(v);
  JubJubNativeFq powVartime(List<BigInt> by) {
    JubJubNativeFq res = JubJubNativeFq.one();
    for (BigInt e in by.reversed) {
      e = e.asU64;
      for (int i = 63; i >= 0; i--) {
        res = res.square();

        if (((e >> i) & BigInt.one) == BigInt.one) {
          res = res * this;
        }
      }
    }

    return res;
  }

  @override
  List<dynamic> get variables => [v, p];
}

/// Element of the JubJub scalar field Fr.
class JubJubNativeFr extends JubJubNativeFieldElement<JubJubNativeFr>
    with Equality
    implements JubJubScalar<JubJubNativeFr> {
  /// Creates a field element assuming v is already in canonical form.
  JubJubNativeFr.nP(super.v) : assert(v < JubJubNativeConst.rJ);
  @override
  BigInt get p => JubJubNativeConst.rJ;
  factory JubJubNativeFr.fromBytes(List<int> bytes) {
    final toBig = BigintUtils.fromBytes(
      bytes.exc(
        length: 32,
        operation: "fromBytes",
        reason: "Invalid field encoding bytes length.",
      ),
      byteOrder: Endian.little,
    );
    if (toBig >= JubJubNativeConst.rJ) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid field encoding bytes.",
      );
    }
    return JubJubNativeFr.nP(
      BigintUtils.fromBytes(bytes, byteOrder: Endian.little),
    );
  }

  factory JubJubNativeFr.random() {
    return JubJubNativeFr.fromBytes64(QuickCrypto.generateRandom(64));
  }
  factory JubJubNativeFr.fromBytes64(List<int> bytes) {
    return JubJubNativeFr(
      BigintUtils.fromBytes(
        bytes.exc(
          length: 64,
          operation: "fromBytes64",
          reason: "Invalid Bytes length.",
        ),
        byteOrder: Endian.little,
      ),
    );
  }

  JubJubNativeFr(BigInt v) : super(v % JubJubNativeConst.rJ);
  static final _zero = JubJubNativeFr.nP(BigInt.zero);
  static final _one = JubJubNativeFr.nP(BigInt.one);
  factory JubJubNativeFr.zero() => _zero;
  factory JubJubNativeFr.one() => _one;
  factory JubJubNativeFr.minusOne() => JubJubNativeFr(-BigInt.one);

  JubJubNativeFr _exp(BigInt e) {
    var result = identity();
    var base = this;
    var k = e;

    while (k > BigInt.zero) {
      if (k.isOdd) result = result * base;
      base = base * base;
      k >>= 1;
    }
    return result;
  }

  JubJubNativeFr _inv() => _exp(p - BigInt.two);

  JubJubNativeFr operator /(JubJubNativeFr o) => this * o._inv();
  @override
  FieldSqrtResult<JubJubNativeFr> sqrt() {
    final sqrt = pow(
      BigInt.parse(
        "1638621099222693452482741890880811432426480316468079320341339790598045813550",
      ),
    );
    return FieldSqrtResult(sqrt, (sqrt * sqrt) == this);
  }

  @override
  JubJubNativeFr operator *(JubJubNativeFr other) {
    return JubJubNativeFr(v * other.v);
  }

  @override
  JubJubNativeFr operator +(JubJubNativeFr other) {
    final BigInt sum = v + other.v;
    return JubJubNativeFr.nP(sum >= p ? sum - p : sum);
  }

  @override
  JubJubNativeFr operator -(JubJubNativeFr other) {
    final BigInt diff = v - other.v;
    return JubJubNativeFr.nP(diff.isNegative ? diff + p : diff);
  }

  @override
  bool isZero() {
    return this == JubJubNativeFr.zero();
  }

  @override
  List<int> toBytes() {
    return v.toU256LeBytes();
  }

  @override
  JubJubNativeFr operator -() {
    return JubJubNativeFr(-v);
  }

  @override
  JubJubNativeFr identity() {
    return _one;
  }

  @override
  JubJubNativeFr square() {
    return JubJubNativeFr(v * v);
  }

  JubJubNativeFr pow(BigInt v) => _exp(v);

  @override
  JubJubNativeFr? invert() {
    if (isZero()) return null;
    return _inv();
  }

  @override
  JubJubNativeFr double() {
    return this + this;
  }

  @override
  List<dynamic> get variables => [v, p];
}
