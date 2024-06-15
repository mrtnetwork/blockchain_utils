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
/// - Keccack: SHA-3, SHA-3/224, SHA-3/256, SHA-3/384, SHA-3/512, SHAKE128-256
/// - Ridemp: RIPEMD-320, RIPEMD-256, RIPEMD-160, RIPEMD-128
/// -....
library hash;

import 'package:blockchain_utils/utils/utils.dart';
import 'dart:math' as math;

import 'package:blockchain_utils/exception/exception.dart';

/// Export statement for the 'sha224' part, providing the SHA-224 hash algorithm.
part 'sha224/sha224.dart';

/// Export statement for the 'sha256' part, offering the SHA-256 hash algorithm.
part 'sha256/sha256.dart';

/// Export statement for the 'sha384' part, providing the SHA-384 hash algorithm.
part 'sha384/sha384.dart';

/// Export statement for the 'sha512' part, which includes the SHA-512 hash algorithm.
part 'sha512/sha512.dart';

/// Export statement for the 'sha512_256' part, offering the SHA-512/256 hash algorithm.
part 'sha512_256/sh512256.dart';

/// Export statement for the 'sha1' part, providing the SHA-1 hash algorithm.
part 'sha1/sha1.dart';

/// Export statement for the 'blake2b' part, offering the Blake2b hash algorithm.
part 'black2b/black2b.dart';

/// Export statement for the 'ridemp' part, providing the RIdEMP hash algorithm.
part 'ridemp/ridemp.dart';

/// Export statement for the 'md5' part, which includes the MD5 hash algorithm.
part 'md5/md5.dart';

/// Export statement for the 'md4' part, offering the MD4 hash algorithm.
part 'md4/md4.dart';

/// Export statement for the 'keccak' part, providing the SHA-3 (Keccak) hash algorithm.
part 'keccack/sha3.dart';

part 'xxhash64/xxhash64.dart';

typedef HashFunc = SerializableHash Function();

/// The `Hash` abstract class defines the basic operations for hash algorithms.
///
/// It serves as the base for hash algorithms, defining methods and properties
/// required for common hash processing.
abstract class Hash {
  /// The length of the digest produced by the hash algorithm.
  int get getDigestLength;

  /// The block size used by the hash algorithm.
  int get getBlockSize;

  /// Updates the hash with the provided data.
  Hash update(List<int> data);

  /// Resets the hash to its initial state.
  Hash reset();

  /// Finalizes the hash computation and stores the result in the provided `out` buffer.
  Hash finish(List<int> out);

  /// Retrieves the hash digest.
  List<int> digest();

  /// Cleans sensitive data in the hash instance.
  void clean();
}

/// The `SerializableHash` abstract class extends the `Hash` class and adds
/// functionality for saving, restoring, and cleaning hash states.
///
/// It's useful for hash algorithms that require intermediate state management.
abstract class SerializableHash<T extends HashState> extends Hash {
  /// Saves the current hash state.
  HashState saveState();

  /// Restores the hash state from a saved state.
  SerializableHash restoreState(T savedState);

  /// Cleans sensitive data from the saved hash state.
  void cleanSavedState(T savedState);
}

/// The `HashState` abstract class serves as a marker interface for hash state classes.
///
/// Implementing classes are used for saving, restoring, and managing the state of a hash algorithm.
abstract class HashState {}
