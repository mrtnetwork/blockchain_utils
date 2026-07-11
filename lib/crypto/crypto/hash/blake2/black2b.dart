part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// Configuration class for the Blake2b hash function.
///
class Blake2bConfig {
  /// The key used in the hash function, if provided.
  final List<int>? key;

  /// A salt value for customizing the hash.
  final List<int>? salt;

  /// A custom personalization string.
  final List<int>? personalization;

  // Configuration for the tree structure, if applicable.
  final Blake2bTree? tree;

  const Blake2bConfig({this.key, this.salt, this.personalization, this.tree});

  Blake2bConfig copyWith({
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    Blake2bTree? tree,
  }) {
    return Blake2bConfig(
      key: key ?? this.key,
      salt: salt ?? this.salt,
      personalization: personalization ?? this.personalization,
      tree: tree ?? this.tree,
    );
  }
}

/// Configuration for the tree structure in Blake2b.
///
/// This class defines parameters related to the tree structure used in the Blake2b hash function, including fanout, maximum depth, leaf size, and more.
class Blake2bTree {
  /// The fanout value for the tree structure.
  final int fanout;

  /// The maximum depth of the tree.
  final int maxDepth;

  /// The size of the leaf nodes in the tree.
  final int leafSize;

  /// High bits of the node offset.
  final int nodeOffsetHighBits;

  /// Low bits of the node offset.
  final int nodeOffsetLowBits;

  /// The depth of the current node in the tree.
  final int nodeDepth;

  /// The length of the inner digest.
  final int innerDigestLength;

  /// Indicates whether this is the last node in the tree.
  final bool lastNode;

  const Blake2bTree({
    required this.fanout,
    required this.maxDepth,
    required this.leafSize,
    required this.nodeOffsetHighBits,
    required this.nodeOffsetLowBits,
    required this.nodeDepth,
    required this.innerDigestLength,
    required this.lastNode,
  });
}

/// Implementation of the BLAKE2b hash function that implements the SerializableHash interface.
class BLAKE2b implements SerializableHash<Blake2bState> {
  final int _blockSize = 128;
  final int _digestLength = 64;
  final int _keyLength = 64;
  final int _personalizationLength = 16;
  final int _saltLength = 16;
  final int _maxLeafSize = 4294967295; // 2^32 - 1
  final int _maxFanout = 255;
  final int _maxMaxDepth = 255;

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

  /// Computes the BLAKE2b hash of the given input data.
  ///
  /// Parameters:
  /// - [data]: The input data to be hashed.
  /// - [digestLength]: The length of the hash digest in bytes (default is 64 bytes).
  /// - [config]: Optional configuration for BLAKE2b (e.g., key, salt, personalization).
  static List<int> hash(
    List<int> data, [
    int digestLength = 64,
    Blake2bConfig? config,
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
  /// - An [ArgumentException] if the provided [digestLength] is out of the valid range.
  BLAKE2b({int digestLength = 64, Blake2bConfig? config}) {
    if (digestLength < 1 || digestLength > _digestLength) {
      throw ArgumentException.invalidOperationArguments(
        "BLAKE2b",
        name: "digestLength",
        reason: "Incorrect diest length.",
      );
    }
    getDigestLength = digestLength;
    config = _validateConfig(config);
    int klength = 0;
    if (config != null && config.key != null) {
      klength = config.key!.length;
    }

    int fanout = 1;
    int maxDepth = 1;
    final tree = config?.tree;
    if (tree != null) {
      fanout = tree.fanout;
      maxDepth = tree.maxDepth;
    }

    _state[0] ^=
        (getDigestLength | (klength << 8) | (fanout << 16) | (maxDepth << 24));

    if (tree != null) {
      _state[1] ^= tree.leafSize;
      _state[2] ^= tree.nodeOffsetLowBits;
      _state[3] ^= tree.nodeOffsetHighBits;
      _state[4] ^= (tree.nodeDepth | (tree.innerDigestLength << 8));
      _lastNode = tree.lastNode;
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

  Blake2bConfig? _validateConfig(Blake2bConfig? config) {
    if (config == null) return config;
    final tree = config.tree;
    List<int>? key = config.key?.clone();
    List<int>? salt = config.salt?.clone();
    List<int>? personalization = config.personalization?.clone();
    if (key != null && key.length > _keyLength) {
      throw ArgumentException.invalidOperationArguments(
        "Blake2bConfig",
        name: "key",
        reason: "Incorrect key length.",
      );
    }
    if (salt != null) {
      if (salt.length > _saltLength) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2bConfig",
          name: "salt",
          reason: "Incorrect salt length.",
        );
      }
      if (salt.length != _saltLength) {
        salt = List.filled(_saltLength, 0)..setAll(0, salt);
      }
    }
    if (personalization != null) {
      if (personalization.length > _personalizationLength) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2bConfig",
          name: "personalization",
          reason: "Incorrect personalization length.",
        );
      }
      if (personalization.length != _personalizationLength) {
        personalization = List.filled(_personalizationLength, 0)
          ..setAll(0, personalization);
      }
    }
    if (tree != null) {
      if (tree.fanout < 0 || tree.fanout > _maxFanout) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2bTree",
          name: "fanout",
          reason: "Incorrect fanout.",
        );
      }
      if (tree.maxDepth < 0 || tree.maxDepth > _maxMaxDepth) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2bTree",
          name: "depth",
          reason: "Incorrect depth.",
        );
      }
      if (tree.leafSize < 0 || tree.leafSize > _maxLeafSize) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2bTree",
          name: "leafSize",
          reason: "Incorrect leaf size.",
        );
      }
      if (tree.innerDigestLength < 0 ||
          tree.innerDigestLength > _digestLength) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2bTree",
          name: "innerDigestLength",
          reason: "Incorrect inner digest length.",
        );
      }
    }
    return Blake2bConfig(
      key: key,
      personalization: personalization,
      salt: salt,
      tree: tree,
    );
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
    if (_finished) {
      throw CryptoException.failed(
        "BLAKE2b.update",
        reason: "State was finished.",
      );
    }

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
  List<int> digest() {
    final List<int> out = List<int>.filled(getDigestLength, 0);
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
    if (_paddedKey != null) {
      BinaryOps.zero(_paddedKey!);
    }
    _bufferLength = 0;
    BinaryOps.zero(_ctr);
    BinaryOps.zero(_flag);
    _lastNode = false;
    _finished = false;
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
  void cleanSavedState(Blake2bState savedState) {
    BinaryOps.zero(savedState.state);
    BinaryOps.zero(savedState.buffer);
    BinaryOps.zero(savedState.initialState);

    if (savedState.paddedKey != null) {
      BinaryOps.zero(savedState.paddedKey!);
    }

    savedState.bufferLength = 0;
    BinaryOps.zero(savedState.ctr);
    BinaryOps.zero(savedState.flag);

    savedState.lastNode = false;
  }

  @override
  int get getBlockSize => _blockSize;

  @override
  late final int getDigestLength;

  /// Restores the hash state to a previously saved state object.
  ///
  /// Parameters:
  /// - [savedState]: The saved hash state to restore.
  @override
  BLAKE2b restoreState(Blake2bState savedState) {
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
  Blake2bState saveState() {
    if (_finished) {
      throw CryptoException.failed(
        "BLAKE2b.saveState",
        reason: "State was finished.",
      );
    }

    return Blake2bState(
      state: List<int>.from(_state, growable: false),
      buffer: List<int>.from(_buffer, growable: false),
      bufferLength: _bufferLength,
      ctr: List<int>.from(_ctr, growable: false),
      flag: List<int>.from(_flag, growable: false),
      lastNode: _lastNode,
      paddedKey: _paddedKey != null ? List<int>.from(_paddedKey!) : null,
      initialState: List<int>.from(_initialState, growable: false),
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

/// Represents the state of a BLAKE2b hash function.
class Blake2bState implements HashState {
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

  /// Creates a new instance of the Blake2bState class with the provided values.
  Blake2bState({
    required this.state,
    required this.buffer,
    required this.bufferLength,
    required this.ctr,
    required this.flag,
    required this.lastNode,
    this.paddedKey,
    required this.initialState,
  });
}
