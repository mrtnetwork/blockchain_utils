import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/hash/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/key_derivation/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/key_derivation/hkdf/hkdf.dart';
import 'package:blockchain_utils/crypto/crypto/key_derivation/pbkdf2/pbkdf2.dart';
import 'package:blockchain_utils/crypto/crypto/key_derivation/scrypt/scrypt.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [KeyDerivationApi] backed by the pure-Dart implementations in this
/// package ([PBKDF2], [Scrypt], [HKDF]).
class DartKeyDerivationApi implements KeyDerivationApi {
  HashApi get hashApi => blockchainUtils.api.hash;
  @override
  BuBytes pbkdf2Sha256DeriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    return PBKDF2.deriveKey(
      mac: () => hashApi.hmacSha256(password),
      salt: salt,
      iterations: iterations,
      length: length,
    );
  }

  @override
  BuBytes pbkdf2Sha512DeriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    return PBKDF2.deriveKey(
      mac: () => hashApi.hmacSha512(password),
      salt: salt,
      iterations: iterations,
      length: length,
    );
  }

  @override
  BuBytes scryptDeriveKey({
    required List<int> password,
    required List<int> salt,
    required int dkLen,
    required int r,
    required int n,
    required int p,
  }) {
    return Scrypt.deriveKey(password, salt, dkLen: dkLen, n: n, p: p, r: r);
  }

  @override
  BuBytes hkdfSha256DeriveKey({
    required List<int> ikm,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  }) {
    final hkdf = HKDF.rfc(
      ikm: ikm,
      hash: blockchainUtils.api.hash.sha256,
      length: length,
      salt: salt,
      info: info,
    );
    try {
      return hkdf.deriveRfc();
    } finally {
      hkdf.clean();
    }
  }

  @override
  BuBytes hkdfSha512DeriveKey({
    required List<int> ikm,
    int length = 32,
    List<int>? salt,
    List<int>? info,
  }) {
    final hkdf = HKDF.rfc(
      ikm: ikm,
      hash: blockchainUtils.api.hash.sha512,
      length: length,
      salt: salt,
      info: info,
    );
    try {
      return hkdf.deriveRfc();
    } finally {
      hkdf.clean();
    }
  }
}
