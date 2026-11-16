part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

class _XXHash64 {
  static const Uint64 _p1 = Uint64.unsafe(0x9E3779B1, 0x85EBCA87);
  static const Uint64 _p2 = Uint64.unsafe(0xC2B2AE3D, 0x27D4EB4F);
  static const Uint64 _p3 = Uint64.unsafe(0x165667B1, 0x9E3779F9);
  static const Uint64 _p4 = Uint64.unsafe(0x85EBCA77, 0xC2B2AE63);
  static const Uint64 _p5 = Uint64.unsafe(0x27D4EB2F, 0x165667C5);

  @pragma('vm:prefer-inline')
  static Uint64 _rotl(Uint64 v, int r) {
    final s = r & 63;
    if (s == 0) return v;
    return (v << s) | (v >> (64 - s));
  }

  @pragma('vm:prefer-inline')
  static Uint64 _readLE64(List<int> b, int off) {
    final lo =
        (b[off] & 0xFF) |
        ((b[off + 1] & 0xFF) << 8) |
        ((b[off + 2] & 0xFF) << 16) |
        ((b[off + 3] & 0xFF) << 24);
    final hi =
        (b[off + 4] & 0xFF) |
        ((b[off + 5] & 0xFF) << 8) |
        ((b[off + 6] & 0xFF) << 16) |
        ((b[off + 7] & 0xFF) << 24);
    return Uint64.fromParts(hi, lo);
  }

  @pragma('vm:prefer-inline')
  static Uint64 _readLE32(List<int> b, int off) {
    final lo =
        (b[off] & 0xFF) |
        ((b[off + 1] & 0xFF) << 8) |
        ((b[off + 2] & 0xFF) << 16) |
        ((b[off + 3] & 0xFF) << 24);
    return Uint64.uncheckedU32(lo);
  }

  @pragma('vm:prefer-inline')
  static Uint64 _round(Uint64 acc, Uint64 lane) {
    return _p1 * _rotl(acc + (_p2 * lane), 31);
  }

  @pragma('vm:prefer-inline')
  static Uint64 _mergeRound(Uint64 h, Uint64 v) {
    return (_p1 * _rotl(v * _p2, 31) ^ h) * _p1 + _p4;
  }

  static Uint64 hashU64(List<int> input, int seedInt) {
    final seed = Uint64(seedInt);
    Uint64 v1 = seed + _p1 + _p2;
    Uint64 v2 = seed + _p2;
    Uint64 v3 = seed;
    Uint64 v4 = seed - _p1;

    List<int> tail;
    int tailLen;
    if (input.length >= 32) {
      final int limit = input.length - 32;
      int p = 0;
      while (true) {
        v1 = _round(v1, _readLE64(input, p));
        p += 8;
        v2 = _round(v2, _readLE64(input, p));
        p += 8;
        v3 = _round(v3, _readLE64(input, p));
        p += 8;
        v4 = _round(v4, _readLE64(input, p));
        p += 8;
        if (p > limit) {
          tailLen = input.length - p;
          tail = tailLen == 0 ? const [] : input.sublist(p);
          break;
        }
      }
    } else {
      tail = input;
      tailLen = input.length;
    }

    Uint64 h;
    if (input.length >= 32) {
      h = _rotl(v1, 1) + _rotl(v2, 7) + _rotl(v3, 12) + _rotl(v4, 18);
      h = _mergeRound(h, v1);
      h = _mergeRound(h, v2);
      h = _mergeRound(h, v3);
      h = _mergeRound(h, v4);
      h = h + Uint64(input.length);
    } else {
      h = seed + _p5 + Uint64(input.length);
    }

    int q = 0;
    while (q + 8 <= tailLen) {
      h = _p1 * _rotl(h ^ (_p1 * _rotl(_p2 * _readLE64(tail, q), 31)), 27) + _p4;
      q += 8;
    }
    if (q + 4 <= tailLen) {
      h = _p2 * _rotl(h ^ (_p1 * _readLE32(tail, q)), 23) + _p3;
      q += 4;
    }
    while (q < tailLen) {
      h = _p1 * _rotl(h ^ (_p5 * Uint64(tail[q])), 11);
      q += 1;
    }

    h = _p2 * (h ^ (h >> 33));
    h = _p3 * (h ^ (h >> 29));
    h = h ^ (h >> 32);
    return h;
  }

  static BuBytes xxhash64(List<int> input, int initSeed) {
    return hashU64(input, initSeed).toBytes();
  }
}

/// xxHash: a fast, non-cryptographic hash. Do not use where collision
/// resistance matters.
class XXHash implements SerializableHash<HashBytesState> {
  @override
  late final int getDigestLength;
  static BuBytes hash(List<int> data, {int bitLength = 64}) {
    final h = XXHash(bitLength: bitLength);
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }

  final BuBytes _buffer = BuBytes.empty();
  bool _finished = false;
  bool _cleaned = false;
  XXHash({int bitLength = 64}) {
    getDigestLength = (bitLength / 64).ceil() * 8;
    if (bitLength % 64 != 0 || ![8, 16, 32].contains(getDigestLength)) {
      throw CoreErrors.invalidOperationArguments(
        "XXHash",
        reason: "Invalid bitlength.",
      );
    }
  }
  @override
  void clean() {
    _buffer.clear();
    _finished = false;
    _cleaned = true;
  }

  @override
  void cleanSavedState(HashBytesState savedState) {
    BinaryOps.zero(savedState.data);
    savedState.pos = 0;
  }

  @override
  BuBytes digest() {
    final BuBytes data = BuBytes.fill(getDigestLength, 0);
    finish(data);
    return data;
  }

  @override
  XXHash finish(List<int> out) {
    final rounds = getDigestLength ~/ getBlockSize;
    for (int seed = 0; seed < rounds; seed++) {
      final hash = _XXHash64.xxhash64(_buffer, seed).reversed.toList();
      out.setAll(seed * 8, hash);
    }
    _finished = true;
    return this;
  }

  @override
  final int getBlockSize = 8;

  @override
  XXHash reset() {
    _ensureAlive("XXHash.reset", _cleaned, null);
    _buffer.clear();
    _finished = false;
    return this;
  }

  @override
  SerializableHash restoreState(HashBytesState savedState) {
    _ensureAlive("XXHash.restoreState", _cleaned, null);
    _buffer.clear();
    _buffer.addAll(savedState.data);
    _finished = false;
    return this;
  }

  @override
  HashBytesState saveState() {
    _ensureAlive("XXHash.saveState", _cleaned, _finished);
    return HashBytesState(data: _buffer, pos: _buffer.length);
  }

  @override
  Hash update(List<int> data) {
    _ensureAlive("XXHash.update", _cleaned, _finished);
    _buffer.addAll(data);
    return this;
  }
}
