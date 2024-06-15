/// The 'crypto' library provides a collection of cryptographic algorithms and utilities
/// for various cryptographic operations and security functions.
library crypto;

/// Export statement for AEAD (Authenticated Encryption with Associated Data) components.
export 'aead/aead.dart';

/// Export statement for AES (Advanced Encryption Standard) encryption and decryption.
export 'aes/aes.dart';

/// Export statement for block ciphers, which are used for block-level encryption and decryption.
export 'blockcipher/blockcipher.dart';

/// Export statement for the 'cdsa' library, which provides tools and components for
/// working with cryptographic algorithms, elliptic curve cryptography, and related functionality.
export 'cdsa/cdsa.dart';

/// Export statement for the ChaCha stream cipher and its variations.
export 'chacha/chacha.dart';

/// Export statement for the ChaCha20-Poly1305 AEAD (Authenticated Encryption with Associated Data) cipher.
export 'chacha20poly1305/chacha20poly1305.dart';

/// Export statement for the CRC32 (Cyclic Redundancy Check) algorithm for error-checking.
export 'crc32/crc32.dart';

/// Export statement for the CTR (Counter) mode encryption.
export 'ctr/ctr.dart';

/// Export statement for the ECB (Electronic Codebook) mode encryption.
export 'ecb/ecb.dart';

/// Export statement for the GCM (Galois/Counter Mode) mode of operation for authenticated encryption.
export 'gcm/gcm.dart';

/// Export statement for various hash functions and cryptographic hash utilities,
/// including SHA-224, SHA-256, SHA-384, SHA-512, SHA-512/256, SHA-1, Blake2b, RIdEMP, MD5, MD4,
/// and SHA-3 (Keccak).
export 'hash/hash.dart';

/// Export statement for HMAC (Hash-based Message Authentication Code) algorithms.
export 'hmac/hmac.dart';

/// Export statement for PBKDF2 (Password-Based Key Derivation Function 2) for securely deriving keys.
export 'pbkdf2/pbkdf2.dart';

/// Export statement for the Poly1305 message authentication code.
export 'poly1305/poly1305.dart';

/// Export statement for the Fortuna cryptographic pseudorandom number generator (PRNG).
export 'prng/fortuna.dart';

/// Export statement for the 'schnorrkel' library, which provides tools for working with the
/// Schnorrkel digital signature scheme, including key management, cryptographic functions,
/// and the Schnorrkel Merlin transcript and Strobe framework for secure digital signatures.
export 'schnorrkel/shnorrkel.dart';

/// Export statement for the 'scrypt' library, which provides tools for working with the
/// scrypt key derivation function.
export 'scrypt/scrypt.dart';

/// Export statement for the XMODEM CRC (Cyclic Redundancy Check) for error-checking in data transmission.
export 'x_modem_crc/x_modem_crc.dart';

export 'crc16/crc16.dart';
