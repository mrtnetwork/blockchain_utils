/// SegWit's Bech32 variant: a witness version byte prepended to the data,
/// bech32 checksum for version 0 and bech32m for every other version
/// (BIP-350).
library;

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/encoding/bech32/src/bech32_base.dart';
import 'package:blockchain_utils/encoding/bech32/src/bech32_utils.dart';

class SegwitBech32Const {
  static const separator = Bech32Const.separator;
  static const checksumStrLen = Bech32Const.checksumStrLen;
  static const witnessProgMinByteLen = 2;
  static const witnessProgMaxByteLen = 40;
  static const witnessVerBech32 = 0;
  static const witnessVerMaxVal = 16;
  static const witnessVerZeroDataByteLen = <int>[20, 32];
}

class SegwitBech32Encoder extends Bech32EncoderBase {
  static String encode(String hrp, int witVer, List<int> witProg) {
    if (witVer < SegwitBech32Const.witnessVerBech32 ||
        witVer > SegwitBech32Const.witnessVerMaxVal) {
      throw BuError(
        DefaultErrorType.invalidLength,
        'Invalid bech32 format.',
        details: {
          'reason':
              'witness version $witVer out of range 0..${SegwitBech32Const.witnessVerMaxVal}',
        },
      );
    }
    return Bech32EncoderBase.encodeBech32(
      hrp,
      [witVer, ...Bech32BaseUtils.convertToBase32(witProg)],
      SegwitBech32Const.separator,
      _computeChecksum,
    );
  }

  static List<int> _computeChecksum(String hrp, List<int> data) {
    final encoding =
        data[0] == SegwitBech32Const.witnessVerBech32
            ? Bech32Encodings.bech32
            : Bech32Encodings.bech32m;
    return Bech32Utils.computeChecksum(hrp, data, encoding);
  }
}

class SegwitBech32Decoder extends Bech32DecoderBase {
  static (int, BuBytes) decode(String? hrp, String addr) {
    final decoded = Bech32DecoderBase.decodeBech32(
      addr,
      SegwitBech32Const.separator,
      SegwitBech32Const.checksumStrLen,
      _verifyChecksum,
    );
    final hrpGot = decoded.$1;
    final data = decoded.$2;

    if (hrp != null && hrp != hrpGot) {
      throw BuError(
        DefaultErrorType.badBech32,
        'Incorrect bech32 hrp.',
        details: {'expected': hrp, 'hrp': hrpGot},
      );
    }

    if (data.isEmpty) {
      throw const BuError(
        DefaultErrorType.badBech32,
        'Invalid bech32 format.',
        details: {'reason': 'empty data payload'},
      );
    }
    final convData = Bech32BaseUtils.convertFromBase32(data.sublist(1));

    if (convData.length < SegwitBech32Const.witnessProgMinByteLen ||
        convData.length > SegwitBech32Const.witnessProgMaxByteLen) {
      throw BuError(
        DefaultErrorType.invalidLength,
        'Invalid bech32 format.',
        details: {
          'reason': 'witness program length ${convData.length} out of range',
        },
      );
    }

    final witVer = data[0];
    if (witVer > SegwitBech32Const.witnessVerMaxVal) {
      throw BuError(
        DefaultErrorType.invalidLength,
        'Invalid bech32 format.',
        details: {
          'reason':
              'witness version $witVer exceeds the maximum of ${SegwitBech32Const.witnessVerMaxVal}',
        },
      );
    }

    if (witVer == 0 &&
        !SegwitBech32Const.witnessVerZeroDataByteLen.contains(
          convData.length,
        )) {
      throw BuError(
        DefaultErrorType.invalidLength,
        'Invalid bech32 format.',
        details: {
          'reason':
              'witness version 0 requires a 20 or 32-byte program, got ${convData.length}',
        },
      );
    }

    return (witVer, BuBytes(convData));
  }

  static bool _verifyChecksum(String hrp, List<int> data) {
    final encoding =
        data[0] == SegwitBech32Const.witnessVerBech32
            ? Bech32Encodings.bech32
            : Bech32Encodings.bech32m;
    return Bech32Utils.verifyChecksum(hrp, data, encoding);
  }
}
