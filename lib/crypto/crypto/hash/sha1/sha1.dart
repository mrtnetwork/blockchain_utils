part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// A class representing the SHA-1 (Secure Hash Algorithm 1) hash algorithm.
///
/// SHA-1 produces a 160-bit (20-byte) hash digest.
///
/// Constructor:
/// - [SHA1]: Initializes an instance of the SHA-1 hash.
///
/// Example:
/// ```dart
/// final sha1 = SHA1();
/// sha1.update(List<int>.from([0x48, 0x65, 0x6C, 0x6C, 0x6F]));
/// final hashDigest = sha1.digest();
/// ```
class SHA1 implements SerializableHash<SH1State> {
  /// Initializes an instance of the SHA-1 hash.
  SHA1() {
    reset();
  }
  final _buffer = List<int>.empty(growable: true);
  int _lengthInBytes = 0;

  final List<int> _temp = List<int>.filled(80, 0);
  final List<int> _estate = List<int>.filled(5, 0);
  final List<int> _currentChunk = List<int>.filled(16, 0);

  bool _finished = false;

  /// Clean up the internal state and reset hash object to its initial state.
  @override
  void clean() {
    zero(_temp);
    zero(_estate);
    zero(_currentChunk);
    _buffer.clear();
    reset();
  }

  void _init() {
    _estate[0] = 0x67452301;
    _estate[1] = 0xEFCDAB89;
    _estate[2] = 0x98BADCFE;
    _estate[3] = 0x10325476;
    _estate[4] = 0xC3D2E1F0;
  }

  /// Clean up and reset the saved state of the hash object to its initial state.
  /// This function erases the buffer and sets the state and length to the default values.
  /// It is used to ensure that a previously saved hash state is cleared and ready for reuse.
  ///
  /// [savedState]: The hash state to be cleaned and reset.
  @override
  void cleanSavedState(SH1State savedState) {
    savedState.buffer = List.empty();
    savedState.state = List<int>.from([
      0x67452301,
      0xEFCDAB89,
      0x98BADCFE,
      0x10325476,
      0xC3D2E1F0,
    ], growable: false);
    savedState.length = 0;
  }

  /// Generates the final hash digest by assembling and returning the hash state in a List<int>.
  ///
  /// This function produces the hash digest by combining the current hash state into a single
  /// List<int> output. It finalizes the hash if it hasn't been finished, effectively completing
  /// the hash computation and returning the result.
  ///
  /// Returns the List<int> containing the computed hash digest.
  @override
  List<int> digest() {
    final out = List<int>.filled(getDigestLength, 0);
    finish(out);
    return out;
  }

  /// Finalizes the hash computation and stores the hash state in the provided List<int> [out].
  ///
  /// This function completes the hash computation, finalizes the state, and stores the resulting
  /// hash in the provided [out] List<int>. If the hash has already been finished, this method
  /// will return the existing state without re-computing.
  ///
  /// Parameters:
  ///   - [out]: The List<int> in which the hash digest is stored.
  ///
  /// Returns the current instance of the hash algorithm.
  @override
  Hash finish(List<int> out) {
    if (!_finished) {
      _finalize();
      _iterate();
      _finished = true;
    }
    for (var i = 0; i < _estate.length; i++) {
      writeUint32BE(_estate[i], out, i * 4);
    }
    return this;
  }

  void _finalize() {
    _buffer.add(0x80);

    final contentsLength = _lengthInBytes + 1 + 8;
    final finalizedLength = (contentsLength + getBlockSize - 1) & -getBlockSize;
    for (var i = 0; i < finalizedLength - contentsLength; i++) {
      _buffer.add(0);
    }

    var lengthInBits = _lengthInBytes * 8;

    // Add the full length of the input data as a 64-bit value at the end of the
    // hash. Note: we're only writing out 64 bits, so skip ahead 8 if the
    // signature is 128-bit.
    final offset = _buffer.length;

    _buffer.addAll(List<int>.filled(8, 0));
    // var byteData = _buffer.buffer.asByteData();

    // We're essentially doing byteData.setUint64(offset, lengthInBits, _endian)
    // here, but that method isn't supported on dart2js so we implement it
    // manually instead.
    var highBits = lengthInBits ~/ 0x100000000; // >> 32
    var lowBits = lengthInBits & mask32;
    writeUint32BE(highBits, _buffer, offset);
    writeUint32BE(lowBits, _buffer, offset + 4);
  }

  void _proccess(List<int> chunk) {
    assert(chunk.length == 16);

    var a = _estate[0];
    var b = _estate[1];
    var c = _estate[2];
    var d = _estate[3];
    var e = _estate[4];

    for (var i = 0; i < 80; i++) {
      if (i < 16) {
        _temp[i] = chunk[i];
      } else {
        _temp[i] = rotl32(
            _temp[i - 3] ^ _temp[i - 8] ^ _temp[i - 14] ^ _temp[i - 16], 1);
      }

      var newA = add32(add32(rotl32(a, 5), e), _temp[i]);
      if (i < 20) {
        newA = add32(add32(newA, (b & c) | (~b & d)), 0x5A827999);
      } else if (i < 40) {
        newA = add32(add32(newA, b ^ c ^ d), 0x6ED9EBA1);
      } else if (i < 60) {
        newA = add32(add32(newA, (b & c) | (b & d) | (c & d)), 0x8F1BBCDC);
      } else {
        newA = add32(add32(newA, b ^ c ^ d), 0xCA62C1D6);
      }

      e = d;
      d = c;
      c = rotl32(b, 30);
      b = a;
      a = newA & mask32;
    }

    _estate[0] = add32(a, _estate[0]);
    _estate[1] = add32(b, _estate[1]);
    _estate[2] = add32(c, _estate[2]);
    _estate[3] = add32(d, _estate[3]);
    _estate[4] = add32(e, _estate[4]);
  }

  @override
  int get getBlockSize => 64;

  @override
  int get getDigestLength => _estate.length * 4;

  /// Resets the hash computation to its initial state.
  ///
  /// This method initializes the hash computation to its initial state, clearing any previously
  /// processed data. After calling this method, you can start a new hash computation.
  ///
  /// Returns the current instance of the hash algorithm with the initial stat
  @override
  Hash reset() {
    _init();
    _finished = false;
    _lengthInBytes = 0;
    return this;
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
  SerializableHash restoreState(SH1State savedState) {
    _buffer.clear();
    _buffer.addAll(savedState.buffer);
    _estate.setAll(0, savedState.state);
    _lengthInBytes = savedState.length;
    _iterate();
    _finished = false;
    return this;
  }

  /// Saves the current hash computation state into a serializable state object.
  ///
  /// This method saves the current state of the hash computation, including the data buffer,
  /// hash state, and etc, into a serializable state object.
  /// The saved state can be later restored using the `restoreState` method.
  ///
  /// Returns a [HashState] object containing the saved state information.
  @override
  SH1State saveState() {
    return SH1State(
        buffer: List<int>.from(_buffer.toList()),
        length: _lengthInBytes,
        state: List<int>.from(_estate, growable: false));
  }

  /// Updates the hash computation with the given data.
  ///
  /// This method updates the hash computation with the provided [data] bytes. It appends the data to
  /// the internal buffer and processes it to update the hash state.
  ///
  /// If the hash has already been finished using the `finish` method, calling this method will result in an error.
  ///
  /// Parameters:
  /// - [data]: The List<int> containing the data to be hashed.
  ///
  /// Returns this [Hash] object for method chaining.
  @override
  Hash update(List<int> data) {
    if (_finished) {
      throw const MessageException(
          "SHA512: can't update because hash was finished.");
    }
    _lengthInBytes += data.length;
    _buffer.addAll(BytesUtils.toBytes(data));
    _iterate();
    return this;
  }

  void _iterate() {
    var pendingDataChunks = _buffer.length ~/ getBlockSize;
    for (var i = 0; i < pendingDataChunks; i++) {
      // Copy words from the pending data buffer into the current chunk buffer.
      for (var j = 0; j < _currentChunk.length; j++) {
        _currentChunk[j] = readUint32BE(_buffer, i * getBlockSize + j * 4);
      }
      _proccess(_currentChunk);
    }

    // Remove all pending data up to the last clean chunk break.
    _buffer.removeRange(0, pendingDataChunks * getBlockSize);
  }

  /// Computes the SHA1 hash of the provided data.
  static List<int> hash(List<int> data) {
    final h = SHA1();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}

/// The `SHA1State` class represents the state of the SHA-1 hash algorithm.
///
/// It encapsulates the intermediate state of the SHA-1 hash computation and is
/// used for saving and restoring the hash state during processing.
class SH1State implements HashState {
  SH1State({required this.buffer, required this.length, required this.state});

  /// The buffer storing data to be hashed.
  List<int> buffer;

  /// The length of the data in bytes.
  int length;

  /// The state of the SHA-1 hash.
  List<int> state;
}
