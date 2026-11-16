/// Monero's block-based variant of Base58.
///
/// Standard Base58 (see base58_base.dart) can't be applied to a long byte
/// string directly and safely, because how many characters a given value
/// encodes to isn't fixed - it depends on the value's magnitude, not just
/// its byte length. Monero addresses need a *fixed* character count for a
/// given byte count, so instead it splits the data into 8-byte blocks,
/// Base58-encodes each block on its own, and left-pads each block's
/// output up to a block-size-specific fixed width. A final partial block
/// (< 8 bytes) is encoded the same way, padded to a shorter fixed width
/// looked up from [Base58XmrConst.blockEncByteLens].
library;

import 'package:blockchain_utils/encoding/base58/base58.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Block sizing constants for Monero's Base58 variant.
class Base58XmrConst {
  /// Monero always uses the standard Bitcoin Base58 alphabet.
  static String get alphabet => Base58Alphabets.bitcoin.alphabet;

  /// Every full input block is this many raw bytes...
  static const int blockDecMaxByteLen = 8;

  /// ...which always encodes to exactly this many Base58 characters.
  static const int blockEncMaxByteLen = 11;

  /// For a final partial block of N raw bytes (N = index into this list,
  /// 0..8), this is the fixed number of Base58 characters it's padded to.
  /// Mandated by the Monero protocol - not derivable from a formula, so
  /// it's just a lookup table.
  static const List<int> blockEncByteLens = [0, 2, 3, 5, 6, 7, 9, 10, 11];
}

/// Encodes bytes using Monero's block-based Base58 variant.
class Base58XmrEncoder {
  /// Encodes [dataBytes] the way Monero encodes addresses and keys.
  static String encode(List<int> dataBytes) {
    dataBytes = dataBytes.asImmutableBytes;
    const blockSize = Base58XmrConst.blockDecMaxByteLen;

    final fullBlockCount = dataBytes.length ~/ blockSize;
    final finalBlockLen = dataBytes.length % blockSize;

    final out = StringBuffer();
    for (var i = 0; i < fullBlockCount; i++) {
      final block = dataBytes.sublist(i * blockSize, (i + 1) * blockSize);
      out.write(
        _padLeft(
          Base58Encoder.encode(block),
          Base58XmrConst.blockEncMaxByteLen,
        ),
      );
    }

    if (finalBlockLen > 0) {
      final block = dataBytes.sublist(
        fullBlockCount * blockSize,
        dataBytes.length,
      );
      final targetLen = Base58XmrConst.blockEncByteLens[finalBlockLen];
      out.write(_padLeft(Base58Encoder.encode(block), targetLen));
    }

    return out.toString();
  }

  static String _padLeft(String encoded, int targetLen) {
    return encoded.padLeft(targetLen, Base58XmrConst.alphabet[0]);
  }
}

/// Decodes strings produced by [Base58XmrEncoder].
class Base58XmrDecoder {
  /// Decodes a Monero-style Base58 string back to raw bytes.
  ///
  /// Throws [Base58FormatError] for characters outside the Bitcoin alphabet
  /// or for a total length whose final-block residue isn't a valid Monero
  /// block width (valid residues: 0, 2, 3, 5, 6, 7, 9, 10 - so 1, 4 and 8
  /// can never occur in a well-formed string).
  static BuBytes decode(String data) {
    const blockCharLen = Base58XmrConst.blockEncMaxByteLen;
    const blockByteLen = Base58XmrConst.blockDecMaxByteLen;

    final fullBlockCount = data.length ~/ blockCharLen;
    final finalBlockCharLen = data.length % blockCharLen;
    final finalBlockByteLen = Base58XmrConst.blockEncByteLens.indexOf(
      finalBlockCharLen,
    );
    if (finalBlockByteLen < 0) {
      throw BuError(DefaultErrorType.invalidLength, "Invalid Monero Base58 string.",
        details: {
          "reason": 'Invalid Monero Base58 length residue $finalBlockCharLen.',
        },
      );
    }

    final out = <int>[];
    for (var i = 0; i < fullBlockCount; i++) {
      final chunk = data.substring(i * blockCharLen, (i + 1) * blockCharLen);
      out.addAll(_stripPadding(Base58Decoder.decode(chunk), blockByteLen));
    }

    if (finalBlockCharLen > 0) {
      final chunk = data.substring(fullBlockCount * blockCharLen, data.length);
      out.addAll(_stripPadding(Base58Decoder.decode(chunk), finalBlockByteLen));
    }

    return BuBytes(out);
  }

  /// [Base58Decoder.decode] can't distinguish "padding-only" leading
  /// alphabet[0] characters (added by [Base58XmrEncoder]'s [_padLeft] just
  /// to hit the fixed block width) from a genuine leading zero *byte* in
  /// the original block - it treats every leading alphabet[0] character
  /// as the latter. So a decoded block can come back longer than the
  /// block's real byte width, with spurious zero bytes stacked on the
  /// front; trim those off by keeping only the last [targetLen] bytes.
  /// (The shorter-than-targetLen branch below is just a defensive
  /// fallback - it shouldn't be reachable for well-formed input, since
  /// the padding widths in [Base58XmrConst.blockEncByteLens] are sized to
  /// always decode to at least the full block width.)
  static BuBytes _stripPadding(List<int> decodedBlock, int targetLen) {
    if (decodedBlock.length >= targetLen) {
      return BuBytes(decodedBlock.sublist(decodedBlock.length - targetLen));
    }
    return BuBytes([
      ...List<int>.filled(targetLen - decodedBlock.length, 0),
      ...decodedBlock,
    ]);
  }
}
