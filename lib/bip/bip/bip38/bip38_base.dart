import 'package:blockchain_utils/bip/bip/bip38/bip38_no_ec.dart';
import 'package:blockchain_utils/bip/bip/types/types.dart';
import 'bip38_ec.dart';

/// Helper class for BIP38 encryption and decryption operations.
class Bip38Encrypter {
  /// Encrypt a Bitcoin private key without using ECDSA.
  ///
  /// - [privKey]: The Bitcoin private key to be encrypted.
  /// - [passphrase]: The passphrase for encryption.
  /// - [pubKeyMode]: The selected public key mode (compressed or uncompressed).
  ///   Defaults to [PubKeyModes.compressed].
  /// - Returns: The BIP38-encrypted private key as a string.
  static String encryptNoEc(
    List<int> privKey,
    String passphrase, {
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
  }) {
    return Bip38NoEcEncrypter.encrypt(privKey, passphrase, pubKeyMode);
  }

  /// Generate a BIP38-encrypted private key with ECDSA.
  ///
  /// - [passphrase]: The passphrase for encryption.
  /// - [pubKeyMode]: The selected public key mode (compressed or uncompressed).
  ///   Defaults to [PubKeyModes.compressed].
  /// - [lotNum]: An optional lot number.
  /// - [sequenceNum]: An optional sequence number.
  /// - Returns: The BIP38-encrypted private key as a string.
  static String generatePrivateKeyEc(
    String passphrase, {
    PubKeyModes pubKeyMode = PubKeyModes.compressed,
    int? lotNum,
    int? sequenceNum,
  }) {
    final intPass = Bip38EcKeysGenerator.generateIntermediatePassphrase(
      passphrase,
      lotNum: lotNum,
      sequenceNum: sequenceNum,
    );

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
  /// - [privKeyEnc]: The BIP38-encrypted Bitcoin private key.
  /// - [passphrase]: The passphrase for decryption.
  /// - Returns: A tuple (pair) containing the decrypted private key
  ///   and the selected public key mode (compressed or uncompressed).
  static (List<int>, PubKeyModes) decryptNoEc(
    String privKeyEnc,
    String passphrase,
  ) {
    return Bip38NoEcDecrypter.decrypt(privKeyEnc, passphrase);
  }

  /// Decrypt a BIP38-encrypted Bitcoin private key with ECDSA.
  ///
  /// - [privKeyEnc]: The BIP38-encrypted Bitcoin private key.
  /// - [passphrase]: The passphrase for decryption.
  /// - Returns: A tuple (pair) containing the decrypted private key
  ///   and the selected public key mode (compressed or uncompressed).
  static (List<int>, PubKeyModes) decryptEc(
    String privKeyEnc,
    String passphrase,
  ) {
    return Bip38EcDecrypter.decrypt(privKeyEnc, passphrase);
  }
}
