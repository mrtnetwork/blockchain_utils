import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

/// Block cipher padding schemes.
enum PaddingAlgorithm {
  /// PKCS#7: every padding byte holds the padding length.
  pkcs7,

  /// ISO/IEC 7816-4: a 0x80 marker byte followed by zeros.
  iso7816,

  /// ANSI X9.23: zeros, with the final byte holding the padding length.
  x923;

  BuPaddingAlgorithm get connectorAlgorithm => switch (this) {
    PaddingAlgorithm.pkcs7 => BuPaddingAlgorithm.pkcs7,
    PaddingAlgorithm.iso7816 => BuPaddingAlgorithm.iso7816,
    PaddingAlgorithm.x923 => BuPaddingAlgorithm.x923,
  };
}

/// Adds and removes block cipher padding. See the library comment above
/// for why [unpad] is written the way it is.
class BlockCipherPadding {
  /// Pads [dataToPad] out to a multiple of [blockSize] using [style].
  static BuBytes pad(
    List<int> dataToPad,
    int blockSize, {
    PaddingAlgorithm style = PaddingAlgorithm.pkcs7,
  }) {
    final paddingLen = blockSize - dataToPad.length % blockSize;
    final padding = BuBytes.fill(paddingLen, 0);

    switch (style) {
      case PaddingAlgorithm.pkcs7:
        for (var i = 0; i < paddingLen; i++) {
          padding[i] = paddingLen;
        }
        break;
      case PaddingAlgorithm.x923:
        padding[paddingLen - 1] = paddingLen;
        break;
      case PaddingAlgorithm.iso7816:
        padding[0] = 0x80;
        break;
    }

    final result = BuBytes.fill(dataToPad.length + paddingLen, 0);
    result.setAll(0, dataToPad);
    result.setAll(dataToPad.length, padding);
    return result;
  }

  /// Returns 1 if `a == b`, else 0 - see the equivalent, exhaustively
  /// verified helper in `aes_lib.dart` (`_ctByteEqMask`) for why this
  /// specific arithmetic shape (small, always-non-negative values only)
  /// is used instead of a shift/mask trick that relies on negative-number
  /// or wide-value shift semantics.
  static int _ctByteEq(int a, int b) {
    var folded = a ^ b;
    folded |= folded >> 4;
    folded |= folded >> 2;
    folded |= folded >> 1;
    return 1 - (folded & 1);
  }

  /// Checks every candidate padding length `1..blockSize` (the loop
  /// counter itself is public, so branching/looping on *it* is fine -
  /// what must stay secret-independent is which byte *values* get
  /// compared, via [_ctByteEq] rather than `!=`), returning the
  /// (paddingLen, isValid) for whichever candidate matches - or `(0,
  /// false)` if none do. [validateLen] computes, for one candidate
  /// length, whether the trailing bytes look like valid padding of
  /// exactly that length; it must do the same amount of work (same
  /// number of [_ctByteEq] calls) for every candidate, which is why it
  /// takes the candidate length as a parameter rather than reading it
  /// from data itself.
  static (int, bool) _selectValidLength(
    int blockSize,
    int Function(int candidateLen) validateLen,
  ) {
    var anyMatch = 0;
    var selected = 0;
    for (var candidateLen = 1; candidateLen <= blockSize; candidateLen++) {
      final matches = validateLen(candidateLen);
      final take = matches & (1 - anyMatch);
      selected += take * candidateLen;
      anyMatch |= matches;
    }
    return (selected, anyMatch == 1);
  }

  /// Removes [style] padding from [paddedData].
  ///
  /// Throws [CryptoException] if [paddedData] is empty, isn't a multiple
  /// of [blockSize], or doesn't end in valid padding.
  static BuBytes unpad(
    List<int> paddedData,
    int blockSize, {
    PaddingAlgorithm style = PaddingAlgorithm.pkcs7,
  }) {
    final n = paddedData.length;

    // These two checks are on PUBLIC information (the ciphertext's own
    // length, and the block size) - not the secret padding content - so
    // branching on them doesn't leak anything about the plaintext.
    if (n == 0) {
      throw CoreErrors.cryptoFailed(
        'unpad',
        reason: "Zero-length input cannot be unpadded.",
      );
    }
    if (n % blockSize != 0) {
      throw CoreErrors.cryptoFailed(
        "unpad",
        reason: "Input data is not padded.",
      );
    }

    final (int paddingLen, bool ok) result;
    switch (style) {
      case PaddingAlgorithm.pkcs7:
        final claimed = paddedData[n - 1];
        result = _selectValidLength(blockSize, (candidateLen) {
          var valid = 1;
          for (var i = 0; i < candidateLen; i++) {
            valid &= _ctByteEq(paddedData[n - 1 - i], candidateLen);
          }
          return valid & _ctByteEq(claimed, candidateLen);
        });
        break;

      case PaddingAlgorithm.x923:
        result = _selectValidLength(blockSize, (candidateLen) {
          var valid = _ctByteEq(paddedData[n - 1], candidateLen);
          for (var i = 1; i < candidateLen; i++) {
            valid &= _ctByteEq(paddedData[n - 1 - i], 0);
          }
          return valid;
        });
        break;

      case PaddingAlgorithm.iso7816:
        result = _selectValidLength(blockSize, (candidateLen) {
          final firstPadPos = n - candidateLen;
          var valid = _ctByteEq(paddedData[firstPadPos], 0x80);
          for (var i = 1; i < candidateLen; i++) {
            valid &= _ctByteEq(paddedData[firstPadPos + i], 0);
          }
          return valid;
        });
        break;
    }

    if (!result.$2) {
      throw CoreErrors.cryptoFailed("unpad", reason: "Incorrect padding.");
    }
    return BuBytes(paddedData.sublist(0, n - result.$1));
  }
}
