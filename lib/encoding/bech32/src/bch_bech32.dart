/// Bitcoin Cash's Bech32 variant (CashAddr): a wider, ~40-bit checksum
/// polynomial and a `:` separator instead of `1`.
///
/// This needs [Uint64], not plain `int` - and that's not about the
/// double-precision 2^53 ceiling (40 bits is nowhere near that). The
/// problem is narrower and sharper: JavaScript's native bitwise operators
/// (`<<`, `>>`, `&`, `^`) all coerce their operands through ToInt32/
/// ToUint32 first, i.e. they only operate correctly within 32 bits. This
/// polynomial's `chk` value and mask both exceed 32 bits (`chk >> 35`,
/// mask `0x07ffffffff` is 35 bits), so on dart2js a plain-`int` version of
/// this shifts/ANDs past the 32-bit boundary and silently corrupts the
/// high bits - confirmed by an actual failing web test run (checksum came
/// back as effectively all-zero). [Uint64] keeps every limb genuinely
/// 32-bit and does bitwise ops per-limb (see its own `_safeShl32` doc
/// comment for the same class of problem), which is exactly what avoids
/// this.
library;

import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/encoding/bech32/src/bech32_utils.dart';

class BchBech32Const {
  static const String separator = ':';
  static const int checksumStrLen = 8;
}

class _BchBech32Utils {
  // (bit, generator-term) pairs, straight from the CashAddr spec, as
  // genuine compile-time constants via Uint64's const `.unsafe(hi, lo)`
  // constructor - no BigInt.from() calls rebuilding this table on every
  // single polyMod() call like the original did.
  static const List<(Uint64 bit, Uint64 term)> _generator = [
    (Uint64.unsafe(0x0, 0x1), Uint64.unsafe(0x98, 0xf2bc8e61)),
    (Uint64.unsafe(0x0, 0x2), Uint64.unsafe(0x79, 0xb76d99e2)),
    (Uint64.unsafe(0x0, 0x4), Uint64.unsafe(0xf3, 0x3e5fb3c4)),
    (Uint64.unsafe(0x0, 0x8), Uint64.unsafe(0xae, 0x2eabe2a8)),
    (Uint64.unsafe(0x0, 0x10), Uint64.unsafe(0x1e, 0x4f43e470)),
  ];
  static const Uint64 _mask = Uint64.unsafe(0x7, 0xffffffff);
  static const Uint64 _valueMask = Uint64.unsafe(0x0, 0x1f);

  static Uint64 polyMod(List<int> values) {
    var chk = Uint64.one;
    for (final value in values) {
      final top = chk >> 35;
      chk = ((chk & _mask) << 5) ^ Uint64.uncheckedU32(value);
      for (final (bit, term) in _generator) {
        if (!(top & bit).isZero) chk ^= term;
      }
    }
    return chk ^ Uint64.one;
  }

  static List<int> hrpExpand(String hrp) {
    final expanded = List<int>.filled(hrp.length + 1, 0);
    var i = 0;
    for (final rune in hrp.runes) {
      expanded[i++] = rune & 0x1f;
    }
    // expanded[hrp.length] stays 0.
    return expanded;
  }

  static List<int> computeChecksum(String hrp, List<int> data) {
    final values = [...hrpExpand(hrp), ...data, 0, 0, 0, 0, 0, 0, 0, 0];
    final polymod = polyMod(values);
    return List<int>.generate(
      BchBech32Const.checksumStrLen,
      (i) => ((polymod >> (5 * (7 - i))) & _valueMask).toInt(),
    );
  }

  static bool verifyChecksum(String hrp, List<int> data) {
    return polyMod([...hrpExpand(hrp), ...data]).isZero;
  }
}

class BchBech32Encoder extends Bech32EncoderBase {
  static String encode(String hrp, List<int> netVar, List<int> data) {
    return Bech32EncoderBase.encodeBech32(
      hrp,
      Bech32BaseUtils.convertToBase32([...netVar, ...data]),
      BchBech32Const.separator,
      _BchBech32Utils.computeChecksum,
    );
  }
}

class BchBech32Decoder extends Bech32DecoderBase {
  static (BuBytes, BuBytes) decode(String? hrp, String address) {
    final decoded = Bech32DecoderBase.decodeBech32(
      address,
      BchBech32Const.separator,
      BchBech32Const.checksumStrLen,
      _BchBech32Utils.verifyChecksum,
    );
    if (hrp != null && decoded.$1 != hrp) {
      throw BuError(
        DefaultErrorType.badBech32,
        'Incorrect bech32 hrp.',
        details: {'expected': hrp, 'hrp': decoded.$1},
      );
    }
    final convData = Bech32BaseUtils.convertFromBase32(decoded.$2);
    if (convData.isEmpty) {
      throw const BuError(
        DefaultErrorType.badBech32,
        'Invalid bech32 format.',
        details: {'reason': 'empty data payload'},
      );
    }
    final ver = convData[0];
    return (ver.toLeBytes(), convData.sublist(1));
  }
}
