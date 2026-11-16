part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// Configuration class for the Blake2b hash function.
///
class Blake2Config extends BuBlake2Config {
  Blake2Config._({
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    super.fanout = 1,
    super.maxDepth = 1,
    super.leafSize = 0,
    super.nodeOffset = 0,
    super.nodeDepth = 0,
    super.innerDigestLength = 0,
    super.lastNode = false,
  }) : super(
         key: key?.asBytes,
         salt: salt?.asBytes,
         personalization: personalization?.asBytes,
       );

  factory Blake2Config.blake2s({
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    int? fanout,
    int? maxDepth,
    int? leafSize,
    int? nodeOffset,
    int? nodeDepth,
    int? innerDigestLength,
    bool? lastNode,
  }) {
    fanout ??= 1;
    maxDepth ??= 1;
    leafSize ??= 0;
    nodeOffset ??= 0;
    innerDigestLength ??= 0;
    lastNode ??= false;
    nodeDepth ??= 0;

    const keyLength = 32;
    const int saltLength = 8;
    const int personalizationLength = 8;
    const int maxFanout = 255;
    const int maxMaxDepth = 255;
    const int maxLeafSize = 4294967295;
    const int maxNodeOffset = 281474976710655;
    const digestLength = 32;
    if (key != null && key.length > keyLength) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "key",
        reason: "Incorrect key length.",
      );
    }
    if (salt != null) {
      if (salt.length > saltLength) {
        throw CoreErrors.invalidOperationArguments(
          "Blake2Config",
          name: "salt",
          reason: "Incorrect salt length.",
        );
      }
      if (salt.length != saltLength) {
        salt = List.filled(saltLength, 0)..setAll(0, salt);
      }
    }
    if (personalization != null) {
      if (personalization.length > personalizationLength) {
        throw CoreErrors.invalidOperationArguments(
          "Blake2Config",
          name: "personalization",
          reason: "Incorrect personalization length.",
        );
      }
      if (personalization.length != personalizationLength) {
        personalization = List.filled(personalizationLength, 0)
          ..setAll(0, personalization);
      }
    }
    if (fanout < 0 || fanout > maxFanout) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "fanout",
        reason: "Incorrect fanout.",
      );
    }
    if (maxDepth < 0 || maxDepth > maxMaxDepth) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "depth",
        reason: "Incorrect depth.",
      );
    }
    if (leafSize < 0 || leafSize > maxLeafSize) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "leafSize",
        reason: "Incorrect leaf size.",
      );
    }
    if (innerDigestLength < 0 || innerDigestLength > digestLength) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "innerDigestLength",
        reason: "Incorrect inner digest length",
      );
    }
    if (nodeOffset < 0 || nodeOffset > maxNodeOffset) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "nodeOffset",
        reason: "Incorrect node offset.",
      );
    }
    return Blake2Config._(
      personalization: personalization,
      salt: salt,
      fanout: fanout,
      innerDigestLength: innerDigestLength,
      key: key,
      lastNode: lastNode,
      leafSize: leafSize,
      maxDepth: maxDepth,
      nodeDepth: nodeDepth,
      nodeOffset: nodeOffset,
    );
  }
  factory Blake2Config.blake2b({
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    int? fanout,
    int? maxDepth,
    int? leafSize,
    int? nodeOffset,
    int? nodeDepth,
    int? innerDigestLength,
    bool? lastNode,
  }) {
    fanout ??= 1;
    maxDepth ??= 1;
    leafSize ??= 0;
    nodeOffset ??= 0;
    innerDigestLength ??= 0;
    lastNode ??= false;
    nodeDepth ??= 0;

    const keyLength = 64;
    const int saltLength = 16;
    const int personalizationLength = 16;
    const int maxFanout = 255;
    const int maxMaxDepth = 255;
    const int maxLeafSize = 4294967295;
    const int maxNodeOffset = 281474976710655;
    const digestLength = 64;
    if (key != null && key.length > keyLength) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "key",
        reason: "Incorrect key length.",
      );
    }
    if (salt != null) {
      if (salt.length > saltLength) {
        throw CoreErrors.invalidOperationArguments(
          "Blake2Config",
          name: "salt",
          reason: "Incorrect salt length.",
        );
      }
      if (salt.length != saltLength) {
        salt = List.filled(saltLength, 0)..setAll(0, salt);
      }
    }
    if (personalization != null) {
      if (personalization.length > personalizationLength) {
        throw CoreErrors.invalidOperationArguments(
          "Blake2Config",
          name: "personalization",
          reason: "Incorrect personalization length.",
        );
      }
      if (personalization.length != personalizationLength) {
        personalization = List.filled(personalizationLength, 0)
          ..setAll(0, personalization);
      }
    }
    if (fanout < 0 || fanout > maxFanout) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "fanout",
        reason: "Incorrect fanout.",
      );
    }
    if (maxDepth < 0 || maxDepth > maxMaxDepth) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "depth",
        reason: "Incorrect depth.",
      );
    }
    if (leafSize < 0 || leafSize > maxLeafSize) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "leafSize",
        reason: "Incorrect leaf size.",
      );
    }
    if (innerDigestLength < 0 || innerDigestLength > digestLength) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "innerDigestLength",
        reason: "Incorrect inner digest length",
      );
    }
    if (nodeOffset < 0 || nodeOffset > maxNodeOffset) {
      throw CoreErrors.invalidOperationArguments(
        "Blake2Config",
        name: "nodeOffset",
        reason: "Incorrect node offset.",
      );
    }
    return Blake2Config._(
      personalization: personalization,
      salt: salt,
      fanout: fanout,
      innerDigestLength: innerDigestLength,
      key: key,
      lastNode: lastNode,
      leafSize: leafSize,
      maxDepth: maxDepth,
      nodeDepth: nodeDepth,
      nodeOffset: nodeOffset,
    );
  }
}

/// Implementation of the BLAKE2b hash function that implements the SerializableHash interface.
class BLAKE2b implements SerializableHash<Blake2State> {
  final int _blockSize = 128;
  final int _digestLength = 64;
  final int _keyLength = 64;
  bool _cleaned = false;
  BLAKE2b clone() {
    final b2 = BLAKE2b();
    b2._state.setAll(0, _state);
    b2._buffer.setAll(0, _buffer);
    b2._bufferLength = _bufferLength;
    b2._ctr.setAll(0, _ctr);
    b2._flag.setAll(0, _flag);
    b2._lastNode = _lastNode;
    b2._finished = _finished;
    b2._vtmp.setAll(0, _vtmp);
    b2._mtmp.setAll(0, _mtmp);
    b2._paddedKey = _paddedKey?.clone();
    b2._initialState = _initialState.clone();
    return b2;
  }

  final _iv = const [
    0xf3bcc908,
    0x6a09e667,
    0x84caa73b,
    0xbb67ae85,
    0xfe94f82b,
    0x3c6ef372,
    0x5f1d36f1,
    0xa54ff53a,
    0xade682d1,
    0x510e527f,
    0x2b3e6c1f,
    0x9b05688c,
    0xfb41bd6b,
    0x1f83d9ab,
    0x137e2179,
    0x5be0cd19,
  ];

  final List<List<int>> _sigma = const [
    [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30],
    [28, 20, 8, 16, 18, 30, 26, 12, 2, 24, 0, 4, 22, 14, 10, 6],
    [22, 16, 24, 0, 10, 4, 30, 26, 20, 28, 6, 12, 14, 2, 18, 8],
    [14, 18, 6, 2, 26, 24, 22, 28, 4, 12, 10, 20, 8, 0, 30, 16],
    [18, 0, 10, 14, 4, 8, 20, 30, 28, 2, 22, 24, 12, 16, 6, 26],
    [4, 24, 12, 20, 0, 22, 16, 6, 8, 26, 14, 10, 30, 28, 2, 18],
    [24, 10, 2, 30, 28, 26, 8, 20, 0, 14, 12, 6, 18, 4, 16, 22],
    [26, 22, 14, 28, 24, 2, 6, 18, 10, 0, 30, 8, 16, 12, 4, 20],
    [12, 30, 28, 18, 22, 6, 0, 16, 24, 4, 26, 14, 2, 8, 20, 10],
    [20, 4, 16, 8, 14, 12, 2, 10, 30, 22, 18, 28, 6, 24, 26, 0],
    [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30],
    [28, 20, 8, 16, 18, 30, 26, 12, 2, 24, 0, 4, 22, 14, 10, 6],
  ];

  late final List<int> _state = List<int>.from(_iv, growable: false);
  final List<int> _buffer = List<int>.filled(128, 0);
  int _bufferLength = 0;
  final List<int> _ctr = List<int>.filled(4, 0);
  final List<int> _flag = List<int>.filled(4, 0);
  bool _lastNode = false;
  bool _finished = false;
  final List<int> _vtmp = List<int>.filled(32, 0);
  final List<int> _mtmp = List<int>.filled(32, 0);
  List<int>? _paddedKey;
  late List<int> _initialState;

  /// Computes the BLAKE2b hash of the given input data.
  ///
  /// Parameters:
  /// - [data]: The input data to be hashed.
  /// - [digestLength]: The length of the hash digest in bytes (default is 64 bytes).
  /// - [config]: Optional configuration for BLAKE2b (e.g., key, salt, personalization).
  static BuBytes hash(
    List<int> data, [
    int digestLength = 64,
    Blake2Config? config,
  ]) {
    final h = BLAKE2b(digestLength: digestLength, config: config);
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }

  /// Creates a BLAKE2b hash instance with the specified digest length and optional configuration.
  ///
  /// Parameters:
  /// - [digestLength]: The length of the hash digest in bytes (default is 64 bytes).
  /// - [config]: Optional configuration for BLAKE2b (e.g., key, salt, personalization).
  ///
  /// Throws:
  /// - An [BuError] if the provided [digestLength] is out of the valid range.
  BLAKE2b({int digestLength = 64, Blake2Config? config}) {
    if (digestLength < 1 || digestLength > _digestLength) {
      throw CoreErrors.invalidOperationArguments(
        "BLAKE2b",
        name: "digestLength",
        reason: "Incorrect digest length.",
      );
    }
    _getDigestLength = digestLength;
    int klength = 0;
    if (config != null && config.key != null) {
      klength = config.key!.length;
    }

    int fanout = 1;
    int maxDepth = 1;
    // final tree = config?.tree;
    if (config != null) {
      fanout = config.fanout;
      maxDepth = config.maxDepth;
    }

    _state[0] ^=
        (getDigestLength | (klength << 8) | (fanout << 16) | (maxDepth << 24));

    if (config != null) {
      _state[1] ^= config.leafSize;
      if (config.nodeOffset > 0) {
        final u64 = Uint64(config.nodeOffset);
        _state[2] ^= u64.lo;
        _state[3] ^= u64.hi;
      }

      _state[4] ^= (config.nodeDepth | (config.innerDigestLength << 8));
      _lastNode = config.lastNode;
    }

    final salt = config?.salt;
    if (salt != null) {
      _state[8] ^= BinaryOps.readUint32LE(salt, 0);
      _state[9] ^= BinaryOps.readUint32LE(salt, 4);
      _state[10] ^= BinaryOps.readUint32LE(salt, 8);
      _state[11] ^= BinaryOps.readUint32LE(salt, 12);
    }
    final personalization = config?.personalization;
    if (personalization != null) {
      _state[12] ^= BinaryOps.readUint32LE(personalization, 0);
      _state[13] ^= BinaryOps.readUint32LE(personalization, 4);
      _state[14] ^= BinaryOps.readUint32LE(personalization, 8);
      _state[15] ^= BinaryOps.readUint32LE(personalization, 12);
    }
    _initialState = List<int>.from(_state, growable: false);
    final key = config?.key;
    if (key != null && _keyLength > 0) {
      _paddedKey = List<int>.filled(_blockSize, 0);
      _paddedKey!.setAll(0, key.asBytes);
      _buffer.setAll(0, _paddedKey!);
      _bufferLength = _blockSize;
    }
  }

  /// Resets the BLAKE2b hash instance to its initial state, clearing all internal data.
  ///
  /// This method restores the initial state of the hash function, including the hash state,
  /// the buffer, counters, and flags. If a key was previously set, it will be put back into
  /// the buffer.
  ///
  @override
  BLAKE2b reset() {
    _ensureAlive("BLAKE2b.reset", _cleaned, null);
    _state.setAll(0, _initialState);

    if (_paddedKey != null) {
      _buffer.setAll(0, _paddedKey!);
      _bufferLength = _blockSize;
    } else {
      _bufferLength = 0;
    }

    BinaryOps.zero(_ctr);
    BinaryOps.zero(_flag);
    _finished = false;

    return this;
  }

  /// Updates the BLAKE2b hash with the given data, optionally specifying the data length.
  ///
  /// Parameters:
  /// - [data]: The data to be hashed.
  /// - [length] (optional): The length of data to process. If not specified, the entire data
  ///   will be processed.
  ///
  @override
  BLAKE2b update(List<int> data, {int? length}) {
    _ensureAlive("BLAKE2b.update", _cleaned, _finished);

    final int left = _blockSize - _bufferLength;
    int dataPos = 0;

    int dataLength = length ?? data.length;

    if (dataLength == 0) {
      return this;
    }

    // Finish buffer.
    if (dataLength > left) {
      for (int i = 0; i < left; i++) {
        _buffer[_bufferLength + i] = data[dataPos + i] & BinaryOps.mask8;
      }
      _processBlock(_blockSize);
      dataPos += left;
      dataLength -= left;
      _bufferLength = 0;
    }

    // Process data blocks.
    while (dataLength > _blockSize) {
      for (int i = 0; i < _blockSize; i++) {
        _buffer[i] = data[dataPos + i] & BinaryOps.mask8;
      }
      _processBlock(_blockSize);
      dataPos += _blockSize;
      dataLength -= _blockSize;
      _bufferLength = 0;
    }

    // Copy leftovers to buffer.
    for (int i = 0; i < dataLength; i++) {
      _buffer[_bufferLength + i] = data[dataPos + i] & BinaryOps.mask8;
    }
    _bufferLength += dataLength;

    return this;
  }

  /// Finalizes the BLAKE2b hash, producing the hash digest and writing it to the given output.
  ///
  /// Parameters:
  /// - [out]: The hash digest will be written.
  ///
  @override
  BLAKE2b finish(List<int> out) {
    _ensureAlive("BLAKE2b.finish", _cleaned, null);
    if (!_finished) {
      for (int i = _bufferLength; i < _blockSize; i++) {
        _buffer[i] = 0;
      }

      // Set last block flag.
      _flag[0] = BinaryOps.mask32;
      _flag[1] = BinaryOps.mask32;

      // Set last node flag if the last node in the tree.
      if (_lastNode) {
        _flag[2] = BinaryOps.mask32;
        _flag[3] = BinaryOps.mask32;
      }

      _processBlock(_bufferLength);
      _finished = true;
    }

    final List<int> tmp = List<int>.filled(64, 0);
    for (int i = 0; i < 16; i++) {
      BinaryOps.writeUint32LE(_state[i], tmp, i * 4);
    }
    out.setRange(0, out.length, tmp);
    return this;
  }

  /// Returns the final hash digest.
  @override
  BuBytes digest() {
    final BuBytes out = BuBytes.fill(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Cleans sensitive data and resets the internal state of the hash function.
  @override
  void clean() {
    BinaryOps.zero(_vtmp);
    BinaryOps.zero(_mtmp);
    BinaryOps.zero(_state);
    BinaryOps.zero(_buffer);
    BinaryOps.zero(_initialState);
    BinaryOps.tryZero(_paddedKey);
    _paddedKey = null;
    _bufferLength = 0;
    BinaryOps.zero(_ctr);
    BinaryOps.zero(_flag);
    _lastNode = false;
    _finished = false;
    _cleaned = true;
  }

  void _g(
    List<int> v,
    int al,
    int bl,
    int cl,
    int dl,
    int ah,
    int bh,
    int ch,
    int dh,
    int ml0,
    int mh0,
    int ml1,
    int mh1,
  ) {
    int vla = v[al],
        vha = v[ah],
        vlb = v[bl],
        vhb = v[bh],
        vlc = v[cl],
        vhc = v[ch],
        vld = v[dl],
        vhd = v[dh];

    // 64-bit: va += vb
    int w = vla & BinaryOps.mask16,
        x = (vla >> 16) & BinaryOps.mask16,
        y = vha & BinaryOps.mask16,
        z = (vha >> 16) & BinaryOps.mask16;

    w += vlb & BinaryOps.mask16;
    x += (vlb >> 16) & BinaryOps.mask16;
    y += vhb & BinaryOps.mask16;
    z += (vhb >> 16) & BinaryOps.mask16;

    x += (w >> 16) & BinaryOps.mask16;
    y += (x >> 16) & BinaryOps.mask16;
    z += (y >> 16) & BinaryOps.mask16;

    vha = ((y & BinaryOps.mask16) | (z << 16)) & BinaryOps.mask32;
    vla = ((w & BinaryOps.mask16) | (x << 16)) & BinaryOps.mask32;

    // 64-bit: va += m[sigma[r][2 * i + 0]]
    w = vla & BinaryOps.mask16;
    x = (vla >> 16) & BinaryOps.mask16;
    y = vha & BinaryOps.mask16;
    z = (vha >> 16) & BinaryOps.mask16;

    w += ml0 & BinaryOps.mask16;
    x += (ml0 >> 16) & BinaryOps.mask16;
    y += mh0 & BinaryOps.mask16;
    z += (mh0 >> 16) & BinaryOps.mask16;

    x += (w >> 16) & BinaryOps.mask16;
    y += (x >> 16) & BinaryOps.mask16;
    z += (y >> 16) & BinaryOps.mask16;

    vha = ((y & BinaryOps.mask16) | (z << 16)) & BinaryOps.mask32;
    vla = ((w & BinaryOps.mask16) | (x << 16)) & BinaryOps.mask32;

    // 64-bit: vd ^= va
    vld ^= vla;
    vhd ^= vha;

    // 64-bit: rot(vd, 32)
    w = vhd;
    vhd = vld;
    vld = w;

    // 64-bit: vc += vd
    w = vlc & BinaryOps.mask16;
    x = (vlc >> 16) & BinaryOps.mask16;
    y = vhc & BinaryOps.mask16;
    z = (vhc >> 16) & BinaryOps.mask16;

    w += vld & BinaryOps.mask16;
    x += (vld >> 16) & BinaryOps.mask16;
    y += vhd & BinaryOps.mask16;
    z += (vhd >> 16) & BinaryOps.mask16;

    x += (w >> 16) & BinaryOps.mask16;
    y += (x >> 16) & BinaryOps.mask16;
    z += (y >> 16) & BinaryOps.mask16;

    vhc = ((y & BinaryOps.mask16) | (z << 16)) & BinaryOps.mask32;
    vlc = ((w & BinaryOps.mask16) | (x << 16)) & BinaryOps.mask32;

    // 64-bit: vb ^= vc
    vlb ^= vlc;
    vhb ^= vhc;

    // 64-bit: rot(vb, 24)
    w = ((vlb << 8) | (vhb >> 24)) & BinaryOps.mask32;
    vlb = ((vhb << 8) | (vlb >> 24)) & BinaryOps.mask32;
    vhb = w;

    // 64-bit: va += vb
    w = vla & BinaryOps.mask16;
    x = (vla >> 16) & BinaryOps.mask16;
    y = vha & BinaryOps.mask16;
    z = (vha >> 16) & BinaryOps.mask16;

    w += vlb & BinaryOps.mask16;
    x += (vlb >> 16) & BinaryOps.mask16;
    y += vhb & BinaryOps.mask16;
    z += (vhb >> 16) & BinaryOps.mask16;

    x += (w >> 16) & BinaryOps.mask16;
    y += (x >> 16) & BinaryOps.mask16;
    z += (y >> 16) & BinaryOps.mask16;

    vha = ((y & BinaryOps.mask16) | (z << 16)) & BinaryOps.mask32;
    vla = ((w & BinaryOps.mask16) | (x << 16)) & BinaryOps.mask32;

    // 64-bit: va += m[sigma[r][2 * i + 1]
    w = vla & BinaryOps.mask16;
    x = (vla >> 16) & BinaryOps.mask16;
    y = vha & BinaryOps.mask16;
    z = (vha >> 16) & BinaryOps.mask16;

    w += ml1 & BinaryOps.mask16;
    x += (ml1 >> 16) & BinaryOps.mask16;
    y += mh1 & BinaryOps.mask16;
    z += (mh1 >> 16) & BinaryOps.mask16;

    x += (w >> 16) & BinaryOps.mask16;
    y += (x >> 16) & BinaryOps.mask16;
    z += (y >> 16) & BinaryOps.mask16;

    vha = ((y & BinaryOps.mask16) | (z << 16)) & BinaryOps.mask32;
    vla = ((w & BinaryOps.mask16) | (x << 16)) & BinaryOps.mask32;

    // 64-bit: vd ^= va
    vld ^= vla;
    vhd ^= vha;

    // 64-bit: rot(vd, 16)
    w = ((vld << 16) | (vhd >> 16)) & BinaryOps.mask32;
    vld = ((vhd << 16) | (vld >> 16)) & BinaryOps.mask32;
    vhd = w;

    // 64-bit: vc += vd
    w = vlc & BinaryOps.mask16;
    x = (vlc >> 16) & BinaryOps.mask16;
    y = vhc & BinaryOps.mask16;
    z = (vhc >> 16) & BinaryOps.mask16;

    w += vld & BinaryOps.mask16;
    x += (vld >> 16) & BinaryOps.mask16;
    y += vhd & BinaryOps.mask16;
    z += (vhd >> 16) & BinaryOps.mask16;

    x += (w >> 16) & BinaryOps.mask16;
    y += (x >> 16) & BinaryOps.mask16;
    z += (y >> 16) & BinaryOps.mask16;

    vhc = ((y & BinaryOps.mask16) | (z << 16)) & BinaryOps.mask32;
    vlc = ((w & BinaryOps.mask16) | (x << 16)) & BinaryOps.mask32;

    // 64-bit: vb ^= vc
    vlb ^= vlc;
    vhb ^= vhc;

    // 64-bit: rot(vb, 63)
    w = ((vhb << 1) | (vlb >> 31)) & BinaryOps.mask32;
    vlb = ((vlb << 1) | (vhb >> 31)) & BinaryOps.mask32;
    vhb = w;

    v[al] = vla;
    v[ah] = vha;
    v[bl] = vlb;
    v[bh] = vhb;
    v[cl] = vlc;
    v[ch] = vhc;
    v[dl] = vld;
    v[dh] = vhd;
  }

  void _processBlock(int length) {
    _incrementCounter(length);
    final v = _vtmp;
    v.setAll(0, _state);
    v.setAll(16, _iv);
    v[12 * 2 + 0] ^= _ctr[0];
    v[12 * 2 + 1] ^= _ctr[1];
    v[13 * 2 + 0] ^= _ctr[2];
    v[13 * 2 + 1] ^= _ctr[3];
    v[14 * 2 + 0] ^= _flag[0];
    v[14 * 2 + 1] ^= _flag[1];
    v[15 * 2 + 0] ^= _flag[2];
    v[15 * 2 + 1] ^= _flag[3];
    final m = _mtmp;
    for (var i = 0; i < 32; i++) {
      m[i] = BinaryOps.readUint32LE(_buffer, i * 4);
    }
    for (var r = 0; r < 12; r++) {
      _g(
        v,
        0,
        8,
        16,
        24,
        1,
        9,
        17,
        25,
        m[_sigma[r][0]],
        m[_sigma[r][0] + 1],
        m[_sigma[r][1]],
        m[_sigma[r][1] + 1],
      );

      _g(
        v,
        2,
        10,
        18,
        26,
        3,
        11,
        19,
        27,
        m[_sigma[r][2]],
        m[_sigma[r][2] + 1],
        m[_sigma[r][3]],
        m[_sigma[r][3] + 1],
      );

      _g(
        v,
        4,
        12,
        20,
        28,
        5,
        13,
        21,
        29,
        m[_sigma[r][4]],
        m[_sigma[r][4] + 1],
        m[_sigma[r][5]],
        m[_sigma[r][5] + 1],
      );
      _g(
        v,
        6,
        14,
        22,
        30,
        7,
        15,
        23,
        31,
        m[_sigma[r][6]],
        m[_sigma[r][6] + 1],
        m[_sigma[r][7]],
        m[_sigma[r][7] + 1],
      );
      _g(
        v,
        0,
        10,
        20,
        30,
        1,
        11,
        21,
        31,
        m[_sigma[r][8]],
        m[_sigma[r][8] + 1],
        m[_sigma[r][9]],
        m[_sigma[r][9] + 1],
      );
      _g(
        v,
        2,
        12,
        22,
        24,
        3,
        13,
        23,
        25,
        m[_sigma[r][10]],
        m[_sigma[r][10] + 1],
        m[_sigma[r][11]],
        m[_sigma[r][11] + 1],
      );
      _g(
        v,
        4,
        14,
        16,
        26,
        5,
        15,
        17,
        27,
        m[_sigma[r][12]],
        m[_sigma[r][12] + 1],
        m[_sigma[r][13]],
        m[_sigma[r][13] + 1],
      );
      _g(
        v,
        6,
        8,
        18,
        28,
        7,
        9,
        19,
        29,
        m[_sigma[r][14]],
        m[_sigma[r][14] + 1],
        m[_sigma[r][15]],
        m[_sigma[r][15] + 1],
      );
    }
    for (var i = 0; i < 16; i++) {
      _state[i] ^= v[i] ^ v[i + 16];
    }
  }

  /// Cleans and resets a saved hash state, securely erasing sensitive data.
  ///
  /// Parameters:
  /// - [savedState]: The hash state to clean and reset securely.
  @override
  void cleanSavedState(Blake2State savedState) {
    BinaryOps.zero(savedState.state);
    BinaryOps.zero(savedState.buffer);
    BinaryOps.zero(savedState.initialState);
    BinaryOps.tryZero(savedState.paddedKey);
    savedState.bufferLength = 0;
    BinaryOps.zero(savedState.ctr);
    BinaryOps.zero(savedState.flag);
    savedState.lastNode = false;
  }

  @override
  int get getBlockSize => _blockSize;

  int _getDigestLength = 64;

  @override
  int get getDigestLength => _getDigestLength;

  /// Restores the hash state to a previously saved state object.
  ///
  /// Parameters:
  /// - [savedState]: The saved hash state to restore.
  @override
  BLAKE2b restoreState(Blake2State savedState) {
    _ensureAlive("BLAKE2b.restoreState", _cleaned, _finished);
    _getDigestLength = savedState.digestLength;
    _state.setAll(0, savedState.state);
    _buffer.setAll(0, savedState.buffer);
    _bufferLength = savedState.bufferLength;
    _ctr.setAll(0, savedState.ctr);
    _flag.setAll(0, savedState.flag);
    _lastNode = savedState.lastNode;

    if (_paddedKey != null) {
      BinaryOps.zero(_paddedKey!);
    }

    _paddedKey =
        savedState.paddedKey != null
            ? List<int>.from(savedState.paddedKey!)
            : null;

    _initialState.setAll(0, savedState.initialState);

    return this;
  }

  /// Saves the current state of the BLAKE2b hash function for future restoration.
  ///
  /// Throws:
  /// - [CryptoException] if the hash function has already been marked as finished.
  @override
  Blake2State saveState() {
    _ensureAlive("BLAKE2b.saveState", _cleaned, _finished);
    return Blake2State(
      state: List<int>.from(_state, growable: false),
      buffer: List<int>.from(_buffer, growable: false),
      bufferLength: _bufferLength,
      ctr: List<int>.from(_ctr, growable: false),
      flag: List<int>.from(_flag, growable: false),
      lastNode: _lastNode,
      paddedKey: _paddedKey != null ? List<int>.from(_paddedKey!) : null,
      initialState: List<int>.from(_initialState, growable: false),
      digestLength: _getDigestLength,
    );
  }

  void _incrementCounter(int length) {
    for (int i = 0; i < 3; i++) {
      final int a = _ctr[i] + length;
      _ctr[i] = a & BinaryOps.mask32;
      if (_ctr[i] == a) {
        return;
      }
      length = 1;
    }
  }
}

/// Serializable snapshot of an in-progress BLAKE2b computation.
class Blake2State extends HashState {
  /// The state vector of the hash function.
  List<int> state;

  /// The buffer of the hash function.
  List<int> buffer;

  /// The length of data currently stored in the buffer.
  int bufferLength;

  /// The counter values used by the hash function.
  List<int> ctr;

  /// The flags used by the hash function.
  List<int> flag;

  /// Indicates whether the hash function represents the last node in a tree.
  bool lastNode;

  /// The padded key used by the hash function, if any.
  List<int>? paddedKey;

  /// The initial state of the hash function.
  List<int> initialState;

  final int digestLength;

  /// Creates a new instance of the Blake2sState class with the provided values.
  Blake2State({
    required this.state,
    required this.buffer,
    required this.bufferLength,
    required this.ctr,
    required this.flag,
    required this.lastNode,
    required this.digestLength,
    this.paddedKey,
    required this.initialState,
  });
}
