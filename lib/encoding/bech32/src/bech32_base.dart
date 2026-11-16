/// Standard Bech32 / Bech32m checksum, encoder, and decoder.
///
library;

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/encoding/bech32/src/bech32_utils.dart';

enum Bech32Encodings { bech32, bech32m }

class Bech32Const {
  static const String separator = '1';
  static const int checksumStrLen = 6;
  static const Map<Bech32Encodings, int> encodingChecksumConst = {
    Bech32Encodings.bech32: 1,
    Bech32Encodings.bech32m: 0x2bc830a3,
  };
}

class Bech32Utils {
  static const List<int> _generator = [
    0x3b6a57b2,
    0x26508e6d,
    0x1ea119fa,
    0x3d4233dd,
    0x2a1462b3,
  ];

  /// The BIP-173/BIP-350 checksum polynomial modulus.
  static int polyMod(List<int> values) {
    var chk = 1;
    for (final value in values) {
      final top = chk >> 25;
      chk = ((chk & 0x1ffffff) << 5) ^ value;
      for (var i = 0; i < 5; i++) {
        if ((top >> i) & 1 != 0) chk ^= _generator[i];
      }
    }
    return chk;
  }

  /// Expands the human-readable part into the values the checksum is
  /// computed over, per spec: high bits of every character, a zero
  /// separator, then low bits of every character.
  static List<int> hrpExpand(String hrp) {
    final expand = List<int>.filled(hrp.length * 2 + 1, 0);
    for (var i = 0; i < hrp.length; i++) {
      expand[i] = hrp.codeUnitAt(i) >> 5;
    }
    // expand[hrp.length] stays 0 - the separator.
    for (var i = 0; i < hrp.length; i++) {
      expand[hrp.length + 1 + i] = hrp.codeUnitAt(i) & 0x1f;
    }
    return expand;
  }

  static List<int> computeChecksum(
    String hrp,
    List<int> data, [
    Bech32Encodings encoding = Bech32Encodings.bech32,
  ]) {
    final values = [...hrpExpand(hrp), ...data, 0, 0, 0, 0, 0, 0];
    final polymod =
        polyMod(values) ^ Bech32Const.encodingChecksumConst[encoding]!;
    return [
      for (var i = 0; i < Bech32Const.checksumStrLen; i++)
        (polymod >> (5 * (5 - i))) & 0x1f,
    ];
  }

  static bool verifyChecksum(
    String hrp,
    List<int> data, [
    Bech32Encodings encoding = Bech32Encodings.bech32,
  ]) {
    final polymod = polyMod([...hrpExpand(hrp), ...data]);
    return polymod == Bech32Const.encodingChecksumConst[encoding];
  }
}

class Bech32Encoder extends Bech32EncoderBase {
  static String encode(
    String hrp,
    List<int> bytes, {
    Bech32Encodings encoding = Bech32Encodings.bech32,
  }) {
    return Bech32EncoderBase.encodeBech32(
      hrp,
      Bech32BaseUtils.convertToBase32(bytes),
      Bech32Const.separator,
      (hrp, data) => Bech32Utils.computeChecksum(hrp, data, encoding),
    );
  }
}

class Bech32Decoder extends Bech32DecoderBase {
  static BuBytes decode(
    String? hrp,
    String address, {
    Bech32Encodings encoding = Bech32Encodings.bech32,
  }) {
    final decoded = Bech32DecoderBase.decodeBech32(
      address,
      Bech32Const.separator,
      Bech32Const.checksumStrLen,
      (hrp, data) => Bech32Utils.verifyChecksum(hrp, data, encoding),
    );
    if (hrp != decoded.$1) {
      throw BuError(DefaultErrorType.badBech32,
        'Incorrect bech32 hrp.',
        details: {'expected': hrp, 'hrp': decoded.$1},
      );
    }
    return Bech32BaseUtils.convertFromBase32(decoded.$2);
  }

  static (String, BuBytes) decodeWithoutHRP(
    String address, {
    Bech32Encodings encoding = Bech32Encodings.bech32,
  }) {
    final decoded = Bech32DecoderBase.decodeBech32(
      address,
      Bech32Const.separator,
      Bech32Const.checksumStrLen,
      (hrp, data) => Bech32Utils.verifyChecksum(hrp, data, encoding),
    );
    return (decoded.$1, Bech32BaseUtils.convertFromBase32(decoded.$2));
  }
}
