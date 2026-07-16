import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/i64.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

abstract class BaseSecp256k1ModinvSigned extends Iterable<Int64> with Equality {
  abstract final List<Int64> limbs;
  const BaseSecp256k1ModinvSigned();
  Secp256k1ModinvSigned clone();

  @override
  List<dynamic> get variables => limbs;
  @override
  Iterator<Int64> get iterator => limbs.iterator;
}

class Secp256k1ModinvSignedConst extends BaseSecp256k1ModinvSigned {
  @override
  final List<Int64> limbs;
  const Secp256k1ModinvSignedConst(this.limbs);

  @override
  Secp256k1ModinvSigned clone() {
    return Secp256k1ModinvSigned(v: limbs.clone());
  }
}

class Secp256k1ModinvSigned extends BaseSecp256k1ModinvSigned {
  List<Int64> _limbs;
  factory Secp256k1ModinvSigned({List<Int64>? v}) {
    if (v != null && v.length != 5) {
      throw CryptoException(
        "Invalid modinv length: expected 5 Int64 values, but received ${v.length}.",
      );
    }
    return Secp256k1ModinvSigned._(v: v);
  }
  Secp256k1ModinvSigned._({List<Int64>? v})
    : _limbs = v ?? List<Int64>.filled(5, Int64.zero);
  @override
  Secp256k1ModinvSigned clone() {
    return Secp256k1ModinvSigned._(v: limbs.clone());
  }

  Int64 operator [](int index) => _limbs[index];

  void operator []=(int index, Int64 value) {
    _limbs[index] = value;
  }

  void set(BaseSecp256k1ModinvSigned other) {
    _limbs = other.limbs.clone();
  }

  @override
  List<Int64> get limbs => _limbs;
}

abstract class BaseSecp256k1ModinvInfo<B extends BaseSecp256k1ModinvSigned>
    with Equality {
  final B modulus;
  final Uint64 modulusInv;
  const BaseSecp256k1ModinvInfo({
    required this.modulus,
    required this.modulusInv,
  });

  @override
  List<dynamic> get variables => [modulus, modulusInv];
}

class Secp256k1ModinvInfo
    extends BaseSecp256k1ModinvInfo<Secp256k1ModinvSigned> {
  const Secp256k1ModinvInfo({
    required super.modulus,
    required super.modulusInv,
  });
}

class Secp256k1ModinvInfoConst
    extends BaseSecp256k1ModinvInfo<Secp256k1ModinvSignedConst> {
  const Secp256k1ModinvInfoConst({
    required super.modulus,
    required super.modulusInv,
  });

  Secp256k1ModinvInfo clone() =>
      Secp256k1ModinvInfo(modulus: modulus.clone(), modulusInv: modulusInv);
}

class Secp256k1ModinvTrans {
  Int64 _u = Int64.zero, _v = Int64.zero, _q = Int64.zero, _r = Int64.zero;
  Int64 get u => _u;
  Int64 get v => _v;
  Int64 get q => _q;
  Int64 get r => _r;

  void fillU64(Uint64 u, Uint64 v, Uint64 q, Uint64 r) {
    _u = u.toInt64();
    _v = v.toInt64();
    _q = q.toInt64();
    _r = r.toInt64();
  }
}
