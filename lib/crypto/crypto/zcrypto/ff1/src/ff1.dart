import 'package:blockchain_utils/crypto/crypto/aes/aes.dart';
import 'package:blockchain_utils/crypto/crypto/cbc/cbc.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/ff1/src/types.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

class _Prf {
  final CBC state;
  List<int> _buffer;
  int _offset = 0;
  int get blockSize => state.blockSize;
  _Prf(this.state) : _buffer = List.filled(state.blockSize, 0);
  _Prf clone() {
    return _Prf(state.clone())
      .._buffer = _buffer.clone()
      .._offset = _offset;
  }

  void update(List<int> data) {
    int pos = 0;
    while (pos < data.length) {
      int toCopy = IntUtils.min(blockSize - _offset, data.length - pos);
      _buffer.setRange(_offset, _offset + toCopy, data, pos);
      _offset += toCopy;
      pos += toCopy;

      if (_offset == blockSize) {
        _buffer = _encryptBlock(_buffer);
        _offset = 0;
      }
    }
  }

  List<int> output() {
    if (_offset != 0) {
      throw CryptoException.failed(
        "PRF.output",
        reason: "PRF not aligned to block boundary",
      );
    }
    return _buffer.clone();
  }

  List<int> _encryptBlock(List<int> block) {
    final out = List<int>.filled(16, 0);
    state.encryptBlock(block, out);
    return out;
  }

  void clean() {
    state.clean();
    BinaryOps.zero(_buffer);
    _offset = 0;
  }
}

abstract class FF1<T extends NumeralString<T>> {
  final AES aes;
  final FF1Radix config;
  _Prf get _prf => _Prf(CBC(aes, List<int>.filled(aes.blockSize, 0)));
  int get radix => config.radix;
  FF1({required this.aes, required int radix, required FF1Encoding type})
    : config = FF1Radix(type: type, radix: radix);

  List<int> _generateS(List<int> r, int d) {
    List<int> output = [];

    // Start with the original block
    output.addAll(r);

    int blocksNeeded = ((d + 15) ~/ 16);

    for (int j = 1; j <= blocksNeeded; j++) {
      // Clone r
      List<int> block = r.clone();

      // XOR block with big-endian bytes of j
      List<int> jBytes = List<int>.filled(16, 0); // assuming 16-byte block
      for (int k = 0; k < 16; k++) {
        jBytes[15 - k] = ((j >> (8 * k)) & BinaryOps.mask8);
      }

      for (int k = 0; k < 16; k++) {
        block[k] ^= jBytes[k];
      }

      // Encrypt the block
      aes.encryptBlock(block, block);

      // Append to output
      output.addAll(block);
    }

    // Return only the first d bytes
    return output.sublist(0, d);
  }

  /// Performs FF1 encryption on [x], optionally using a tweak.
  T encrypt(T x, {List<int> tweak = const []}) {
    if (!x.isValid(radix)) {
      throw ArgumentException.invalidOperationArguments(
        "FF1.encrypt",
        reason: "Incorrect input for radix.",
        details: {"radix": radix},
      );
    }
    final n = x.numeralCount();
    if (n < config.minLen || n > config.maxLen) {
      throw ArgumentException.invalidOperationArguments(
        "FF1.encrypt",
        reason: "Incorrect input for radix.",
        details: {"radix": radix},
      );
    }

    final t = tweak.length;
    final xN = x.split();
    var xA = xN[0];
    var xB = xN[1];
    final u = xA.numeralCount();
    final v = xB.numeralCount();
    final b = config.calculateB(v);
    final d = 4 * ((b + 3) ~/ 4) + 4;
    final p = [1, 2, 1, 0, 0, 0, 10, u, 0, 0, 0, 0, 0, 0, 0, 0];
    p.setRange(3, 6, IntUtils.toBytes(radix, length: 4).sublist(1));
    p.setRange(8, 12, IntUtils.toBytes(n, length: 4));
    p.setRange(12, 16, IntUtils.toBytes(t, length: 4));
    final prf = _prf;
    prf.update(p);
    prf.update(tweak);
    int padding = ((-(t + b + 1)) % 16 + 16) % 16;
    for (int i = 0; i < padding; i++) {
      prf.update([0]);
    }
    for (int i = 0; i < 10; i++) {
      final newPrf = prf.clone();
      newPrf.update([i]);
      newPrf.update(xB.toBytesInternal(radix, b));
      final r = newPrf.output();
      final s = _generateS(r, d);
      final m = (i % 2) == 0 ? u : v;
      final xC = xA.addModExp(s, radix, m);
      xA = xB;
      xB = xC;
      newPrf.clean();
    }
    return x.concat(xA, xB);
  }

  /// Performs FF1 decryption on [x], optionally using a tweak.
  T decrypt(T x, {List<int> tweak = const []}) {
    if (!x.isValid(radix)) {
      throw ArgumentException.invalidOperationArguments(
        "FF1.decrypt",
        reason: "Incorrect input for radix.",
        details: {"radix": radix},
      );
    }

    final n = x.numeralCount();
    if (n < config.minLen || n > config.maxLen) {
      throw ArgumentException.invalidOperationArguments(
        "FF1.decrypt",
        reason: "Incorrect input length for radix.",
        details: {"radix": radix},
      );
    }

    final t = tweak.length;
    final xN = x.split();
    var xA = xN[0];
    var xB = xN[1];
    final u = xA.numeralCount();
    final v = xB.numeralCount();
    final b = config.calculateB(v);
    final d = 4 * ((b + 3) ~/ 4) + 4;
    final p = [1, 2, 1, 0, 0, 0, 10, u, 0, 0, 0, 0, 0, 0, 0, 0];

    p.setRange(3, 6, IntUtils.toBytes(radix, length: 4).sublist(1));
    p.setRange(8, 12, IntUtils.toBytes(n, length: 4));
    p.setRange(12, 16, IntUtils.toBytes(t, length: 4));
    final prf = _prf;
    prf.update(p);
    prf.update(tweak);
    int padding = ((-(t + b + 1)) % 16 + 16) % 16;

    for (int i = 0; i < padding; i++) {
      prf.update([0]);
    }

    for (int i = 0; i < 10; i++) {
      int e = 9 - i;
      final newPrf = prf.clone();
      newPrf.update([e]);
      newPrf.update(xA.toBytesInternal(radix, b));
      final r = newPrf.output();
      final s = _generateS(r, d);
      final m = (e % 2) == 0 ? u : v;
      final xC = xB.subModExp(s, radix, m);
      xB = xA;
      xA = xC;
      newPrf.clean();
    }
    return x.concat(xA, xB);
  }
}

/// FF1 format-preserving encryption using a flexible numeral string.
class FF1Flexible extends FF1<FlexibleNumeralString> {
  FF1Flexible({required super.aes, super.radix = 2})
    : super(type: FF1Encoding.flexible);
}

/// FF1 format-preserving encryption specialized for binary data.
class FF1Binary extends FF1<BinaryNumeralString> {
  FF1Binary({required super.aes, super.radix = 2})
    : super(type: FF1Encoding.binary);
}
