import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// The `HMAC` class represents a Hash-based Message Authentication Code.
///
/// It computes a MAC using a given hash function with a secret key and input data.
class HMAC implements SerializableHash {
  /// block size
  @override
  int get getBlockSize => _blockSize ?? _outer.getBlockSize;

  /// digest length
  @override
  int get getDigestLength => _outer.getDigestLength;

  late SerializableHash _inner; // inner hash
  late SerializableHash _outer; // outer hash

  bool _finished = false; // true if HMAC was finalized

  // Copies of hash states after keying.
  // Need for quick reset without hashing the key again.
  dynamic _innerKeyedState;
  dynamic _outerKeyedState;
  late final int? _blockSize;

  /// Creates an HMAC instance with the specified hash function and secret key.
  ///
  /// Example:
  /// ```dart
  /// final key = `List<int>`.from([0x00, 0x01, 0x02]);
  /// final hmac = HMAC(()=>SHA256(), key);
  /// ```
  ///
  /// The `hash` parameter should be a function that returns a hash instance, e.g., SHA1, SHA256, etc.
  /// The `key` is the secret key as a `List<int>`.
  /// The optional `blockSize` parameter sets the block size for the HMAC.
  /// If not provided, it defaults to the block size of the hash function.
  HMAC(HashFunc hash, List<int> key, [int? blockSize]) {
    _blockSize = blockSize;
    // Initialize inner and outer hashes.
    _inner = hash();
    _outer = hash();

    // Pad temporary stores a key (or its hash) padded with zeroes.
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
    zero(pad);
  }

  /// Resets the hash computation to its initial state.
  ///
  /// This method initializes the hash computation to its initial state, clearing any previously
  /// processed data. After calling this method, you can start a new hash computation.
  ///
  /// Returns the current instance of the hash algorithm with the initial stat
  @override
  HMAC reset() {
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
  }

  /// Updates the hash computation with the given data.
  ///
  /// This method updates the hash computation with the provided [data] bytes. It appends the data to
  /// the internal buffer and processes it to update the hash state.
  ///
  /// If the hash has already been finished using the `finish` method, calling this method will result in an error.
  ///
  /// Parameters:
  /// - [data]: The `List<int>` containing the data to be hashed.
  ///
  /// Returns this [Hash] object for method chaining.
  @override
  Hash update(List<int> data) {
    _inner.update(data);
    return this;
  }

  /// Finalizes the hash computation and stores the hash state in the provided `List<int>` [out].
  ///
  /// This function completes the hash computation, finalizes the state, and stores the resulting
  /// hash in the provided [out] `List<int>`. If the hash has already been finished, this method
  /// will return the existing state without re-computing.
  ///
  /// Parameters:
  ///   - [out]: The `List<int>` in which the hash digest is stored.
  ///
  /// Returns the current instance of the hash algorithm.
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
  ///
  /// This function produces the hash digest by combining the current hash state into a single
  /// `List<int>` output. It finalizes the hash if it hasn't been finished, effectively completing
  /// the hash computation and returning the result.
  ///
  /// Returns the `List<int>` containing the computed hash digest.
  @override
  List<int> digest() {
    final out = List<int>.filled(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Saves the current hash computation state into a serializable state object.
  ///
  /// This method saves the current state of the hash computation, including the data buffer,
  /// hash state, and etc, into a serializable state object.
  /// The saved state can be later restored using the `restoreState` method.
  ///
  /// Returns a [HashState] object containing the saved state information.
  @override
  HashState saveState() {
    return _inner.saveState();
  }

  /// Restores the hash computation state from a previously saved state.
  ///
  /// This method allows you to restore the hash computation state to a previously saved state.
  /// It is useful when you want to continue hashing data from a certain point, or if you want
  /// to combine multiple hash computations.
  ///
  /// Parameters:
  /// - `savedState`: The saved state to restore.
  ///
  /// Returns the current instance of the hash algorithm with the restored state.
  @override
  HMAC restoreState(dynamic savedState) {
    _inner.restoreState(savedState);
    _outer.restoreState(_outerKeyedState);
    _finished = false;

    return this;
  }

  /// Clean up and reset the saved state of the hash object to its initial state.
  /// This function erases the buffer and sets the state and length to the default values.
  /// It is used to ensure that a previously saved hash state is cleared and ready for reuse.
  ///
  /// [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(dynamic savedState) {
    _inner.cleanSavedState(savedState);
  }

  /// Calculates an HMAC using a specified hash function, a secret key, and input data.
  /// The `hash` parameter should be a function that returns a hash instance, e.g., SHA1, SHA256, etc.
  ///
  /// Example:
  /// ```dart
  /// final key = `List<int>`.from([0x00, 0x01, 0x02]);
  /// final data = `List<int>`.from([0x10, 0x11, 0x12, 0x13]);
  /// final hmac = hmac(()=>SHA256(), key, data);
  /// ```
  static List<int> hmac(HashFunc hash, List<int> key, List<int> data) {
    final h = HMAC(hash, key);
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}
