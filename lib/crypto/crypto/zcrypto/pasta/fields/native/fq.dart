import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class VestaNativeFq extends PastaNativeFieldElement<VestaNativeFq>
    with Equality {
  @override
  final BigInt v;
  BigInt get p => PastaNativeConst.q;
  VestaNativeFq.nP(this.v) : assert(v < PastaNativeConst.q);
  VestaNativeFq(BigInt v) : v = v % PastaNativeConst.q;

  factory VestaNativeFq.random() {
    return VestaNativeFq.fromBytes64(QuickCrypto.generateRandom(64));
  }
  factory VestaNativeFq.from(int v) {
    final big = BigInt.from(v);
    if (big.isNegative) return VestaNativeFq(big);
    return VestaNativeFq.nP(big);
  }
  factory VestaNativeFq.fromBytes(List<int> bytes) {
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
    return VestaNativeFq.nP(toBig);
  }
  factory VestaNativeFq.fromBytes64(List<int> bytes) {
    return VestaNativeFq(
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

  static final _zero = VestaNativeFq.nP(BigInt.zero);
  static final _one = VestaNativeFq.nP(BigInt.one);
  static VestaNativeFq zero() => _zero;
  static VestaNativeFq one() => _one;
  factory VestaNativeFq.two() => VestaNativeFq.nP(BigInt.two);

  VestaNativeFq _exp(BigInt e) {
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

  VestaNativeFq _inv() => _exp(p - BigInt.two);
  VestaNativeFq operator /(VestaNativeFq o) => this * o._inv();
  factory VestaNativeFq.theta() => VestaNativeFq.nP(
    BigInt.parse(
      "19542237030899541288482047651115607340417301175065916331554475033324169403229",
    ),
  );
  factory VestaNativeFq.z() => VestaNativeFq.nP(
    BigInt.parse(
      "28948022309329048855892746252171976963363056481941647379679742748393362948084",
    ),
  );
  factory VestaNativeFq.zeta() => VestaNativeFq.nP(
    BigInt.parse(
      "2942865608506852014473558576493638302197734138389222805617480874486368177743",
    ),
  );

  factory VestaNativeFq.minusOne() => VestaNativeFq(-BigInt.one);
  factory VestaNativeFq.twoInv() => VestaNativeFq.nP(
    BigInt.parse(
      "14474011154664524427946373126085988481681528240970823689839871374196681474049",
    ),
  );

  factory VestaNativeFq.rootOfUnity() => VestaNativeFq.nP(
    BigInt.parse(
      "20761624379169977859705911634190121761503565370703356079647768903521299517535",
    ),
  );
  @override
  VestaNativeFq double() => this + this;

  // static final PastaSqrtTables<VestaNativeFq> _fpTables = PastaSqrtTables(
  //   hashXor: 0x116A9E,
  //   hashMod: 1206,
  //   rootOfUnity: VestaNativeFq.rootOfUnity(),
  //   one: VestaNativeFq.one(),
  // );

  @override
  FieldSqrtResult<VestaNativeFq> sqrt() {
    return PastaUtils.sqrtTonelliShanks(
      f: this,
      fPowTm1d2: powByTMinus1Over2(),

      one: _one,
      rootOfUnity: VestaNativeFq.rootOfUnity(),
      s: 32,
      conditionalSelect: (a, b, choice) => choice ? b : a,
    );
  }

  static FieldSqrtResult<VestaNativeFq> sqrtRatio(
    VestaNativeFq num,
    VestaNativeFq div,
  ) {
    return PastaUtils.sqrtRatioGeneric(
      num: num,
      div: div,
      zero: VestaNativeFq.zero(),
      rootOfUnity: VestaNativeFq.rootOfUnity(),
    );
  }

  static FieldSqrtResult<VestaNativeFq> sqrtAlt(VestaNativeFq r) {
    return PastaUtils.sqrtTonelliShanks(
      f: r,
      fPowTm1d2: r.powByTMinus1Over2(),

      one: _one,
      rootOfUnity: VestaNativeFq.rootOfUnity(),
      s: 32,
      conditionalSelect: (a, b, choice) => choice ? b : a,
    );
  }

  @override
  VestaNativeFq operator *(VestaNativeFq other) {
    return VestaNativeFq(v * other.v);
  }

  @override
  VestaNativeFq operator +(VestaNativeFq other) {
    final BigInt sum = v + other.v;
    return VestaNativeFq.nP(sum >= p ? sum - p : sum);
  }

  @override
  VestaNativeFq operator -(VestaNativeFq other) {
    final BigInt diff = v - other.v;
    return VestaNativeFq.nP(diff.isNegative ? diff + p : diff);
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
  VestaNativeFq operator -() {
    return VestaNativeFq(-v);
  }

  @override
  VestaNativeFq square() {
    return VestaNativeFq(v * v);
  }

  @override
  VestaNativeFq identity() {
    return _one;
  }

  @override
  List<dynamic> get variables => [v, p];

  @override
  int getLower32() {
    return v.toU32;
  }

  @override
  VestaNativeFq? invert() {
    if (isZero()) return null;
    return _inv();
  }

  @override
  VestaNativeFq powByTMinus1Over2() {
    return pow(
      BigInt.parse(
        "3369993333393829974333376885877453834209946971612708570864021632400",
      ),
    );
  }

  @override
  factory VestaNativeFq.conditionalSelect(
    VestaNativeFq a,
    VestaNativeFq b,
    bool choice,
  ) {
    return choice ? b : a;
  }

  VestaNativeFq pow(BigInt r) => _exp(r);
  @override
  VestaNativeFq conditionalSelect(
    VestaNativeFq a,
    VestaNativeFq b,
    bool choice,
  ) {
    return choice ? b : a;
  }

  @override
  FieldSqrtResult<VestaNativeFq> sRatio(VestaNativeFq a, VestaNativeFq b) {
    return sqrtRatio(a, b);
  }
}
