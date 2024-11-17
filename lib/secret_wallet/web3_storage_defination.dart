import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/uuid/uuid.dart';

import 'exception.dart';

class _SecretStorageConst {
  static const List<int> scryptTag = [180];
  static const List<int> pbdkdf2Tag = [181];
  static const List<int> tag = [200];
  static const int version = 3;
  static const int ivLength = 128 ~/ 8;
  static const saltLength = 32;
}

enum KDFMode { scrypt, pbkdf2 }

/// Enum representing different encoding formats for secret wallets.
enum SecretWalletEncoding {
  base64, // Base64 encoding
  json, // JSON encoding
  cbor, // cbor encoding
}

/// Abstract class representing a key derivation strategy.
abstract class KDFParam {
  const KDFParam();
  List<int> deriveKey(List<int> password);
  Map<String, dynamic> encode();
  CborTagValue cborEncode();
  KDFMode get type;

  factory KDFParam.fromCbor(CborObject cbor) {
    if (cbor is! CborTagValue || cbor.value is! CborListValue) {
      throw const Web3SecretStorageDefinationV3Exception(
          "invalid secret wallet cbor bytes");
    }
    if (BytesUtils.bytesEqual(cbor.tags, _SecretStorageConst.pbdkdf2Tag)) {
      final toObj = KDF2.fromCbor(cbor.value);
      return toObj;
    } else if (BytesUtils.bytesEqual(
        cbor.tags, _SecretStorageConst.scryptTag)) {
      return KDFScrypt.fromCbor(cbor.value);
    } else {
      throw const Web3SecretStorageDefinationV3Exception(
          "invalid secret wallet cbor bytes");
    }
  }

  factory KDFParam.fromJson(Map<String, dynamic> json) {
    final kdf = json["kdf"];
    final params = json["kdfparams"];
    switch (kdf) {
      case "scrypt":
        return KDFScrypt.fromJson(params);
      case "pbkdf2":
        return KDF2.fromJson(params);
      default:
        throw Web3SecretStorageDefinationV3Exception("Invalid kdf.", details: {
          "excepted": ["scrypt", "pbkdf2"].join(", "),
          "kdf": kdf
        });
    }
  }
}

/// A class implementing key derivation using the PBKDF2 algorithm.
class KDF2 extends KDFParam {
  KDF2._(this.iterations, List<int> salt, this.dklen)
      : salt = BytesUtils.toBytes(salt, unmodifiable: true);
  factory KDF2(
      {required int iterations, required List<int> salt, required int dklen}) {
    if (salt.length != _SecretStorageConst.saltLength) {
      throw Web3SecretStorageDefinationV3Exception("Invalid salt length.",
          details: {
            "excepted": _SecretStorageConst.saltLength,
            "length": salt.length
          });
    }
    return KDF2._(iterations, salt, dklen);
  }
  factory KDF2.fromJson(Map<String, dynamic> json) {
    if (json["prf"] != "hmac-sha256") {
      throw Web3SecretStorageDefinationV3Exception("Invalid prf.",
          details: {"excepted": "hmac-sha256", "prf": json["prf"]});
    }
    return KDF2(
      iterations: json["c"],
      salt: BytesUtils.fromHexString(json["salt"]),
      dklen: json["dklen"],
    );
  }

  final int iterations;
  final List<int> salt;
  final int dklen;

  factory KDF2.fromCbor(CborListValue v) {
    final int c = v.value[0].value;
    final int dklen = v.value[1].value;
    final String prf = v.value[2].value;
    if (prf != "hmac-sha256") {
      throw Web3SecretStorageDefinationV3Exception("Invalid prf.",
          details: {"excepted": "hmac-sha256", "prf": prf});
    }
    final List<int> salt = v.value[3].value;
    return KDF2(iterations: c, salt: salt, dklen: dklen);
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

  @override
  KDFMode get type => KDFMode.pbkdf2;
}

/// A class implementing key derivation using the Scrypt algorithm.
class KDFScrypt extends KDFParam {
  KDFScrypt._(this.dklen, this.n, this.r, this.p, List<int> salt)
      : salt = BytesUtils.toBytes(salt, unmodifiable: true);
  factory KDFScrypt(
      {required int dklen,
      required int n,
      required int r,
      required int p,
      required List<int> salt}) {
    if (salt.length != _SecretStorageConst.saltLength) {
      throw Web3SecretStorageDefinationV3Exception("Invalid salt length.",
          details: {
            "excepted": _SecretStorageConst.saltLength,
            "length": salt.length
          });
    }
    return KDFScrypt._(dklen, n, r, p, salt);
  }

  factory KDFScrypt.fromJson(Map<String, dynamic> json) {
    return KDFScrypt(
      dklen: json["dklen"],
      n: json["n"],
      r: json["r"],
      p: json["p"],
      salt: BytesUtils.fromHexString(json["salt"]),
    );
  }

  factory KDFScrypt.fromCbor(CborListValue v) {
    final int dklen = v.value[0].value;
    final int n = v.value[1].value;
    final int r = v.value[2].value;
    final int p = v.value[3].value;
    final List<int> salt = v.value[4].value;
    return KDFScrypt(dklen: dklen, n: n, r: r, p: p, salt: salt);
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
      "dklen": dklen,
      "n": n,
      "r": r,
      "p": p,
      "salt": BytesUtils.toHexString(salt),
    };
  }

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
  }

  @override
  KDFMode get type => KDFMode.scrypt; // Name of the Scrypt strategy.
}

class CryptoParam {
  const CryptoParam._({required this.kdf, required this.iv});
  factory CryptoParam({required KDFParam kdf, required List<int> iv}) {
    if (iv.length != _SecretStorageConst.ivLength) {
      throw Web3SecretStorageDefinationV3Exception("Invalid iv length.",
          details: {
            "excepted": _SecretStorageConst.ivLength,
            "length": iv.length
          });
    }
    return CryptoParam._(kdf: kdf, iv: iv);
  }
  final KDFParam kdf;
  final List<int> iv;
  factory CryptoParam.fromJson(Map<String, dynamic> json) {
    return CryptoParam(
        kdf: KDFParam.fromJson(json),
        iv: BytesUtils.fromHexString(json["cipherparams"]["iv"]));
  }
  static String _mac(List<int> dk, List<int> ciphertext) {
    // Concatenate the derived key and ciphertext to form the input for the MAC calculation.
    final mac = <int>[...dk, ...ciphertext];

    // Hash the concatenated data using Keccak.
    return BytesUtils.toHexString(Keccack.hash(List<int>.from(mac)));
  }

  Map<String, dynamic> encode(List<int> password, List<int> data) {
    final derived = List<int>.unmodifiable(kdf.deriveKey(password));
    final macBytes = List<int>.unmodifiable(derived.sublist(16, 32));
    final aesKey = List<int>.from(derived.sublist(0, 16));
    final encryptOut = QuickCrypto.processCtr(key: aesKey, iv: iv, data: data);
    return {
      "cipher": "aes-128-ctr",
      "cipherparams": {'iv': BytesUtils.toHexString(iv)},
      "ciphertext": BytesUtils.toHexString(encryptOut),
      "kdf": kdf.type.name,
      "kdfparams": kdf.encode(),
      "mac": _mac(macBytes, encryptOut),
    };
  }

  String encodeCbor(List<int> password, List<int> data, String uuid) {
    final derived = List<int>.unmodifiable(kdf.deriveKey(password));
    final macBytes = List<int>.unmodifiable(derived.sublist(16, 32));
    final aesKey = List<int>.from(derived.sublist(0, 16));
    final encryptOut = QuickCrypto.processCtr(key: aesKey, iv: iv, data: data);
    return CborTagValue(
            CborListValue.dynamicLength([
              CborListValue.fixedLength([
                CborStringValue("aes-128-ctr"),
                CborBytesValue(iv),
                CborBytesValue(encryptOut),
                kdf.cborEncode(),
                CborStringValue(_mac(macBytes, encryptOut)),
              ]),
              CborStringValue(uuid),
              const CborIntValue(3),
            ]),
            _SecretStorageConst.tag)
        .toCborHex();
  }
}

///
/// The `Web3SecretStorageDefinationV3` class represents a secret wallet that stores sensitive credentials
/// using a specified key derivation strategy.
class Web3SecretStorageDefinationV3 {
  final List<int> data;
  final List<int> _password;
  final String uuid;
  final CryptoParam _crypto;
  Web3SecretStorageDefinationV3._(
      this._crypto, List<int> _password, this.uuid, List<int> data)
      : _password = BytesUtils.toBytes(_password, unmodifiable: true),
        data = BytesUtils.toBytes(data, unmodifiable: true);
  factory Web3SecretStorageDefinationV3(
      {required CryptoParam param,
      required List<int> password,
      required List<int> data,
      required String id}) {
    return Web3SecretStorageDefinationV3(
        param: param, password: password, data: data, id: id);
  }

  /// Factory method to create a `Web3SecretStorageDefinationV3` with encoded credentials.
  ///
  /// - `credentials`: The encoded credentials to be stored in the wallet.
  /// - `password`: The password used to derive the encryption key.
  /// - `scryptN`: Parameter 'n' for the Scrypt key derivation function (default is 8192).
  /// - `p`: Parameter 'p' for the Scrypt key derivation function (default is 1).
  ///
  /// Returns a `Web3SecretStorageDefinationV3` instance with the encoded credentials.
  factory Web3SecretStorageDefinationV3.encode(
    List<int> data,
    String password, {
    int scryptN = 8192,
    int p = 1,
  }) {
    final passwordBytes = StringUtils.encode(password);
    final salt = QuickCrypto.generateRandom(_SecretStorageConst.saltLength);
    final derivator = KDFScrypt(dklen: 32, n: scryptN, r: 8, p: p, salt: salt);
    final uuid = UUID.generateUUIDv4();
    final iv = QuickCrypto.generateRandom(_SecretStorageConst.ivLength);
    final CryptoParam crypto = CryptoParam(kdf: derivator, iv: iv);
    return Web3SecretStorageDefinationV3._(crypto, passwordBytes, uuid, data);
  }

  static Map<String, dynamic> _toJsonEcoded(String encoded,
      {SecretWalletEncoding encoding = SecretWalletEncoding.json}) {
    try {
      if (encoding == SecretWalletEncoding.json) {
        return StringUtils.toJson(encoded);
      }
      return StringUtils.toJson(StringUtils.decode(
          StringUtils.encode(encoded, type: StringEncoding.base64)));
    } catch (e) {
      throw const Web3SecretStorageDefinationV3Exception("invalid encoding");
    }
  }

  /// Factory method to decode and create a `Web3SecretStorageDefinationV3` from an encoded string and a password.
  ///
  /// - `encoded`: The encoded string containing wallet data.
  /// - `password`: The password used to derive the encryption key.
  ///
  /// Returns a `Web3SecretStorageDefinationV3` instance decoded from the input data, or throws an error
  /// if decoding or password validation fails.
  factory Web3SecretStorageDefinationV3.decode(String encoded, String password,
      {SecretWalletEncoding encoding = SecretWalletEncoding.json}) {
    if (encoding == SecretWalletEncoding.cbor) {
      return _decodeCbor(encoded, password);
    }
    final json = _toJsonEcoded(encoded, encoding: encoding);

    if (json['version'] != 3) {
      throw const Web3SecretStorageDefinationV3Exception(
          "Library only supports version 3");
    }
    final crypto = json['crypto'] ?? json['Crypto'];
    final KDFParam derivator = KDFParam.fromJson(crypto);

    final encodedPassword = List<int>.from(StringUtils.encode(password));
    final derivedKey = derivator.deriveKey(encodedPassword);
    final aesKey = List<int>.from(derivedKey.sublist(0, 16));
    final List<int> macBytes = derivedKey.sublist(16, 32);
    final encryptedPrivateKey = BytesUtils.fromHexString(crypto["ciphertext"]);
    final derivedMac = CryptoParam._mac(macBytes, encryptedPrivateKey);
    if (derivedMac != crypto["mac"]) {
      throw const Web3SecretStorageDefinationV3Exception(
          "Wrong password or the file is corrupted");
    }
    if (crypto["cipher"] != "aes-128-ctr") {
      throw Web3SecretStorageDefinationV3Exception("Invalid Cypher.",
          details: {"excepted": "aes-128-ctr", "cipher": crypto["cipher"]});
    }
    final iv = BytesUtils.fromHexString(crypto['cipherparams']['iv']);
    final encryptText = List<int>.from(encryptedPrivateKey);
    final List<int> data =
        QuickCrypto.processCtr(key: aesKey, iv: iv, data: encryptText);
    return Web3SecretStorageDefinationV3._(
        CryptoParam.fromJson(json['crypto'] ?? json['Crypto']),
        encodedPassword,
        json["id"],
        data);
  }

  static Web3SecretStorageDefinationV3 _decodeCbor(
      String encoded, String password) {
    try {
      final cborTag = CborObject.fromCborHex(encoded);
      if (cborTag is! CborTagValue ||
          cborTag.value is! CborListValue ||
          cborTag.value.value.length != 3) {
        throw const Web3SecretStorageDefinationV3Exception(
            "Invalid secret wallet cbor bytes");
      }
      if (!BytesUtils.bytesEqual(cborTag.tags, _SecretStorageConst.tag)) {
        throw const Web3SecretStorageDefinationV3Exception(
            "invalid secret wallet cbor tag");
      }
      final cbor = cborTag.value as CborListValue;
      final int version = cbor.value[2].value;
      if (version != _SecretStorageConst.version) {
        throw const Web3SecretStorageDefinationV3Exception(
            "Library only supports version ${_SecretStorageConst.version}");
      }
      String uuid;
      final uuidObj = cbor.value[1];
      if (uuidObj is CborStringValue) {
        uuid = uuidObj.value;
      } else {
        uuid = UUID.fromBuffer(uuidObj.value);
      }
      final params = cbor.value[0] as CborListValue;
      final String cipher = params.value[0].value;
      if (cipher != "aes-128-ctr") {
        throw Web3SecretStorageDefinationV3Exception("Invalid cypher type.",
            details: {"excepted": "aes-128-ctr", "cypher": cipher});
      }
      final List<int> iv = params.value[1].value;
      final kdf = KDFParam.fromCbor(params.value[3]);
      final List<int> ciphertext = params.value[2].value;
      final String mac = params.value[4].value;
      final encodedPassword = List<int>.from(StringUtils.encode(password));
      final derivedKey = kdf.deriveKey(encodedPassword);
      final List<int> macBytes =
          List<int>.unmodifiable(derivedKey.sublist(16, 32));
      final aesKey = List<int>.from(derivedKey.sublist(0, 16));
      final derivedMac = CryptoParam._mac(macBytes, ciphertext);
      if (derivedMac != mac) {
        throw const Web3SecretStorageDefinationV3Exception(
            "wrong password or the file is corrupted");
      }
      final List<int> data =
          QuickCrypto.processCtr(key: aesKey, iv: iv, data: ciphertext);
      return Web3SecretStorageDefinationV3._(
          CryptoParam(kdf: kdf, iv: iv), encodedPassword, uuid, data);
    } on Web3SecretStorageDefinationV3Exception {
      rethrow;
    } catch (e) {
      throw const Web3SecretStorageDefinationV3Exception(
          "invalid secret wallet cbor bytes");
    }
  }

  /// Encrypts the sensitive wallet data using the specified encoding format and returns
  /// the encrypted representation.
  ///
  /// - `encoding`: The encoding format to use for the encrypted output (default is JSON).
  ///
  /// Returns the encrypted wallet data as a string in the chosen encoding format.
  String encrypt({SecretWalletEncoding encoding = SecretWalletEncoding.json}) {
    if (encoding == SecretWalletEncoding.cbor) {
      return _crypto.encodeCbor(_password, data, uuid);
    }

    // Prepare the JSON representation of the encrypted data.
    final Map<String, dynamic> toJson = {
      "crypto": _crypto.encode(_password, data),
      "id": uuid,
      "version": 3
    };

    // Convert the JSON to a string.
    final toString = StringUtils.fromJson(toJson);

    // Based on the specified encoding format, return the encrypted data as a string.
    if (encoding == SecretWalletEncoding.json) {
      return toString;
    }
    return StringUtils.decode(StringUtils.encode(toString),
        type: StringEncoding.base64);
  }
}
