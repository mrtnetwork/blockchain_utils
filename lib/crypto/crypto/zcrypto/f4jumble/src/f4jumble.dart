import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

/// Implements the F4Jumble transformation and its inverse.
class F4Jumble {
  static const int minValidLength = 48;

  /// Applies the forward F4Jumble transformation to the message.
  static List<int> apply(List<int> message) {
    if (!haveValidLength(message)) {
      throw ArgumentException.invalidOperationArguments(
        "apply",
        name: "message",
        reason: "Invalid message length.",
      );
    }
    final state = _F4JumbleState(message);
    try {
      return state.applyF4Jumble();
    } finally {
      state.clear();
    }
  }

  /// Applies the inverse F4Jumble transformation to the message.
  static List<int> applyInv(List<int> message) {
    if (!haveValidLength(message)) {
      throw ArgumentException.invalidOperationArguments(
        "applyInv",
        name: "message",
        reason: "Invalid message length.",
      );
    }
    final state = _F4JumbleState(message);
    try {
      return state.applyF4JumbleInv();
    } finally {
      state.clear();
    }
  }

  static bool haveValidLength(List<int> message) {
    const int maxValidLength = 4194368;
    return message.length >= minValidLength && message.length <= maxValidLength;
  }
}

class _F4JumbleState {
  int get outBytes => QuickCrypto.blake2b512DigestSize;
  List<int> _left;
  List<int> _right;
  _F4JumbleState._({required List<int> left, required List<int> right})
    : _left = left,
      _right = right;
  factory _F4JumbleState(List<int> bytes) {
    final length = IntUtils.min(
      QuickCrypto.blake2b512DigestSize,
      bytes.length ~/ 2,
    );

    return _F4JumbleState._(
      left: bytes.sublist(0, length),
      right: bytes.sublist(length),
    );
  }

  static List<int> _blake(List<int> data, int size, List<int> pers) {
    final config = Blake2bConfig(personalization: pers);
    final b = BLAKE2b(digestLength: size, config: config);
    try {
      b.update(data);
      return b.digest();
    } finally {
      b.clean();
    }
  }

  static List<int> _hPers(int i) => [
    85,
    65,
    95,
    70,
    52,
    74,
    117,
    109,
    98,
    108,
    101,
    95,
    72,
    i,
    0,
    0,
  ];

  static List<int> _gPers(int i, int j) => [
    85,
    65,
    95,
    70,
    52,
    74,
    117,
    109,
    98,
    108,
    101,
    95,
    71,
    i,
    j.toU8,
    (j >> 8).toU8,
  ];

  // XOR helper
  static void _xor(List<int> target, List<int> src, int offset, int length) {
    if (length > target.length) {
      length = target.length;
    }
    for (var i = offset; i < length; i++) {
      target[i] ^= src[i - offset];
    }
  }

  // ---- ROUNDS ----

  void _hRound(int i) {
    final hash = _blake(_right, _left.length, _hPers(i));
    _xor(_left, hash, 0, _left.length);
  }

  void _gRound(int i) {
    final chunkCount = (_right.length + outBytes - 1) ~/ outBytes;
    for (var j = 0; j < chunkCount; j++) {
      final hash = _blake(_left, outBytes, _gPers(i, j));
      final start = j * outBytes;
      final end = IntUtils.min(start + outBytes, _right.length);
      _xor(_right, hash, start, end);
    }
  }

  List<int> applyF4Jumble() {
    _gRound(0);
    _hRound(0);
    _gRound(1);
    _hRound(1);
    return [..._left, ..._right];
  }

  List<int> applyF4JumbleInv() {
    _hRound(1);
    _gRound(1);
    _hRound(0);
    _gRound(0);
    return [..._left, ..._right];
  }

  void clear() {
    _left = [];
    _right = [];
  }
}
