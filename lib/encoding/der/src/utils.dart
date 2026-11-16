import 'package:blockchain_utils/encoding/der/src/constants.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class DerUtils {
  static String derToPem(List<int> der, String label) {
    final b64 = StringUtils.decode(
      der.asBytes,
      encoding: StringEncoding.base64,
    );
    final lines = <String>[];
    for (var i = 0; i < b64.length; i += 64) {
      final end = (i + 64 > b64.length) ? b64.length : i + 64;
      lines.add(b64.substring(i, end));
    }
    return '-----BEGIN $label-----\n${lines.join('\n')}\n-----END $label-----\n';
  }

  static BuBytes pemToDer(String pem) {
    final body =
        pem
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty && !l.startsWith('-----'))
            .join();
    return StringUtils.encode(body, encoding: StringEncoding.base64);
  }

  static BuBytes _encodeBase128(int value) {
    if (value == 0) return BuBytes([0]);
    final out = <int>[];
    var v = value;
    while (v > 0) {
      out.insert(0, v & 0x7F);
      v >>= 7;
    }
    for (var i = 0; i < out.length - 1; i++) {
      out[i] |= 0x80;
    }
    return BuBytes(out);
  }

  static BuBytes encodeOid(String oid) {
    final parts = <int>[];
    for (final arc in oid.split('.')) {
      final v = int.tryParse(arc);
      if (v == null || v.isNegative) {
        throw CoreErrors.cryptoFailed(
          "encodeOid",
          reason: "Invalid OID arc '$arc'.",
        );
      }
      parts.add(v);
    }
    if (parts.length < 2) {
      throw CoreErrors.cryptoFailed(
        "encodeOid",
        reason: "OID needs at least 2 arcs",
      );
    }
    final bytes = <int>[parts[0] * 40 + parts[1]];
    for (var i = 2; i < parts.length; i++) {
      bytes.addAll(_encodeBase128(parts[i]));
    }
    return BuBytes(bytes);
  }

  static String decodeOid(List<int> bytes) {
    if (bytes.isEmpty) {
      throw CoreErrors.cryptoFailed("decodeOid", reason: 'Empty OID.');
    }
    final parts = <int>[];
    final first = bytes[0];
    if (first < 40) {
      parts.addAll([0, first]);
    } else if (first < 80) {
      parts.addAll([1, first - 40]);
    } else {
      parts.addAll([2, first - 80]);
    }
    var value = 0;
    for (var i = 1; i < bytes.length; i++) {
      value = (value << 7) | (bytes[i] & 0x7F);
      if ((bytes[i] & 0x80) == 0) {
        parts.add(value);
        value = 0;
      }
    }
    return parts.join('.');
  }

  static BuBytes _derLength(int len) {
    if (len < 0x80) return BuBytes([len]);
    final bytes = <int>[];
    var l = len;
    while (l > 0) {
      bytes.insert(0, l & 0xFF);
      l >>= 8;
    }
    return BuBytes([0x80 | bytes.length, ...bytes]);
  }

  static BuBytes derTlv(int tag, List<int> value) =>
      BuBytes([tag, ..._derLength(value.length), ...value]);

  static BuBytes derSequence(List<int> children) =>
      derTlv(DerTag.sequence, children);

  /// DER INTEGER encoding: minimal length, big-endian, with a leading 0x00
  /// inserted whenever the high bit of the first byte is set (so the value
  /// is never mistaken for negative under two's-complement rules).
  static BuBytes derInteger(List<int> bytes) {
    List<int> b = bytes.asBytes;
    var i = 0;
    while (i < b.length - 1 && b[i] == 0 && (b[i + 1] & 0x80) == 0) {
      i++;
    }
    b = b.sublist(i);
    if (b.isEmpty) b = BuBytes([0]);
    if ((b[0] & 0x80) != 0) {
      b = BuBytes.concat([
        [0],
        b,
      ]);
    }
    return derTlv(DerTag.integer, b);
  }

  static BuBytes derSmallInt(int value) =>
      derInteger([value & BinaryOps.mask8]);

  static BuBytes derOctetString(List<int> bytes) =>
      derTlv(DerTag.octetString, bytes);

  static BuBytes derBitString(List<int> bytes, {int unusedBits = 0}) =>
      derTlv(DerTag.bitString, [unusedBits, ...bytes]);

  static BuBytes derNull() => BuBytes([DerTag.nullTag, 0x00]);

  static BuBytes derOid(String oid) => derTlv(DerTag.oid, encodeOid(oid));

  static BuBytes derContext(int tagNumber, List<int> content) =>
      derTlv(0xA0 | tagNumber, content);
}
