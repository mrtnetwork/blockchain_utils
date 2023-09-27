library bitcoin_crypto;

import 'dart:convert';
import 'package:pointycastle/export.dart';
import "dart:typed_data";

// ignore: implementation_imports
import 'package:pointycastle/src/platform_check/platform_check.dart'
    as platform;

// This function calculates the hash160 digest of a given Uint8List buffer.
Uint8List hash160(Uint8List buffer) {
  // Calculate the SHA-256 hash of the input buffer.
  Uint8List tmp = SHA256Digest().process(buffer);

  // Calculate the RIPEMD-160 hash of the SHA-256 hash.
  return RIPEMD160Digest().process(tmp);
}

// This function calculates the HMAC-SHA-512 digest of a given key and data using HMAC (Hash-based Message Authentication Code).
// HMAC is a method for verifying both the data integrity and authenticity of a message.
Uint8List hmacSHA512(Uint8List key, Uint8List data) {
  // Create an HMAC instance with the SHA-512 hash algorithm and a 128-bit block size.
  final tmp = HMac(SHA512Digest(), 128);

  // Initialize the HMAC instance with the provided key.
  tmp.init(KeyParameter(key));

  // Calculate the HMAC-SHA-512 digest of the input data.
  return tmp.process(data);
}

// This function calculates a double SHA-256 hash of the provided input buffer.
// Double hashing is commonly used in blockchain and cryptographic applications.
Uint8List doubleHash(Uint8List buffer) {
  // Calculate the first SHA-256 hash of the input buffer.
  Uint8List tmp = SHA256Digest().process(buffer);

  // Calculate the second SHA-256 hash of the first hash result.
  return SHA256Digest().process(tmp);
}

// This function calculates a single SHA-256 hash of the provided input buffer.
// It computes a one-time SHA-256 hash without any further processing.
Uint8List singleHash(Uint8List buffer) {
  // Calculate the SHA-256 hash of the input buffer.
  Uint8List tmp = SHA256Digest().process(buffer);

  // Return the resulting hash.
  return tmp;
}

// A private field to hold the FortunaRandom instance for generating random numbers.
FortunaRandom? _randomGenerator;

// This function generates a random Uint8List of the specified size (default is 32 bytes).
Uint8List generateRandom({int size = 32}) {
  // Check if the _randomGenerator instance has been initialized.
  if (_randomGenerator == null) {
    // If not, create a new FortunaRandom instance and seed it with entropy.
    _randomGenerator = FortunaRandom();

    // Generate 32 bytes of entropy from the platform's entropy source and use it as the seed.
    _randomGenerator!.seed(KeyParameter(
        platform.Platform.instance.platformEntropySource().getBytes(32)));
  }

  // Generate the random bytes of the specified size using the _randomGenerator.
  final r = _randomGenerator!.nextBytes(size);

  // Return the generated random bytes.
  return r;
}

// This function derives a key from a mnemonic passphrase and a salt using the PBKDF2 algorithm with SHA-512.
// It returns a Uint8List representing the derived key.
Uint8List pbkdfDeriveDigest(String mnemonic, String salt) {
  // Convert the salt string into a Uint8List of bytes.
  final toBytesSalt = Uint8List.fromList(utf8.encode(salt));

  // Create a PBKDF2 key derivator with an HMAC-SHA-512 pseudorandom function and a 128-bit block size.
  final derive = PBKDF2KeyDerivator(HMac(SHA512Digest(), 128));

  // Reset the derivator to its initial state.
  derive.reset();

  // Initialize the derivator with the salt, iteration count (2048), and desired key length (64 bytes).
  derive.init(Pbkdf2Parameters(toBytesSalt, 2048, 64));

  // Convert the mnemonic passphrase string into a Uint8List of bytes and derive the key.
  return derive.process(Uint8List.fromList(mnemonic.codeUnits));
}

// A final instance of the KeccakDigest with a hash length of 256 bits (32 bytes).
final KeccakDigest _keccakDigest = KeccakDigest(256);

// This function computes the Keccak-256 hash (SHA-3) of the given input data.
// It resets the KeccakDigest instance before processing the input.
// It returns a Uint8List representing the Keccak-256 hash.
Uint8List keccak256(Uint8List input) {
  // Reset the _keccakDigest instance to its initial state.
  _keccakDigest.reset();

  // Process the input data using the KeccakDigest to calculate the Keccak-256 hash.
  return _keccakDigest.process(input);
}
