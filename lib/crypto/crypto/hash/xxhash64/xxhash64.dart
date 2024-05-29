part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

class _XXHashState {
  final BigInt seed;
  final List<int> u8a;
  int u8asize;
  BigInt v1;
  BigInt v2;
  BigInt v3;
  BigInt v4;
  _XXHashState clone() {
    return _XXHashState(
        seed: seed,
        u8a: List<int>.from(u8a),
        u8asize: u8asize,
        v1: v1,
        v2: v2,
        v3: v3,
        v4: v4);
  }

  _XXHashState(
      {required this.seed,
      required this.u8a,
      required this.u8asize,
      required this.v1,
      required this.v2,
      required this.v3,
      required this.v4});
}

class _XXHash64Const {
  static final BigInt p64One = BigInt.parse('11400714785074694791');
  static final BigInt p64Two = BigInt.parse('14029467366897019727');
  static final BigInt p64Three = BigInt.parse('1609587929392839161');
  static final BigInt p64four = BigInt.parse('9650029242287828579');
  static final BigInt p64five = BigInt.parse('2870177450012600261');
  static final BigInt u64 = BigInt.parse('ffffffffffffffff', radix: 16);
  static final BigInt n256 = BigInt.from(256);
  static BigInt _rotl(BigInt a, int b) {
    final c = a & _XXHash64Const.u64;
    return ((c << b.toInt()) | (c >> (64 - b).toInt())) & _XXHash64Const.u64;
  }

  static BigInt fromU8a(List<int> u8a, int p, int count) {
    final bigints = List<BigInt>.filled(count, BigInt.zero);
    int offset = 0;
    for (var i = 0; i < count; i++, offset += 2) {
      bigints[i] = BigInt.from(u8a[p + offset] | (u8a[p + 1 + offset] << 8));
    }
    BigInt result = BigInt.zero;
    for (var i = count - 1; i >= 0; i--) {
      result = (result << 16) + bigints[i];
    }
    return result;
  }

  static _XXHashState init(BigInt seed, List<int> input) {
    final state = _XXHashState(
      seed: seed,
      u8a: List<int>.filled(32, 0),
      u8asize: 0,
      v1: seed + _XXHash64Const.p64One + _XXHash64Const.p64Two,
      v2: seed + _XXHash64Const.p64Two,
      v3: seed,
      v4: seed - _XXHash64Const.p64One,
    );

    if (input.length < 32) {
      state.u8a.setAll(0, input);
      state.u8asize = input.length;
      return state;
    }

    final limit = input.length - 32;
    int p = 0;
    if (limit >= 0) {
      adjustV(BigInt v) =>
          _XXHash64Const.p64One *
          _rotl(v + _XXHash64Const.p64Two * fromU8a(input, p, 4), 31);
      do {
        state.v1 = adjustV(state.v1);
        p += 8;
        state.v2 = adjustV(state.v2);
        p += 8;
        state.v3 = adjustV(state.v3);
        p += 8;
        state.v4 = adjustV(state.v4);
        p += 8;
      } while (p <= limit);
    }
    if (p < input.length) {
      state.u8a.setRange(0, input.length - p, input.sublist(p));
      state.u8asize = input.length - p;
    }
    return state;
  }

  static List<int> xxhash64(List<int> input, int initSeed) {
    final state = init(BigInt.from(initSeed), input);
    int p = 0;
    BigInt h64 = _XXHash64Const.u64 &
        (BigInt.from(input.length) +
            (input.length >= 32
                ? (((((((((_rotl(state.v1, 1) + _rotl(state.v2, 7) + _rotl(state.v3, 12) + _rotl(state.v4, 18)) ^
                                                                (_XXHash64Const.p64One *
                                                                    _rotl(
                                                                        state.v1 *
                                                                            _XXHash64Const
                                                                                .p64Two,
                                                                        31))) *
                                                            _XXHash64Const
                                                                .p64One +
                                                        _XXHash64Const
                                                            .p64four) ^
                                                    (_XXHash64Const.p64One *
                                                        _rotl(
                                                            state.v2 *
                                                                _XXHash64Const
                                                                    .p64Two,
                                                            31))) *
                                                _XXHash64Const.p64One +
                                            _XXHash64Const.p64four) ^
                                        (_XXHash64Const.p64One *
                                            _rotl(
                                                state.v3 *
                                                    _XXHash64Const.p64Two,
                                                31))) *
                                    _XXHash64Const.p64One +
                                _XXHash64Const.p64four) ^
                            (_XXHash64Const.p64One *
                                _rotl(state.v4 * _XXHash64Const.p64Two, 31))) *
                        _XXHash64Const.p64One +
                    _XXHash64Const.p64four)
                : (state.seed + _XXHash64Const.p64five)));

    while (p <= (state.u8asize - 8)) {
      h64 = _XXHash64Const.u64 &
          (_XXHash64Const.p64four +
              _XXHash64Const.p64One *
                  _rotl(
                      h64 ^
                          (_XXHash64Const.p64One *
                              _rotl(
                                  _XXHash64Const.p64Two *
                                      fromU8a(state.u8a, p, 4),
                                  31)),
                      27));
      p += 8;
    }

    if ((p + 4) <= state.u8asize) {
      h64 = _XXHash64Const.u64 &
          (_XXHash64Const.p64Three +
              _XXHash64Const.p64Two *
                  _rotl(
                      h64 ^ (_XXHash64Const.p64One * fromU8a(state.u8a, p, 2)),
                      23));
      p += 4;
    }

    while (p < state.u8asize) {
      h64 = _XXHash64Const.u64 &
          (_XXHash64Const.p64One *
              _rotl(
                  h64 ^ (_XXHash64Const.p64five * BigInt.from(state.u8a[p++])),
                  11));
    }

    h64 = _XXHash64Const.u64 & (_XXHash64Const.p64Two * (h64 ^ (h64 >> 33)));
    h64 = _XXHash64Const.u64 & (_XXHash64Const.p64Three * (h64 ^ (h64 >> 29)));
    h64 = _XXHash64Const.u64 & (h64 ^ (h64 >> 32));

    final result = List<int>.filled(8, 0);
    for (int i = 7; i >= 0; i--) {
      result[i] = (h64 % _XXHash64Const.n256).toInt() & mask8;
      h64 = h64 ~/ _XXHash64Const.n256;
    }

    return result;
  }
}

class XXHash64 extends SerializableHash<HashBytesState> {
  static List<int> hash(List<int> data, {int bitlength = 64}) {
    final h = XXHash64(bitLength: bitlength);
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }

  final List<int> _buffer = List.empty(growable: true);
  bool _finished = false;
  XXHash64({int bitLength = 64})
      : getDigestLength = (bitLength / 64).ceil() * 8;
  @override
  void clean() {
    _buffer.clear();
    _finished = false;
  }

  @override
  void cleanSavedState(HashBytesState savedState) {
    zero(savedState.data);
    savedState.pos = 0;
  }

  @override
  List<int> digest() {
    if (_finished) {
      return List<int>.from(_buffer);
    }
    final List<int> data = List<int>.filled(getDigestLength, 0);
    finish(data);
    return data;
  }

  @override
  Hash finish(List<int> out) {
    final rounds = getDigestLength ~/ getBlockSize;
    for (int seed = 0; seed < rounds; seed++) {
      final hash = _XXHash64Const.xxhash64(_buffer, seed).reversed.toList();
      out.setAll(seed * 8, hash);
    }
    _finished = true;
    return this;
  }

  @override
  final int getBlockSize = 8;

  @override
  final int getDigestLength;

  @override
  Hash reset() {
    _buffer.clear();
    _finished = false;
    return this;
  }

  @override
  SerializableHash restoreState(HashBytesState savedState) {
    _buffer.clear();
    _buffer.addAll(savedState.data);
    _finished = false;
    return this;
  }

  @override
  HashBytesState saveState() {
    if (_finished) {
      throw MessageException(
          "XXHash64: can't update because hash was finished.");
    }
    return HashBytesState(data: _buffer, pos: _buffer.length);
  }

  @override
  Hash update(List<int> data) {
    if (_finished) {
      throw MessageException(
          "XXHash64: can't update because hash was finished.");
    }
    _buffer.addAll(data);
    return this;
  }
}
