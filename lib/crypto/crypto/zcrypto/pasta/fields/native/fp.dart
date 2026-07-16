import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/constants/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class PastaNativeConst {
  static final BigInt p = BigInt.parse(
    '0x40000000000000000000000000000000224698fc094cf91b992d30ed00000001',
  );

  static final BigInt q = BigInt.parse(
    '0x40000000000000000000000000000000224698fc0994a8dd8c46eb2100000001',
  );
}

abstract class PastaNativeFieldElement<F extends PastaNativeFieldElement<F>>
    extends PastaFieldElement<F>
    implements Comparable<F> {
  const PastaNativeFieldElement();
  F identity();
  BigInt get v;

  @override
  int compareTo(F other) {
    return v.compareTo(other.v);
  }
}

class PallasNativeFp extends PastaNativeFieldElement<PallasNativeFp>
    with Equality {
  @override
  final BigInt v;
  BigInt get p => PastaNativeConst.p;
  PallasNativeFp.nP(this.v) : assert(v < PastaNativeConst.p);
  PallasNativeFp(BigInt v) : v = v % PastaNativeConst.p;
  factory PallasNativeFp.fromBytes(List<int> bytes) {
    final toBig = BigintUtils.fromBytes(
      bytes.exc(
        length: 32,
        operation: "fromBytes",
        reason: "Invalid field bytes length.",
      ),
      byteOrder: Endian.little,
    );
    if (toBig >= PastaNativeConst.q) {
      throw ArgumentException.invalidOperationArguments(
        "fromBytes",
        reason: "Invalid field bytes encoding.",
      );
    }
    return PallasNativeFp(toBig);
  }
  factory PallasNativeFp.fromBytes64(List<int> bytes) {
    return PallasNativeFp(
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
  factory PallasNativeFp.from(int v) {
    final big = BigInt.from(v);
    if (big.isNegative) return PallasNativeFp(big);
    return PallasNativeFp.nP(big);
  }
  factory PallasNativeFp.random() {
    return PallasNativeFp.fromBytes64(QuickCrypto.generateRandom(64));
  }

  static final _zero = PallasNativeFp.nP(BigInt.zero);
  static final _one = PallasNativeFp.nP(BigInt.one);
  factory PallasNativeFp.zero() => _zero;
  factory PallasNativeFp.max() =>
      PallasNativeFp.nP(PastaNativeConst.p - BigInt.one);
  factory PallasNativeFp.one() => _one;
  factory PallasNativeFp.two() => PallasNativeFp.nP(BigInt.two);
  factory PallasNativeFp.z() => PallasNativeFp.nP(
    BigInt.parse(
      "28948022309329048855892746252171976963363056481941560715954676764349967630324",
    ),
  );
  factory PallasNativeFp.delta() => PallasNativeFp.nP(
    BigInt.parse(
      "4730712715107027403836960807135378615419710616093490380467347787225654598562",
    ),
  );
  factory PallasNativeFp.theta() => PallasNativeFp.nP(
    BigInt.parse(
      "7003529136733518259227950775588032800807760729532353866644138209790443401614",
    ),
  );
  factory PallasNativeFp.zeta() => PallasNativeFp.nP(
    BigInt.parse(
      "8503465768106391777493614032514048814691664078728891710322960303815233784505",
    ),
  );
  factory PallasNativeFp.r() => _one;
  factory PallasNativeFp.minusOne() => PallasNativeFp(-BigInt.one);
  factory PallasNativeFp.twoInv() => PallasNativeFp.nP(
    BigInt.parse(
      "14474011154664524427946373126085988481681528240970780357977338382174983815169",
    ),
  );

  factory PallasNativeFp.rootOfUnity() => PallasNativeFp.nP(
    BigInt.parse(
      "19814229590243028906643993866117402072516588566294623396325693409366934201135",
    ),
  );
  factory PallasNativeFp.rootOfUnityInv() => PallasNativeFp.nP(
    BigInt.parse(
      "20278381027301128054966451283949098903157062660188087428315625391740337164790",
    ),
  );
  @override
  PallasNativeFp double() {
    return this + this;
  }

  // static final PastaSqrtTables<PallasNativeFp> _fpTables = PastaSqrtTables(
  //   hashXor: 0x11BE,
  //   hashMod: 1098,
  //   rootOfUnity: PallasNativeFp.rootOfUnity(),
  //   one: PallasNativeFp.one(),
  // );

  @override
  FieldSqrtResult<PallasNativeFp> sqrt() {
    return sqrtAlt(this);
  }

  static FieldSqrtResult<PallasNativeFp> sqrtRatio(
    PallasNativeFp num,
    PallasNativeFp div,
  ) {
    return PastaUtils.sqrtRatioGeneric(
      num: num,
      div: div,
      zero: PallasNativeFp.zero(),
      rootOfUnity: PallasNativeFp.rootOfUnity(),
    );
  }

  static FieldSqrtResult<PallasNativeFp> sqrtAlt(PallasNativeFp e) {
    return PastaUtils.sqrtTonelliShanks(
      f: e,
      fPowTm1d2: e.powByTMinus1Over2(),
      one: _one,
      rootOfUnity: PallasNativeFp.rootOfUnity(),
      s: PallasFPConst.S,
      conditionalSelect: (a, b, choice) => choice ? b : a,
    );
  }

  PallasNativeFp _exp(BigInt e) {
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

  PallasNativeFp _inv() => _exp(p - BigInt.two);
  PallasNativeFp operator /(PallasNativeFp o) => this * o._inv();
  @override
  PallasNativeFp operator *(PallasNativeFp other) {
    return PallasNativeFp(v * other.v);
  }

  @override
  PallasNativeFp operator +(PallasNativeFp other) {
    final BigInt sum = v + other.v;
    return PallasNativeFp.nP(sum >= p ? sum - p : sum);
  }

  @override
  PallasNativeFp operator -(PallasNativeFp other) {
    final BigInt diff = v - other.v;
    return PallasNativeFp.nP(diff.isNegative ? diff + p : diff);
  }

  @override
  bool isZero() {
    return this == _zero;
  }

  @override
  List<int> toBytes() {
    return v.toU256LeBytes();
  }

  @override
  PallasNativeFp operator -() {
    return PallasNativeFp(-v);
  }

  @override
  PallasNativeFp square() {
    return this * this;
  }

  @override
  PallasNativeFp identity() {
    return _one;
  }

  PallasNativeFp powVartime(List<BigInt> by) {
    PallasNativeFp res = PallasNativeFp.one();
    for (BigInt e in by.reversed) {
      for (int i = 63; i >= 0; i--) {
        res = res.square();

        if (((e >> i) & BigInt.one) == BigInt.one) {
          res = res * this;
        }
      }
    }

    return res;
  }

  PallasNativeFp pow(BigInt r) => _exp(r);

  @override
  List<dynamic> get variables => [v, p];

  @override
  int getLower32() {
    return v.toU32;
  }

  @override
  PallasNativeFp? invert() {
    if (isZero()) return null;
    return _inv();
  }

  @override
  PallasNativeFp powByTMinus1Over2() {
    return _exp(
      BigInt.parse(
        "3369993333393829974333376885877453834209946971612698481878577354870",
      ),
    );
  }

  @override
  PallasNativeFp conditionalSelect(
    PallasNativeFp a,
    PallasNativeFp b,
    bool choice,
  ) {
    return choice ? b : a;
  }

  @override
  FieldSqrtResult<PallasNativeFp> sRatio(PallasNativeFp a, PallasNativeFp b) {
    return sqrtRatio(a, b);
  }
}
