import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/point/extended.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class JubJubNielsPoint extends BaseJubJubNielsPoint<JubJubFr> with Equality {
  final JubJubFq vPlusU;
  final JubJubFq vMinusU;
  final JubJubFq z;
  final JubJubFq t2d;

  JubJubNielsPoint({
    required this.vPlusU,
    required this.z,
    required this.vMinusU,
    required this.t2d,
  });
  factory JubJubNielsPoint.identity() {
    return JubJubNielsPoint(
      vPlusU: JubJubFq.one(),
      vMinusU: JubJubFq.one(),
      z: JubJubFq.one(),
      t2d: JubJubFq.zero(),
    );
  }
  factory JubJubNielsPoint.conditionalSelect(
    JubJubNielsPoint a,
    JubJubNielsPoint b,
    bool choice,
  ) {
    return JubJubNielsPoint(
      vPlusU: JubJubFq.conditionalSelect(a.vPlusU, b.vPlusU, choice),
      vMinusU: JubJubFq.conditionalSelect(a.vMinusU, b.vMinusU, choice),
      z: JubJubFq.conditionalSelect(a.z, b.z, choice),
      t2d: JubJubFq.conditionalSelect(a.t2d, b.t2d, choice),
    );
  }
  @override
  JubJubPoint operator *(JubJubFr rhs) {
    return multiply(rhs.toBytes());
  }

  @override
  JubJubNielsPoint operator +(BaseRedJubJubPoint rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  List<int> toBytes() {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubNielsPoint toNiels() {
    return this;
  }

  @override
  JubJubPoint multiply(List<int> by) {
    assert(by.length == 32);
    final zero = JubJubNielsPoint.identity();
    JubJubPoint acc = JubJubPoint.identity();
    final bits = BytesUtils.bytesToBits(by);
    final iterableBits = bits.reversed.skip(4);
    for (final bit in iterableBits) {
      acc = acc.double();
      acc += JubJubNielsPoint.conditionalSelect(zero, this, bit);
    }
    return acc;
  }

  @override
  JubJubNielsPoint operator -(BaseRedJubJubPoint rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubNielsPoint operator -() {
    throw CryptoException.operationNotSupported;
  }

  @override
  List<dynamic> get variables => [vMinusU, vPlusU, z, t2d];
}

class JubJubAffineNielsPoint extends BaseJubJubNielsPoint<JubJubFr>
    with Equality {
  final JubJubFq vPlusU;
  final JubJubFq vMinusU;
  final JubJubFq t2d;

  JubJubAffineNielsPoint({
    required this.vPlusU,
    required this.vMinusU,
    required this.t2d,
  });
  factory JubJubAffineNielsPoint.conditionalSelect(
    JubJubAffineNielsPoint a,
    JubJubAffineNielsPoint b,
    bool choice,
  ) {
    return JubJubAffineNielsPoint(
      vMinusU: JubJubFq.conditionalSelect(a.vMinusU, b.vMinusU, choice),
      vPlusU: JubJubFq.conditionalSelect(a.vPlusU, b.vPlusU, choice),
      t2d: JubJubFq.conditionalSelect(a.t2d, b.t2d, choice),
    );
  }
  factory JubJubAffineNielsPoint.identity() {
    return JubJubAffineNielsPoint(
      vPlusU: JubJubFq.one(),
      vMinusU: JubJubFq.one(),
      t2d: JubJubFq.zero(),
    );
  }
  @override
  JubJubPoint operator *(JubJubFr rhs) {
    return multiply(rhs.toBytes());
  }

  @override
  JubJubAffineNielsPoint operator +(BaseRedJubJubPoint rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubAffineNielsPoint operator -(BaseRedJubJubPoint rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  List<int> toBytes() {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubAffineNielsPoint toNiels() {
    return this;
  }

  @override
  JubJubAffineNielsPoint operator -() {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubPoint multiply(List<int> by) {
    assert(by.length == 32);
    final zero = JubJubAffineNielsPoint.identity();
    JubJubPoint acc = JubJubPoint.identity();
    final bits = BytesUtils.bytesToBits(by); // length = 256
    final iterableBits = bits.reversed.skip(4);
    for (final bit in iterableBits) {
      acc = acc.double();
      acc += JubJubAffineNielsPoint.conditionalSelect(zero, this, bit);
    }
    return acc;
  }

  @override
  List<dynamic> get variables => [vMinusU, vPlusU, t2d];
}

class JubJubNielsNativePoint extends BaseJubJubNielsPoint<JubJubNativeFr>
    with Equality {
  final JubJubNativeFq vPlusU;
  final JubJubNativeFq vMinusU;
  final JubJubNativeFq z;
  final JubJubNativeFq t2d;

  JubJubNielsNativePoint({
    required this.vPlusU,
    required this.z,
    required this.vMinusU,
    required this.t2d,
  });
  factory JubJubNielsNativePoint.identity() {
    return JubJubNielsNativePoint(
      vPlusU: JubJubNativeFq.one(),
      vMinusU: JubJubNativeFq.one(),
      z: JubJubNativeFq.one(),
      t2d: JubJubNativeFq.zero(),
    );
  }
  factory JubJubNielsNativePoint.conditionalSelect(
    JubJubNielsNativePoint a,
    JubJubNielsNativePoint b,
    bool choice,
  ) {
    return choice ? b : a;
    // return JubJubNielsNativePoint(
    //   vPlusU: JubJubNativeFq.conditionalSelect(a.vPlusU, b.vPlusU, choice),
    //   vMinusU: JubJubNativeFq.conditionalSelect(a.vMinusU, b.vMinusU, choice),
    //   z: JubJubNativeFq.conditionalSelect(a.z, b.z, choice),
    //   t2d: JubJubNativeFq.conditionalSelect(a.t2d, b.t2d, choice),
    // );
  }
  @override
  JubJubNativePoint operator *(JubJubNativeFr rhs) {
    return multiply(rhs.toBytes());
  }

  @override
  JubJubNielsNativePoint operator +(BaseRedJubJubPoint<JubJubNativeFr> rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  List<int> toBytes() {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubNielsNativePoint toNiels() {
    return this;
  }

  @override
  JubJubNativePoint multiply(List<int> by) {
    assert(by.length == 32);
    final zero = JubJubNielsNativePoint.identity();
    JubJubNativePoint acc = JubJubNativePoint.identity();
    final bits = BytesUtils.bytesToBits(by); // length = 256
    final iterableBits = bits.reversed.skip(4);
    for (final bit in iterableBits) {
      acc = acc.double();
      acc += JubJubNielsNativePoint.conditionalSelect(zero, this, bit);
    }
    return acc;
  }

  @override
  JubJubNielsNativePoint operator -(BaseRedJubJubPoint<JubJubNativeFr> rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubNielsNativePoint operator -() {
    throw CryptoException.operationNotSupported;
  }

  @override
  List<dynamic> get variables => [vMinusU, vPlusU, z, t2d];
}

class JubJubAffineNielsNativePoint extends BaseJubJubNielsPoint<JubJubNativeFr>
    with Equality {
  final JubJubNativeFq vPlusU;
  final JubJubNativeFq vMinusU;
  final JubJubNativeFq t2d;

  JubJubAffineNielsNativePoint({
    required this.vPlusU,
    required this.vMinusU,
    required this.t2d,
  });
  factory JubJubAffineNielsNativePoint.identity() {
    return JubJubAffineNielsNativePoint(
      vPlusU: JubJubNativeFq.one(),
      vMinusU: JubJubNativeFq.one(),
      t2d: JubJubNativeFq.zero(),
    );
  }
  @override
  JubJubNativePoint operator *(JubJubNativeFr rhs) {
    return multiply(rhs.toBytes());
  }

  @override
  JubJubNielsNativePoint operator +(BaseRedJubJubPoint<JubJubNativeFr> rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubNielsNativePoint operator -(BaseRedJubJubPoint<JubJubNativeFr> rhs) {
    throw CryptoException.operationNotSupported;
  }

  @override
  List<int> toBytes() {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubAffineNielsNativePoint toNiels() {
    return this;
  }

  @override
  JubJubNielsNativePoint operator -() {
    throw CryptoException.operationNotSupported;
  }

  @override
  JubJubNativePoint multiply(List<int> by) {
    assert(by.length == 32);
    final zero = JubJubAffineNielsNativePoint.identity();
    JubJubNativePoint acc = JubJubNativePoint.identity();
    final bits = BytesUtils.bytesToBits(by);
    final iterableBits = bits.reversed.skip(4);
    for (final bit in iterableBits) {
      acc = acc.double();
      acc += bit ? this : zero;
    }
    return acc;
  }

  @override
  List<dynamic> get variables => [vMinusU, vPlusU, t2d];
}
