import 'dart:convert';
import 'dart:typed_data';
import 'package:blockchain_utils/bip39/bip39.dart';
import 'package:blockchain_utils/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/ec_encryption.dart';
import 'package:blockchain_utils/formating/bytes_num_formating.dart';
import 'package:blockchain_utils/base58/base58.dart' as bs;
import 'package:blockchain_utils/secret_wallet/secret_wallet.dart';

import 'cypto_currencies/cyrpto_currency.dart';

/// An abstract class representing a Hierarchical Deterministic (HD) Wallet.
/// HD Wallets are used to generate a hierarchy of cryptographic key pairs,
/// making it easier to manage keys for different purposes and improving security.
/// Implementations of this class should provide methods to retrieve
/// private and public keys, as well as other relevant information.
abstract class HdWallet {
  /// Gets the private key associated with this HD Wallet.
  Uint8List get privateKey;

  /// Gets the public key associated with this HD Wallet.
  Uint8List get publicKey;

  /// Gets the index of this HD Wallet in the hierarchical structure.
  int get index;

  /// Gets the depth of this HD Wallet in the hierarchical structure.
  int get depth;

  /// Gets the chain code associated with this HD Wallet.
  Uint8List get chainCode;
}

class BIP32HWallet extends HdWallet {
  /// The seed used to generate Bitcoin keys.
  static const String _bitcoinKey = "Bitcoin seed";

  /// Constructs a BIP32 hierarchical wallet from a private key.
  ///
  /// [privateKey] is the private key associated with the wallet.
  /// [chainCode] is the chain code associated with the wallet.
  /// [depth] is the depth of the wallet in the hierarchical structure (default is 0).
  /// [index] is the index of the wallet in the hierarchical structure (default is 0).
  /// [fingerPrint] is the fingerprint of the wallet (default is a 4-byte empty list).
  BIP32HWallet._fromPrivateKey(
      {required Uint8List privateKey,
      required Uint8List chainCode,
      int depth = 0,
      int index = 0,
      Uint8List? fingerPrint})
      : _fingerPrint = fingerPrint ?? Uint8List(4),
        _chainCode = chainCode,
        _private = privateKey,
        _ecPublic = pointFromScalar(privateKey, true)!,
        _fromXpub = false,
        _depth = depth,
        _index = index;

  /// Constructs a BIP32 hierarchical wallet from a public key.
  ///
  /// [public] is the public key associated with the wallet.
  /// [chainCode] is the chain code associated with the wallet.
  /// [depth] is the depth of the wallet in the hierarchical structure (default is 0).
  /// [index] is the index of the wallet in the hierarchical structure (default is 0).
  /// [fingerPrint] is the fingerprint of the wallet (default is a 4-byte empty list).
  BIP32HWallet._fromPublicKey(
      {required Uint8List public,
      required Uint8List chainCode,
      int depth = 0,
      int index = 0,
      Uint8List? fingerPrint})
      : _fingerPrint = fingerPrint ?? Uint8List(4),
        _chainCode = chainCode,
        _ecPublic = public,
        _fromXpub = true,
        _depth = depth,
        _index = index;

  /// Factory constructor to create a BIP32 hierarchical wallet from secret storage.
  ///
  /// [encryptedWallet] is the encrypted wallet data.
  /// [password] is the password used to decrypt the wallet.
  factory BIP32HWallet.fromSecretStorage(
      String encryptedWallet, String password) {
    try {
      final secret = SecretWallet.decode(encryptedWallet, password);
      final toJson = json.decode(secret.credentials);

      final CurrencySymbol symbol = CurrencySymbol.fromName(toJson["currency"]);
      if (toJson["xprv"] != null) {
        return BIP32HWallet.fromXPrivateKey(toJson["xprv"],
            currencySymbol: symbol);
      }
      return BIP32HWallet.fromXpublicKey(toJson["xpub"],
          currencySymbol: symbol);
    } catch (e) {
      throw ArgumentError("Invalid BIP32 Secret wallet");
    }
  }

  int _depth = 0;

  /// Gets the depth of this BIP32 hierarchical wallet in the hierarchical structure.
  @override
  int get depth => _depth;

  int _index = 0;

  /// Gets the index of this BIP32 hierarchical wallet in the hierarchical structure.
  @override
  int get index => _index;

  final Uint8List _fingerPrint;

  /// The fingerprint of the wallet.
  Uint8List get fingerPrint => _fingerPrint;

  /// Indicates whether this BIP32 hierarchical wallet is the root wallet.
  late final bool isRoot = bytesListEqual(_fingerPrint, Uint8List(4));

  late final Uint8List _private;

  /// The private key associated with this wallet.
  @override
  Uint8List get privateKey => _fromXpub
      ? throw ArgumentError("connot access private from publicKey wallet")
      : _private;

  late final Uint8List _ecPublic;

  /// The public key associated with this wallet.
  @override
  Uint8List get publicKey => _ecPublic;
  final bool _fromXpub;

  /// Indicates whether this is a public key wallet.
  bool get isPublicKeyWallet => _fromXpub;

  /// Factory constructor to create a BIP32 hierarchical wallet from a mnemonic.
  ///
  /// [mnemonic] is the BIP-39 mnemonic phrase.
  /// [passphrase] is an optional passphrase to be used with the mnemonic (default is an empty string).
  /// [key] is the key used for hashing (default is the Bitcoin seed key).
  factory BIP32HWallet.fromMnemonic(String mnemonic,
      {String passphrase = "", String key = _bitcoinKey}) {
    // Generate a seed from the mnemonic and passphrase using BIP-39.
    final seed = BIP39.toSeed(mnemonic, passphrase: passphrase);

    // Validate the length of the generated seed.
    if (seed.length < 16) {
      throw ArgumentError("Seed should be at least 128 bits");
    }
    if (seed.length > 64) {
      throw ArgumentError("Seed should be at most 512 bits");
    }

    // Compute the HMAC-SHA512 hash of the seed using the provided key.
    final hash = hmacSHA512(utf8.encode(key) as Uint8List, seed);

    // Extract the private key (first 32 bytes) and chain code (remaining bytes).
    final private = hash.sublist(0, 32);
    final chainCode = hash.sublist(32);

    // Create and return a BIP32 hierarchical wallet from the private key and chain code.
    final wallet =
        BIP32HWallet._fromPrivateKey(privateKey: private, chainCode: chainCode);
    return wallet;
  }

  /// The chain code associated with this BIP32 hierarchical wallet.
  final Uint8List _chainCode;

  /// A constant representing the high bit for 32-bit integers.
  static const _highBit = 0x80000000;

  /// A constant representing the maximum value of a 31-bit unsigned integer.
  static const _maxUint31 = 2147483647;

  /// A constant representing the maximum value of a 32-bit unsigned integer.
  static const _maxUint32 = 4294967295;

  /// Override to get the chain code associated with this BIP32 hierarchical wallet.
  ///
  /// Returns the chain code as a [Uint8List].
  @override
  Uint8List get chainCode {
    return _chainCode;
  }

  /// Adds a new derivation path to the BIP32 hierarchical wallet based on the given [index].
  ///
  /// [index] is the index of the new derivation path.
  ///
  /// Throws [ArgumentError] if the [index] is not a valid UInt32.
  ///
  /// Returns a new BIP32 hierarchical wallet instance representing the derived path.
  BIP32HWallet _addDrive(int index) {
    // Check if the index is a valid UInt32.
    if (index > _maxUint32 || index < 0) throw ArgumentError("Expected UInt32");

    // Determine if the derivation is for a hardened key.
    final isHardened = index >= _highBit;

    // Create a Uint8List to hold the data.
    Uint8List data = Uint8List(37);

    if (isHardened) {
      if (_fromXpub) {
        throw ArgumentError("Cannot use hardened path in a public wallet");
      }
      data[0] = 0x00;
      data.setRange(1, 33, _private);
      data.buffer.asByteData().setUint32(33, index);
    } else {
      data.setRange(0, 33, publicKey);
      data.buffer.asByteData().setUint32(33, index);
    }

    // Compute the master key using HMAC-SHA512.
    final masterKey = hmacSHA512(_chainCode, data);

    // Extract the derived key and chain code.
    final key = masterKey.sublist(0, 32);
    final chain = masterKey.sublist(32);

    // Check if the derived key is not private (i.e., not a valid key).
    if (!isPrivate(key)) {
      return _addDrive(index + 1);
    }

    // Calculate the child depth and index.
    final childDepth = depth + 1;
    final childIndex = index;

    // Calculate the fingerprint for the derived path.
    final finger = hash160(publicKey).sublist(0, 4);

    if (_fromXpub) {
      // Create a new public key based on the derived path.
      final newPoint = pointAddScalar(_ecPublic, key, true);

      // Check if the new point is valid.
      if (newPoint == null) {
        return _addDrive(index + 1);
      }

      // Return a new BIP32 hierarchical wallet from the derived public key.
      return BIP32HWallet._fromPublicKey(
          public: newPoint,
          chainCode: chain,
          depth: childDepth,
          index: childIndex,
          fingerPrint: finger);
    } else {
      // Generate a new private key based on the derived path.
      final newPrivate = generateTweek(_private, key);

      // Return a new BIP32 hierarchical wallet from the derived private key.
      return BIP32HWallet._fromPrivateKey(
          privateKey: newPrivate!,
          chainCode: chain,
          depth: childDepth,
          index: childIndex,
          fingerPrint: finger);
    }
  }

  /// Checks if a given BIP32 derivation path is valid.
  ///
  /// [path] is the BIP32 derivation path to validate.
  ///
  /// Returns true if the [path] is valid, otherwise false.
  static bool isValidPath(String path) {
    // Define a regular expression to match valid BIP32 derivation paths.
    final regex = RegExp(r"^(m\/)?(\d+'?\/)*\d+'?$");

    // Check if the [path] matches the regular expression.
    return regex.hasMatch(path);
  }

  /// Determines whether a given extended private or public key is a root key.
  ///
  /// [xPrivateKey] is the extended private or public key to check.
  /// [cryptocurrency] is the cryptocurrency configuration.
  /// [isPublicKey] is a flag indicating whether the key is a public key (default is false).
  ///
  /// Returns a tuple containing a boolean indicating whether the key is a root key and the key data as a [Uint8List].
  static (bool, Uint8List) isRootKey(
      String xPrivateKey, Cryptocurrency cryptocurrency,
      {bool isPublicKey = false}) {
    // Decode the extended key from base58 format.
    final dec = bs.decodeCheck(xPrivateKey);

    // Check if the decoded key has the expected length (78 bytes).
    if (dec.length != 78) {
      throw ArgumentError("Invalid xPrivateKey");
    }

    // Extract the first 4 bytes (semantic) of the decoded key.
    final semantic = dec.sublist(0, 4);

    // Determine the key type based on whether it's a public or private key.
    final type = isPublicKey
        ? cryptocurrency.extendedPublicKey.getExtendedType(semantic)
        : cryptocurrency.extendedPrivateKey.getExtendedType(semantic);

    // If the key type is null, it's invalid for the given network.
    if (type == null) {
      throw ArgumentError("Invalid network");
    }

    // Get the expected network prefix for the key type.
    final networkPrefix = isPublicKey
        ? cryptocurrency.extendedPublicKey.getExtended(type)
        : cryptocurrency.extendedPrivateKey.getExtended(type);

    // Create the expected prefix for network identification.
    final prefix = hexToBytes("${networkPrefix}000000000000000000");

    // Check if the prefix of the decoded key matches the expected prefix.
    return (bytesListEqual(prefix, dec.sublist(0, prefix.length)), dec);
  }

  /// Creates a BIP32 hierarchical wallet from an extended private key.
  ///
  /// [xPrivateKey] is the extended private key.
  /// [foreRootKey] is an optional flag indicating whether the key is expected to be a root key.
  /// [currencySymbol] is the currency symbol (default is CurrencySymbol.btc).
  ///
  /// Returns a BIP32 hierarchical wallet instance.
  factory BIP32HWallet.fromXPrivateKey(String xPrivateKey,
      {bool? foreRootKey, CurrencySymbol currencySymbol = CurrencySymbol.btc}) {
    // Get the cryptocurrency configuration based on the currency symbol.
    final currency = Cryptocurrency.fromSymbol(currencySymbol);

    // Check if the key is a root key, and optionally verify if it's expected to be a root key.
    final check = isRootKey(xPrivateKey, currency);
    if (foreRootKey != null) {
      if (check.$1 != foreRootKey) {
        throw ArgumentError(
            "The key is not a valid ${foreRootKey ? "rootXPrivateKey" : "xPrivateKey"}");
      }
    }

    // Decode the key to extract relevant information.
    final decode = _decodeXKeys(check.$2);
    final chain = decode[4];
    final private = decode[5];
    final index = intFromBytes(decode[3], Endian.big);
    final depth = intFromBytes(decode[1], Endian.big);

    // Create a BIP32 hierarchical wallet from the decoded key components.
    return BIP32HWallet._fromPrivateKey(
        privateKey: private,
        chainCode: chain,
        depth: depth,
        fingerPrint: decode[2],
        index: index);
  }

  /// Decodes an extended private or public key into its individual components.
  ///
  /// [xKey] is the extended private or public key to decode.
  /// [isPublic] is a flag indicating whether the key is a public key (default is false).
  ///
  /// Returns a list containing the decoded key components.
  static List<Uint8List> _decodeXKeys(Uint8List xKey, {bool isPublic = false}) {
    return [
      xKey.sublist(0, 4), // Semantic
      xKey.sublist(4, 5), // Depth
      xKey.sublist(5, 9), // Fingerprint
      xKey.sublist(9, 13), // Child index
      xKey.sublist(13, 45), // Chain code
      xKey.sublist(isPublic ? 45 : 46) // Public or private key
    ];
  }

  /// Converts the BIP32 hierarchical wallet to its extended public key representation.
  ///
  /// [semantic] specifies the extended key type (default is ExtendedKeyType.p2pkh).
  /// [currencySymbol] is the currency symbol (default is CurrencySymbol.btc).
  ///
  /// Returns the extended public key as a string.
  String toXpublicKey(
      {ExtendedKeyType semantic = ExtendedKeyType.p2pkh,
      CurrencySymbol currencySymbol = CurrencySymbol.btc}) {
    // Get the cryptocurrency configuration based on the currency symbol.
    final currency = Cryptocurrency.fromSymbol(currencySymbol);

    // Retrieve the semantic version hex for the given extended key type.
    final versionHex = currency.extendedPublicKey.getExtended(semantic);

    // Check if the network supports the specified semantic version.
    if (versionHex == null) {
      throw ArgumentError("Network does not support this semantic version");
    }

    // Convert the version hex to bytes.
    final version = hexToBytes(versionHex);

    // Convert depth, fingerprint, and index to bytes.
    final depthBytes = Uint8List.fromList([depth]);
    final fingerPrintBytes = _fingerPrint;
    final indexBytes = packUint32BE(index);

    // Combine all key components into a single byte list.
    final data = publicKey;
    final result = Uint8List.fromList([
      ...version,
      ...depthBytes,
      ...fingerPrintBytes,
      ...indexBytes,
      ..._chainCode,
      ...data
    ]);

    // Encode the result into a base58 check-encoded string.
    final check = bs.encodeCheck(result);

    return check;
  }

  /// Creates a BIP32 hierarchical wallet from an extended public key (xPub).
  ///
  /// [xPublicKey] is the extended public key to create the wallet from.
  /// [currencySymbol] is the currency symbol (default is CurrencySymbol.btc).
  /// [forceRootKey] is a flag to force treating the key as a root key (optional).
  ///
  /// Returns a BIP32 hierarchical wallet instance initialized with the provided extended public key.
  factory BIP32HWallet.fromXpublicKey(String xPublicKey,
      {CurrencySymbol currencySymbol = CurrencySymbol.btc,
      bool? forceRootKey}) {
    // Get the cryptocurrency configuration based on the currency symbol.
    final Cryptocurrency currency = Cryptocurrency.fromSymbol(currencySymbol);

    // Check if the provided xPublicKey is a valid root key.
    final check = isRootKey(xPublicKey, currency, isPublicKey: true);

    // If forceRootKey is specified, verify that the key matches the expected type.
    if (forceRootKey != null) {
      if (check.$1 != forceRootKey) {
        throw ArgumentError(
            "The provided key is not a valid ${forceRootKey ? "rootPublicKey" : "publicKey"}");
      }
    }

    // Decode the components of the extended public key.
    final decode = _decodeXKeys(check.$2, isPublic: true);

    // Extract chain code, public key, index, and depth from the decoded components.
    final chain = decode[4];
    final publicKey = decode[5];
    final index = intFromBytes(decode[3], Endian.big);
    final deph = intFromBytes(decode[1], Endian.big);

    // Create and return a BIP32 hierarchical wallet from the extracted components.
    return BIP32HWallet._fromPublicKey(
        public: publicKey,
        chainCode: chain,
        depth: deph,
        fingerPrint: decode[2],
        index: index);
  }

  /// Generates an extended private key (xPrv) string for this hierarchical wallet.
  ///
  /// [semantic] is the semantic version for the extended private key (default is ExtendedKeyType.p2pkh).
  /// [currencySymbol] is the currency symbol (default is CurrencySymbol.btc).
  ///
  /// Returns an extended private key string based on the provided semantic version and currency.
  ///
  /// Throws [ArgumentError] if attempting to access private key from a public key wallet.
  /// Throws [ArgumentError] if the network does not support the specified semantic version.
  String toXpriveKey(
      {ExtendedKeyType semantic = ExtendedKeyType.p2pkh,
      CurrencySymbol currencySymbol = CurrencySymbol.btc}) {
    // Check if the wallet is derived from an extended public key (xPub).
    if (_fromXpub) {
      throw ArgumentError("Cannot access private key from a publicKey wallet");
    }

    // Get the cryptocurrency configuration based on the currency symbol.
    final n = Cryptocurrency.fromSymbol(currencySymbol);

    // Retrieve the semantic version for the extended private key.
    final versionHex = n.extendedPrivateKey.getExtended(semantic);

    // Ensure that the network supports the specified semantic version.
    if (versionHex == null) {
      throw ArgumentError("Network does not support this semantic version");
    }

    // Convert the version to bytes.
    final version = hexToBytes(versionHex);

    // Create bytes for depth, fingerprint, index, and private key data.
    final depthBytes = Uint8List.fromList([depth]);
    final fingerPrintBytes = _fingerPrint;
    final indexBytes = packUint32BE(index);
    final data = Uint8List.fromList(
        [0, ..._private]); // Prepend 0 to indicate private key.

    // Combine all bytes to create the extended private key.
    final result = Uint8List.fromList([
      ...version,
      ...depthBytes,
      ...fingerPrintBytes,
      ...indexBytes,
      ..._chainCode,
      ...data
    ]);

    // Encode and return the extended private key as a string with a checksum.
    final check = bs.encodeCheck(result);
    return check;
  }

  /// Drives and returns a hierarchical wallet (BIP32HWallet) along the specified BIP32 derivation path.
  ///
  /// [masterWallet] is the master hierarchical wallet from which the path is derived.
  /// [path] is the BIP32 derivation path string to follow.
  ///
  /// Returns a new hierarchical wallet derived from the master wallet following the provided path.
  ///
  /// Throws [ArgumentError] if the provided BIP32 path is invalid.
  /// Throws [ArgumentError] if attempting to derive a hardened path from a public wallet.
  /// Throws [ArgumentError] if the path contains an invalid index or exceeds maximum index value.
  static BIP32HWallet drivePath(BIP32HWallet masterWallet, String path) {
    // Check if the provided BIP32 path is valid.
    if (!isValidPath(path)) {
      throw ArgumentError("Invalid BIP32 Path");
    }

    // Split the path into individual segments and remove the leading "m" or "M" if present.
    List<String> splitPath = path.split("/");
    if (splitPath[0] == "m" || splitPath[0] == "M") {
      splitPath = splitPath.sublist(1);
    }

    // Use fold to iteratively drive the hierarchical wallet along the path.
    return splitPath.fold(masterWallet, (BIP32HWallet prevHd, String indexStr) {
      int index;
      if (indexStr.endsWith("'")) {
        // Handle hardened path segment.
        if (masterWallet._fromXpub) {
          throw ArgumentError(
              "Cannot drive hardened path from a public wallet");
        }
        index = int.parse(indexStr.substring(0, indexStr.length - 1));
        if (index > _maxUint31 || index < 0) {
          throw ArgumentError("Invalid index");
        }
        // Derive a new hierarchical wallet with a hardened index.
        final newDrive = prevHd._addDrive(index + _highBit);
        return newDrive;
      } else {
        // Handle non-hardened path segment.
        index = int.parse(indexStr);
        // Derive a new hierarchical wallet with a non-hardened index.
        final newDrive = prevHd._addDrive(index);
        return newDrive;
      }
    });
  }

  /// Converts the BIP32 hierarchical wallet data into a JSON representation.
  ///
  /// [semantic] specifies the extended key type semantic (e.g., P2PKH).
  /// [currencySymbol] represents the currency symbol (e.g., BTC).
  ///
  /// Returns a Map containing the JSON representation of the wallet data.
  Map<String, dynamic> _toJson({
    ExtendedKeyType semantic = ExtendedKeyType.p2pkh,
    CurrencySymbol currencySymbol = CurrencySymbol.btc,
  }) {
    final Map<String, dynamic> toJson = {
      "index": index,
      "depth": depth,
      "semantic": semantic.name,
      "currency": currencySymbol.name,
      "chainCode": bytesToHex(chainCode),
    };
    if (!_fromXpub) {
      toJson["xprv"] =
          toXpriveKey(currencySymbol: currencySymbol, semantic: semantic);
    } else {
      toJson["xpub"] =
          toXpublicKey(semantic: semantic, currencySymbol: currencySymbol);
    }

    return toJson;
  }

  /// Converts the BIP32 hierarchical wallet data into a secure JSON representation for secret storage.
  ///
  /// [password] is the password used to encrypt the secret storage.
  /// [semantic] specifies the extended key type semantic (e.g., P2PKH).
  /// [currencySymbol] represents the currency symbol (e.g., BTC).
  /// [encoding] specifies the encoding format for the secret wallet data (e.g., JSON).
  ///
  /// Returns a secure JSON representation of the wallet data encrypted with the provided password.
  String toSecretStorage(
    String password, {
    ExtendedKeyType semantic = ExtendedKeyType.p2pkh,
    CurrencySymbol currencySymbol = CurrencySymbol.btc,
    SecretWalletEncoding encoding = SecretWalletEncoding.json,
  }) {
    final toJs = _toJson(currencySymbol: currencySymbol, semantic: semantic);
    final toStr = json.encode(toJs);
    final secret = SecretWallet.encode(toStr, password);
    return secret.encrypt(encoding: encoding);
  }
}
