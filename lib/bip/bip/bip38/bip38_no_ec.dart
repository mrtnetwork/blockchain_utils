import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/bip/bip38/bip38_addr.dart';
import 'package:blockchain_utils/bip/bip/types/types.dart';
import 'package:blockchain_utils/bip/ecc/keys/secp256k1_keys_ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/scrypt/scrypt.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// Constants for BIP38 encryption and decryption without ECDSA.
///
/// This class provides constant values that are specific to BIP38 encryption and
/// decryption for Bitcoin addresses without using the Elliptic Curve Digital
/// Signature Algorithm (ECDSA).
class Bip38NoEcConst {
  /// Length of the BIP38 encrypted key in bytes.
  static const int encKeyByteLen = 39;

  /// Prefix bytes for the encrypted key.
  static const List<int> encKeyPrefix = [0x01, 0x42];

  /// Flagbyte for compressed public keys.
  static const List<int> flagbyteCompressed = [0xe0];

  /// Flagbyte for uncompressed public keys.
  static const List<int> flagbyteUncompressed = [0xc0];

  /// Length of the scrypt-derived key in bytes.
  static const int scryptKeyLen = 64;

  /// Parameter 'N' for the scrypt key derivation function.
  static const int scryptN = 16384;

  /// Parameter 'P' for the scrypt key derivation function.
  static const int scryptP = 8;

  /// Parameter 'R' for the scrypt key derivation function.
  static const int scryptR = 8;
}

/// Utility class for BIP38 encryption and decryption without ECDSA.
///
/// This class provides utility methods for BIP38 encryption and decryption of
/// Bitcoin addresses without using the Elliptic Curve Digital Signature Algorithm (ECDSA).
class Bip38NoEcUtils {
  /// Compute the address hash from private key bytes and public key mode.
  ///
  /// This method computes the address hash from the provided private key bytes
  /// and the selected public key mode (compressed or uncompressed).
  ///
  /// - [privKeyBytes]: The private key bytes.
  /// - [pubKeyMode]: The selected public key mode.
  /// - Returns: The address hash as a `List<int>`.
  static List<int> addressHash(List<int> privKeyBytes, PubKeyModes pubKeyMode) {
    final publicBytes = Secp256k1PrivateKeyEcdsa.fromBytes(privKeyBytes)
        .publicKey
        .point
        .toBytes();

    return Bip38Addr.addressHash(publicBytes, pubKeyMode);
  }

  /// Derive key halves from a passphrase and an address hash.
  ///
  /// This method derives key halves from the provided passphrase and address hash.
  /// It uses scrypt key derivation to obtain two key halves for use in BIP38
  /// encryption and decryption.
  ///
  /// - [passphrase]: The passphrase for key derivation.
  /// - [addressHash]: The address hash as input for key derivation.
  /// - Returns: A tuple (pair) containing the two derived key halves as `List<int>`s.
  static Tuple<List<int>, List<int>> deriveKeyHalves(
      String passphrase, List<int> addressHash) {
    final key = Scrypt.deriveKey(
      StringUtils.encode(passphrase),
      addressHash,
      dkLen: Bip38NoEcConst.scryptKeyLen,
      n: Bip38NoEcConst.scryptN,
      r: Bip38NoEcConst.scryptR,
      p: Bip38NoEcConst.scryptP,
    );

    final derivedHalf1 = key.sublist(0, Bip38NoEcConst.scryptKeyLen ~/ 2);
    final derivedHalf2 = key.sublist(Bip38NoEcConst.scryptKeyLen ~/ 2);

    return Tuple(derivedHalf1, derivedHalf2);
  }
}

/// Helper class for encrypting Bitcoin private keys without using ECDSA.
///
/// This class provides a method for encrypting Bitcoin private keys using BIP38
/// encryption without the Elliptic Curve Digital Signature Algorithm (ECDSA).
/// It takes a private key, passphrase, and public key mode as inputs and returns
/// the BIP38-encrypted private key as a string.
class Bip38NoEcEncrypter {
  /// Encrypt a Bitcoin private key without using ECDSA.
  ///
  /// This method encrypts a Bitcoin private key without using the Elliptic Curve
  /// Digital Signature Algorithm (ECDSA). It takes a private key, passphrase,
  /// and a public key mode (compressed or uncompressed) as inputs and returns
  /// the BIP38-encrypted private key as a string.
  ///
  /// - [privKey]: The Bitcoin private key to be encrypted.
  /// - [passphrase]: The passphrase for encryption.
  /// - [pubKeyMode]: The selected public key mode (compressed or uncompressed).
  /// - Returns: The BIP38-encrypted private key as a string.
  static String encrypt(
      List<int> privKey, String passphrase, PubKeyModes pubKeyMode) {
    /// Compute the address hash from the private key and public key mode.
    final addressHash = Bip38NoEcUtils.addressHash(privKey, pubKeyMode);

    /// Derive key halves using the passphrase and address hash.
    final derivedHalves =
        Bip38NoEcUtils.deriveKeyHalves(passphrase, addressHash);

    /// Extract the derived key halves.
    final derivedHalf1 = derivedHalves.item1;
    final derivedHalf2 = derivedHalves.item2;

    /// Encrypt the private key using the derived halves.
    final encryptedHalves =
        _encryptPrivateKey(privKey, derivedHalf1, derivedHalf2);

    /// Extract the encrypted halves.
    final encryptedHalf1 = encryptedHalves.item1;
    final encryptedHalf2 = encryptedHalves.item2;

    /// Determine the flagbyte based on the public key mode.
    final flagbyte = pubKeyMode == PubKeyModes.compressed
        ? Bip38NoEcConst.flagbyteCompressed
        : Bip38NoEcConst.flagbyteUncompressed;

    /// Create the BIP38-encrypted private key as bytes.
    final encKeyBytes = Bip38NoEcConst.encKeyPrefix +
        flagbyte +
        addressHash +
        encryptedHalf1 +
        encryptedHalf2;

    /// Encode the encrypted private key as a Base58 string.
    return Base58Encoder.checkEncode(List<int>.from(encKeyBytes));
  }

  /// Encrypt the private key using derived key halves.
  ///
  /// This method encrypts a Bitcoin private key by using the derived key halves
  /// obtained from the passphrase and address hash. It performs AES-CBC encryption
  /// on the private key, splitting it into two halves before encryption. The two
  /// encrypted halves are returned as a tuple (pair).
  ///
  /// - [privKeyBytes]: The Bitcoin private key to be encrypted.
  /// - [derivedHalf1]: The first derived key half.
  /// - [derivedHalf2]: The second derived key half.
  /// - Returns: A tuple (pair) containing the two encrypted private key halves
  ///   as `List<int>`s.
  static Tuple<List<int>, List<int>> _encryptPrivateKey(
      List<int> privKeyBytes, List<int> derivedHalf1, List<int> derivedHalf2) {
    /// Encrypt the first half of the private key.
    final encryptedHalf1 = QuickCrypto.aesCbcEncrypt(
        derivedHalf2,
        BytesUtils.xor(
            privKeyBytes.sublist(0, 16), derivedHalf1.sublist(0, 16)));

    /// Encrypt the second half of the private key.
    final encryptedHalf2 = QuickCrypto.aesCbcEncrypt(derivedHalf2,
        BytesUtils.xor(privKeyBytes.sublist(16), derivedHalf1.sublist(16)));

    return Tuple(encryptedHalf1, encryptedHalf2);
  }
}

/// Helper class for decrypting BIP38-encrypted Bitcoin private keys without ECDSA.
///
/// This class provides methods for decrypting BIP38-encrypted Bitcoin private keys
/// without using the Elliptic Curve Digital Signature Algorithm (ECDSA). It includes
/// a `decrypt` method for decrypting the private key and a `_decryptAndGetPrivKey`
/// method for the core decryption process.
class Bip38NoEcDecrypter {
  /// Decrypt a BIP38-encrypted Bitcoin private key without using ECDSA.
  ///
  /// This method decrypts a BIP38-encrypted Bitcoin private key without relying on
  /// the Elliptic Curve Digital Signature Algorithm (ECDSA). It takes an encrypted
  /// private key and a passphrase as inputs and returns the decrypted private key
  /// and the selected public key mode (compressed or uncompressed) as a tuple.
  ///
  /// - [privKeyEnc]: The BIP38-encrypted Bitcoin private key.
  /// - [passphrase]: The passphrase for decryption.
  /// - Returns: A tuple (pair) containing the decrypted private key as a `List<int>`
  ///   and the selected public key mode (compressed or uncompressed).
  static Tuple<List<int>, PubKeyModes> decrypt(
      String privKeyEnc, String passphrase) {
    final privKeyEncBytes = Base58Decoder.checkDecode(privKeyEnc);

    if (privKeyEncBytes.length != Bip38NoEcConst.encKeyByteLen) {
      throw ArgumentException(
          'Invalid encrypted key length (${privKeyEncBytes.length})');
    }

    final prefix = privKeyEncBytes.sublist(0, 2);
    final flagbyte = List<int>.from([privKeyEncBytes[2]]);
    final addressHash = privKeyEncBytes.sublist(3, 7);
    final encryptedHalf1 = privKeyEncBytes.sublist(7, 23);
    final encryptedHalf2 = privKeyEncBytes.sublist(23);

    // Check prefix and flagbyte
    if (!BytesUtils.bytesEqual(prefix, Bip38NoEcConst.encKeyPrefix)) {
      throw ArgumentException(
          'Invalid prefix (${BytesUtils.toHexString(prefix)})');
    }
    if (flagbyte[0] != Bip38NoEcConst.flagbyteCompressed.first &&
        flagbyte[0] != Bip38NoEcConst.flagbyteUncompressed.first) {
      throw ArgumentException(
          'Invalid flagbyte (${BytesUtils.toHexString(flagbyte)})');
    }

    // Derive key halves from the passphrase and address hash
    final derivedHalves =
        Bip38NoEcUtils.deriveKeyHalves(passphrase, addressHash);

    final derivedHalf1 = derivedHalves.item1;
    final derivedHalf2 = derivedHalves.item2;

    // Get the private key back by decrypting
    final privKeyBytes = _decryptAndGetPrivKey(
        encryptedHalf1, encryptedHalf2, derivedHalf1, derivedHalf2);

    // Get public key mode
    final pubKeyMode = flagbyte[0] == Bip38NoEcConst.flagbyteCompressed.first
        ? PubKeyModes.compressed
        : PubKeyModes.uncompressed;

    // Verify the address hash
    final addressHashGot = Bip38NoEcUtils.addressHash(privKeyBytes, pubKeyMode);
    if (!BytesUtils.bytesEqual(addressHash, addressHashGot)) {
      throw ArgumentException(
          'Invalid address hash (expected: ${BytesUtils.toHexString(addressHash)}, '
          'got: ${BytesUtils.toHexString(addressHashGot)})');
    }

    return Tuple(privKeyBytes, pubKeyMode);
  }

  /// Decrypt and return the Bitcoin private key.
  ///
  /// This method decrypts the Bitcoin private key from the encrypted halves using
  /// the derived key halves. It combines the two decrypted halves to reconstruct
  /// the private key and returns it as a `List<int>`.
  ///
  /// - [encryptedHalf1]: The first encrypted half of the private key.
  /// - [encryptedHalf2]: The second encrypted half of the private key.
  /// - [derivedHalf1]: The first derived key half.
  /// - [derivedHalf2]: The second derived key half.
  /// - Returns: The decrypted private key as a `List<int>`.
  static List<int> _decryptAndGetPrivKey(
      List<int> encryptedHalf1,
      List<int> encryptedHalf2,
      List<int> derivedHalf1,
      List<int> derivedHalf2) {
    final decryptedHalf1 =
        QuickCrypto.aesCbcDecrypt(derivedHalf2, encryptedHalf1);
    final decryptedHalf2 =
        QuickCrypto.aesCbcDecrypt(derivedHalf2, encryptedHalf2);

    return BytesUtils.xor(
        List<int>.from([...decryptedHalf1, ...decryptedHalf2]), derivedHalf1);
  }
}
