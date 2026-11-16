/// SS58 address encoding/decoding - the address format used by Substrate
/// and Substrate-based chains (Polkadot, Kusama, etc.): a network/format
/// identifier byte (or two), the raw account bytes, and a Blake2b-derived
/// checksum, all wrapped in Base58.
library;

import 'package:blockchain_utils/encoding/base58/src/base58_base.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';


/// Constants for the SS58 format, per the Substrate SS58 registry spec.
class _Ss58Const {
  /// Format values 0..63 ("simple" accounts) fit in a single format byte.
  /// Anything above this uses the two-byte encoding instead.
  static const int simpleAccountFormatMaxVal = 63;

  /// SS58 format is a 14-bit value (0..16383) - two bytes' worth of
  /// identifier space once the two format-length marker bits are
  /// accounted for (see the bit-packing comments in [SS58Encoder.encode]
  /// and [SS58Decoder.decode]).
  static const int formatMaxVal = 16383;

  /// Format values reserved by the spec and never valid on the wire.
  static const List<int> reservedFormats = [46, 47];

  /// ASCII "SS58PRE" - prepended to the payload before hashing, so the
  /// checksum can't collide with a checksum computed the same way for an
  /// unrelated purpose.
  static const List<int> checksumPrefix = [83, 83, 53, 56, 80, 82, 69];

  /// SS58 uses a 1-byte checksum normally, but a 2-byte checksum
  /// specifically for the two "account ID" payload lengths (32 raw bytes
  /// + 1 format byte = 33, or + 2 format bytes = 34) - this extra byte of
  /// checksum is a spec quirk for those particular total lengths, not a
  /// function of the format value itself.
  static int checkBytesLen(int dataBytesLength) {
    return [33, 34].contains(dataBytesLength) ? 2 : 1;
  }
}

/// Checksum computation shared by [SS58Encoder] and [SS58Decoder].
class _Ss58Utils {
  /// Blake2b-512 of `"SS58PRE" + dataBytes`, truncated to the 1 or 2
  /// bytes the format/data length calls for (see
  /// [_Ss58Const.checkBytesLen]).
  static BuBytes computeChecksum(List<int> dataBytes) {
    final prefixAndData = [..._Ss58Const.checksumPrefix, ...dataBytes];
    return QuickCrypto.blake2b512Hash(
      prefixAndData,
    ).sublist(0, _Ss58Const.checkBytesLen(dataBytes.length));
  }
}

/// Encodes raw account bytes into an SS58 address string.
class SS58Encoder {
  /// Encodes [dataBytes] (the raw account/public-key bytes) as an SS58
  /// address under [ss58Format] (the network/address-type identifier -
  /// e.g. `0` for Polkadot, `2` for Kusama, `42` for the generic
  /// Substrate format).
  ///
  /// [ss58Format] must be in `0..16383` and not one of the two reserved
  /// values (46, 47). Values `0..63` ("simple" formats) are packed into a
  /// single format byte; anything from 64 up uses the spec's two-byte
  /// encoding instead - both cases are handled automatically, callers
  /// just pass the plain format number either way.
  ///
  /// Throws [SS58FormatError] if [ss58Format] is out of range or reserved.
  static String encode(List<int> dataBytes, int ss58Format) {
    if (ss58Format < 0 ||
        ss58Format > _Ss58Const.formatMaxVal ||
        _Ss58Const.reservedFormats.contains(ss58Format)) {
      throw BuError(DefaultErrorType.invalidLength,
        'Invalid SS58 format.',
        details: {
          'reason': 'ss58Format $ss58Format is out of range or reserved',
        },
      );
    }

    List<int> ss58FormatBytes;
    if (ss58Format <= _Ss58Const.simpleAccountFormatMaxVal) {
      // Simple formats (0..63) are just the format value as a single
      // byte - toLeBytes() on a value this small always produces exactly
      // one byte.
      ss58FormatBytes = ss58Format.toLeBytes();
    } else {
      // Full (14-bit) formats spread across two bytes with the top two
      // bits of the first byte set to `01` as a marker distinguishing
      // this from the single-byte form (whose values are always < 64,
      // i.e. always have those two bits clear) - see SS58Decoder.decode
      // for the exact inverse of this bit layout.
      ss58FormatBytes = [
        ((ss58Format & 0x00FC) >> 2) | 0x0040,
        (ss58Format >> 8) | ((ss58Format & 0x0003) << 6),
      ];
    }

    final payload = [...ss58FormatBytes, ...dataBytes];
    final checksum = _Ss58Utils.computeChecksum(payload);
    return Base58Encoder.encode([...payload, ...checksum]);
  }
}

/// Decodes SS58 address strings back into their format and data bytes.
class SS58Decoder {
  /// Decodes [ss58Str] into `(ss58Format, dataBytes)`.
  ///
  /// Throws [SS58FormatError] if the decoded format is reserved, the input
  /// is empty, or a two-byte format marker is cut off - or
  /// [SS58ChecksumError] if the checksum doesn't match (the address was
  /// mistyped, truncated, or corrupted) - or genuinely can't be resolved,
  /// see the comment on the checksum-length loop below.
  /// [Base58FormatError] propagates from the inner Base58 decode when
  /// [ss58Str] contains a character outside the Bitcoin alphabet.
  static (int, BuBytes) decode(String ss58Str) {
    final decBytes = Base58Decoder.decode(ss58Str);

    if (decBytes.isEmpty) {
      throw BuError(DefaultErrorType.badSs58,
        'Invalid SS58 address.',
        details: {'reason': 'decoded address is empty'},
      );
    }
    int ss58Format;
    int ss58FormatLen;
    if ((decBytes[0] & 0x40) != 0) {
      if (decBytes.length < 2) {
        throw BuError(DefaultErrorType.badSs58,
          'Invalid SS58 address.',
          details: {'reason': 'truncated two-byte format'},
        );
      }
      // Top two bits `01` set (see SS58Encoder.encode) - this is the
      // two-byte full-format encoding; undo the same bit spread.
      ss58FormatLen = 2;
      ss58Format =
          ((decBytes[0] & 0x3F) << 2) |
          (decBytes[1] >> 6) |
          ((decBytes[1] & 0x3F) << 8);
    } else {
      // Single format byte, value 0..63.
      ss58FormatLen = 1;
      ss58Format = decBytes[0];
    }

    if (_Ss58Const.reservedFormats.contains(ss58Format)) {
      throw BuError(DefaultErrorType.badSs58,
        'Invalid SS58 format.',
        details: {'reason': 'decoded ss58Format $ss58Format is reserved'},
      );
    }

    // The checksum is 1 or 2 bytes, per _Ss58Const.checkBytesLen - but
    // that decision is keyed on the *payload* length (format + data,
    // excluding the checksum itself), which isn't directly recoverable
    // from decBytes.length alone: the same total length can arise from
    // two different (payload, checksum) splits (e.g. a 34-byte payload
    // with a 2-byte checksum, and a 35-byte payload with a 1-byte
    // checksum, both total 36 bytes). Rather than guess via a formula
    // that gets this wrong for some lengths, try both candidate checksum
    // lengths and accept whichever one's checksum actually verifies - a
    // checksum collision on the wrong split is cryptographically
    // negligible, so this is unambiguous in practice. The common case (1
    // byte) is tried first.
    for (final checkSumLength in const [1, 2]) {
      if (decBytes.length <= ss58FormatLen + checkSumLength) continue;

      final splitAt = decBytes.length - checkSumLength;
      final payload = decBytes.sublist(0, splitAt);
      final checksumBytes = decBytes.sublist(splitAt);
      final expectedChecksum = _Ss58Utils.computeChecksum(payload);

      // Self-consistency: this split is only a real candidate if
      // checkBytesLen() would independently choose this same checksum
      // length for a payload of this length - otherwise the byte
      // comparison below is meaningless (comparing against a checksum of
      // the wrong length can never match).
      if (expectedChecksum.length != checkSumLength) continue;

      if (BytesUtils.bytesEqual(expectedChecksum, checksumBytes)) {
        return (ss58Format, decBytes.sublist(ss58FormatLen, splitAt));
      }
    }

    throw CoreErrors.ss58InvalidChecksum;
  }
}
