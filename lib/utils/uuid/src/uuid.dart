/// UUID generation and parsing, covering the versions actually in common
/// use today rather than the full RFC 9562 set: v1 (time + node), v3
/// (name-based, MD5), v4 (random), v5 (name-based, SHA-1), and v7 (Unix
/// Epoch time, the modern k-sortable variant increasingly used by
/// databases). Deliberately not implemented: v2 (DCE security - rarely
/// used, and its semantics are domain/site-specific rather than generic),
/// v6 (a reordered v1 - v7 supersedes it for the sortable-UUID use case),
/// and v8 (vendor/application-defined - there's no fixed algorithm to
/// implement, it's a free-form slot for custom formats).
library;

import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class UUID {
  // Standard namespace UUIDs, RFC 4122 Appendix C - for use as the
  // `namespace` argument to [v3]/[v5].
  static const String namespaceDns = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
  static const String namespaceUrl = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';
  static const String namespaceOid = '6ba7b812-9dad-11d1-80b4-00c04fd430c8';
  static const String namespaceX500 = '6ba7b814-9dad-11d1-80b4-00c04fd430c8';

  // Offset between the UUID time origin (1582-10-15T00:00:00Z, the date
  // the Gregorian calendar was adopted) and the Unix epoch, in 100ns
  // units - the constant every UUID v1 implementation needs. Verified
  // independently (12,219,292,800 seconds * 10,000,000).
  static final BigInt _v1EpochOffset100ns = BigInt.parse('122192928000000000');

  // ---------------------------------------------------------------------
  // v4 - random
  // ---------------------------------------------------------------------

  /// Generates a version 4 (random) UUID.
  static String v4() {
    final bytes = QuickCrypto.generateRandom(length: 16);
    _setVersionAndVariant(bytes, 4);
    return _bytesToUuidString(bytes);
  }

  // ---------------------------------------------------------------------
  // v3 / v5 - name-based (MD5 / SHA-1)
  // ---------------------------------------------------------------------

  /// Generates a version 3 (name-based, MD5) UUID: deterministic for a
  /// given ([namespace], [name]) pair - the same inputs always produce
  /// the same UUID. [namespace] is itself a UUID string; use one of
  /// [namespaceDns]/[namespaceUrl]/[namespaceOid]/[namespaceX500], or any
  /// UUID string of your own for a custom namespace.
  ///
  /// Prefer [v5] for new uses - MD5 is only kept here for compatibility
  /// with existing v3-based identifiers, per RFC 4122/9562.
  static String v3(String namespace, String name) {
    return _nameBased(namespace, name, 3, QuickCrypto.md5Hash);
  }

  /// Generates a version 5 (name-based, SHA-1) UUID - the same idea as
  /// [v3] but with SHA-1, which RFC 4122/9562 recommends over v3 for new
  /// uses.
  static String v5(String namespace, String name) {
    return _nameBased(namespace, name, 5, QuickCrypto.sha1Hash);
  }

  static String _nameBased(
    String namespace,
    String name,
    int version,
    List<int> Function(List<int> data) hash,
  ) {
    final namespaceBytes = toBuffer(namespace);
    final nameBytes = StringUtils.encode(name);
    final digest = hash([...namespaceBytes, ...nameBytes]);
    final bytes = digest.sublist(0, 16);
    _setVersionAndVariant(bytes, version);
    return _bytesToUuidString(bytes);
  }

  // ---------------------------------------------------------------------
  // v1 - time-based
  // ---------------------------------------------------------------------

  /// Generates a version 1 (time-based) UUID: a 60-bit timestamp (100ns
  /// intervals since 1582-10-15) plus a random clock sequence and node
  /// ID.
  ///
  /// The node ID is meant to be an IEEE 802 (MAC) address per the RFC,
  /// but there's no portable way to read one in pure Dart across native
  /// and web - so per RFC 4122 §4.1.6's own fallback, this uses a random
  /// 48-bit value with the multicast bit set, which marks it as
  /// explicitly not a real hardware address (avoiding any risk of
  /// colliding with one).
  static String v1() {
    final bytes = List<int>.filled(16, 0);

    // The timestamp is computed via BigInt: at today's date it's already
    // past 2^53 (~1.4e17), well beyond what's exact as a plain
    // double/int on every platform.
    final microsSinceUnixEpoch = BigInt.from(
      DateTime.now().microsecondsSinceEpoch,
    );
    final timestamp100ns =
        microsSinceUnixEpoch * BigInt.from(10) + _v1EpochOffset100ns;

    final timeLow = (timestamp100ns & BigInt.from(0xFFFFFFFF)).toInt();
    final timeMid = ((timestamp100ns >> 32) & BigInt.from(0xFFFF)).toInt();
    final timeHiAndVersion =
        (((timestamp100ns >> 48) & BigInt.from(0x0FFF)) | BigInt.from(0x1000))
            .toInt();

    // Extracting bytes from these already-bounded plain-int values (timeLow
    // is < 2^32, timeMid/timeHiAndVersion < 2^16) via division/modulo
    // rather than shifts - after getting burned once already by a wrong
    // assumption about which bitwise ops dart2js handles exactly near the
    // 32-bit boundary (see bch_bech32.dart's doc comment for the full
    // story), plain arithmetic is the option that doesn't require being
    // sure about that boundary at all.
    bytes[0] = timeLow ~/ 0x1000000;
    bytes[1] = (timeLow ~/ 0x10000) % 0x100;
    bytes[2] = (timeLow ~/ 0x100) % 0x100;
    bytes[3] = timeLow % 0x100;
    bytes[4] = timeMid ~/ 0x100;
    bytes[5] = timeMid % 0x100;
    bytes[6] = timeHiAndVersion ~/ 0x100; // version nibble lives in here
    bytes[7] = timeHiAndVersion % 0x100;

    // 14-bit clock sequence: random, since this is a stateless generator
    // with no persisted "last timestamp" to compare against and bump on
    // a same-millisecond collision (the RFC's documented fallback for
    // that situation).
    final clockSeq = QuickCrypto.generateRandomInt(16384); // 0..2^14-1
    bytes[8] = ((clockSeq ~/ 0x100) & 0x3F) | 0x80; // variant bits folded in
    bytes[9] = clockSeq % 0x100;

    final node = QuickCrypto.generateRandom(length: 6);
    node[0] |= 0x01; // multicast bit - "this is not a real MAC address"
    for (var i = 0; i < 6; i++) {
      bytes[10 + i] = node[i];
    }

    return _bytesToUuidString(bytes);
  }

  // ---------------------------------------------------------------------
  // v7 - Unix Epoch time-based (RFC 9562) - k-sortable
  // ---------------------------------------------------------------------

  /// Generates a version 7 UUID: a 48-bit Unix timestamp in milliseconds
  /// followed by random bits. Unlike v1/v4, v7 UUIDs generated in
  /// increasing time order sort in increasing lexicographic/byte order
  /// too - useful as a database primary key where index locality matters.
  static String v7() {
    final bytes = List<int>.filled(16, 0);
    final ms = DateTime.now().millisecondsSinceEpoch; // ~1.7e12 today

    // Split the 48-bit ms value into two 24-bit halves via integer
    // division/modulo - NOT bit shifts - before doing any bitwise byte
    // extraction. Dividing/mod'ing a double-safe value stays exact on
    // every platform, but *shifting* a value past 32 bits is not
    // reliably exact on dart2js (its native bitwise ops truncate through
    // JS's ToInt32 first, same class of issue documented on Uint64's
    // _safeShl32). Splitting first keeps every subsequent shift
    // comfortably under 32 bits, so plain `int` bitwise ops are safe.
    final msHi = ms ~/ 0x1000000; // top 24 bits
    final msLo = ms % 0x1000000; // bottom 24 bits

    bytes[0] = msHi ~/ 0x10000;
    bytes[1] = (msHi ~/ 0x100) % 0x100;
    bytes[2] = msHi % 0x100;
    bytes[3] = msLo ~/ 0x10000;
    bytes[4] = (msLo ~/ 0x100) % 0x100;
    bytes[5] = msLo % 0x100;

    final randA = QuickCrypto.generateRandomInt(4096); // 12 random bits
    bytes[6] =
        ((randA ~/ 0x100) & 0x0F) | 0x70; // version nibble + top of rand_a
    bytes[7] = randA % 0x100;

    // 62-bit rand_b: 8 random bytes with the variant bits folded into
    // the top of the first one - same pattern as v4's byte 8.
    final randB = QuickCrypto.generateRandom(length: 8);
    randB[0] = (randB[0] & 0x3F) | 0x80;
    for (var i = 0; i < 8; i++) {
      bytes[8 + i] = randB[i];
    }

    return _bytesToUuidString(bytes);
  }

  // ---------------------------------------------------------------------
  // Buffer conversion
  // ---------------------------------------------------------------------

  /// Converts a UUID string to its raw 16-byte buffer.
  ///
  /// Throws [UUIDError] if [validate] is true (the default) and
  /// [uuidString] isn't a validly-formatted UUID (any of the supported
  /// versions - see [isValid]).
  static BuBytes toBuffer(String uuidString, {bool validate = true}) {
    if (validate && !isValid(uuidString)) {
      throw BuError(
        DefaultErrorType.badUuid,
        'Invalid UUID string.',
        details: {
          'reason': 'not a valid UUID (v1/v3/v4/v5/v7) string',
          'value': uuidString,
        },
      );
    }
    final cleaned = uuidString.replaceAll('-', '');
    final bytes = BytesUtils.fromHexString(cleaned);
    if (bytes.length != 16) {
      throw BuError(
        DefaultErrorType.invalidLength,
        'Invalid UUID string.',
        details: {
          'reason': 'decoded to ${bytes.length} bytes, expected 16',
          'value': uuidString,
        },
      );
    }
    return bytes;
  }

  /// Converts a raw 16-byte buffer to its UUID string form.
  ///
  /// Throws [UUIDError] if [buffer] isn't exactly 16 bytes long.
  static String fromBuffer(List<int> buffer) {
    if (buffer.length != 16) {
      throw BuError(
        DefaultErrorType.invalidLength,
        'Invalid UUID buffer.',
        details: {'reason': 'buffer has ${buffer.length} bytes, expected 16'},
      );
    }
    return _bytesToUuidString(buffer);
  }

  // ---------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------

  // Version nibble restricted to the versions this class actually
  // generates (1/3/4/5/7); variant nibble restricted to the RFC
  // 4122/9562 variant (10xx, i.e. 8/9/a/b).
  static final RegExp _validPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[13457][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  /// True if [uuid] is validly formatted as any of the versions this
  /// class generates (v1, v3, v4, v5, v7).
  static bool isValid(String uuid) => _validPattern.hasMatch(uuid);

  // ---------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------

  /// Sets the version nibble (top 4 bits of byte 6) and the RFC
  /// 4122/9562 variant bits (top 2 bits of byte 8) in place - shared by
  /// every version whose fields are otherwise "just bytes" (v3/v4/v5;
  /// v1/v7 fold these bits in directly while building their
  /// timestamp/random fields, since those need the surrounding bits
  /// assembled at the same time anyway).
  static void _setVersionAndVariant(List<int> bytes, int version) {
    bytes[6] = (bytes[6] & 0x0F) | (version << 4);
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
  }

  /// Formats a 16-byte buffer as a hyphenated UUID string.
  static String _bytesToUuidString(List<int> bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
