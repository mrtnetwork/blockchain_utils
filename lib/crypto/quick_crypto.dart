import 'package:blockchain_utils/crypto/crypto/aes/padding.dart';
import 'package:blockchain_utils/crypto/crypto/chacha20poly1305/chacha20poly1305.dart';
import 'package:blockchain_utils/crypto/crypto/ecb/ecb.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/hmac/hmac.dart';
import 'package:blockchain_utils/crypto/crypto/pbkdf2/pbkdf2.dart';
import 'package:blockchain_utils/crypto/crypto/prng/fortuna.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/tuple/tuple.dart';

/// QuickCrypto provides a set of utility methods for cryptographic operations.
///
/// This class contains static methods for generating random bytes, hashing data,
/// and performing other cryptographic operations commonly used in various
/// applications.
class QuickCrypto {
  /// Calculate the SHA-256 hash of the input data
  static List<int> sha256Hash(List<int> data) {
    return SHA256.hash(data);
  }

  /// Calculate the SHA-256 hash of the SHA-256 hash of the input data
  static List<int> sha256DoubleHash(List<int> data) {
    List<int> tmp = sha256Hash(data);
    return sha256Hash(tmp);
  }

  /// Static property that defines the size of SHA-256 digests in bytes
  static const int sha256DigestSize = 32;

  /// Derive a key from a password using PBKDF2 algorithm
  static List<int> pbkdf2DeriveKey(
      {required List<int> password,
      required List<int> salt,
      required int iterations,
      Hash Function()? hash,
      int? dklen}) {
    final hashing = (hash ?? () => SHA512());

    return PBKDF2.deriveKey(
        mac: () => HMAC(hashing, password),
        salt: salt,
        iterations: iterations,
        length: dklen ?? hashing().getDigestLength);
  }

  /// Calculate the RIPEMD-160 hash of the SHA-256 hash of the input data
  static List<int> hash160(List<int> data) {
    List<int> tmp = SHA256.hash(data);
    return RIPEMD160.hash(tmp);
  }

  /// Define the size of RIPEMD-160 digests, which is 20 bytes (160 bits)
  static const int hash160DigestSize = 20;

  /// Calculate the RIPEMD-160 hash of the input data
  static List<int> ripemd160Hash(List<int> data) {
    return RIPEMD160.hash(data);
  }

  static List<int> _blake2bHash(
    List<int> data,
    int digestSize, {
    List<int>? key,
    List<int>? salt,
  }) {
    final hash =
        BLAKE2b.hash(data, digestSize, Blake2bConfig(key: key, salt: salt));

    return hash;
  }

  /// Define the size of BLAKE2b-512 digests, which is 64 bytes (512 bits)
  static const int blake2b512DigestSize = 64;

  /// Calculate the BLAKE2b-512 hash of the input data
  static List<int> blake2b512Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
  }) =>
      _blake2bHash(data, blake2b512DigestSize, key: key, salt: salt);

  /// Define the size of BLAKE2b-256 digests, which is 32 bytes (256 bits)
  static const int blake2b256DigestSize = 32;

  /// Calculate the BLAKE2b-256 hash of the input data
  static List<int> blake2b256Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
  }) =>
      _blake2bHash(data, blake2b256DigestSize, key: key, salt: salt);

  /// Define the size of BLAKE2b-224 digests, which is 28 bytes (224 bits)
  static const int blake2b224DigestSize = 28;

  /// Calculate the BLAKE2b-224 hash of the input data
  static List<int> blake2b224Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
  }) =>
      _blake2bHash(data, blake2b224DigestSize, key: key, salt: salt);

  /// Define the size of BLAKE2b-160 digests, which is 20 bytes (160 bits)
  static const int blake2b160DigestSize = 20;

  /// Calculate the BLAKE2b-160 hash of the input data
  static List<int> blake2b160Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
  }) =>
      _blake2bHash(data, blake2b160DigestSize, key: key, salt: salt);

  /// Define the size of BLAKE2b-40 digests, which is 5 bytes (40 bits)
  static const int blake2b40DigestSize = 5;

  /// Calculate the BLAKE2b-40 hash of the input data
  static List<int> blake2b40Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
  }) =>
      _blake2bHash(data, blake2b40DigestSize, key: key, salt: salt);

  /// Define the size of BLAKE2b-32 digests, which is 4 bytes (32 bits)
  static const int blake2b32DigestSize = 4;

  /// Calculate the BLAKE2b-32 hash of the input data
  static List<int> blake2b32Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
  }) =>
      _blake2bHash(data, blake2b32DigestSize, key: key, salt: salt);

  /// Calculate the SHA-512/256 hash of the input data
  static List<int> sha512256Hash(List<int> data) {
    return SHA512256.hash(data);
  }

  /// Calculate the SHA-512 hash of the input data
  static List<int> sha512Hash(List<int> data) {
    return SHA512.hash(data);
  }

  /// Gets the length of the SHA512 digest.
  static const int sha512DeigestLength = SHA512.digestLength;

  /// Computes the SHA512 hash of the input data and returns its halves.
  ///
  /// This method computes the SHA512 hash of the provided data and returns the first
  /// half and the second half of the hash as a tuple.
  ///
  /// [data] The input data for which the hash is to be computed.
  /// returns A tuple containing the first and second halves of the SHA512 hash.
  static Tuple<List<int>, List<int>> sha512HashHalves(List<int> data) {
    final hash = SHA512.hash(data);
    final halvesLength = sha512DeigestLength ~/ 2;
    return Tuple(hash.sublist(0, halvesLength), hash.sublist(halvesLength));
  }

  /// Calculate the Keccak-256 hash of the input data
  static List<int> keccack256Hash(List<int> data) {
    return Keccack.hash(data, 32);
  }

  /// Calculate the SHA-3-256 hash of the input data
  static List<int> sha3256Hash(List<int> data) {
    return SHA3256.hash(data);
  }

  /// Define the size of SHA-3-256 digests, which is 32 bytes (256 bits)
  static const int sha3256DigestSize = 32;

  /// Calculate the HMAC-SHA-256 hash of the input data using the provided key
  static List<int> hmacsha256Hash(List<int> key, List<int> data) {
    final hm = HMAC(() => SHA256(), key);
    hm.update(data);
    return hm.digest();
  }

  /// Calculate the HMAC-SHA-512 hash of the input data using the provided key
  static List<int> hmacSha512Hash(List<int> key, List<int> data) {
    final hm = HMAC(() => SHA512(), key);
    hm.update(data);
    return hm.digest();
  }

  /// Define the size of HMAC-SHA-512 digests, which is 64 bytes (512 bits)
  static const int hmacSha512DigestSize = 64;

  /// Calculate the HMAC-SHA-512 hash of the input data using the provided key and
  /// split the result into two halves. Return a tuple containing both halves
  static Tuple<List<int>, List<int>> hmacSha512HashHalves(
      List<int> key, List<int> data) {
    final bytes = hmacSha512Hash(key, data);
    return Tuple(bytes.sublist(0, hmacSha512DigestSize ~/ 2),
        bytes.sublist(hmacSha512DigestSize ~/ 2));
  }

  /// Encrypt the input data using AES in Cipher Block Chaining (CBC) mode with the provided key.
  /// Optionally, specify the padding algorithm to be used.
  static List<int> aesCbcEncrypt(List<int> key, List<int> data,
      {PaddingAlgorithm? paddingAlgorithm}) {
    final ecb = ECB(key);
    return ecb.encryptBlock(data, null, paddingAlgorithm);
  }

  /// Decrypt the input data using AES in Cipher Block Chaining (CBC) mode with the provided key.
  /// Optionally, specify the padding algorithm to be used.
  static List<int> aesCbcDecrypt(List<int> key, List<int> data,
      {PaddingAlgorithm? paddingAlgorithm}) {
    final ecb = ECB(key);
    return ecb.decryptBlock(data, null, paddingAlgorithm);
  }

  /// Decrypt data using the ChaCha20-Poly1305 authenticated encryption algorithm.
  /// Requires a key, nonce, ciphertext, and optional associated data.
  static List<int> chaCha20Poly1305Decrypt({
    required List<int> key,
    required List<int> nonce,
    required List<int> cipherText,
    List<int>? assocData,
  }) {
    final chacha = ChaCha20Poly1305(key);
    final decrypt =
        chacha.decrypt(nonce, cipherText, associatedData: assocData);

    if (decrypt != null) {
      return decrypt;
    }
    throw MessageException("ChaCha20-Poly1305 decryption fail");
  }

  /// Encrypt data using the ChaCha20-Poly1305 authenticated encryption algorithm.
  /// Requires a key, nonce, plaintext, and optional associated data.
  static List<int> chaCha20Poly1305Encrypt({
    required List<int> key,
    required List<int> nonce,
    required List<int> plainText,
    List<int>? assocData,
  }) {
    final chacha = ChaCha20Poly1305(key);
    return chacha.encrypt(nonce, plainText, associatedData: assocData);
  }

  /// Define the tag length for ChaCha20-Poly1305, which is 16 bytes
  static const int chacha20Polu1305Taglenght = 16;

  /// Define the key size for ChaCha20-Poly1305, which is 32 bytes
  static const int chacha20Polu1305Keysize = 32;

  /// A private field to hold the FortunaRandom instance for generating random numbers.
  static FortunaPRNG? _randomGenerator;

  static GenerateRandom _generateRandom = (length) {
    _randomGenerator ??= FortunaPRNG();
    return _randomGenerator!.nextBytes(length);
  };

  /// This function generates a random List<int> of the specified size (default is 32 bytes).
  static List<int> generateRandom([int size = 32, GenerateRandom? random]) {
    if (random != null) {
      _generateRandom = random;
    }

    /// Generate the random bytes of the specified size using the _randomGenerator.
    final r = _generateRandom(size);

    /// Return the generated random bytes.
    return r;
  }
}
