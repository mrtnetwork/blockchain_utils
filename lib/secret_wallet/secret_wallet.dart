import 'package:blockchain_utils/blockchain_utils.dart';

class _SecretStorageConst {
  static const List<int> scryptTag = [180];
  static const List<int> pbdkdf2Tag = [181];
  static const List<int> tag = [200];
  static const int version = 3;
}

/// Enum representing different encoding formats for secret wallets.
enum SecretWalletEncoding {
  base64, // Base64 encoding
  json, // JSON encoding
  cbor, // cbor encoding
}

/// Abstract class representing a key derivation strategy.
abstract class _Derivator {
  List<int> deriveKey(List<int> password);

  String get name; // The name of the key derivation strategy.
  Map<String, dynamic> encode();
  CborTagValue cborEncode();

  static _Derivator fromCbor(CborObject cbor) {
    if (cbor is! CborTagValue || cbor.value is! CborListValue) {
      throw ArgumentException("invalid secret wallet cbor bytes");
    }
    if (bytesEqual(cbor.tags, _SecretStorageConst.pbdkdf2Tag)) {
      final toObj = _PBDKDF2Derivator.fromCbor(cbor.value);
      return toObj;
    } else if (bytesEqual(cbor.tags, _SecretStorageConst.scryptTag)) {
      return _Scrypt.fromCbor(cbor.value);
    } else {
      throw ArgumentException("invalid secret wallet cbor bytes");
    }
  }
}

/// A class implementing key derivation using the PBKDF2 algorithm.
class _PBDKDF2Derivator extends _Derivator {
  _PBDKDF2Derivator(this.iterations, this.salt, this.dklen);
  final int iterations;
  final List<int> salt;
  final int dklen;

  factory _PBDKDF2Derivator.fromCbor(CborListValue v) {
    final int c = v.value[0].value;
    final int dklen = v.value[1].value;
    final String prf = v.value[2].value;
    if (prf != 'hmac-sha256') {
      throw ArgumentException('Invalid prf only support hmac-sha256');
    }
    final List<int> salt = v.value[3].value;
    return _PBDKDF2Derivator(c, salt, dklen);
  }

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
  final String name = 'pbkdf2';

  @override
  CborTagValue cborEncode() {
    return CborTagValue(
        CborListValue.fixedLength([
          CborIntValue(iterations),
          CborIntValue(dklen),
          CborStringValue("hmac-sha256"),
          CborBytesValue(salt)
        ]),
        _SecretStorageConst.pbdkdf2Tag);
  }
}

/// A class implementing key derivation using the Scrypt algorithm.
class _Scrypt extends _Derivator {
  _Scrypt(this.dklen, this.n, this.r, this.p, this.salt);
  factory _Scrypt.fromCbor(CborListValue v) {
    final int dklen = v.value[0].value;
    final int n = v.value[1].value;
    final int r = v.value[2].value;
    final int p = v.value[3].value;
    final List<int> salt = v.value[4].value;
    return _Scrypt(dklen, n, r, p, salt);
  }
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
  final String name = 'scrypt';

  @override
  CborTagValue cborEncode() {
    return CborTagValue(
        CborListValue.fixedLength([
          CborIntValue(dklen),
          CborIntValue(n),
          CborIntValue(r),
          CborIntValue(p),
          CborBytesValue(salt)
        ]),
        _SecretStorageConst.scryptTag);
  } // Name of the Scrypt strategy.
}

/// The `SecretWallet` class represents a secret wallet that stores sensitive credentials
/// using a specified key derivation strategy.
class SecretWallet {
  SecretWallet._(
    List<int> data,
    this._derivator,
    this._password,
    this._iv,
    this._id,
  ) : data = List<int>.unmodifiable(data);

  /// Factory method to create a `SecretWallet` with encoded credentials.
  ///
  /// - `credentials`: The encoded credentials to be stored in the wallet.
  /// - `password`: The password used to derive the encryption key.
  /// - `scryptN`: Parameter 'n' for the Scrypt key derivation function (default is 8192).
  /// - `p`: Parameter 'p' for the Scrypt key derivation function (default is 1).
  ///
  /// Returns a `SecretWallet` instance with the encoded credentials.
  factory SecretWallet.encode(
    List<int> data,
    String password, {
    int scryptN = 8192,
    int p = 1,
  }) {
    final passwordBytes = StringUtils.encode(password);

    final salt = QuickCrypto.generateRandom(32);

    final derivator = _Scrypt(32, scryptN, 8, p, salt);

    final uuid = UUID.toBuffer(UUID.generateUUIDv4());

    final iv = QuickCrypto.generateRandom(128 ~/ 8);

    return SecretWallet._(data, derivator, passwordBytes, iv, uuid);
  }

  static Map<String, dynamic> _toJsonEcoded(String encoded,
      {SecretWalletEncoding encoding = SecretWalletEncoding.json}) {
    try {
      if (encoding == SecretWalletEncoding.json) {
        return StringUtils.toJson(encoded);
      }
      return StringUtils.toJson(StringUtils.decode(
          StringUtils.encode(encoded, StringEncoding.base64)));
    } catch (e) {
      throw ArgumentException("invalid encoding");
    }
  }

  /// Factory method to decode and create a `SecretWallet` from an encoded string and a password.
  ///
  /// - `encoded`: The encoded string containing wallet data.
  /// - `password`: The password used to derive the encryption key.
  ///
  /// Returns a `SecretWallet` instance decoded from the input data, or throws an error
  /// if decoding or password validation fails.
  factory SecretWallet.decode(String encoded, String password,
      {SecretWalletEncoding encoding = SecretWalletEncoding.json}) {
    if (encoding == SecretWalletEncoding.cbor) {
      return _decodeCbor(encoded, password);
    }
    final data = _toJsonEcoded(encoded, encoding: encoding);

    final version = data['version'];
    if (version != 3) {
      throw ArgumentException("Library only supports version 3");
    }

    final params = data['crypto'] ?? data['Crypto'];

    final String kdf = params['kdf'];
    _Derivator derivator;

    switch (kdf) {
      case 'pbkdf2':
        final derParams = params['kdfparams'] as Map<String, dynamic>;

        if (derParams['prf'] != 'hmac-sha256') {
          throw ArgumentException('Invalid prf only support hmac-sha256');
        }

        derivator = _PBDKDF2Derivator(
          derParams['c'] as int,
          BytesUtils.fromHexString(derParams['salt']),
          derParams['dklen'] as int,
        );

        break;
      case 'scrypt':
        final derParams = params['kdfparams'] as Map<String, dynamic>;
        derivator = _Scrypt(
          derParams['dklen'] as int,
          derParams['n'] as int,
          derParams['r'] as int,
          derParams['p'] as int,
          BytesUtils.fromHexString(derParams['salt']),
        );
        break;
      default:
        throw ArgumentException(
          '$kdf which is not supported.',
        );
    }

    final encodedPassword = List<int>.from(StringUtils.encode(password));
    final derivedKey = derivator.deriveKey(encodedPassword);
    final aesKey = List<int>.from(derivedKey.sublist(0, 16));
    final List<int> macBytes = derivedKey.sublist(16, 32);
    final encryptedPrivateKey = BytesUtils.fromHexString(params['ciphertext']);
    final derivedMac = _mac(macBytes, encryptedPrivateKey);
    if (derivedMac != params['mac']) {
      throw ArgumentException('wrong password or the file is corrupted');
    }

    if (params['cipher'] != 'aes-128-ctr') {
      throw ArgumentException("only cipher aes-128-ctr is supported.");
    }
    final iv = BytesUtils.fromHexString(params['cipherparams']['iv']);
    final encryptText = List<int>.from(encryptedPrivateKey);
    final CTR ctr = CTR(AES(aesKey), iv);
    final List<int> privateKey = List<int>.filled(encryptText.length, 0);
    ctr.streamXOR(encryptText, privateKey);
    ctr.clean();
    final id = UUID.toBuffer(data['id'] as String);
    return SecretWallet._(privateKey, derivator, encodedPassword, iv, id);
  }

  static SecretWallet _decodeCbor(String encoded, String password) {
    try {
      final cborTag = CborObject.fromCborHex(encoded);
      if (cborTag is! CborTagValue ||
          cborTag.value is! CborListValue ||
          cborTag.value.value.length != 3) {
        throw ArgumentException("Invalid secret wallet cbor bytes");
      }
      if (!bytesEqual(cborTag.tags, _SecretStorageConst.tag)) {
        throw ArgumentException("invalid secret wallet cbor tag");
      }
      final cbor = cborTag.value as CborListValue;
      final int version = cbor.value[2].value;
      if (version != _SecretStorageConst.version) {
        throw ArgumentException(
            "Library only supports version ${_SecretStorageConst.version}");
      }

      final List<int> uuid = cbor.value[1].value;
      final params = cbor.value[0] as CborListValue;
      final String cipher = params.value[0].value;
      if (cipher != 'aes-128-ctr') {
        throw ArgumentException("only cipher aes-128-ctr is supported.");
      }
      final List<int> iv = params.value[1].value;
      final derivator = _Derivator.fromCbor(params.value[3]);
      final List<int> ciphertext = params.value[2].value;
      final String mac = params.value[4].value;
      final encodedPassword = List<int>.from(StringUtils.encode(password));
      final derivedKey = derivator.deriveKey(encodedPassword);
      final List<int> macBytes =
          List<int>.unmodifiable(derivedKey.sublist(16, 32));
      final aesKey = List<int>.from(derivedKey.sublist(0, 16));
      final derivedMac = _mac(macBytes, ciphertext);
      if (derivedMac != mac) {
        throw ArgumentException('wrong password or the file is corrupted');
      }
      final CTR ctr = CTR(AES(aesKey), iv);
      final List<int> privateKey = List<int>.filled(ciphertext.length, 0);
      ctr.streamXOR(ciphertext, privateKey);
      ctr.clean();
      return SecretWallet._(privateKey, derivator, encodedPassword, iv, uuid);
    } on ArgumentException {
      rethrow;
    } catch (e) {
      throw ArgumentException('invalid secret wallet cbor bytes');
    }
  }

  final List<int> data;

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
    // print("cipher ${BytesUtils.toHexString(ciphertextBytes)}");
    if (encoding == SecretWalletEncoding.cbor) {
      return _toCbor(ciphertextBytes);
    }

    // Prepare the JSON representation of the encrypted data.
    final Map<String, dynamic> toJson = {
      'crypto': {
        'cipher': 'aes-128-ctr',
        'cipherparams': {'iv': BytesUtils.toHexString(_iv)},
        'ciphertext': BytesUtils.toHexString(ciphertextBytes.item1),
        'kdf': _derivator.name,
        'kdfparams': _derivator.encode(),
        'mac': _mac(ciphertextBytes.item2, ciphertextBytes.item1),
      },
      'id': uuid,
      'version': 3,
    };

    // Convert the JSON to a string.
    final toString = StringUtils.fromJson(toJson);

    // Based on the specified encoding format, return the encrypted data as a string.
    if (encoding == SecretWalletEncoding.json) {
      return toString;
    }
    return StringUtils.decode(
        StringUtils.encode(toString), StringEncoding.base64);
  }

  String _toCbor(Tuple<List<int>, List<int>> ciphertextBytes) {
    return CborTagValue(
            CborListValue.dynamicLength([
              CborListValue.fixedLength([
                CborStringValue('aes-128-ctr'),
                CborBytesValue(_iv),
                CborBytesValue(ciphertextBytes.item1),
                _derivator.cborEncode(),
                CborStringValue(
                    _mac(ciphertextBytes.item2, ciphertextBytes.item1)),
              ]),
              CborBytesValue(_id),
              CborIntValue(3),
            ]),
            _SecretStorageConst.tag)
        .toCborHex();
  }

  /// Generates a Message Authentication Code (MAC) for the provided derived key and ciphertext.
  ///
  /// - `dk`: The derived key.
  /// - `ciphertext`: The encrypted ciphertext.
  ///
  /// Returns the MAC as a hexadecimal string.
  static String _mac(List<int> dk, List<int> ciphertext) {
    // Concatenate the derived key and ciphertext to form the input for the MAC calculation.
    final mac = <int>[...dk, ...ciphertext];

    // Hash the concatenated data using Keccak.
    return BytesUtils.toHexString(Keccack.hash(List<int>.from(mac)));
  }

  /// Encrypts the wallet's sensitive credentials using AES-128-CTR encryption.
  ///
  /// Returns the encrypted ciphertext as a list of bytes.
  Tuple<List<int>, List<int>> _encryptPassword() {
    // Derive the encryption key from the password.
    final derived = List<int>.unmodifiable(_derivator.deriveKey(_password));
    final macBytes = List<int>.unmodifiable(derived.sublist(16, 32));
    final aesKey = List<int>.from(derived.sublist(0, 16));
    // final plainText = List<int>.from(StringUtils.toBytes());
    final CTR ctr = CTR(AES(aesKey), _iv);
    final encryptOut = List<int>.filled(data.length, 0);
    ctr.streamXOR(data, encryptOut);
    ctr.clean();

    return Tuple(encryptOut, macBytes);
  }
}
