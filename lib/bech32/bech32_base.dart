import 'package:blockchain_utils/utils/utils.dart';

import 'bech32_utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// An enumeration representing different Bech32 encodings.
enum Bech32Encodings {
  /// The standard Bech32 encoding.
  bech32,

  /// The Bech32m encoding, an improved and more error-resistant variant.
  bech32m,
}

/// A utility class containing constants and configurations for Bech32 encoding.
class Bech32Const {
  /// The separator character used in Bech32 encoded strings.
  static const String separator = '1';

  /// The length of the checksum part in a Bech32 encoded string.
  static const int checksumStrLen = 6;

  /// A map associating each Bech32 encoding with its corresponding checksum constant.
  static const Map<Bech32Encodings, int> encodingChecksumConst = {
    Bech32Encodings.bech32: 1,
    Bech32Encodings.bech32m: 0x2bc830a3,
  };
}

/// A utility class containing methods for converting data to and from bech32 encoding.
class Bech32Utils {
  /// Computes the polynomial modulus.
  static int polyMod(List<int> values) {
    // Generator polynomial
    final generator = [
      0x3b6a57b2,
      0x26508e6d,
      0x1ea119fa,
      0x3d4233dd,
      0x2a1462b3
    ];

    // Compute modulus
    var chk = 1;
    for (final value in values) {
      final top = chk >> 25;
      chk = (chk & 0x1ffffff) << 5 ^ value;
      for (var i = 0; i < 5; i++) {
        chk ^= (top >> i) & 1 != 0 ? generator[i] : 0;
      }
    }
    return chk;
  }

  /// Expand the HRP into values for checksum computation.
  static List<int> hrpExpand(String hrp) {
    final List<int> expand = [];
    for (int i = 0; i < hrp.length; i++) {
      final codeUnit = hrp.codeUnitAt(i);
      expand.add(codeUnit >> 5);
    }
    expand.add(0);
    for (int i = 0; i < hrp.length; i++) {
      final codeUnit = hrp.codeUnitAt(i);
      expand.add(codeUnit & 0x1f);
    }
    return expand;
  }

  /// Compute the checksum from the specified HRP and data.
  static List<int> computeChecksum(String hrp, List<int> data,
      [Bech32Encodings encoding = Bech32Encodings.bech32]) {
    final values = [...hrpExpand(hrp), ...data];
    final polymod = (polyMod([...values, 0, 0, 0, 0, 0, 0]) ^
        Bech32Const.encodingChecksumConst[encoding]!);

    return List<int>.from([
      for (var i = 0; i < Bech32Const.checksumStrLen; i++)
        (polymod >> (5 * (5 - i))) & 0x1f
    ]);
  }

  /// Verify the checksum from the specified HRP and converted data characters.
  static bool verifyChecksum(String hrp, List<int> data,
      [Bech32Encodings encoding = Bech32Encodings.bech32]) {
    final polymod = polyMod([...hrpExpand(hrp), ...data]);
    return polymod == Bech32Const.encodingChecksumConst[encoding];
  }
}

/// A class for encoding data into Bech32 format using the standard Bech32 encoding.
class Bech32Encoder extends Bech32EncoderBase {
  /// Encodes data with a Human-Readable Part (HRP) into a Bech32 string.
  ///
  /// This method takes an HRP and a byte array and encodes them into a Bech32
  /// string using the standard Bech32 encoding.
  ///
  /// - [hrp]: The Human-Readable Part (prefix) of the Bech32 string.
  /// - [bytes]: The byte array to encode.
  ///
  /// Returns the encoded Bech32 string.
  static String encode(String hrp, List<int> bytes) {
    return Bech32EncoderBase.encodeBech32(
        hrp,
        Bech32BaseUtils.convertToBase32(bytes),
        Bech32Const.separator,
        Bech32Utils.computeChecksum);
  }
}

/// A class for decoding Bech32-encoded strings using the standard Bech32 decoding.
class Bech32Decoder extends Bech32DecoderBase {
  /// Decodes a Bech32-encoded address into a byte array.
  ///
  /// This method takes a Human-Readable Part (HRP) and a Bech32-encoded address
  /// and decodes them into a byte array using the standard Bech32 decoding.
  ///
  /// - [hrp]: The expected Human-Readable Part (prefix) of the address.
  /// - [address]: The Bech32-encoded address to decode.
  ///
  /// Returns the decoded byte array.
  ///
  /// Throws an ArgumentException if the decoding fails or if the HRP doesn't match.
  static List<int> decode(String? hrp, String address) {
    final decode = Bech32DecoderBase.decodeBech32(
        address,
        Bech32Const.separator,
        Bech32Const.checksumStrLen,
        Bech32Utils.verifyChecksum);
    if (hrp != decode.item1) {
      throw ArgumentException(
          "Invalid format (HRP not valid, expected {$hrp}, got {${decode.item1}})");
    }
    final result = Bech32BaseUtils.convertFromBase32(decode.item2);
    return result;
  }

  static Tuple<String, List<int>> decodeWithoutHRP(String address) {
    final decode = Bech32DecoderBase.decodeBech32(
        address,
        Bech32Const.separator,
        Bech32Const.checksumStrLen,
        Bech32Utils.verifyChecksum);
    final result = Bech32BaseUtils.convertFromBase32(decode.item2);
    return Tuple(decode.item1, result);
  }
}
