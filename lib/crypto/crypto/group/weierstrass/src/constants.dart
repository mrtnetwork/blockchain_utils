import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

class Secp256k1FpConst {
  static const int s = 1;
  static const Uint64 inv = Uint64.unsafe(3627551005, 3525653809);
  static const List<Uint64> modulusLimbs = [
    Uint64.unsafe(4294967294, 4294966319),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(4294967295, 4294967295),
  ];
}

class Secp256k1FrConst {
  static const int s = 6;
  static const Uint64 inv = Uint64.unsafe(1259208550, 1435021631);
  static const List<Uint64> modulusLimbs = [
    Uint64.unsafe(3218235020, 3493216577),
    Uint64.unsafe(3132021990, 2940772411),
    Uint64.unsafe(4294967295, 4294967294),
    Uint64.unsafe(4294967295, 4294967295),
  ];
}

class Secp256r1FpConst {
  static const int s = 1;
  static const Uint64 inv = Uint64.unsafe(0, 1);
  static const List<Uint64> modulusLimbs = [
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(0, 4294967295),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(4294967295, 1),
  ];
}

class Secp256r1FrConst {
  static const int s = 4;
  static const Uint64 inv = Uint64.unsafe(3436300458, 3993025615);
  static const List<Uint64> modulusLimbs = [
    Uint64.unsafe(4089039554, 4234356049),
    Uint64.unsafe(3169254061, 2803342980),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(4294967295, 0),
  ];
}
