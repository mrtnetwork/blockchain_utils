import 'package:blockchain_utils/numbers/src/i128.dart';
import 'package:blockchain_utils/numbers/src/u128.dart';

class MutableUint128 {
  Uint128 _r = Uint128.zero;
  Uint128 get r => _r;
  void assign(Uint128 r) {
    _r = r;
  }

  @override
  String toString() {
    return r.toString();
  }
}

class MutableInt128 {
  Int128 _r = Int128.zero;
  Int128 get r => _r;

  @override
  String toString() {
    return r.toString();
  }

  void assign(Int128 r) {
    _r = r;
  }
}
