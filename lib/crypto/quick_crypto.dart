import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/api/rng/native.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// QuickCrypto provides a set of utility methods for cryptographic operations.
///
/// This class contains static methods for generating random bytes, hashing data,
/// and performing other cryptographic operations commonly used in various
/// applications.
class QuickCrypto {
  static BuBytes _onShotHash(List<int> data, BuSerializableHash hash) {
    try {
      hash.update(data);
      return hash.digest().asBytes;
    } finally {
      hash.clean();
    }
  }

  /// Calculate the SHA-256 hash of the input data
  static BuBytes sha256Hash(List<int> data) {
    final hash = blockchainUtils.api.hash.sha256();
    return _onShotHash(data, hash);
  }

  /// Calculate the SHA-256 hash of the input data
  static BuBytes sha224Hash(List<int> data) {
    final hash = blockchainUtils.api.hash.sha224();
    return _onShotHash(data, hash);
  }

  static BuBytes md5Hash(List<int> data) {
    final hash = blockchainUtils.api.hash.md5();
    return _onShotHash(data, hash);
  }

  static BuBytes sha1Hash(List<int> data) {
    final hash = blockchainUtils.api.hash.sha1();
    return _onShotHash(data, hash);
  }

  /// Calculate the SHA-256 hash of the SHA-256 hash of the input data
  static BuBytes sha256DoubleHash(List<int> data) {
    final List<int> tmp = sha256Hash(data);
    return sha256Hash(tmp);
  }

  /// Static property that defines the size of SHA-256 digests in bytes
  static const int sha256DigestSize = 32;

  /// Derive a key from a password using PBKDF2 algorithm
  static BuBytes pbkdf2Sha512DeriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    int? dklen,
  }) {
    return blockchainUtils.api.keyDerivation.pbkdf2Sha512DeriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
      length: dklen ?? sha512DigestLength,
    );
  }

  static BuBytes pbkdf2Sha256DeriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    int? dklen,
  }) {
    return blockchainUtils.api.keyDerivation.pbkdf2Sha256DeriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
      length: dklen ?? sha256DigestSize,
    );
  }

  static BuBytes scryptDerive(
    List<int> password,
    List<int> salt, {
    int dkLen = 32,
    int r = 8,
    int n = 8192,
    int p = 1,
  }) {
    return blockchainUtils.api.keyDerivation.scryptDeriveKey(
      password: password,
      salt: salt,
      dkLen: dkLen,
      r: r,
      n: n,
      p: p,
    );
  }

  /// Calculate the RIPEMD-160 hash of the SHA-256 hash of the input data
  static BuBytes hash160(List<int> data) {
    final List<int> tmp = sha256Hash(data);
    final hash160 = blockchainUtils.api.hash.ripemd160();
    return _onShotHash(tmp, hash160);
  }

  /// Define the size of RIPEMD-160 digests, which is 20 bytes (160 bits)
  static const int hash160DigestSize = 20;

  /// Calculate the RIPEMD-160 hash of the input data
  static BuBytes ripemd160Hash(List<int> data) {
    final hash160 = blockchainUtils.api.hash.ripemd160();
    return _onShotHash(data, hash160);
  }

  static BuBytes blake2bHash(
    List<int>? data,
    int digestSize, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> batch = const [],
  }) {
    final config = Blake2Config.blake2b(
      key: key,
      salt: salt,
      personalization: personalization,
    );
    final b = blockchainUtils.api.hash.blake2b(
      digestLength: digestSize,
      config: config,
    );
    try {
      if (data != null) {
        b.update(data);
      }
      for (final i in batch) {
        b.update(i);
      }
      return b.digest().asBytes;
    } finally {
      b.clean();
    }
  }

  static BuBytes _blake2sHash(
    List<int> data,
    int digestSize, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> batch = const [],
  }) {
    final config = Blake2Config.blake2s(
      key: key,
      salt: salt,
      personalization: personalization,
    );
    final b = blockchainUtils.api.hash.blake2s(
      digestLength: digestSize,
      config: config,
    );
    try {
      b.update(data);
      for (final i in batch) {
        b.update(i);
      }
      return b.digest().asBytes;
    } finally {
      b.clean();
    }
  }

  /// Define the size of BLAKE2b-512 digests, which is 64 bytes (512 bits)
  static const int blake2b512DigestSize = 64;

  /// Calculate the BLAKE2b-512 hash of the input data
  static BuBytes blake2b512Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> extraBlocks = const [],
  }) => blake2bHash(
    data,
    blake2b512DigestSize,
    key: key,
    salt: salt,
    personalization: personalization,
    batch: extraBlocks,
  );

  /// Define the size of BLAKE2b-256 digests, which is 32 bytes (256 bits)
  static const int blake2b256DigestSize = 32;

  /// Calculate the BLAKE2b-256 hash of the input data
  static BuBytes blake2b256Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> extraBlocks = const [],
  }) => blake2bHash(
    data,
    blake2b256DigestSize,
    key: key,
    salt: salt,
    personalization: personalization,
    batch: extraBlocks,
  );

  /// Calculate the BLAKE2s-256 hash of the input data
  static BuBytes blake2s256Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> extraBlocks = const [],
  }) => _blake2sHash(
    data,
    blake2b256DigestSize,
    key: key,
    salt: salt,
    personalization: personalization,
    batch: extraBlocks,
  );

  /// Define the size of BLAKE2b-224 digests, which is 28 bytes (224 bits)
  static const int blake2b224DigestSize = 28;

  /// Calculate the BLAKE2b-224 hash of the input data
  static BuBytes blake2b224Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> extraBlocks = const [],
  }) => blake2bHash(
    data,
    blake2b224DigestSize,
    key: key,
    salt: salt,
    personalization: personalization,
    batch: extraBlocks,
  );

  /// Define the size of BLAKE2b-160 digests, which is 20 bytes (160 bits)
  static const int blake2b160DigestSize = 20;

  /// Calculate the BLAKE2b-160 hash of the input data
  static BuBytes blake2b160Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> extraBlocks = const [],
  }) => blake2bHash(
    data,
    blake2b160DigestSize,
    key: key,
    salt: salt,
    batch: extraBlocks,
    personalization: personalization,
  );

  /// Define the size of BLAKE2b-160 digests, which is 20 bytes (128 bits)
  static const int blake2b128DigestSize = 16;

  /// Calculate the BLAKE2b-128 hash of the input data
  static BuBytes blake2b128Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> extraBlocks = const [],
  }) => blake2bHash(
    data,
    blake2b128DigestSize,
    key: key,
    salt: salt,
    batch: extraBlocks,
    personalization: personalization,
  );

  /// Define the size of BLAKE2b-40 digests, which is 5 bytes (40 bits)
  static const int blake2b40DigestSize = 5;

  /// Calculate the BLAKE2b-40 hash of the input data
  static BuBytes blake2b40Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> extraBlocks = const [],
  }) => blake2bHash(
    data,
    blake2b40DigestSize,
    key: key,
    salt: salt,
    personalization: personalization,
    batch: extraBlocks,
  );

  /// Define the size of BLAKE2b-32 digests, which is 4 bytes (32 bits)
  static const int blake2b32DigestSize = 4;

  /// Calculate the BLAKE2b-32 hash of the input data
  static BuBytes blake2b32Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> extraBlocks = const [],
  }) => blake2bHash(
    data,
    blake2b32DigestSize,
    key: key,
    salt: salt,
    personalization: personalization,
    batch: extraBlocks,
  );

  /// Define the size of BLAKE2b-32 digests, which is 4 bytes (32 bits)
  static const int blake2b64DigestSize = 8;

  /// Calculate the BLAKE2b-64 hash of the input data
  static BuBytes blake2b64Hash(
    List<int> data, {
    List<int>? key,
    List<int>? salt,
    List<int>? personalization,
    List<List<int>> extraBlocks = const [],
  }) => blake2bHash(
    data,
    blake2b64DigestSize,
    key: key,
    salt: salt,
    personalization: personalization,
    batch: extraBlocks,
  );

  static BuBytes _xxHash(List<int> data, int digestSize) {
    final hash = blockchainUtils.api.hash.xxHash(bitLength: digestSize * 8);
    return _onShotHash(data, hash);
  }

  static const int twoX64DigestSize = 8;
  static BuBytes twoX64(List<int> data) {
    return _xxHash(data, twoX64DigestSize);
  }

  static const int twoX128DigestSize = 16;
  static BuBytes twoX128(List<int> data) {
    return _xxHash(data, twoX128DigestSize);
  }

  static const int twoX256DigestSize = 32;
  static BuBytes twoX256(List<int> data) {
    return _xxHash(data, twoX256DigestSize);
  }

  /// Calculate the SHA-512/256 hash of the input data
  static BuBytes sha512256Hash(List<int> data) {
    final hash = blockchainUtils.api.hash.sha512256();
    return _onShotHash(data, hash);
  }

  /// Calculate the SHA-512 hash of the input data
  static BuBytes sha512Hash(List<int> data) {
    final hash = blockchainUtils.api.hash.sha512();
    return _onShotHash(data, hash);
  }

  /// Calculate the SHA-512 hash of the input data
  static BuBytes sha384Hash(List<int> data) {
    final hash = blockchainUtils.api.hash.sha384();
    return _onShotHash(data, hash);
  }

  /// Gets the length of the SHA512 digest.
  static const int sha512DigestLength = 64;

  /// Computes the SHA512 hash of the input data and returns its halves.
  ///
  /// This method computes the SHA512 hash of the provided data and returns the first
  /// half and the second half of the hash as a tuple.
  ///
  /// [data] The input data for which the hash is to be computed.
  /// returns A tuple containing the first and second halves of the SHA512 hash.
  static (BuBytes, BuBytes) sha512HashHalves(List<int> data) {
    final hash = sha512Hash(data);
    const halvesLength = sha512DigestLength ~/ 2;
    return (hash.sublist(0, halvesLength), hash.sublist(halvesLength));
  }

  /// Calculate the Keccak-256 hash of the input data
  static BuBytes keccak256Hash(List<int> data) {
    final hash = blockchainUtils.api.hash.keccak(digestLength: 32);
    return _onShotHash(data, hash);
  }

  static BuBytes keccakF1600(BuBytes src) {
    // return Keccak.keccakF1600(src);
    final hash = blockchainUtils.api.hash.keccakF1600(src);
    return hash;
  }

  /// Calculate the SHA-3-256 hash of the input data
  static BuBytes sha3256Hash(List<int> data) {
    final hash = blockchainUtils.api.hash.sha3(digestLength: 32);
    return _onShotHash(data, hash);
  }

  /// Define the size of SHA-3-256 digests, which is 32 bytes (256 bits)
  static const int sha3256DigestSize = 32;

  /// Calculate the HMAC-SHA-256 hash of the input data using the provided key
  static BuBytes hmacsha256Hash(List<int> key, List<int> data) {
    final hm = blockchainUtils.api.hash.hmacSha256(key);
    try {
      hm.update(data);
      return hm.digest().asBytes;
    } finally {
      hm.clean();
    }
  }

  /// Calculate the HMAC-SHA-384 hash of the input data using the provided key
  static BuBytes hmacSha384Hash(List<int> key, List<int> data) {
    final hm = blockchainUtils.api.hash.hmacSha384(key);
    try {
      hm.update(data);
      return hm.digest().asBytes;
    } finally {
      hm.clean();
    }
  }

  /// Calculate the HMAC-SHA-512 hash of the input data using the provided key
  static BuBytes hmacSha512Hash(List<int> key, List<int> data) {
    final hm = blockchainUtils.api.hash.hmacSha512(key);
    try {
      hm.update(data);
      return hm.digest().asBytes;
    } finally {
      hm.clean();
    }
  }

  /// Define the size of HMAC-SHA-512 digests, which is 64 bytes (512 bits)
  static const int hmacSha512DigestSize = 64;

  /// Calculate the HMAC-SHA-512 hash of the input data using the provided key and
  /// split the result into two halves. Return a tuple containing both halves
  static (BuBytes, BuBytes) hmacSha512HashHalves(
    List<int> key,
    List<int> data,
  ) {
    final bytes = hmacSha512Hash(key, data);
    return (
      bytes.sublist(0, hmacSha512DigestSize ~/ 2),
      bytes.sublist(hmacSha512DigestSize ~/ 2),
    );
  }

  /// Encrypt the input data using AES(ECB)
  static BuBytes aesEcbEncrypt(
    List<int> key,
    List<int> data, {
    PaddingAlgorithm? paddingAlgorithm,
  }) {
    final ecb = blockchainUtils.api.blockCipher.aesEcb(
      key,
      padding: paddingAlgorithm,
    );
    try {
      return ecb.encrypt(data).asBytes;
    } finally {
      ecb.clean();
    }
  }

  /// Decrypt the input data using AES(ECB)
  static BuBytes aesEcbDecrypt(
    List<int> key,
    List<int> data, {
    PaddingAlgorithm? paddingAlgorithm,
  }) {
    final ecb = blockchainUtils.api.blockCipher.aesEcb(
      key,
      padding: paddingAlgorithm,
    );
    try {
      final decrypt = ecb.decrypt(data)?.asBytes;

      if (decrypt == null) {
        throw CoreErrors.cryptoFailed(
          "aesEcbDecrypt",
          reason: "Decryption failed.",
        );
      }
      return decrypt;
    } finally {
      ecb.clean();
    }
  }

  /// Decrypt data using the ChaCha20-Poly1305 authenticated encryption algorithm.
  /// Requires a key, nonce, ciphertext, and optional associated data.
  static BuBytes chaCha20Poly1305Decrypt({
    required List<int> key,
    required List<int> nonce,
    required List<int> cipherText,
    List<int>? assocData,
  }) {
    return chacha20Poly1305(key, (chacha) {
      final decrypt = chacha.decrypt(
        nonce,
        cipherText,
        associatedData: assocData,
      );

      if (decrypt != null) {
        return decrypt;
      }
      throw CoreErrors.cryptoFailed(
        "chaCha20Poly1305Decrypt",
        reason: "Decryption failed.",
      );
    });
  }

  /// Decrypt data using the ChaCha20-Poly1305 authenticated encryption algorithm.
  /// Requires a key, nonce, ciphertext, and optional associated data.
  static BuBytes? tryChaCha20Poly1305Decrypt({
    required List<int> key,
    required List<int> nonce,
    required List<int> cipherText,
    List<int>? assocData,
  }) {
    return chacha20Poly1305(key, (chacha) {
      return chacha.decrypt(nonce, cipherText, associatedData: assocData);
    });
  }

  /// Encrypt data using the ChaCha20-Poly1305 authenticated encryption algorithm.
  /// Requires a key, nonce, plaintext, and optional associated data.
  static BuBytes chaCha20Poly1305Encrypt({
    required List<int> key,
    required List<int> nonce,
    required List<int> plainText,
    List<int>? assocData,
  }) {
    return chacha20Poly1305(key, (chacha) {
      return chacha.encrypt(nonce, plainText, associatedData: assocData);
    });
  }

  /// Define the tag length for ChaCha20-Poly1305, which is 16 bytes
  static const int chacha20Polu1305Taglenght = 16;

  /// Define the key size for ChaCha20-Poly1305, which is 32 bytes
  static const int chacha20Polu1305Keysize = 32;

  /// field to hold the FortunaRandom instance for generating random numbers.
  static Rng _prng = FortunaPRNG();

  static Rng get prng => _prng;

  static CbGenerateRandom _generateRandom = (length) {
    return prng.nextBytes(length);
  };

  static void setupPRNG(Rng prng) {
    _prng = prng;
  }

  static void setupRandom(CbGenerateRandom? random) {
    if (random == null) {
      _generateRandom = (length) {
        return prng.nextBytes(length);
      };
    } else {
      _generateRandom = random;
    }
  }

  /// Routes [generateRandom] through the active backend RNG
  /// (`blockchainUtils.api.rng`, seeded below when necessary).
  ///
  /// Falls back to the Fortuna [_prng] whenever the active backend has no
  /// global RNG (pure-Dart backend), so callers keep working across
  /// `setRustApi`/`setDartApi` switches. Prefer [BlockchainUtils.setRustApi]
  /// (which calls this) and [BlockchainUtils.setDartApi] (which restores
  /// [setupRandom] `null`) over calling this directly.
  static void setupBackendRng() {
    final backend = blockchainUtils.api.rng;
    if (backend is NativeRngApi && !backend.isSeeded) {
      // `dart test` runs files in concurrent isolates sharing one process
      // (and one native library): two files can both observe an unseeded
      // RNG and race to seed it. Losing is fine as long as *someone* won —
      // re-check the seeded state before treating a failed seed as fatal.
      try {
        backend.seed(seed32: generateRandom(length: 32));
      } on BuError {
        if (!backend.isSeeded) rethrow;
      }
    }
    _generateRandom = (length) {
      if (length == 0) return <int>[].asBytes;
      final active = blockchainUtils.api.rng;
      if (active is NativeRngApi) return active.fill(length: length).asBytes;
      return _prng.nextBytes(length);
    };
  }

  /// This function generates a random `List<int>` of the specified size (default is 32 bytes).
  static BuBytes generateRandom({int length = 32}) {
    /// Generate the random bytes of the specified size using the _randomGenerator.
    final r = _generateRandom(length);
    assert(r.length == length, "Incorrect random generted size.");

    /// Return the generated random bytes.
    return r;
  }

  /// This function generates a random `List<int>` of the specified size (default is 32 bytes).
  static BuBytes generateRandomFromRng({int length = 32, Rng? rng}) {
    /// Generate the random bytes of the specified size using the _randomGenerator.
    final r = rng?.nextBytes(length) ?? _generateRandom(length);
    assert(r.length == length, "Incorrect random generted size.");

    /// Return the generated random bytes.
    return r;
  }

  static BuBytes generateUniqueRandom({
    int length = 32,
    List<List<int>> existingKeys = const [],
  }) {
    BuBytes rand = generateRandom(length: length);
    if (existingKeys.isEmpty) return rand;
    while (BytesUtils.isContains(existingKeys, rand)) {
      rand = QuickCrypto.generateRandom(length: length);
    }
    return rand;
  }

  static int generateRandomInt(int max) {
    return prng.nextInt(max);
  }

  static int nextU32() {
    return prng.nextU32();
  }

  static BigInt nextU64() {
    return prng.nextU64();
  }

  static bool generateRandoomBool() {
    return prng.nextBool();
  }

  static String generateRandomHex([int size = 32]) {
    return BytesUtils.toHexString(generateRandom(length: size));
  }

  static String generateUniqueRandomHex({
    int length = 32,
    List<List<int>> existingKeys = const [],
  }) {
    return BytesUtils.toHexString(
      generateUniqueRandom(length: length, existingKeys: existingKeys),
    );
  }

  static BuBytes processCtr({
    required List<int> key,
    required List<int> iv,
    required List<int> data,
  }) {
    final ctr = blockchainUtils.api.blockCipher.aesCtr(key, iv);
    // final CTR ctr = CTR(AES(key), iv);
    final xor = BuBytes.fill(data.length, 0);
    ctr.process(data, xor);
    ctr.clean();
    return xor;
  }

  static X25519Keypair generateX25519XKeyPair({List<int>? seed}) {
    return X25519Keypair.generate(seed: seed);
  }

  /// Strict RFC 5869 HKDF-SHA-256 quick call, routed through the active
  /// backend (pure-Dart or native Rust). Always Extract-then-Expand;
  /// omitted [salt] defaults to 32 zeros (§2.2) on every backend.
  /// Prefer this over [hdfkDerive] for interoperable derivations.
  static BuBytes hkdfDeriveSha256({
    required List<int> ikm,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  }) {
    _checkHkdfLength("hkdfDeriveSha256", length);
    return blockchainUtils.api.keyDerivation.hkdfSha256DeriveKey(
      ikm: ikm,
      length: length,
      salt: salt,
      info: info,
    );
  }

  /// Strict RFC 5869 HKDF-SHA-512 quick call, routed through the active
  /// backend (pure-Dart or native Rust). Always Extract-then-Expand;
  /// omitted [salt] defaults to 64 zeros (§2.2) on every backend.
  /// Prefer this over [hdfkDerive] for interoperable derivations.
  static BuBytes hkdfDeriveSha512({
    required List<int> ikm,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  }) {
    _checkHkdfLength("hkdfDeriveSha512", length);
    return blockchainUtils.api.keyDerivation.hkdfSha512DeriveKey(
      ikm: ikm,
      length: length,
      salt: salt,
      info: info,
    );
  }

  /// L = 0 diverges by backend (Dart: empty OKM, native: error), so the
  /// HKDF quick calls require L >= 1 like ValidatedKeyDerivationApi does.
  static void _checkHkdfLength(String operation, int length) {
    if (length < 1) {
      throw CoreErrors.invalidOperationArguments(
        operation,
        name: "length",
        reason: "Invalid length. Must be positive.",
      );
    }
  }

  static String generateRandomString(
    int length, {
    String charset =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
  }) {
    final characters = List.generate(
      length,
      (_) => charset[prng.nextInt(charset.length)],
    );
    return characters.join();
  }

  static BuSerializableHash sha512Instance() =>
      blockchainUtils.api.hash.sha512();

  /// Runs [use] with a fresh SHA-512 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T sha512<T extends Object?>(
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = sha512Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash sha512256Instance() =>
      blockchainUtils.api.hash.sha512256();

  /// Runs [use] with a fresh SHA-512/256 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T sha512256<T extends Object?>(
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = sha512256Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash sha256Instance() =>
      blockchainUtils.api.hash.sha256();

  /// Runs [use] with a fresh SHA-256 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T sha256<T extends Object?>(
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = sha256Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash sha1Instance() => blockchainUtils.api.hash.sha1();

  /// Runs [use] with a fresh SHA-1 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T sha1<T extends Object?>(T Function(BuSerializableHash cipher) use) {
    final cipher = sha1Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash sha3Instance({int digestLength = 32}) =>
      blockchainUtils.api.hash.sha3(digestLength: digestLength);

  /// Runs [use] with a fresh SHA-3 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T sha3<T extends Object?>(
    T Function(BuSerializableHash cipher) use, {
    int digestLength = 32,
  }) {
    final cipher = sha3Instance(digestLength: digestLength);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash keccakInstance({int digestLength = 64}) =>
      blockchainUtils.api.hash.keccak(digestLength: digestLength);

  /// Runs [use] with a fresh Keccak hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T keccak<T extends Object?>(
    T Function(BuSerializableHash cipher) use, {
    int digestLength = 64,
  }) {
    final cipher = keccakInstance(digestLength: digestLength);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash shake128Instance() {
    return blockchainUtils.api.hash.shake128();
  }

  /// Runs [use] with a fresh SHAKE-128 XOF, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T shake128<T extends Object?>(
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = shake128Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash shake256Instance() {
    return blockchainUtils.api.hash.shake256();
  }

  /// Runs [use] with a fresh SHAKE-256 XOF, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T shake256<T extends Object?>(
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = shake256Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash xxHashInstance({int bitLength = 64}) {
    return blockchainUtils.api.hash.xxHash(bitLength: bitLength);
  }

  /// Runs [use] with a fresh XXHash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T xxHash<T extends Object?>(
    T Function(BuSerializableHash cipher) use, {
    int bitLength = 64,
  }) {
    final cipher = xxHashInstance(bitLength: bitLength);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash hmacSha512Instance(List<int> key) =>
      blockchainUtils.api.hash.hmacSha512(key);

  /// Runs [use] with a fresh HMAC-SHA-512 built from [key], then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T hmacSha512<T extends Object?>(
    List<int> key,
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = hmacSha512Instance(key);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash hmacSha256Instance(List<int> key) =>
      blockchainUtils.api.hash.hmacSha256(key);

  /// Runs [use] with a fresh HMAC-SHA-256 built from [key], then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T hmacSha256<T extends Object?>(
    List<int> key,
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = hmacSha256Instance(key);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash hmacSha384Instance(List<int> key) =>
      blockchainUtils.api.hash.hmacSha384(key);

  /// Runs [use] with a fresh HMAC-SHA-384 built from [key], then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T hmacSha384<T extends Object?>(
    List<int> key,
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = hmacSha384Instance(key);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash md4Instance() => blockchainUtils.api.hash.md4();

  /// Runs [use] with a fresh MD4 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T md4<T extends Object?>(T Function(BuSerializableHash cipher) use) {
    final cipher = md4Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash md5Instance() => blockchainUtils.api.hash.md5();

  /// Runs [use] with a fresh MD5 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T md5<T extends Object?>(T Function(BuSerializableHash cipher) use) {
    final cipher = md5Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash ripemd128Instance() =>
      blockchainUtils.api.hash.ripemd128();

  /// Runs [use] with a fresh RIPEMD-128 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T ripemd128<T extends Object?>(
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = ripemd128Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash ripemd160Instance() =>
      blockchainUtils.api.hash.ripemd160();

  /// Runs [use] with a fresh RIPEMD-160 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T ripemd160<T extends Object?>(
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = ripemd160Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash ripemd256Instance() =>
      blockchainUtils.api.hash.ripemd256();

  /// Runs [use] with a fresh RIPEMD-256 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T ripemd256<T extends Object?>(
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = ripemd256Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash ripemd320Instance() =>
      blockchainUtils.api.hash.ripemd320();

  /// Runs [use] with a fresh RIPEMD-320 hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T ripemd320<T extends Object?>(
    T Function(BuSerializableHash cipher) use,
  ) {
    final cipher = ripemd320Instance();
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash blake2bInstance({
    int digestLength = 64,
    Blake2Config? config,
  }) => blockchainUtils.api.hash.blake2b(
    digestLength: digestLength,
    config: config,
  );

  /// Runs [use] with a fresh BLAKE2b hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T blake2b<T extends Object?>(
    T Function(BuSerializableHash cipher) use, {
    int digestLength = 64,
    Blake2Config? config,
  }) {
    final cipher = blake2bInstance(digestLength: digestLength, config: config);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuSerializableHash blake2sInstance({
    int digestLength = 32,
    Blake2Config? config,
  }) => blockchainUtils.api.hash.blake2s(
    digestLength: digestLength,
    config: config,
  );

  /// Runs [use] with a fresh BLAKE2s hash, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T blake2s<T extends Object?>(
    T Function(BuSerializableHash cipher) use, {
    int digestLength = 32,
    Blake2Config? config,
  }) {
    final cipher = blake2sInstance(digestLength: digestLength, config: config);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuBytes shake256Hash(List<int> data, int outlen) {
    return shake256((hash) {
      final out = BuBytes.fill(outlen, 0);
      hash.update(data);
      hash.finish(out);
      // SHAKE256.shake(data, outlen)
      return out;
    });
  }

  static BuBlockCipher aesInstance(List<int> key) =>
      blockchainUtils.api.blockCipher.aes(key);

  /// Runs [use] with a fresh AES block cipher built from [key], then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T aes<T extends Object?>(
    List<int> key,
    T Function(BuBlockCipher cipher) use,
  ) {
    final cipher = aesInstance(key);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuAesCtr aesCtrInstance(List<int> key, List<int> counter) =>
      blockchainUtils.api.blockCipher.aesCtr(key, counter);

  /// Runs [use] with a fresh AES-CTR cipher built from [key]/[counter], then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T aesCtr<T extends Object?>(
    List<int> key,
    List<int> counter,
    T Function(BuAesCtr cipher) use,
  ) {
    final cipher = aesCtrInstance(key, counter);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuAesEcb aesEcbInstance(
    List<int> key, {
    PaddingAlgorithm? padding = PaddingAlgorithm.pkcs7,
  }) => blockchainUtils.api.blockCipher.aesEcb(key, padding: padding);

  /// Runs [use] with a fresh AES-ECB cipher, then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T aesEcb<T extends Object?>(
    List<int> key,
    T Function(BuAesEcb cipher) use, {
    PaddingAlgorithm? padding = PaddingAlgorithm.pkcs7,
  }) {
    final cipher = aesEcbInstance(key, padding: padding);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  static BuAead chacha20Poly1305Instance(List<int> key) =>
      blockchainUtils.api.aed.chacha20Poly1305(key);

  /// Runs [use] with a fresh ChaCha20-Poly1305 AEAD built from [key], then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T chacha20Poly1305<T extends Object?>(
    List<int> key,
    T Function(BuAead cipher) use,
  ) {
    final cipher = chacha20Poly1305Instance(key);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  /// XSalsa20-Poly1305 (NaCl secretbox) AEAD from a 32-byte [key].
  /// Strict 24-byte nonce. Pure-Dart on every backend (web-safe).

  static BuAead xsalsa20Poly1305Instance(List<int> key) =>
      blockchainUtils.api.aed.xsalsa20Poly1305(key);

  /// Runs [use] with a fresh XSalsa20-Poly1305 AEAD built from [key], then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T xsalsa20Poly1305<T extends Object?>(
    List<int> key,
    T Function(BuAead cipher) use,
  ) {
    final cipher = xsalsa20Poly1305Instance(key);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }

  /// Encrypt with XSalsa20-Poly1305 (NaCl secretbox order:
  /// `16-byte tag || ciphertext`).
  static BuBytes xsalsa20Poly1305Encrypt({
    required List<int> key,
    required List<int> nonce,
    required List<int> plainText,
  }) {
    return xsalsa20Poly1305(key, (box) {
      return box.encrypt(nonce, plainText);
    });
  }

  /// Decrypt with XSalsa20-Poly1305. Throws [CryptoException] on
  /// authentication failure.
  static BuBytes xsalsa20Poly1305Decrypt({
    required List<int> key,
    required List<int> nonce,
    required List<int> cipherText,
  }) {
    return xsalsa20Poly1305(key, (box) {
      final decrypt = box.decrypt(nonce, cipherText);
      if (decrypt != null) {
        return decrypt;
      }
      throw CoreErrors.cryptoFailed(
        "xsalsa20Poly1305Decrypt",
        reason: "Decryption failed.",
      );
    });
  }

  /// NaCl `crypto_box_beforenm` quick call, routed through the active
  /// backend (Dart today, native automatically once the connector gains
  /// box support). Returns the 32-byte transport key.
  static BuBytes salsaBoxBeforenm({
    required List<int> peerPublicKey,
    required List<int> secretKey,
  }) {
    return blockchainUtils.api.aed.salsaBoxBeforenm(
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  /// NaCl `crypto_box_easy` detached encrypt quick call, routed through the
  /// active backend. Explicit 24-byte [nonce]; returns `TAG || CIPHERTEXT`.
  static BuBytes salsaBoxEncrypt({
    required List<int> peerPublicKey,
    required List<int> secretKey,
    required List<int> nonce,
    required List<int> plainText,
  }) {
    return blockchainUtils.api.aed.salsaBoxEncrypt(
      nonce,
      plainText,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  /// NaCl `crypto_box_open_easy` detached decrypt quick call, routed through
  /// the active backend. Returns plaintext, or `null` on authentication
  /// failure.
  static BuBytes? salsaBoxDecrypt({
    required List<int> peerPublicKey,
    required List<int> secretKey,
    required List<int> nonce,
    required List<int> sealed,
  }) {
    return blockchainUtils.api.aed.salsaBoxDecrypt(
      nonce,
      sealed,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  /// NaCl `crypto_box` seal quick call for TON Connect, routed through the
  /// active backend: X25519 + XSalsa20-Poly1305, returning
  /// `NONCE || TAG || CIPHERTEXT`. Generates a fresh random 24-byte nonce
  /// (web-safe Fortuna PRNG) when [nonce] is omitted; pass an explicit
  /// nonce for deterministic vectors/tests.
  static BuBytes salsaBoxSeal({
    required List<int> peerPublicKey,
    required List<int> secretKey,
    required List<int> plainText,
    List<int>? nonce,
  }) {
    final n = nonce ?? generateRandom(length: xsalsa20Poly1305NonceSize);
    try {
      return blockchainUtils.api.aed.salsaBoxSeal(
        n,
        plainText,
        peerPublicKey: peerPublicKey,
        secretKey: secretKey,
      );
    } finally {
      if (nonce == null) {
        BinaryOps.zero(n);
      }
    }
  }

  /// Opens a `NONCE || TAG || CIPHERTEXT` blob, routed through the active
  /// backend. Returns `null` when truncated or unauthenticated.
  static BuBytes? salsaBoxOpen({
    required List<int> peerPublicKey,
    required List<int> secretKey,
    required List<int> sealed,
  }) {
    return blockchainUtils.api.aed.salsaBoxOpen(
      sealed,
      peerPublicKey: peerPublicKey,
      secretKey: secretKey,
    );
  }

  /// Define the tag length for XSalsa20-Poly1305, which is 16 bytes
  static const int xsalsa20Poly1305TagLength = 16;

  /// Define the key size for XSalsa20-Poly1305, which is 32 bytes
  static const int xsalsa20Poly1305KeySize = 32;

  /// Define the nonce size for XSalsa20-Poly1305, which is 24 bytes
  static const int xsalsa20Poly1305NonceSize = 24;

  static BuStreamCipher chacha20Instance(List<int> key) =>
      blockchainUtils.api.streamCipher.chacha20(key);

  /// Runs [use] with a fresh ChaCha20 stream cipher built from [key], then wipes it.
  /// The instance must be clean after you don't need it; this method
  /// guarantees that, even if [use] throws.
  static T chacha20<T extends Object?>(
    List<int> key,
    T Function(BuStreamCipher cipher) use,
  ) {
    final cipher = chacha20Instance(key);
    try {
      return use(cipher);
    } finally {
      cipher.clean();
    }
  }
}
