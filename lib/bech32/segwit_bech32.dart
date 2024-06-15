import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'bech32_base.dart';
import 'bech32_utils.dart';

/// A utility class containing constants used for segwit Bech32 encoding and decoding.
class SegwitBech32Const {
  /// Separator
  static const separator = Bech32Const.separator;

  /// Checksum length
  static const checksumStrLen = Bech32Const.checksumStrLen;

  /// Minimum witness program length in bytes
  static const witnessProgMinByteLen = 2;

  /// Maximum witness program length in bytes
  static const witnessProgMaxByteLen = 40;

  /// Witness version for Bech32 encoding
  static const witnessVerBech32 = 0;

  /// Witness version maximum value
  static const witnessVerMaxVal = 16;

  /// Accepted data lengths when witness version is zero
  static const witnessVerZeroDataByteLen = <int>[20, 32];
}

/// A class for encoding Segregated Witness (SegWit) addresses using Bech32 encoding.
class SegwitBech32Encoder extends Bech32EncoderBase {
  /// Encodes a Segregated Witness (SegWit) address using Bech32 encoding.
  ///
  /// This method takes a Human-Readable Part (HRP), a SegWit version, and a
  /// witness program. It encodes them into a Bech32-encoded SegWit address.
  ///
  /// - [hrp]: The Human-Readable Part (prefix) for the address.
  /// - [witVer]: The SegWit version.
  /// - [witProg]: The witness program bytes.
  ///
  /// Returns the Bech32-encoded SegWit address.
  static String encode(String hrp, int witVer, List<int> witProg) {
    return Bech32EncoderBase.encodeBech32(
        hrp,
        List<int>.from([witVer, ...Bech32BaseUtils.convertToBase32(witProg)]),
        SegwitBech32Const.separator,
        _computeChecksum);
  }

  /// Computes the checksum for SegWit Bech32 encoding.
  ///
  /// This method computes the checksum for SegWit Bech32 encoding based on the
  /// provided Human-Readable Part (HRP) and encoded data. It determines the
  /// encoding (bech32 or bech32m) based on the SegWit version and returns the
  /// computed checksum.
  ///
  /// - [hrp]: The Human-Readable Part (HRP) for the address.
  /// - [data]: The encoded data.
  ///
  /// Returns the computed checksum as a list of integers.
  static List<int> _computeChecksum(String hrp, List<int> data) {
    final encoding = data[0] == SegwitBech32Const.witnessVerBech32
        ? Bech32Encodings.bech32
        : Bech32Encodings.bech32m;
    return Bech32Utils.computeChecksum(hrp, data, encoding);
  }
}

/// A class for decoding Segregated Witness (SegWit) addresses from Bech32 encoding.
class SegwitBech32Decoder extends Bech32DecoderBase {
  /// Decodes a Bech32-encoded SegWit address.
  ///
  /// This method decodes a Bech32-encoded SegWit address, verifying its format,
  /// Human-Readable Part (HRP), witness version, and witness program.
  ///
  /// - [hrp]: The expected Human-Readable Part (HRP) for the address.
  /// - [addr]: The Bech32-encoded SegWit address to decode.
  ///
  /// Returns a tuple containing the SegWit version (witness version) and the
  /// decoded witness program as a List<int>.
  static Tuple<int, List<int>> decode(String? hrp, String addr) {
    final decoded = Bech32DecoderBase.decodeBech32(
        addr,
        SegwitBech32Const.separator,
        SegwitBech32Const.checksumStrLen,
        _verifyChecksum);
    final hrpGot = decoded.item1;
    final data = decoded.item2;

    // Check HRP
    if (hrp != null && hrp != hrpGot) {
      throw ArgumentException(
          'Invalid format (HRP not valid, expected $hrp, got $hrpGot)');
    }

    // Convert back from base32 (remove witness version)
    final convData = Bech32BaseUtils.convertFromBase32(data.sublist(1));

    // Check data length
    if (convData.length < SegwitBech32Const.witnessProgMinByteLen ||
        convData.length > SegwitBech32Const.witnessProgMaxByteLen) {
      throw ArgumentException(
          'Invalid format (witness program length not valid: ${convData.length})');
    }

    // Check witness version
    final witVer = data[0];
    if (witVer > SegwitBech32Const.witnessVerMaxVal) {
      throw ArgumentException(
          'Invalid format (witness version not valid: $witVer)');
    }

    if (witVer == 0 &&
        !SegwitBech32Const.witnessVerZeroDataByteLen
            .contains(convData.length)) {
      throw ArgumentException(
          'Invalid format (length not valid: ${convData.length})');
    }

    return Tuple(witVer, convData);
  }

  static bool _verifyChecksum(String hrp, List<int> data) {
    final encoding = (data[0] == SegwitBech32Const.witnessVerBech32
        ? Bech32Encodings.bech32
        : Bech32Encodings.bech32m);

    return Bech32Utils.verifyChecksum(hrp, data, encoding);
  }
}
