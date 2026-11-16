// Uint64 widening-multiply/divmod: native 64-bit ints on the VM, BigInt-backed on web.
export 'package:blockchain_utils/utils/numbers/fixed/src/u64/word_math/word_math_web.dart' if (dart.library.io) 'word_math_native.dart';
