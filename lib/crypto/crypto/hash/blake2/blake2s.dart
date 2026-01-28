part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// Configuration class for the Blake2b hash function.
class Blake2sConfig {
  /// The key used in the hash function, if provided.
  final List<int>? key;

  /// A salt value for customizing the hash.
  final List<int>? salt;

  /// A custom personalization string.
  final List<int>? personalization;
  // Configuration for the tree structure, if applicable.
  final Blake2sTree? tree;

  const Blake2sConfig({this.key, this.salt, this.personalization, this.tree});

  Blake2sConfig copyWith({
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    Blake2sTree? tree,
  }) {
    return Blake2sConfig(
      key: key ?? this.key,
      salt: salt ?? this.salt,
      personalization: personalization ?? this.personalization,
      tree: tree ?? this.tree,
    );
  }
}

/// Configuration for the tree structure in Blake2b.
class Blake2sTree {
  final int nodeOffset;

  /// The fanout value for the tree structure.
  final int fanout;

  /// The maximum depth of the tree.
  final int maxDepth;

  /// The size of the leaf nodes in the tree.
  final int leafSize;

  /// The depth of the current node in the tree.
  final int nodeDepth;

  /// The length of the inner digest.
  final int innerDigestLength;

  /// Indicates whether this is the last node in the tree.
  final bool lastNode;

  const Blake2sTree({
    required this.fanout,
    required this.maxDepth,
    required this.leafSize,
    required this.nodeDepth,
    required this.innerDigestLength,
    required this.lastNode,
    required this.nodeOffset,
  });
}

class Blake2sState implements HashState {
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

  /// Creates a new instance of the Blake2sState class with the provided values.
  Blake2sState({
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

/// Implementation of the BLAKE2s hash function that implements the SerializableHash interface.
class BLAKE2s implements SerializableHash<Blake2sState> {
  final int _blockSize = 64; // 64 bytes
  final int _digestLength = 32; // max digest
  final int _keyLength = 32;
  final int _saltLength = 8;
  final int _personalizationLength = 8;
  final int _maxFanout = 255;
  final int _maxMaxDepth = 255;
  final int _maxLeafSize = 4294967295;
  final int _maxNodeOffset = 281474976710655;
  final List<int> _iv = const [
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19,
  ];
  late final List<int> _state = List<int>.from(_iv, growable: false);
  final List<int> _buffer = List<int>.filled(64, 0);
  int _bufferLength = 0;
  final List<int> _ctr = List<int>.filled(2, 0);
  final List<int> _flag = List<int>.filled(2, 0);
  bool _lastNode = false;
  bool _finished = false;
  List<int>? _paddedKey;
  List<int> _initialState = [];
  static List<int> hash(
    List<int> data, [
    int digestLength = 32,
    Blake2sConfig? config,
  ]) {
    final h = BLAKE2s(digestLength: digestLength, config: config);
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }

  /// Creates a BLAKE2s hash instance with the specified digest length and optional configuration.
  ///
  /// Parameters:
  /// - [digestLength]: The length of the hash digest in bytes (default is 64 bytes).
  /// - [config]: Optional configuration for BLAKE2s (e.g., key, salt, personalization).
  ///
  /// Throws:
  /// - An [ArgumentException] if the provided [digestLength] is out of the valid range.
  BLAKE2s({int digestLength = 32, Blake2sConfig? config}) {
    if (digestLength < 1 || digestLength > _digestLength) {
      throw ArgumentException.invalidOperationArguments(
        "BLAKE2s",
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
      final nofHi = (tree.nodeOffset ~/ 0x100000000) & BinaryOps.mask32;
      final nofLo = tree.nodeOffset & BinaryOps.mask32;
      _state[1] ^= tree.leafSize;
      _state[2] ^= nofLo;
      _state[3] ^=
          nofHi | (tree.nodeDepth << 16) | (tree.innerDigestLength << 24);
      _lastNode = tree.lastNode;
    }
    final salt = config?.salt;
    if (salt != null) {
      _state[4] ^= BinaryOps.readUint32LE(salt, 0);
      _state[5] ^= BinaryOps.readUint32LE(salt, 4);
    }
    final personalization = config?.personalization;
    if (personalization != null) {
      _state[6] ^= BinaryOps.readUint32LE(personalization, 0);
      _state[7] ^= BinaryOps.readUint32LE(personalization, 4);
    }
    _initialState = _state.immutable;
    final key = config?.key;
    if (key != null && _keyLength > 0) {
      _paddedKey = List<int>.filled(_blockSize, 0);
      _paddedKey!.setAll(0, key.asBytes);
      _buffer.setAll(0, _paddedKey!);
      _bufferLength = _blockSize;
    }
  }
  @override
  BLAKE2s reset() {
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

  Blake2sConfig? _validateConfig(Blake2sConfig? config) {
    if (config == null) return config;
    final tree = config.tree;
    List<int>? key = config.key?.clone();
    List<int>? salt = config.salt?.clone();
    List<int>? personalization = config.personalization?.clone();
    if (key != null && key.length > _keyLength) {
      throw ArgumentException.invalidOperationArguments(
        "Blake2sConfig",
        name: "key",
        reason: "Incorrect key length.",
      );
    }
    if (salt != null) {
      if (salt.length > _saltLength) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2sConfig",
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
          "Blake2sConfig",
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
          "Blake2sTree",
          name: "fanout",
          reason: "Incorrect fanout.",
        );
      }
      if (tree.maxDepth < 0 || tree.maxDepth > _maxMaxDepth) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2sTree",
          name: "depth",
          reason: "Incorrect depth.",
        );
      }
      if (tree.leafSize < 0 || tree.leafSize > _maxLeafSize) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2sTree",
          name: "leafSize",
          reason: "Incorrect leaf size.",
        );
      }
      if (tree.innerDigestLength < 0 ||
          tree.innerDigestLength > _digestLength) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2sTree",
          name: "innerDigestLength",
          reason: "Incorrect inner digest length",
        );
      }
      if (tree.nodeOffset < 0 || tree.nodeOffset > _maxNodeOffset) {
        throw ArgumentException.invalidOperationArguments(
          "Blake2sTree",
          name: "nodeOffset",
          reason: "Incorrect node offset.",
        );
      }
    }
    return Blake2sConfig(
      key: key,
      personalization: personalization,
      salt: salt,
      tree: tree,
    );
  }

  @override
  BLAKE2s update(List<int> data, {int? length}) {
    if (_finished) {
      throw const CryptoException(
        "blake2s: can't update because hash was finished.",
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

  @override
  BLAKE2s finish(List<int> out) {
    if (!_finished) {
      for (int i = _bufferLength; i < _blockSize; i++) {
        _buffer[i] = 0;
      }

      // Set last block flag.
      _flag[0] = BinaryOps.mask32;
      // Set last node flag if the last node in the tree.
      if (_lastNode) {
        _flag[1] = BinaryOps.mask32;
      }

      _processBlock(_bufferLength);
      _finished = true;
    }

    final List<int> tmp = List<int>.filled(32, 0);
    for (int i = 0; i < 8; i++) {
      BinaryOps.writeUint32LE(_state[i], tmp, i * 4);
    }
    out.setRange(0, out.length, tmp);
    return this;
  }

  @override
  List<int> digest() {
    final List<int> out = List<int>.filled(getDigestLength, 0);
    finish(out);
    return out;
  }

  @override
  void clean() {
    BinaryOps.zero(_state);
    BinaryOps.zero(_buffer);
    _initialState = [];
    if (_paddedKey != null) {
      BinaryOps.zero(_paddedKey!);
    }
    _bufferLength = 0;
    BinaryOps.zero(_ctr);
    BinaryOps.zero(_flag);
    _lastNode = false;
    _finished = false;
  }

  void _processBlock(int length) {
    int nc = _ctr[0] + length;
    _ctr[0] = (nc & BinaryOps.mask32);
    if (nc != _ctr[0]) {
      _ctr[1] = _ctr[1] + 1;
    }

    int v0 = _state[0],
        v1 = _state[1],
        v2 = _state[2],
        v3 = _state[3],
        v4 = _state[4],
        v5 = _state[5],
        v6 = _state[6],
        v7 = _state[7],
        v8 = _iv[0],
        v9 = _iv[1],
        v10 = _iv[2],
        v11 = _iv[3],
        v12 = (_iv[4] ^ _ctr[0]),
        v13 = (_iv[5] ^ _ctr[1]),
        v14 = (_iv[6] ^ _flag[0]),
        v15 = (_iv[7] ^ _flag[1]);

    final x = _buffer;
    final m0 = (x[3] << 24) | (x[2] << 16) | (x[1] << 8) | x[0];
    final m1 = (x[7] << 24) | (x[6] << 16) | (x[5] << 8) | x[4];
    final m2 = (x[11] << 24) | (x[10] << 16) | (x[9] << 8) | x[8];
    final m3 = (x[15] << 24) | (x[14] << 16) | (x[13] << 8) | x[12];
    final m4 = (x[19] << 24) | (x[18] << 16) | (x[17] << 8) | x[16];
    final m5 = (x[23] << 24) | (x[22] << 16) | (x[21] << 8) | x[20];
    final m6 = (x[27] << 24) | (x[26] << 16) | (x[25] << 8) | x[24];
    final m7 = (x[31] << 24) | (x[30] << 16) | (x[29] << 8) | x[28];
    final m8 = (x[35] << 24) | (x[34] << 16) | (x[33] << 8) | x[32];
    final m9 = (x[39] << 24) | (x[38] << 16) | (x[37] << 8) | x[36];
    final m10 = (x[43] << 24) | (x[42] << 16) | (x[41] << 8) | x[40];
    final m11 = (x[47] << 24) | (x[46] << 16) | (x[45] << 8) | x[44];
    final m12 = (x[51] << 24) | (x[50] << 16) | (x[49] << 8) | x[48];
    final m13 = (x[55] << 24) | (x[54] << 16) | (x[53] << 8) | x[52];
    final m14 = (x[59] << 24) | (x[58] << 16) | (x[57] << 8) | x[56];
    final m15 = (x[63] << 24) | (x[62] << 16) | (x[61] << 8) | x[60];

    // Round 1.
    v0 = (v0 + m0);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v1 = (v1 + m2);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v2 = (v2 + m4);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v3 = (v3 + m6);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v2 = (v2 + m5);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v3 = (v3 + m7);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v1 = (v1 + m3);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    v0 = (v0 + m1);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v0 = (v0 + m8);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v1 = (v1 + m10);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v2 = (v2 + m12);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v3 = (v3 + m14);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v2 = (v2 + m13);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v3 = (v3 + m15);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v1 = (v1 + m11);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v0 = (v0 + m9);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);

    // Round 2.
    v0 = (v0 + m14);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v1 = (v1 + m4);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v2 = (v2 + m9);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v3 = (v3 + m13);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v2 = (v2 + m15);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v3 = (v3 + m6);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v1 = (v1 + m8);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    v0 = (v0 + m10);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v0 = (v0 + m1);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v1 = (v1 + m0);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v2 = (v2 + m11);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v3 = (v3 + m5);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v2 = (v2 + m7);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v3 = (v3 + m3);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v1 = (v1 + m2);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v0 = (v0 + m12);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);

    // Round 3.
    v0 = (v0 + m11);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v1 = (v1 + m12);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v2 = (v2 + m5);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v3 = (v3 + m15);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v2 = (v2 + m2);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v3 = (v3 + m13);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v1 = (v1 + m0);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    v0 = (v0 + m8);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v0 = (v0 + m10);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v1 = (v1 + m3);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v2 = (v2 + m7);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v3 = (v3 + m9);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v2 = (v2 + m1);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v3 = (v3 + m4);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v1 = (v1 + m6);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v0 = (v0 + m14);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);

    // Round 4.
    v0 = (v0 + m7);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v1 = (v1 + m3);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v2 = (v2 + m13);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v3 = (v3 + m11);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v2 = (v2 + m12);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v3 = (v3 + m14);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v1 = (v1 + m1);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    v0 = (v0 + m9);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v0 = (v0 + m2);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v1 = (v1 + m5);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v2 = (v2 + m4);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v3 = (v3 + m15);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v2 = (v2 + m0);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v3 = (v3 + m8);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v1 = (v1 + m10);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v0 = (v0 + m6);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);

    // Round 5.
    v0 = (v0 + m9);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v1 = (v1 + m5);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v2 = (v2 + m2);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v3 = (v3 + m10);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v2 = (v2 + m4);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v3 = (v3 + m15);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v1 = (v1 + m7);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    v0 = (v0 + m0);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v0 = (v0 + m14);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v1 = (v1 + m11);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v2 = (v2 + m6);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v3 = (v3 + m3);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v2 = (v2 + m8);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v3 = (v3 + m13);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v1 = (v1 + m12);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v0 = (v0 + m1);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);

    // Round 6.
    v0 = (v0 + m2);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v1 = (v1 + m6);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v2 = (v2 + m0);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v3 = (v3 + m8);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v2 = (v2 + m11);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v3 = (v3 + m3);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v1 = (v1 + m10);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    v0 = (v0 + m12);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v0 = (v0 + m4);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v1 = (v1 + m7);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v2 = (v2 + m15);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v3 = (v3 + m1);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v2 = (v2 + m14);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v3 = (v3 + m9);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v1 = (v1 + m5);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v0 = (v0 + m13);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);

    // Round 7.
    v0 = (v0 + m12);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v1 = (v1 + m1);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v2 = (v2 + m14);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v3 = (v3 + m4);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v2 = (v2 + m13);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v3 = (v3 + m10);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v1 = (v1 + m15);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    v0 = (v0 + m5);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v0 = (v0 + m0);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v1 = (v1 + m6);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v2 = (v2 + m9);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v3 = (v3 + m8);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v2 = (v2 + m2);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v3 = (v3 + m11);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v1 = (v1 + m3);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v0 = (v0 + m7);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);

    // Round 8.
    v0 = (v0 + m13);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v1 = (v1 + m7);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v2 = (v2 + m12);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v3 = (v3 + m3);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v2 = (v2 + m1);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v3 = (v3 + m9);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v1 = (v1 + m14);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    v0 = (v0 + m11);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v0 = (v0 + m5);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v1 = (v1 + m15);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v2 = (v2 + m8);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v3 = (v3 + m2);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v2 = (v2 + m6);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v3 = (v3 + m10);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v1 = (v1 + m4);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v0 = (v0 + m0);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);

    // Round 9.
    v0 = (v0 + m6);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v1 = (v1 + m14);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v2 = (v2 + m11);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v3 = (v3 + m0);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v2 = (v2 + m3);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v3 = (v3 + m8);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v1 = (v1 + m9);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    v0 = (v0 + m15);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v0 = (v0 + m12);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v1 = (v1 + m13);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v2 = (v2 + m1);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v3 = (v3 + m10);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v2 = (v2 + m4);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v3 = (v3 + m5);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v1 = (v1 + m7);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v0 = (v0 + m2);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);

    // Round 10.
    v0 = (v0 + m10);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v1 = (v1 + m8);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v2 = (v2 + m7);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v3 = (v3 + m1);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v2 = (v2 + m6);
    v2 = (v2 + v6);
    v14 = (v14 ^ v2) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v10 = (v10 + v14);
    v6 = (v6 ^ v10) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v3 = (v3 + m5);
    v3 = (v3 + v7);
    v15 = (v15 ^ v3) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v11 = (v11 + v15);
    v7 = (v7 ^ v11) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v1 = (v1 + m4);
    v1 = (v1 + v5);
    v13 = (v13 ^ v1) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v9 = (v9 + v13);
    v5 = (v5 ^ v9) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    v0 = (v0 + m2);
    v0 = (v0 + v4);
    v12 = (v12 ^ v0) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v8 = (v8 + v12);
    v4 = (v4 ^ v8) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v0 = (v0 + m15);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 16)) | v15 >> 16);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 12)) | v5 >> 12);
    v1 = (v1 + m9);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 16)) | v12 >> 16);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 12)) | v6 >> 12);
    v2 = (v2 + m3);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 16)) | v13 >> 16);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 12)) | v7 >> 12);
    v3 = (v3 + m13);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 16)) | v14 >> 16);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 12)) | v4 >> 12);
    v2 = (v2 + m12);
    v2 = (v2 + v7);
    v13 = (v13 ^ v2) & (BinaryOps.mask32);
    v13 = ((v13 << (32 - 8)) | v13 >> 8);
    v8 = (v8 + v13);
    v7 = (v7 ^ v8) & (BinaryOps.mask32);
    v7 = ((v7 << (32 - 7)) | v7 >> 7);
    v3 = (v3 + m0);
    v3 = (v3 + v4);
    v14 = (v14 ^ v3) & (BinaryOps.mask32);
    v14 = ((v14 << (32 - 8)) | v14 >> 8);
    v9 = (v9 + v14);
    v4 = (v4 ^ v9) & (BinaryOps.mask32);
    v4 = ((v4 << (32 - 7)) | v4 >> 7);
    v1 = (v1 + m14);
    v1 = (v1 + v6);
    v12 = (v12 ^ v1) & (BinaryOps.mask32);
    v12 = ((v12 << (32 - 8)) | v12 >> 8);
    v11 = (v11 + v12);
    v6 = (v6 ^ v11) & (BinaryOps.mask32);
    v6 = ((v6 << (32 - 7)) | v6 >> 7);
    v0 = (v0 + m11);
    v0 = (v0 + v5);
    v15 = (v15 ^ v0) & (BinaryOps.mask32);
    v15 = ((v15 << (32 - 8)) | v15 >> 8);
    v10 = (v10 + v15);
    v5 = (v5 ^ v10) & (BinaryOps.mask32);
    v5 = ((v5 << (32 - 7)) | v5 >> 7);
    _state[0] ^= (v0 ^ v8).toU32;
    _state[1] ^= (v1 ^ v9).toU32;
    _state[2] ^= (v2 ^ v10).toU32;
    _state[3] ^= (v3 ^ v11).toU32;
    _state[4] ^= (v4 ^ v12).toU32;
    _state[5] ^= (v5 ^ v13).toU32;
    _state[6] ^= (v6 ^ v14).toU32;
    _state[7] ^= (v7 ^ v15).toU32;
  }

  @override
  void cleanSavedState(Blake2sState savedState) {
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
  @override
  BLAKE2s restoreState(Blake2sState savedState) {
    _state.setAll(0, savedState.state);
    _buffer.setAll(0, savedState.buffer);
    _bufferLength = savedState.bufferLength;
    _ctr.setAll(0, savedState.ctr);
    _flag.setAll(0, savedState.flag);
    _lastNode = savedState.lastNode;
    if (_paddedKey != null) {
      BinaryOps.zero(_paddedKey!);
    }
    _paddedKey = savedState.paddedKey?.clone();
    _initialState.setAll(0, savedState.initialState);
    return this;
  }

  @override
  Blake2sState saveState() {
    if (_finished) {
      throw CryptoException.failed(
        "Blake2sState.saveState",
        reason: "State was finished.",
      );
    }
    return Blake2sState(
      state: _state.clone(),
      buffer: _buffer.clone(),
      bufferLength: _bufferLength,
      ctr: _ctr.clone(),
      flag: _flag.clone(),
      lastNode: _lastNode,
      paddedKey: _paddedKey?.clone(),
      initialState: _initialState.clone(),
    );
  }
}
