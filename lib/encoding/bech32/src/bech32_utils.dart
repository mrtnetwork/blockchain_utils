/// Bech32 bit-packing (8-bit bytes <-> 5-bit groups), string framing
/// (hrp + separator + data + checksum), and the shared encode/decode
/// scaffolding both the standard Bech32 and BCH/SegWit variants build on.
///
/// The character <-> 5-bit-value lookup is a single `const` array indexed
/// directly by code unit, computed once at compile time - not a per
/// character `charset.indexOf(...)`/`charset.contains(...)` scan (which,
/// on top of being O(32) per character, also allocated a fresh 1-character
/// String for every character just to do the lookup).
library;

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/utils/string/string.dart';

/// Constants for Bech32 encoding/decoding.
class Bech32BaseConst {
  static const String charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";

  /// charset[i] -> i, indexed directly by ASCII code unit. -1 means "not a
  /// valid Bech32 character". Sized to 128 (charset is ASCII-only, max
  /// code unit 122 for 'z'), so any code unit >= 128 is rejected by a
  /// simple range check before ever touching this table.
  static const List<int> reverseCharset = [
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    15,
    -1,
    10,
    17,
    21,
    20,
    26,
    30,
    7,
    5,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    29,
    -1,
    24,
    13,
    25,
    9,
    8,
    23,
    -1,
    18,
    22,
    31,
    27,
    19,
    -1,
    1,
    0,
    3,
    16,
    11,
    28,
    12,
    14,
    6,
    4,
    2,
    -1,
    -1,
    -1,
    -1,
    -1,
  ];

  /// Value (0..31) for [charCode], or -1 if it isn't a valid Bech32
  /// character.
  static int valueOf(int charCode) =>
      charCode < reverseCharset.length ? reverseCharset[charCode] : -1;
}

/// Bit-packing between 8-bit bytes and Bech32's 5-bit groups.
class Bech32BaseUtils {
  static List<int> convertToBase32(List<int> data) {
    return _convertBits(data, 8, 5, pad: true);
  }

  static BuBytes convertFromBase32(List<int> data) {
    return _convertBits(data, 5, 8, pad: false);
  }

  static BuBytes _convertBits(
    List<int> data,
    int fromBits,
    int toBits, {
    required bool pad,
  }) {
    final maxOutVal = (1 << toBits) - 1;
    final maxAcc = (1 << (fromBits + toBits - 1)) - 1;

    var acc = 0;
    var bits = 0;
    final ret = BuBytes.empty();

    for (final value in data) {
      if (value < 0 || (value >> fromBits) != 0) {
        throw BuError(DefaultErrorType.badBech32,
          'Invalid bech32 data.',
          details: {'reason': 'value $value does not fit in $fromBits bits'},
        );
      }
      acc = ((acc << fromBits) | value) & maxAcc;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        ret.add((acc >> bits) & maxOutVal);
      }
    }

    if (pad) {
      if (bits > 0) {
        ret.add((acc << (toBits - bits)) & maxOutVal);
      }
    } else if (bits >= fromBits ||
        ((acc << (toBits - bits)) & maxOutVal) != 0) {
      throw const BuError(DefaultErrorType.badBech32,
        'Invalid bech32 data.',
        details: {'reason': 'incomplete group or non-zero padding bits'},
      );
    }

    return ret;
  }
}

/// Shared string framing: `hrp` + separator + data-as-charset-chars +
/// checksum-as-charset-chars.
abstract class Bech32EncoderBase {
  static String encodeBech32(
    String hrp,
    List<int> data,
    String sep,
    List<int> Function(String hrp, List<int> data) computeChecksum,
  ) {
    final checksum = computeChecksum(hrp, data);
    final combined = [...data, ...checksum];

    final out = StringBuffer(hrp)..write(sep);
    for (final value in combined) {
      out.writeCharCode(Bech32BaseConst.charset.codeUnitAt(value));
    }
    return out.toString();
  }
}

abstract class Bech32DecoderBase {
  static (String, List<int>) decodeBech32(
    String bechStr,
    String sep,
    int checksumLen,
    bool Function(String hrp, List<int> data) verifyChecksum,
  ) {
    if (_isStringMixedCase(bechStr)) {
      throw const BuError(DefaultErrorType.badBech32,
        'Invalid bech32 format.',
        details: {'reason': 'mixed uppercase and lowercase characters'},
      );
    }

    bechStr = bechStr.toLowerCase();

    final sepPos = bechStr.lastIndexOf(sep);
    if (sepPos == -1) {
      throw BuError(DefaultErrorType.badBech32,
        'Invalid bech32 format.',
        details: {'reason': 'missing separator "$sep"'},
      );
    }

    final hrp = bechStr.substring(0, sepPos);
    if (hrp.isEmpty || StringUtils.encode(hrp).any((x) => x < 33 || x > 126)) {
      throw const BuError(DefaultErrorType.badBech32,
        'Invalid bech32 format.',
        details: {'reason': 'empty or invalid human-readable part'},
      );
    }

    final dataPart = bechStr.substring(sepPos + 1);
    // Exactly checksumLen characters (zero-length payload, pure checksum)
    // is the minimum valid length - e.g. the official BIP-173 minimal
    // test vector "A12UEL5L" has a 6-character data part with
    // checksumStrLen == 6. The original required checksumLen + 1 here,
    // which would incorrectly reject that vector.
    if (dataPart.length < checksumLen) {
      throw const BuError(DefaultErrorType.invalidChecksum,
        'Invalid bech32 format.',
        details: {'reason': 'data part shorter than the checksum length'},
      );
    }

    // Single pass: validates every character AND looks up its value at
    // the same time, instead of one .any()/.contains() scan (each
    // re-scanning the 32-char charset per input character, and each
    // allocating a fresh 1-char String to do so) followed by a second
    // .indexOf() pass to actually get the values.
    final intData = List<int>.filled(dataPart.length, 0);
    for (var i = 0; i < dataPart.length; i++) {
      final value = Bech32BaseConst.valueOf(dataPart.codeUnitAt(i));
      if (value == -1) {
        throw BuError(DefaultErrorType.badBech32,
          'Invalid bech32 format.',
          details: {'reason': 'invalid character at index $i'},
        );
      }
      intData[i] = value;
    }

    if (!verifyChecksum(hrp, intData)) {
      throw const BuError(DefaultErrorType.invalidChecksum,
        'Invalid checksum.',
        details: {'reason': 'checksum verification failed'},
      );
    }

    return (hrp, intData.sublist(0, intData.length - checksumLen));
  }

  /// True if [str] contains both an uppercase and a lowercase letter -
  /// Bech32 requires a string to be entirely one case or the other.
  /// A single pass over code units, rather than two separate RegExp scans.
  static bool _isStringMixedCase(String str) {
    var sawLower = false;
    var sawUpper = false;
    for (var i = 0; i < str.length; i++) {
      final c = str.codeUnitAt(i);
      if (c >= 0x61 && c <= 0x7A) {
        sawLower = true;
      } else if (c >= 0x41 && c <= 0x5A) {
        sawUpper = true;
      }
      if (sawLower && sawUpper) return true;
    }
    return false;
  }
}
