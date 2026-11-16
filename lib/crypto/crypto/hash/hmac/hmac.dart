part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// The `HMAC` class represents a Hash-based Message Authentication Code.
///
/// It computes a MAC using a given hash function with a secret key and input data.
class HMAC implements SerializableHash<HMACState> {
  /// block size
  @override
  int get getBlockSize => _outer.getBlockSize;

  /// digest length
  @override
  int get getDigestLength => _outer.getDigestLength;

  late BuSerializableHash _inner; // inner hash
  late BuSerializableHash _outer; // outer hash

  bool _finished = false; // true if HMAC was finalized

  bool _cleaned = false;

  // Copies of hash states after keying.
  // Need for quick reset without hashing the key again.
  late BuHashState _innerKeyedState;
  late BuHashState _outerKeyedState;
  // late final int? _blockSize;

  /// Creates an HMAC instance with the specified hash function and secret key.
  HMAC(CbHashFunc hash, List<int> key) {
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
        ..reset();
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
    _ensureAlive("HMAC.reset", _cleaned, null);
    _inner.restoreState(_innerKeyedState);
    _outer.restoreState(_outerKeyedState);
    _finished = false;
    return this;
  }

  /// Clean up the internal state and reset hash object to its initial state.
  @override
  void clean() {
    _inner.cleanSavedState(_innerKeyedState);
    _outer.cleanSavedState(_outerKeyedState);
    _inner.clean();
    _outer.clean();
    _finished = false;
    _cleaned = true;
  }

  /// Updates the hash computation with the given data.
  ///
  /// Parameters:
  /// - [data]: Containing the data to be hashed.
  ///
  @override
  Hash update(List<int> data) {
    _ensureAlive("HMAC.update", _cleaned, _finished);
    _inner.update(data);
    return this;
  }

  /// Finalizes the hash computation and stores the hash state in the provided [out].
  /// Parameters:
  ///   - [out]: In which the hash digest is stored.
  ///
  @override
  HMAC finish(List<int> out) {
    _ensureAlive("HMAC.finish", _cleaned, null);
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
  BuBytes digest() {
    final out = BuBytes.fill(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Saves the current hash computation state into a serializable state object.
  @override
  HMACState saveState() {
    _ensureAlive("HMAC.saveState", _cleaned, _finished);
    return HMACState(
      inner: _inner.saveState(),
      outer: _outer.saveState(),
      innerKeyState: _innerKeyedState,
      outerKeyState: _outerKeyedState,
    );
  }

  /// Restores the hash computation state from a previously saved state.
  ///
  /// Parameters:
  /// - [savedState]: The saved state to restore.
  ///
  @override
  HMAC restoreState(HMACState savedState) {
    _ensureAlive("HMAC.restoreState", _cleaned, null);
    _inner.restoreState(savedState.inner);
    _outer.restoreState(savedState.outer);
    _innerKeyedState = savedState.innerKeyState;
    _outerKeyedState = savedState.outerKeyState;

    _finished = false;

    return this;
  }

  /// Clean up and reset the saved state of the hash object to its initial state.
  /// - [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(HMACState savedState) {
    _inner.cleanSavedState(savedState.inner);
    _outer.cleanSavedState(savedState.outer);
  }

  /// Calculates an HMAC using a specified hash function, a secret key, and input data.
  static BuBytes hmac(CbHashFunc hash, List<int> key, List<int> data) {
    final h = HMAC(hash, key);
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}

/// Serializable snapshot of an in-progress [HMAC] computation.
class HMACState extends HashState {
  final BuHashState inner;
  final BuHashState outer;
  final BuHashState innerKeyState;
  final BuHashState outerKeyState;
  const HMACState({
    required this.inner,
    required this.outer,
    required this.innerKeyState,
    required this.outerKeyState,
  });
}
