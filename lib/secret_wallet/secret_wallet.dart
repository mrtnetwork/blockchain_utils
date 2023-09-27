import 'dart:convert';
import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto.dart';
import 'package:blockchain_utils/formating/bytes_num_formating.dart';
import 'package:blockchain_utils/uuid/uuid.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart' as pbkdf2;
import 'package:pointycastle/key_derivators/scrypt.dart' as scrypt;

enum SecretWalletEncoding { base64, json }

/// Abstract class for key derivators.
abstract class _KeyDerivator {
  Uint8List deriveKey(Uint8List password);

  String get name;
  Map<String, dynamic> encode();
}

/// Implementation of PBKDF2 key derivator.
class _PBDKDF2KeyDerivator extends _KeyDerivator {
  _PBDKDF2KeyDerivator(this.iterations, this.salt, this.dklen);
  final int iterations;
  final Uint8List salt;
  final int dklen;

  static final Mac mac = HMac(SHA256Digest(), 64);

  @override
  Uint8List deriveKey(Uint8List password) {
    final impl = pbkdf2.PBKDF2KeyDerivator(mac)
      ..init(Pbkdf2Parameters(salt, iterations, dklen));

    return impl.process(password);
  }

  @override
  Map<String, dynamic> encode() {
    return {
      'c': iterations,
      'dklen': dklen,
      'prf': 'hmac-sha256',
      'salt': bytesToHex(salt)
    };
  }

  @override
  final String name = 'pbkdf2';
}

/// Implementation of Scrypt key derivator.
class _ScryptKeyDerivator extends _KeyDerivator {
  _ScryptKeyDerivator(this.dklen, this.n, this.r, this.p, this.salt);
  final int dklen;
  final int n;
  final int r;
  final int p;
  final Uint8List salt;

  @override
  Uint8List deriveKey(Uint8List password) {
    final impl = scrypt.Scrypt()..init(ScryptParameters(n, r, p, dklen, salt));

    return impl.process(password);
  }

  @override
  Map<String, dynamic> encode() {
    return {
      'dklen': dklen,
      'n': n,
      'r': r,
      'p': p,
      'salt': bytesToHex(salt),
    };
  }

  @override
  final String name = 'scrypt';
}

/// Represents a wallet file. Wallets are used to securely store credentials
/// like a private key belonging to an Ethereum address. The private key in a
/// wallet is encrypted with a secret password that needs to be known in order
/// to obtain the private key.
class SecretWallet {
  const SecretWallet._(
    this.credentials,
    this._derivator,
    this._password,
    this._iv,
    this._id,
  );

  /// Creates a new wallet wrapping the specified [credentials] by encrypting
  /// the private key with the [password]
  /// You can configure the parameter N of the scrypt algorithm if you need to.
  /// The default value for [scryptN] is 8192. Be aware that this N must be a
  /// power of two.
  ///
  /// using a separate thread for encode or decode secret wallet.
  factory SecretWallet.encode(
    String credentials,
    String password, {
    int scryptN = 8192,
    int p = 1,
  }) {
    final passwordBytes = Uint8List.fromList(utf8.encode(password));

    /// Generate a random salt for key derivation.
    final salt = generateRandom(size: 32);

    /// Create a Scrypt key derivator with specified parameters.
    final derivator = _ScryptKeyDerivator(32, scryptN, 8, p, salt);

    /// Generate a random UUID and convert it to a buffer.
    final uuid = UUID.toBuffer(UUID.generateUUIDv4());

    /// Generate a random initialization vector (IV) for encryption.
    final iv = generateRandom(size: 128 ~/ 8);

    /// Create a SecretWallet instance with the provided parameters.
    return SecretWallet._(credentials, derivator, passwordBytes, iv, uuid);
  }

  static Map<String, dynamic> _toJsonEcoded(String encoded) {
    try {
      final bs64 = base64Decode(encoded);
      return json.decode(utf8.decode(bs64));
    } catch (e) {
      return json.decode(encoded);
    }
  }

  /// using a separate thread for encode or decode secret wallet.
  factory SecretWallet.decode(String encoded, String password) {
    /*
      In order to read the wallet and obtain the secret key stored in it, we
      need to do the following:
      1: Key Derivation: Based on the key derivator specified (either pbdkdf2 or
         scryt), we need to use the password to obtain the aes key used to
         decrypt the private key.
      2: Using the obtained aes key and the iv parameter, decrypt the private
         key stored in the wallet.
    */

    final data = _toJsonEcoded(encoded);

    /// Ensure version is 3, only version that we support at the moment
    final version = data['version'];
    if (version != 3) {
      throw ArgumentError.value(
        version,
        'version',
        'Library only supports '
            'version 3 of wallet files at the moment. However, the following value'
            ' has been given:',
      );
    }

    final crypto = data['crypto'] ?? data['Crypto'];

    final kdf = crypto['kdf'] as String;
    _KeyDerivator derivator;

    switch (kdf) {
      case 'pbkdf2':
        final derParams = crypto['kdfparams'] as Map<String, dynamic>;

        if (derParams['prf'] != 'hmac-sha256') {
          throw ArgumentError(
            'Invalid prf supplied with the pdf: was ${derParams["prf"]}, expected hmac-sha256',
          );
        }

        derivator = _PBDKDF2KeyDerivator(
          derParams['c'] as int,
          Uint8List.fromList(hexToBytes(derParams['salt'] as String)),
          derParams['dklen'] as int,
        );

        break;
      case 'scrypt':
        final derParams = crypto['kdfparams'] as Map<String, dynamic>;
        derivator = _ScryptKeyDerivator(
          derParams['dklen'] as int,
          derParams['n'] as int,
          derParams['r'] as int,
          derParams['p'] as int,
          Uint8List.fromList(hexToBytes(derParams['salt'] as String)),
        );
        break;
      default:
        throw ArgumentError(
          'Wallet file uses $kdf as key derivation function, which is not supported.',
        );
    }

    /// Now that we have the derivator, let's obtain the aes key:
    final encodedPassword = Uint8List.fromList(utf8.encode(password));
    final derivedKey = derivator.deriveKey(encodedPassword);
    final aesKey = Uint8List.fromList(derivedKey.sublist(0, 16));

    final encryptedPrivateKey = hexToBytes(crypto['ciphertext'] as String);

    //Validate the derived key with the mac provided
    final derivedMac = _generateMac(derivedKey, encryptedPrivateKey);
    if (derivedMac != crypto['mac']) {
      throw ArgumentError(
        'Could not unlock wallet file. You either supplied the wrong password or the file is corrupted',
      );
    }

    /// We only support this mode at the moment
    if (crypto['cipher'] != 'aes-128-ctr') {
      throw ArgumentError(
        'Wallet file uses ${crypto["cipher"]} as cipher, but only aes-128-ctr is supported.',
      );
    }
    final iv =
        Uint8List.fromList(hexToBytes(crypto['cipherparams']['iv'] as String));

    final aes = _initCipher(false, aesKey, iv);
    final privateKey = aes.process(Uint8List.fromList(encryptedPrivateKey));
    final id = UUID.toBuffer(data['id'] as String);
    return SecretWallet._(
        utf8.decode(privateKey), derivator, encodedPassword, iv, id);
  }

  /// The credentials stored in this wallet file
  final String credentials;

  /// The key derivator used to obtain the aes decryption key from the password
  final _KeyDerivator _derivator;

  final Uint8List _password;
  final Uint8List _iv;

  final Uint8List _id;

  /// Gets the random uuid assigned to this wallet file
  String get uuid => UUID.fromBuffer(_id);

  /// Encrypts the private key using the secret specified earlier and returns
  /// a json representation of its data as a v3-wallet file.
  String encrypt({SecretWalletEncoding encoding = SecretWalletEncoding.json}) {
    final ciphertextBytes = _encryptPrivateKey();

    final map = {
      'crypto': {
        'cipher': 'aes-128-ctr',
        'cipherparams': {'iv': bytesToHex(_iv)},
        'ciphertext': bytesToHex(ciphertextBytes),
        'kdf': _derivator.name,
        'kdfparams': _derivator.encode(),
        'mac': _generateMac(_derivator.deriveKey(_password), ciphertextBytes),
      },
      'id': uuid,
      'version': 3,
    };
    final toString = json.encode(map);
    if (encoding == SecretWalletEncoding.json) {
      return toString;
    }
    return base64Encode(utf8.encode(toString));
  }

  /// Generates a message authentication code (MAC) for the encrypted data.
  static String _generateMac(List<int> dk, List<int> ciphertext) {
    /// Create a MAC body by concatenating the second half of the derived key (dk)
    /// with the ciphertext.
    final macBody = <int>[...dk.sublist(16, 32), ...ciphertext];

    /// Calculate the MAC using the keccak256 hash function.
    return bytesToHex(keccak256(Uint8List.fromList(macBody)));
  }

  /// Initializes a counter (CTR) stream cipher with the given key and IV.
  static CTRStreamCipher _initCipher(
    bool forEncryption,
    Uint8List key,
    Uint8List iv,
  ) {
    return CTRStreamCipher(AESEngine())
      ..init(forEncryption, ParametersWithIV(KeyParameter(key), iv));
  }

  /// Encrypts the private key.
  List<int> _encryptPrivateKey() {
    /// Derive a key using the key derivator and the provided password.
    final derived = _derivator.deriveKey(_password);

    /// Extract the first 16 bytes of the derived key as the AES encryption key.
    final aesKey = Uint8List.view(derived.buffer, 0, 16);

    /// Initialize an AES cipher in encryption mode with the derived key and IV.
    final aes = _initCipher(true, aesKey, _iv);

    /// Encrypt the credentials using AES encryption.
    return aes.process(Uint8List.fromList(utf8.encode(credentials)));
  }
}
