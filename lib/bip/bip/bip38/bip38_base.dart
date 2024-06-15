import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/bip/bip38/bip38_no_ec.dart';

import 'bip38_ec.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Helper class for BIP38 encryption and decryption operations.
///
/// This class provides static methods for encrypting and decrypting Bitcoin
/// private keys using the BIP38 standard. It offers support for both EC and
/// non-EC (NoEc) encryption methods.
class Bip38Encrypter {
  /// Encrypt a Bitcoin private key without using ECDSA.
  ///
  /// This method encrypts a Bitcoin private key using BIP38 encryption without
  /// relying on the Elliptic Curve Digital Signature Algorithm (ECDSA). It takes
  /// the private key, passphrase, and an optional public key mode as inputs and
  /// returns the BIP38-encrypted private key as a string.
  ///
  /// - [privKey]: The Bitcoin private key to be encrypted.
  /// - [passphrase]: The passphrase for encryption.
  /// - [pubKeyMode]: The selected public key mode (compressed or uncompressed).
  ///   Defaults to [PubKeyModes.compressed].
  /// - Returns: The BIP38-encrypted private key as a string.
  static String encryptNoEc(List<int> privKey, String passphrase,
      {PubKeyModes pubKeyMode = PubKeyModes.compressed}) {
    return Bip38NoEcEncrypter.encrypt(privKey, passphrase, pubKeyMode);
  }

  /// Generate a BIP38-encrypted private key with ECDSA.
  ///
  /// This method generates a BIP38-encrypted private key using ECDSA encryption.
  /// It takes a passphrase, an optional public key mode, and optional lot number
  /// and sequence number as inputs. It returns the BIP38-encrypted private key
  /// as a string.
  ///
  /// - [passphrase]: The passphrase for encryption.
  /// - [pubKeyMode]: The selected public key mode (compressed or uncompressed).
  ///   Defaults to [PubKeyModes.compressed].
  /// - [lotNum]: An optional lot number.
  /// - [sequenceNum]: An optional sequence number.
  /// - Returns: The BIP38-encrypted private key as a string.
  static String generatePrivateKeyEc(String passphrase,
      {PubKeyModes pubKeyMode = PubKeyModes.compressed,
      int? lotNum,
      int? sequenceNum}) {
    final intPass = Bip38EcKeysGenerator.generateIntermediatePassphrase(
        passphrase,
        lotNum: lotNum,
        sequenceNum: sequenceNum);

    return Bip38EcKeysGenerator.generatePrivateKey(intPass, pubKeyMode);
  }
}

/// Helper class for BIP38 decryption operations.
///
/// This class provides static methods for decrypting BIP38-encrypted Bitcoin
/// private keys. It supports both EC and non-EC (NoEc) decryption methods.
class Bip38Decrypter {
  /// Decrypt a BIP38-encrypted Bitcoin private key without using ECDSA.
  ///
  /// This method decrypts a BIP38-encrypted Bitcoin private key without relying
  /// on the Elliptic Curve Digital Signature Algorithm (ECDSA). It takes an
  /// encrypted private key and a passphrase as inputs and returns the decrypted
  /// private key and the selected public key mode (compressed or uncompressed)
  /// as a tuple.
  ///
  /// - [privKeyEnc]: The BIP38-encrypted Bitcoin private key.
  /// - [passphrase]: The passphrase for decryption.
  /// - Returns: A tuple (pair) containing the decrypted private key as a List<int>
  ///   and the selected public key mode (compressed or uncompressed).
  static Tuple<List<int>, PubKeyModes> decryptNoEc(
      String privKeyEnc, String passphrase) {
    return Bip38NoEcDecrypter.decrypt(privKeyEnc, passphrase);
  }

  /// Decrypt a BIP38-encrypted Bitcoin private key with ECDSA.
  ///
  /// This method decrypts a BIP38-encrypted Bitcoin private key using ECDSA
  /// decryption. It takes an encrypted private key and a passphrase as inputs
  /// and returns the decrypted private key and the selected public key mode
  /// (compressed or uncompressed) as a tuple.
  ///
  /// - [privKeyEnc]: The BIP38-encrypted Bitcoin private key.
  /// - [passphrase]: The passphrase for decryption.
  /// - Returns: A tuple (pair) containing the decrypted private key as a List<int>
  ///   and the selected public key mode (compressed or uncompressed).
  static Tuple<List<int>, PubKeyModes> decryptEc(
      String privKeyEnc, String passphrase) {
    return Bip38EcDecrypter.decrypt(privKeyEnc, passphrase);
  }
}
