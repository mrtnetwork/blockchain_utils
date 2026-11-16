/// The `hash` library provides a collection of cryptographic hashing and HMAC (Hash-based Message Authentication Code) functions
/// for secure data integrity verification and password protection.
///
/// Supported Algorithms:
/// - SHA-256: Secure Hash Algorithm 256-bit.
/// - SHA-512: Secure Hash Algorithm 512-bit.
/// - HMAC: Hash-based Message Authentication Code for secure authentication.
/// - Blake2b: A high-speed cryptographic hash function.
/// - SHA-1: Secure Hash Algorithm 1.
/// - MD5: Message Digest Algorithm 5.
/// - MD4: Message Digest Algorithm 4.
/// - SHA-384: Secure Hash Algorithm 384-bit.
/// - Keccak: SHA-3, SHA-3/224, SHA-3/256, SHA-3/384, SHA-3/512, SHAKE128-256
/// - RIPEMD: RIPEMD-320, RIPEMD-256, RIPEMD-160, RIPEMD-128
/// -....
library;

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

import 'dart:math' as math;

import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

export 'package:blockchain_utils/crypto/crypto/hash/pedersen_hash/pedersen_hash.dart';
export 'package:blockchain_utils/crypto/crypto/hash/poseidon/poseidon.dart';
export 'package:blockchain_utils/crypto/crypto/hash/sinsemilla/sinsemilla.dart';
export 'package:blockchain_utils/crypto/crypto/hash/api/api.dart';

/// Export statement for the 'sha224' part, providing the SHA-224 hash algorithm.
part 'package:blockchain_utils/crypto/crypto/hash/sha224/sha224.dart';

/// Export statement for the 'sha256' part, offering the SHA-256 hash algorithm.
part 'package:blockchain_utils/crypto/crypto/hash/sha256/sha256.dart';

/// Export statement for the 'sha384' part, providing the SHA-384 hash algorithm.
part 'package:blockchain_utils/crypto/crypto/hash/sha384/sha384.dart';

/// Export statement for the 'sha512' part, which includes the SHA-512 hash algorithm.
part 'package:blockchain_utils/crypto/crypto/hash/sha512/sha512.dart';

/// Export statement for the 'sha512_256' part, offering the SHA-512/256 hash algorithm.
part 'package:blockchain_utils/crypto/crypto/hash/sha512_256/sh512256.dart';

/// Export statement for the 'sha1' part, providing the SHA-1 hash algorithm.
part 'package:blockchain_utils/crypto/crypto/hash/sha1/sha1.dart';

/// Export statement for the 'blake2b' part, offering the Blake2b hash algorithm.
part 'package:blockchain_utils/crypto/crypto/hash/blake2/black2b.dart';

// NOTE: the directory is spelled 'ridemp' but the algorithm is RIPEMD
// (letters transposed). Renaming the directory/file would be a
// separate, purely-structural change, so only the identifiers and
// docs were corrected here.
/// The RIPEMD family of hash algorithms.
part 'package:blockchain_utils/crypto/crypto/hash/ridemp/ridemp.dart';

/// Export statement for the 'md5' part, which includes the MD5 hash algorithm.
part 'package:blockchain_utils/crypto/crypto/hash/md5/md5.dart';

/// Export statement for the 'md4' part, offering the MD4 hash algorithm.
part 'package:blockchain_utils/crypto/crypto/hash/md4/md4.dart';

/// Export statement for the 'keccak' part, providing the SHA-3 (Keccak) hash algorithm.
part 'package:blockchain_utils/crypto/crypto/hash/keccak/sha3.dart';

part 'package:blockchain_utils/crypto/crypto/hash/xxhash/xxhash.dart';

part 'package:blockchain_utils/crypto/crypto/hash/blake2/blake2s.dart';

part 'package:blockchain_utils/crypto/crypto/hash/hmac/hmac.dart';

typedef CbHashFunc<T extends BuHashState> = BuSerializableHash<T> Function();

/// The `Hash` abstract class defines the basic operations for hash algorithms.
///
/// It serves as the base for hash algorithms, defining methods and properties
/// required for common hash processing.
abstract class Hash implements BuHash {
  /// The length of the digest produced by the hash algorithm.
  @override
  int get getDigestLength;

  /// The block size used by the hash algorithm.
  @override
  int get getBlockSize;

  /// Updates the hash with the provided data.
  @override
  Hash update(List<int> data);

  /// Resets the hash to its initial state.
  @override
  Hash reset();

  /// Finalizes the hash computation and stores the result in the provided `out` buffer.
  @override
  Hash finish(List<int> out);

  /// Retrieves the hash digest.
  @override
  BuBytes digest();

  /// Cleans sensitive data in the hash instance.
  @override
  void clean();
}

/// The `SerializableHash` abstract class extends the `Hash` class and adds
/// functionality for saving, restoring, and cleaning hash states.
///
/// It's useful for hash algorithms that require intermediate state management.
abstract class SerializableHash<T extends BuHashState>
    implements Hash, BuSerializableHash<T> {
  /// Saves the current hash state.
  @override
  T saveState();

  /// Restores the hash state from a saved state.
  @override
  SerializableHash restoreState(T savedState);

  /// Cleans sensitive data from the saved hash state.
  @override
  void cleanSavedState(T savedState);
}

/// The `HashState` abstract class serves as a marker interface for hash state classes.
///
/// Implementing classes are used for saving, restoring, and managing the state of a hash algorithm.
abstract class HashState implements BuHashState {
  const HashState();
  @override
  Object get handle => this;
}

void _ensureAlive(String where, bool cleaned, bool? finished) {
  if (cleaned) {
    throw CoreErrors.cryptoFailed(where, reason: "State was finished.");
  }
  if (finished == true) {
    throw CoreErrors.cryptoFailed(where, reason: "State was finished.");
  }
}

/// The `HashBytesState` class represents the state of a hashing process that operates on a byte array.
///
/// It implements the `HashState` interface, providing a way to manage the state of a byte-based hashing operation.
///
/// Parameters:
/// - `data`: A `List<int>` that holds the data to be hashed.
/// - `pos`: An integer representing the current position or progress in processing the data.
///
/// This class is useful for tracking the state of a hash computation, enabling efficient incremental hashing
/// where data is processed in chunks or sections, and the `pos` field keeps track of the current position
/// within the data buffer.
class HashBytesState extends HashState {
  HashBytesState({required List<int> data, required this.pos})
    : data = data.clone();
  final List<int> data;
  int pos;
}
