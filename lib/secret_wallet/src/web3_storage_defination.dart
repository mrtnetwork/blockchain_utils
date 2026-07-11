import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'package:blockchain_utils/uuid/uuid.dart';

import 'exception.dart';

class _SecretStorageConst {
  static const List<int> scryptTag = [180];
  static const List<int> pbdkdf2Tag = [181];
  static const List<int> tag = [200];
  static const int version = 3;
  static const int ivLength = 128 ~/ 8;
  static const saltLength = 32;
  static const String prfAlgorithm = "hmac-sha256";
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
      throw ArgumentException.invalidOperationArguments(
        "KDFParam",
        name: "cbor",
        reason: "Invalid secret wallet cbor encoding.",
      );
    }
    if (BytesUtils.bytesEqual(cbor.tags, _SecretStorageConst.pbdkdf2Tag)) {
      final toObj = KDF2.fromCbor(cbor.value.cast());
      return toObj;
    } else if (BytesUtils.bytesEqual(
      cbor.tags,
      _SecretStorageConst.scryptTag,
    )) {
      return KDFScrypt.fromCbor(cbor.value.cast());
    } else {
      throw ArgumentException.invalidOperationArguments(
        "KDFParam",
        name: "cbor",
        reason: "Invalid secret wallet cbor encoding.",
      );
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
        throw Web3SecretStorageDefinationV3Exception.unsuportedBackupContent;
    }
  }
}

/// A class implementing key derivation using the PBKDF2 algorithm.
class KDF2 extends KDFParam {
  KDF2._(this.iterations, List<int> salt, this.dklen)
    : salt = salt.asImmutableBytes;
  factory KDF2({
    required int iterations,
    required List<int> salt,
    required int dklen,
  }) {
    if (salt.length != _SecretStorageConst.saltLength) {
      throw ArgumentException.invalidOperationArguments(
        "KDF2",
        name: "salt",
        reason: "Invalid salt bytes length.",
      );
    }
    return KDF2._(iterations, salt, dklen);
  }
  factory KDF2.fromJson(Map<String, dynamic> json) {
    final String? prf = json.valueAs("prf");
    if (prf != _SecretStorageConst.prfAlgorithm) {
      throw Web3SecretStorageDefinationV3Exception.unsuportedBackupContent;
    }
    return KDF2(
      iterations: json.valueAs("c"),
      salt: json.valueAsBytes("salt"),
      dklen: json.valueAs("dklen"),
    );
  }

  final int iterations;
  final List<int> salt;
  final int dklen;

  factory KDF2.fromCbor(CborListValue v) {
    final String? prf = v.rawValueAt(2);
    if (prf != _SecretStorageConst.prfAlgorithm) {
      throw Web3SecretStorageDefinationV3Exception.unsuportedBackupContent;
    }
    final int c = v.rawValueAt(0);
    final int dklen = v.rawValueAt(1);
    final List<int> salt = v.rawValueAt(3);
    return KDF2(iterations: c, salt: salt, dklen: dklen);
  }

  @override
  List<int> deriveKey(List<int> password) {
    return PBKDF2.deriveKey(
      mac: () => HMAC(() => SHA256(), password),
      salt: salt,
      iterations: iterations,
      length: dklen,
    );
  }

  @override
  Map<String, dynamic> encode() {
    return {
      'c': iterations,
      'dklen': dklen,
      'prf': _SecretStorageConst.prfAlgorithm,
      'salt': BytesUtils.toHexString(salt),
    };
  }

  @override
  CborTagValue cborEncode() {
    return CborTagValue(
      CborListValue<CborObject>.definite([
        CborIntValue(iterations),
        CborIntValue(dklen),
        CborStringValue(_SecretStorageConst.prfAlgorithm),
        CborBytesValue(salt),
      ]),
      _SecretStorageConst.pbdkdf2Tag,
    );
  }

  @override
  KDFMode get type => KDFMode.pbkdf2;
}

/// A class implementing key derivation using the Scrypt algorithm.
class KDFScrypt extends KDFParam {
  final int dklen;
  final int n;
  final int r;
  final int p;
  final List<int> salt;
  KDFScrypt._(this.dklen, this.n, this.r, this.p, List<int> salt)
    : salt = salt.asImmutableBytes;
  factory KDFScrypt({
    required int dklen,
    required int n,
    required int r,
    required int p,
    required List<int> salt,
  }) {
    if (salt.length != _SecretStorageConst.saltLength) {
      throw ArgumentException.invalidOperationArguments(
        "KDFScrypt",
        name: "salt",
        reason: "Invalid salt bytes length.",
      );
    }
    return KDFScrypt._(dklen, n, r, p, salt);
  }

  factory KDFScrypt.fromJson(Map<String, dynamic> json) {
    return KDFScrypt(
      dklen: json.valueAs("dklen"),
      n: json.valueAs("n"),
      r: json.valueAs("r"),
      p: json.valueAs("p"),
      salt: json.valueAsBytes("salt"),
    );
  }

  factory KDFScrypt.fromCbor(CborListValue v) {
    final List<int> salt = v.rawValueAt(4);
    if (salt.length != _SecretStorageConst.saltLength) {
      throw ArgumentException.invalidOperationArguments(
        "KDFScrypt",
        name: "salt",
        reason: "Invalid salt bytes length.",
      );
    }
    final int dklen = v.rawValueAt(0);
    final int n = v.rawValueAt(1);
    final int r = v.rawValueAt(2);
    final int p = v.rawValueAt(3);

    return KDFScrypt(dklen: dklen, n: n, r: r, p: p, salt: salt);
  }

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
      CborListValue<CborObject>.definite([
        CborIntValue(dklen),
        CborIntValue(n),
        CborIntValue(r),
        CborIntValue(p),
        CborBytesValue(salt),
      ]),
      _SecretStorageConst.scryptTag,
    );
  }

  @override
  KDFMode get type => KDFMode.scrypt; // Name of the Scrypt strategy.
}

class CryptoParam {
  const CryptoParam._({required this.kdf, required this.iv});
  factory CryptoParam({required KDFParam kdf, required List<int> iv}) {
    if (iv.length != _SecretStorageConst.ivLength) {
      throw ArgumentException.invalidOperationArguments(
        "CryptoParam",
        name: "iv",
        reason: "Invalid iv bytes length.",
      );
    }
    return CryptoParam._(kdf: kdf, iv: iv);
  }
  final KDFParam kdf;
  final List<int> iv;
  factory CryptoParam.fromJson(Map<String, dynamic> json) {
    return CryptoParam(
      kdf: KDFParam.fromJson(json),
      iv: json
          .valueEnsureAsMap<String, dynamic>("cipherparams")
          .valueAsBytes("iv"),
    );
  }
  static String _mac(List<int> dk, List<int> ciphertext) {
    // Concatenate the derived key and ciphertext to form the input for the MAC calculation.
    final mac = <int>[...dk, ...ciphertext];

    // Hash the concatenated data using Keccak.
    return BytesUtils.toHexString(Keccack.hash(mac));
  }

  Map<String, dynamic> encode(List<int> password, List<int> data) {
    final derived = kdf.deriveKey(password);
    final macBytes = derived.sublist(16, 32);
    final aesKey = derived.sublist(0, 16);
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
    final derived = kdf.deriveKey(password);
    final macBytes = derived.sublist(16, 32);
    final aesKey = derived.sublist(0, 16);
    final encryptOut = QuickCrypto.processCtr(key: aesKey, iv: iv, data: data);
    return CborTagValue(
      CborListValue<CborObject>.inDefinite([
        CborListValue<CborObject>.definite([
          CborStringValue("aes-128-ctr"),
          CborBytesValue.unsafe(iv),
          CborBytesValue.unsafe(encryptOut),
          kdf.cborEncode(),
          CborStringValue(_mac(macBytes, encryptOut)),
        ]),
        CborStringValue(uuid),
        const CborIntValue(3),
      ]),
      _SecretStorageConst.tag,
    ).toCborHex();
  }
}

///
/// The `Web3SecretStorageDefinationV3` class represents a secret wallet that stores sensitive credentials
/// using a specified key derivation strategy.
class Web3SecretStorageDefinationV3 {
  final List<int> _data;
  final List<int> _password;
  final String uuid;
  final CryptoParam _crypto;
  Web3SecretStorageDefinationV3._(
    this._crypto,
    List<int> _password,
    this.uuid,
    List<int> data,
  ) : _password = _password.clone(),
      _data = data.clone();
  factory Web3SecretStorageDefinationV3({
    required CryptoParam param,
    required List<int> password,
    required List<int> data,
    required String id,
  }) {
    return Web3SecretStorageDefinationV3(
      param: param,
      password: password,
      data: data,
      id: id,
    );
  }

  /// Factory method to create a `Web3SecretStorageDefinationV3` with encoded credentials.
  ///
  /// - [data]: The encoded credentials to be stored in the wallet.
  /// - [password]: The password used to derive the encryption key.
  /// - [scryptN]: Parameter 'n' for the Scrypt key derivation function (default is 8192).
  /// - [p]: Parameter 'p' for the Scrypt key derivation function (default is 1).
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

  static Map<String, dynamic> _toJsonEcoded(
    String encoded, {
    SecretWalletEncoding encoding = SecretWalletEncoding.json,
  }) {
    try {
      if (encoding == SecretWalletEncoding.json) {
        return StringUtils.toJson(encoded);
      }
      return StringUtils.toJson(
        StringUtils.decode(
          StringUtils.encode(encoded, encoding: StringEncoding.base64),
        ),
      );
    } catch (_) {
      throw ArgumentException.invalidOperationArguments(
        "decode",
        name: "encoded",
        reason: "Invalid secret storage encoding.",
      );
    }
  }

  /// Factory method to decode and create a `Web3SecretStorageDefinationV3` from an encoded string and a password.
  ///
  /// - [encoded]: The encoded string containing wallet data.
  /// - [password]: The password used to derive the encryption key.
  ///
  factory Web3SecretStorageDefinationV3.decode(
    String encoded,
    String password, {
    SecretWalletEncoding encoding = SecretWalletEncoding.json,
  }) {
    if (encoding == SecretWalletEncoding.cbor) {
      return _decodeCbor(encoded, password);
    }
    final json = _toJsonEcoded(encoded, encoding: encoding);
    final version = json.valueAs("version");
    if (version != 3) {
      throw Web3SecretStorageDefinationV3Exception.unsuportedBackupContent;
    }
    final crypto = json['crypto'] ?? json['Crypto'];
    if (crypto["cipher"] != "aes-128-ctr") {
      throw Web3SecretStorageDefinationV3Exception.unsuportedBackupContent;
    }
    final KDFParam derivator = KDFParam.fromJson(crypto);

    final encodedPassword = StringUtils.encode(password);
    final derivedKey = derivator.deriveKey(encodedPassword);
    final aesKey = derivedKey.sublist(0, 16);
    final List<int> macBytes = derivedKey.sublist(16, 32);
    final encryptedPrivateKey = BytesUtils.fromHexString(crypto["ciphertext"]);
    final derivedMac = CryptoParam._mac(macBytes, encryptedPrivateKey);
    if (derivedMac != crypto["mac"]) {
      throw Web3SecretStorageDefinationV3Exception.wrongBackupPassword;
    }

    final iv = BytesUtils.fromHexString(crypto['cipherparams']['iv']);
    final encryptText = encryptedPrivateKey.clone();
    final List<int> data = QuickCrypto.processCtr(
      key: aesKey,
      iv: iv,
      data: encryptText,
    );
    return Web3SecretStorageDefinationV3._(
      CryptoParam.fromJson(crypto),
      encodedPassword,
      json.valueAs("id"),
      data,
    );
  }

  static Web3SecretStorageDefinationV3 _decodeCbor(
    String encoded,
    String password,
  ) {
    try {
      final cborTag = CborTagValue.decode(BytesUtils.fromHexString(encoded));
      if (cborTag.value is! CborListValue ||
          cborTag.asValue<CborListValue>().value.length != 3) {
        throw ArgumentException.invalidOperationArguments(
          "decode",
          name: "encoded",
          reason: "Invalid secret storage bytes.",
        );
      }
      if (!BytesUtils.bytesEqual(cborTag.tags, _SecretStorageConst.tag)) {
        throw ArgumentException.invalidOperationArguments(
          "decode",
          name: "encoded",
          reason: "Invalid secret storage bytes.",
        );
      }
      final cbor = cborTag.asValue<CborListValue>();
      final int version = cbor.rawValueAt(2);
      if (version != _SecretStorageConst.version) {
        throw Web3SecretStorageDefinationV3Exception.unsuportedBackupContent;
      }
      String uuid;
      if (cbor.isTypeAt<CborStringValue>(1)) {
        uuid = cbor.rawValueAt(1);
      } else {
        uuid = UUID.fromBuffer(cbor.rawValueAt<List<int>>(1));
      }
      final params = cbor.value[0] as CborListValue;
      final String cipher = params.rawValueAt(0);
      if (cipher != "aes-128-ctr") {
        throw Web3SecretStorageDefinationV3Exception.unsuportedBackupContent;
      }
      final List<int> iv = params.rawValueAt(1);
      final kdf = KDFParam.fromCbor(params.value[3]);
      final List<int> ciphertext = params.rawValueAt(2);
      final String mac = params.rawValueAt(4);
      final encodedPassword = StringUtils.encode(password);
      final derivedKey = kdf.deriveKey(encodedPassword);
      final List<int> macBytes = List<int>.unmodifiable(
        derivedKey.sublist(16, 32),
      );
      final aesKey = derivedKey.sublist(0, 16);
      final derivedMac = CryptoParam._mac(macBytes, ciphertext);
      if (derivedMac != mac) {
        throw Web3SecretStorageDefinationV3Exception.wrongBackupPassword;
      }
      final List<int> data = QuickCrypto.processCtr(
        key: aesKey,
        iv: iv,
        data: ciphertext,
      );
      return Web3SecretStorageDefinationV3._(
        CryptoParam(kdf: kdf, iv: iv),
        encodedPassword,
        uuid,
        data,
      );
    } on ArgumentException {
      rethrow;
    } on Web3SecretStorageDefinationV3Exception {
      rethrow;
    } catch (e) {
      throw ArgumentException.invalidOperationArguments(
        "decode",
        name: "encoded",
        reason: "Invalid secret storage bytes.",
      );
    }
  }

  /// Encrypts the sensitive wallet data using the specified encoding format and returns
  /// the encrypted representation.
  ///
  /// - `encoding`: The encoding format to use for the encrypted output (default is JSON).
  ///
  String encrypt({SecretWalletEncoding encoding = SecretWalletEncoding.json}) {
    if (encoding == SecretWalletEncoding.cbor) {
      return _crypto.encodeCbor(_password, _data, uuid);
    }

    // Prepare the JSON representation of the encrypted data.
    final Map<String, dynamic> toJson = {
      "crypto": _crypto.encode(_password, _data),
      "id": uuid,
      "version": 3,
    };

    // Convert the JSON to a string.
    final toString = StringUtils.fromJson(toJson);

    // Based on the specified encoding format, return the encrypted data as a string.
    if (encoding == SecretWalletEncoding.json) {
      return toString;
    }
    return StringUtils.decode(
      StringUtils.encode(toString),
      encoding: StringEncoding.base64,
    );
  }

  List<int> get data => _data.clone();

  void clean() {
    BinaryOps.zero(_data);
    BinaryOps.zero(_password);
  }
}
