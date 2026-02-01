import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

/// The `HMAC` class represents a Hash-based Message Authentication Code.
///
/// It computes a MAC using a given hash function with a secret key and input data.
class HMAC<T extends HashState> implements SerializableHash<T> {
  /// block size
  @override
  int get getBlockSize => _blockSize ?? _outer.getBlockSize;

  /// digest length
  @override
  int get getDigestLength => _outer.getDigestLength;

  late SerializableHash<T> _inner; // inner hash
  late SerializableHash<T> _outer; // outer hash

  bool _finished = false; // true if HMAC was finalized

  // Copies of hash states after keying.
  // Need for quick reset without hashing the key again.
  T? _innerKeyedState;
  T? _outerKeyedState;
  late final int? _blockSize;

  /// Creates an HMAC instance with the specified hash function and secret key.
  HMAC(HashFunc<T> hash, List<int> key, [int? blockSize]) {
    _blockSize = blockSize;
    // Initialize inner and outer hashes.
    _inner = hash();
    _outer = hash();

    // SinsemillaPad temporary stores a key (or its hash) padded with zeroes.
    final pad = List<int>.filled(getBlockSize, 0);

    if (key.length > getBlockSize) {
      // If key is bigger than hash block size, it must be
      // hashed and this hash is used as a key instead.
      _inner.update(key)
        ..finish(pad)
        ..clean();
    } else {
      // Otherwise, copy the key into pad.
      pad.setAll(0, key);
    }

    // Now two different keys are derived from the padded key
    // by XORing a different byte value to each.

    // To make the inner hash key, XOR byte 0x36 into pad.
    for (var i = 0; i < pad.length; i++) {
      pad[i] ^= 0x36;
    }
    // Update inner hash with the result.
    _inner.update(pad);

    // To make the outer hash key, XOR byte 0x5c into pad.
    // But since we already XORed 0x36 there, we must
    // first undo this by XORing it again.
    for (var i = 0; i < pad.length; i++) {
      pad[i] ^= 0x36 ^ 0x5c;
    }
    // Update outer hash with the result.
    _outer.update(pad);

    // Save states of both hashes, so that we can quickly restore
    // them later in reset() without the need to remember the actual
    // key and perform this initialization again.
    _innerKeyedState = _inner.saveState();
    _outerKeyedState = _outer.saveState();

    // Clean pad.
    BinaryOps.zero(pad);
  }

  /// Resets the hash computation to its initial state.
  @override
  HMAC reset() {
    final innerState = _innerKeyedState;
    if (innerState != null) {
      _inner.restoreState(innerState);
    }
    final outState = _outerKeyedState;
    if (outState != null) {
      _outer.restoreState(outState);
    }
    _finished = false;

    return this;
  }

  /// Clean up the internal state and reset hash object to its initial state.
  @override
  void clean() {
    final innerState = _innerKeyedState;
    if (innerState != null) {
      _inner.cleanSavedState(innerState);
    }
    final outState = _outerKeyedState;
    if (outState != null) {
      _outer.cleanSavedState(outState);
    }
  }

  /// Updates the hash computation with the given data.
  ///
  /// Parameters:
  /// - [data]: Containing the data to be hashed.
  ///
  @override
  Hash update(List<int> data) {
    _inner.update(data);
    return this;
  }

  /// Finalizes the hash computation and stores the hash state in the provided [out].
  /// Parameters:
  ///   - [out]: In which the hash digest is stored.
  ///
  @override
  HMAC finish(List<int> out) {
    if (_finished) {
      _outer.finish(out);
      return this;
    }

    _inner.finish(out);

    _outer.update(out.sublist(0, getDigestLength)).finish(out);

    _finished = true;

    return this;
  }

  /// Generates the final hash digest by assembling and returning the hash state in a `List<int>`.
  @override
  List<int> digest() {
    final out = List<int>.filled(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Saves the current hash computation state into a serializable state object.
  @override
  T saveState() {
    return _inner.saveState();
  }

  /// Restores the hash computation state from a previously saved state.
  ///
  /// Parameters:
  /// - [savedState]: The saved state to restore.
  ///
  @override
  HMAC restoreState(T savedState) {
    _inner.restoreState(savedState);
    final outState = _outerKeyedState;
    if (outState != null) {
      _outer.restoreState(outState);
    }
    _finished = false;

    return this;
  }

  /// Clean up and reset the saved state of the hash object to its initial state.
  /// - [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(T savedState) {
    _inner.cleanSavedState(savedState);
  }

  /// Calculates an HMAC using a specified hash function, a secret key, and input data.
  static List<int> hmac(HashFunc hash, List<int> key, List<int> data) {
    final h = HMAC(hash, key);
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}
