import 'dart:convert';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/crypto/crypto/aes/aes.dart';
import 'package:blockchain_utils/crypto/crypto/ctr/ctr.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/hmac/hmac.dart';
import 'package:blockchain_utils/crypto/crypto/pbkdf2/pbkdf2.dart';
import 'package:blockchain_utils/crypto/crypto/scrypt/scrypt.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/string/string.dart';
import 'package:blockchain_utils/uuid/uuid.dart';

/// Enum representing different encoding formats for secret wallets.
enum SecretWalletEncoding {
  base64, // Base64 encoding
  json, // JSON encoding
}

/// Abstract class representing a key derivation strategy.
abstract class _Derivator {
  List<int> deriveKey(List<int> password);

  String get name; // The name of the key derivation strategy.
  Map<String, dynamic>
      encode(); // Method to encode the parameters of the strategy.
}

/// A class implementing key derivation using the PBKDF2 algorithm.
class _PBDKDF2Derivator extends _Derivator {
  _PBDKDF2Derivator(this.iterations, this.salt, this.dklen);
  final int iterations;
  final List<int> salt;
  final int dklen;

  @override
  List<int> deriveKey(List<int> password) {
    return PBKDF2.deriveKey(
        mac: () => HMAC(() => SHA256(), password),
        salt: salt,
        iterations: iterations,
        length: dklen);
  }

  @override
  Map<String, dynamic> encode() {
    return {
      'c': iterations,
      'dklen': dklen,
      'prf': 'hmac-sha256',
      'salt': BytesUtils.toHexString(salt)
    };
  }

  @override
  final String name = 'pbkdf2'; // Name of the PBKDF2 strategy.
}

/// A class implementing key derivation using the Scrypt algorithm.
class _ScryptDerivator extends _Derivator {
  _ScryptDerivator(this.dklen, this.n, this.r, this.p, this.salt);
  final int dklen;
  final int n;
  final int r;
  final int p;
  final List<int> salt;

  @override
  List<int> deriveKey(List<int> password) {
    return Scrypt.deriveKey(password, salt, dkLen: dklen, n: n, r: r, p: p);
  }

  @override
  Map<String, dynamic> encode() {
    return {
      'dklen': dklen,
      'n': n,
      'r': r,
      'p': p,
      'salt': BytesUtils.toHexString(salt),
    };
  }

  @override
  final String name = 'scrypt'; // Name of the Scrypt strategy.
}

/// The `SecretWallet` class represents a secret wallet that stores sensitive credentials
/// using a specified key derivation strategy.
class SecretWallet {
  const SecretWallet._(
    this.credentials,
    this._derivator,
    this._password,
    this._iv,
    this._id,
  );

  /// Factory method to create a `SecretWallet` with encoded credentials.
  ///
  /// - `credentials`: The encoded credentials to be stored in the wallet.
  /// - `password`: The password used to derive the encryption key.
  /// - `scryptN`: Parameter 'n' for the Scrypt key derivation function (default is 8192).
  /// - `p`: Parameter 'p' for the Scrypt key derivation function (default is 1).
  ///
  /// Returns a `SecretWallet` instance with the encoded credentials.
  factory SecretWallet.encode(
    String credentials,
    String password, {
    int scryptN = 8192,
    int p = 1,
  }) {
    final passwordBytes = StringUtils.encode(password);

    final salt = QuickCrypto.generateRandom(32);

    final derivator = _ScryptDerivator(32, scryptN, 8, p, salt);

    final uuid = UUID.toBuffer(UUID.generateUUIDv4());

    final iv = QuickCrypto.generateRandom(128 ~/ 8);

    return SecretWallet._(credentials, derivator, passwordBytes, iv, uuid);
  }

  static Map<String, dynamic> _toJsonEcoded(String encoded) {
    try {
      final bs64 = base64Decode(encoded);
      return json.decode(StringUtils.decode(bs64));
    } catch (e) {
      return json.decode(encoded);
    }
  }

  /// Factory method to decode and create a `SecretWallet` from an encoded string and a password.
  ///
  /// - `encoded`: The encoded string containing wallet data.
  /// - `password`: The password used to derive the encryption key.
  ///
  /// Returns a `SecretWallet` instance decoded from the input data, or throws an error
  /// if decoding or password validation fails.
  factory SecretWallet.decode(String encoded, String password) {
    final data = _toJsonEcoded(encoded);

    final version = data['version'];
    if (version != 3) {
      throw ArgumentError("Library only supports version 3");
    }

    final params = data['crypto'] ?? data['Crypto'];

    final String kdf = params['kdf'];
    _Derivator derivator;

    switch (kdf) {
      case 'pbkdf2':
        final derParams = params['kdfparams'] as Map<String, dynamic>;

        if (derParams['prf'] != 'hmac-sha256') {
          throw ArgumentError('Invalid prf only support hmac-sha256');
        }

        derivator = _PBDKDF2Derivator(
          derParams['c'] as int,
          BytesUtils.fromHexString(derParams['salt']),
          derParams['dklen'] as int,
        );

        break;
      case 'scrypt':
        final derParams = params['kdfparams'] as Map<String, dynamic>;
        derivator = _ScryptDerivator(
          derParams['dklen'] as int,
          derParams['n'] as int,
          derParams['r'] as int,
          derParams['p'] as int,
          BytesUtils.fromHexString(derParams['salt']),
        );
        break;
      default:
        throw ArgumentError(
          '$kdf which is not supported.',
        );
    }

    final encodedPassword = List<int>.from(StringUtils.encode(password));
    final derivedKey = derivator.deriveKey(encodedPassword);
    final aesKey = List<int>.from(derivedKey.sublist(0, 16));
    final encryptedPrivateKey = BytesUtils.fromHexString(params['ciphertext']);
    final derivedMac = _generateMac(derivedKey, encryptedPrivateKey);
    if (derivedMac != params['mac']) {
      throw ArgumentError('wrong password or the file is corrupted');
    }

    if (params['cipher'] != 'aes-128-ctr') {
      throw ArgumentError("only cipher aes-128-ctr is supported.");
    }
    final iv = BytesUtils.fromHexString(params['cipherparams']['iv']);
    final encryptText = List<int>.from(encryptedPrivateKey);
    final CTR ctr = CTR(AES(aesKey), iv);
    final List<int> privateKey = List<int>.filled(encryptText.length, 0);
    ctr.streamXOR(encryptText, privateKey);
    ctr.clean();
    final id = UUID.toBuffer(data['id'] as String);
    return SecretWallet._(
        StringUtils.decode(privateKey), derivator, encodedPassword, iv, id);
  }

  final String credentials;

  final _Derivator _derivator;

  final List<int> _password;
  final List<int> _iv;

  final List<int> _id;

  String get uuid => UUID.fromBuffer(_id);

  /// Encrypts the sensitive wallet data using the specified encoding format and returns
  /// the encrypted representation.
  ///
  /// - `encoding`: The encoding format to use for the encrypted output (default is JSON).
  ///
  /// Returns the encrypted wallet data as a string in the chosen encoding format.
  String encrypt({SecretWalletEncoding encoding = SecretWalletEncoding.json}) {
    // Encrypt the wallet data and obtain the ciphertext bytes.
    final ciphertextBytes = _encryptPassword();

    // Prepare the JSON representation of the encrypted data.
    final Map<String, dynamic> toJson = {
      'crypto': {
        'cipher': 'aes-128-ctr',
        'cipherparams': {'iv': BytesUtils.toHexString(_iv)},
        'ciphertext': BytesUtils.toHexString(ciphertextBytes),
        'kdf': _derivator.name,
        'kdfparams': _derivator.encode(),
        'mac': _generateMac(_derivator.deriveKey(_password), ciphertextBytes),
      },
      'id': uuid,
      'version': 3,
    };

    // Convert the JSON to a string.
    final toString = json.encode(toJson);

    // Based on the specified encoding format, return the encrypted data as a string.
    if (encoding == SecretWalletEncoding.json) {
      return toString;
    }
    return base64Encode(StringUtils.encode(toString));
  }

  /// Generates a Message Authentication Code (MAC) for the provided derived key and ciphertext.
  ///
  /// - `dk`: The derived key.
  /// - `ciphertext`: The encrypted ciphertext.
  ///
  /// Returns the MAC as a hexadecimal string.
  static String _generateMac(List<int> dk, List<int> ciphertext) {
    // Concatenate the derived key and ciphertext to form the input for the MAC calculation.
    final mac = <int>[...dk.sublist(16, 32), ...ciphertext];

    // Hash the concatenated data using Keccak.
    return BytesUtils.toHexString(Keccack.hash(List<int>.from(mac)));
  }

  /// Encrypts the wallet's sensitive credentials using AES-128-CTR encryption.
  ///
  /// Returns the encrypted ciphertext as a list of bytes.
  List<int> _encryptPassword() {
    // Derive the encryption key from the password.
    final derived = _derivator.deriveKey(_password);
    final aesKey = List<int>.from(derived.sublist(0, 16));

    // Convert the credentials to bytes and encrypt using AES-128-CTR.
    final plainText = List<int>.from(StringUtils.encode(credentials));
    final CTR ctr = CTR(AES(aesKey), _iv);
    final encryptOut = List<int>.filled(plainText.length, 0);
    ctr.streamXOR(plainText, encryptOut);
    ctr.clean();

    return encryptOut;
  }
}
