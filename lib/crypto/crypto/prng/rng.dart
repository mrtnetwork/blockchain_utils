import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

abstract mixin class Rng implements Random {
  List<int> nextBytes(int length);

  int nextU32({Endian endian = Endian.little}) {
    final bytes = nextBytes(4);
    return IntUtils.fromBytes(bytes, byteOrder: endian);
  }

  BigInt nextU64({Endian endian = Endian.little}) {
    final bytes = nextBytes(8);
    return BigintUtils.fromBytes(bytes, byteOrder: endian);
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentException.invalidOperationArguments(
        "nextInt",
        name: "max",
        reason: "Max must be greater than 0",
      );
    }
    final double fraction = nextU32() / 4294967296.0;
    return (fraction * max).floor();
  }

  @override
  bool nextBool() {
    final n = nextInt(2);
    return n == 1 ? true : false;
  }

  int nextU8() {
    return nextBytes(1).first;
  }

  @override
  double nextDouble() {
    return nextU32() / 4294967296.0;
  }
}
