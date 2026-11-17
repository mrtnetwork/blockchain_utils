import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

class Ed25519FpConst {
  static const int s = 2;
  static const Uint64 inv = Uint64.unsafe(2260509103, 678152731);
  static const List<Uint64> modulusLimbs = [
    Uint64.unsafe(4294967295, 4294967277),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(4294967295, 4294967295),
    Uint64.unsafe(2147483647, 4294967295),
  ];
}

class Ed25519FrConst {
  static const int s = 2;
  static const Uint64 inv = Uint64.unsafe(3535084963, 307527195);
  static const List<Uint64> modulusLimbs = [
    Uint64.unsafe(1477600026, 1559614445),
    Uint64.unsafe(350157278, 2734136534),
    Uint64.unsafe(0, 0),
    Uint64.unsafe(268435456, 0),
  ];
}
