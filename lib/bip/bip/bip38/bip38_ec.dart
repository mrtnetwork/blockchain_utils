import 'dart:typed_data';

import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bip/bip/types/types.dart';

import 'package:blockchain_utils/bip/bip/bip38/bip38_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/secp256k1_keys_ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/ec/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/scrypt/scrypt.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/bit_utils.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

//
/// Constants for BIP38 encryption and decryption operations.
///
class Bip38EcConst {
  /// Lot and Sequence Number Constants
  static const int lotNumMinVal = 0;
  static const int lotNumMaxVal = 1048575;
  static const int seqNumMinVal = 0;
  static const int seqNumMaxVal = 4095;

  /// Owner Salt Constants
  static const int ownerSaltWithLotSeqByteLen = 4;
  static const int ownerSaltNoLotSeqByteLen = 8;

  /// Intermediate Passphrase Encryption Constants
  static const int intPassEncByteLen = 49;
  static const List<int> intPassMagicWithLotSeq = [
    44,
    233,
    179,
    225,
    255,
    57,
    226,
    81,
  ];
  static const List<int> intPassMagicNoLotSeq = [
    44,
    233,
    179,
    225,
    255,
    57,
    226,
    83,
  ];

  /// Seed and Encrypted Key Constants
  static const int seedBByteLen = 24;
  static const int encByteLen = 39;
  static const List<int> encKeyPrefix = [1, 67];
  static const int flagBitCompressed = 5;
  static const int flagBitLotSeq = 2;

  /// Scrypt Constants
  static const int scryptPrefactorKeyLen = 32;
  static const int scryptPrefactorN = 16384;
  static const int scryptPrefactorP = 8;
  static const int scryptPrefactorR = 8;
  static const int scryptHalvesKeyLen = 64;
  static const int scryptHalvesN = 1024;
  static const int scryptHalvesP = 1;
  static const int scryptHalvesR = 1;
}

/// Utility class for BIP38 encryption and decryption operations.
class Bip38EcUtils {
  /// Generate owner entropy with lot and sequence numbers.
  ///
  /// - [lotNum]: The lot number to use for owner entropy.
  /// - [sequenceNum]: The sequence number to use for owner entropy.
  ///
  static List<int> ownerEntropyWithLotSeq(int lotNum, int sequenceNum) {
    if (lotNum < Bip38EcConst.lotNumMinVal ||
        lotNum > Bip38EcConst.lotNumMaxVal) {
      throw ArgumentException.invalidOperationArguments(
        "ownerEntropyWithLotSeq",
        name: "lotNum",
        reason: 'Invalid lot number ($lotNum)',
      );
    }
    if (sequenceNum < Bip38EcConst.seqNumMinVal ||
        sequenceNum > Bip38EcConst.seqNumMaxVal) {
      throw ArgumentException.invalidOperationArguments(
        "ownerEntropyWithLotSeq",
        name: "sequenceNum",
        reason: 'Invalid sequence number ($sequenceNum)',
      );
    }

    final ownerSalt = QuickCrypto.generateRandom(
      Bip38EcConst.ownerSaltWithLotSeqByteLen,
    );

    final lotSequence =
        ((lotNum * (Bip38EcConst.seqNumMaxVal + 1)) + sequenceNum)
            .toU32LeBytes();
    return [...ownerSalt, ...lotSequence];
  }

  /// Generate owner entropy without lot and sequence numbers.
  static List<int> ownerEntropyNoLotSeq() {
    final ownerSalt = QuickCrypto.generateRandom(
      Bip38EcConst.ownerSaltNoLotSeqByteLen,
    );
    return ownerSalt;
  }

  /// Extract owner salt from owner entropy based on lot and sequence numbers.
  ///
  /// - [ownerEntropy]: The owner entropy containing owner salt.
  /// - [hasLotSeq]: A boolean flag indicating whether lot and sequence numbers are
  ///   included in the owner entropy.
  ///
  static List<int> ownerSaltFromEntropy(
    List<int> ownerEntropy,
    bool hasLotSeq,
  ) {
    return hasLotSeq
        ? ownerEntropy.sublist(0, Bip38EcConst.ownerSaltWithLotSeqByteLen)
        : ownerEntropy;
  }

  /// Derive the pass factor for BIP38 encryption.
  ///
  /// - [passphrase]: The passphrase to be used in deriving the pass factor.
  /// - [ownerEntropy]: The owner entropy from which the pass factor is derived.
  /// - [hasLotSeq]: A boolean flag indicating whether lot and sequence numbers are
  ///   included in the owner entropy.
  ///
  static List<int> passFactor(
    String passphrase,
    List<int> ownerEntropy,
    bool hasLotSeq,
  ) {
    final ownerSalt = ownerSaltFromEntropy(ownerEntropy, hasLotSeq);

    /// Derive the prefactor using Scrypt key derivation function.
    final prefactor = Scrypt.deriveKey(
      StringUtils.encode(passphrase),
      ownerSalt,
      dkLen: Bip38EcConst.scryptPrefactorKeyLen,
      n: Bip38EcConst.scryptPrefactorN,
      p: Bip38EcConst.scryptPrefactorP,
      r: Bip38EcConst.scryptPrefactorR,
    );

    /// Combine the prefactor with owner entropy, if present.
    final combinedValue =
        hasLotSeq
            ? QuickCrypto.sha256DoubleHash([...prefactor, ...ownerEntropy])
            : prefactor;

    return combinedValue;
  }

  /// Calculate the EC point for the pass factor.
  ///
  /// - [passfactor]: The pass factor for which the EC point is calculated.
  ///
  static List<int> passPoint(List<int> passfactor) {
    /// Get the generator point for the Secp256k1 curve.
    final generator = Curves.generatorSecp256k1;

    /// Convert the pass factor to a big integer.
    final toBig = BigintUtils.fromBytes(passfactor);

    /// Calculate the EC point by scalar multiplication.
    final toPoint = generator * toBig;

    /// Convert the EC point to bytes.
    return toPoint.toBytes();
  }

  /// Derive key halves from passpoint, address hash, and owner entropy.
  ///
  /// - [passpoint]: The passpoint used in key derivation.
  /// - [addressHash]: The address hash to be combined in key derivation.
  /// - [ownerEntropy]: The owner entropy used in key derivation.
  ///
  static (List<int>, List<int>) deriveKeyHalves(
    List<int> passpoint,
    List<int> addressHash,
    List<int> ownerEntropy,
  ) {
    /// Derive a key using Scrypt with combined data.
    final key = Scrypt.deriveKey(
      passpoint,
      [...addressHash, ...ownerEntropy],
      dkLen: Bip38EcConst.scryptHalvesKeyLen,
      n: Bip38EcConst.scryptHalvesN,
      p: Bip38EcConst.scryptHalvesP,
      r: Bip38EcConst.scryptHalvesR,
    );

    /// Split the derived key into two halves.
    final derivedHalf1 = key.sublist(0, Bip38EcConst.scryptHalvesKeyLen ~/ 2);
    final derivedHalf2 = key.sublist(Bip38EcConst.scryptHalvesKeyLen ~/ 2);

    return (derivedHalf1, derivedHalf2);
  }
}

/// Helper class for generating BIP38-encrypted keys.
class Bip38EcKeysGenerator {
  /// Generate an intermediate passphrase from a regular passphrase.
  ///
  /// - [passphrase]: The regular passphrase to be transformed.
  /// - [lotNum]: The optional lot number.
  /// - [sequenceNum]: The optional sequence number.
  ///
  static String generateIntermediatePassphrase(
    String passphrase, {
    int? lotNum,
    int? sequenceNum,
  }) {
    /// Determine if lot and sequence numbers are included.
    final hasLotSeq = lotNum != null && sequenceNum != null;

    /// Generate owner entropy based on lot and sequence numbers.
    final ownerEntropy =
        hasLotSeq
            ? Bip38EcUtils.ownerEntropyWithLotSeq(lotNum, sequenceNum)
            : Bip38EcUtils.ownerEntropyNoLotSeq();

    /// Derive passfactor and passpoint from the passphrase and owner entropy.
    final passfactor = Bip38EcUtils.passFactor(
      passphrase,
      ownerEntropy,
      hasLotSeq,
    );
    final passpoint = Bip38EcUtils.passPoint(passfactor);

    /// Determine the appropriate magic number based on lot and sequence numbers.
    final magic =
        hasLotSeq
            ? Bip38EcConst.intPassMagicWithLotSeq
            : Bip38EcConst.intPassMagicNoLotSeq;

    /// Encode the intermediate passphrase
    final intermediatePassphrase = Base58Encoder.checkEncode([
      ...magic,
      ...ownerEntropy,
      ...passpoint,
    ]);

    return intermediatePassphrase;
  }

  /// Generate a BIP38-encrypted private key from an intermediate passphrase.
  ///
  /// - [intPassphrase]: The intermediate passphrase.
  /// - [pubKeyMode]: The public key mode specifying the address type.
  ///
  static String generatePrivateKey(
    String intPassphrase,
    PubKeyModes pubKeyMode,
  ) {
    /// Decode the intermediate passphrase into bytes.
    final intPassphraseBytes = Base58Decoder.checkDecode(intPassphrase);

    /// Ensure the length of the intermediate code is valid.
    if (intPassphraseBytes.length != Bip38EcConst.intPassEncByteLen) {
      throw ArgumentException.invalidOperationArguments(
        "generatePrivateKey",
        name: "intPassphrase",
        reason: "Invalid intermediate code length",
      );
    }

    /// Extract magic, owner entropy, and passpoint from the intermediate code.
    final magic = intPassphraseBytes.sublist(0, 8);
    final ownerEntropy = intPassphraseBytes.sublist(8, 16);
    final passpoint = Secp256k1PublicKey.fromBytes(
      intPassphraseBytes.sublist(16),
    );

    /// Check if the magic number is valid.
    if (!BytesUtils.bytesEqual(magic, Bip38EcConst.intPassMagicNoLotSeq) &&
        !BytesUtils.bytesEqual(magic, Bip38EcConst.intPassMagicWithLotSeq)) {
      throw ArgumentException.invalidOperationArguments(
        "generatePrivateKey",
        name: "intPassphrase",
        reason: "Invalid magic",
      );
    }

    /// Generate a random seed for seedb and derive a new point.
    final seedb = QuickCrypto.generateRandom(Bip38EcConst.seedBByteLen);
    final factorb = QuickCrypto.sha256DoubleHash(seedb);
    final newPoint = passpoint.point * BigintUtils.fromBytes(factorb);

    /// Calculate the address hash.
    final addressHash = Bip38Addr.addressHash(newPoint.toBytes(), pubKeyMode);

    /// Derive key halves using Scrypt.
    final derivedHalves = Bip38EcUtils.deriveKeyHalves(
      passpoint.compressed,
      addressHash,
      ownerEntropy,
    );

    /// Encrypt seedb and create the BIP38-encrypted private key.
    final encryptedParts = _encryptSeedb(
      seedb,
      derivedHalves.$1,
      derivedHalves.$2,
    );
    final flagbyte = _setFlagbyteBits(magic, pubKeyMode);
    final encKeyBytes = [
      ...Bip38EcConst.encKeyPrefix,
      ...flagbyte,
      ...addressHash,
      ...ownerEntropy,
      ...encryptedParts.$1.sublist(0, 8),
      ...encryptedParts.$2,
    ];

    return Base58Encoder.checkEncode(encKeyBytes);
  }

  /// Encrypt the 'seedb' value using AES-CBC encryption.
  ///
  /// - [seedb]: The 'seedb' value to be encrypted.
  /// - [derivedHalf1]: The first derived key half.
  /// - [derivedHalf2]: The second derived key half.
  ///
  static (List<int>, List<int>) _encryptSeedb(
    List<int> seedb,
    List<int> derivedHalf1,
    List<int> derivedHalf2,
  ) {
    /// Encrypt the first part of 'seedb'.
    final encryptedPart1 = QuickCrypto.aesCbcEncrypt(
      derivedHalf2,
      BytesUtils.xor(seedb.sublist(0, 16), derivedHalf1.sublist(0, 16)),
    );

    /// Encrypt the second part of 'seedb'.
    final encryptedPart2 = QuickCrypto.aesCbcEncrypt(
      derivedHalf2,
      BytesUtils.xor([
        ...encryptedPart1.sublist(8),
        ...seedb.sublist(16),
      ], derivedHalf1.sublist(16)),
    );

    return (encryptedPart1, encryptedPart2);
  }

  /// Set flag bits in the 'flagbyte' based on public key mode and magic number.
  ///
  /// - [magic]: The magic number extracted from the intermediate passphrase.
  /// - [pubKeyMode]: The selected public key mode (compressed or uncompressed).
  ///
  static List<int> _setFlagbyteBits(List<int> magic, PubKeyModes pubKeyMode) {
    int flagbyteInt = 0;

    /// Set the 'compressed' bit if the public key mode is 'compressed'.
    if (pubKeyMode == PubKeyModes.compressed) {
      flagbyteInt = BitUtils.setBit(
        flagbyteInt,
        Bip38EcConst.flagBitCompressed,
      );
    }

    /// Set the 'lot and sequence' bit if the magic number matches 'with lot/seq'.
    if (BytesUtils.bytesEqual(magic, Bip38EcConst.intPassMagicWithLotSeq)) {
      flagbyteInt = BitUtils.setBit(flagbyteInt, Bip38EcConst.flagBitLotSeq);
    }
    return flagbyteInt.toBytes(byteOrder: Endian.little);
  }
}

/// Helper class for decrypting BIP38-encrypted private keys.
class Bip38EcDecrypter {
  /// Decrypt a BIP38-encrypted private key with a passphrase.
  ///
  /// - [privKeyEnc]: The BIP38-encrypted private key to be decrypted.
  /// - [passphrase]: The passphrase used for decryption.
  /// - Returns: A tuple (pair) containing the decrypted private key bytes and
  ///   the associated public key mode.
  static (List<int>, PubKeyModes) decrypt(
    String privKeyEnc,
    String passphrase,
  ) {
    final privKeyEncBytes = Base58Decoder.checkDecode(privKeyEnc);

    /// Check if the length of the encrypted private key is valid.
    if (privKeyEncBytes.length != Bip38EcConst.encByteLen) {
      throw ArgumentException.invalidOperationArguments(
        "decrypt",
        name: "privKeyEnc",
        reason: "Invalid encrypted private key length.",
      );
    }

    /// Extract various components from the encrypted private key.
    final prefix = privKeyEncBytes.sublist(0, 2);
    final flagbyte = [privKeyEncBytes[2]];
    final addressHash = privKeyEncBytes.sublist(3, 7);
    final ownerEntropy = privKeyEncBytes.sublist(7, 15);
    final encryptedPart1Lower = privKeyEncBytes.sublist(15, 23);
    final encryptedPart2 = privKeyEncBytes.sublist(23);

    /// Verify the prefix of the encrypted private key.
    if (!BytesUtils.bytesEqual(prefix, Bip38EcConst.encKeyPrefix)) {
      throw ArgumentException.invalidOperationArguments(
        "decrypt",
        name: "privKeyEnc",
        reason: "Invalid prefix.",
      );
    }

    /// Extract flag options based on the flag byte.
    final flagOptions = _getFlagbyteOptions(flagbyte);

    /// Derive the pass factor and key halves for decryption.
    final passfactor = Bip38EcUtils.passFactor(
      passphrase,
      ownerEntropy,
      flagOptions.$2,
    );

    final derivedHalves = Bip38EcUtils.deriveKeyHalves(
      Bip38EcUtils.passPoint(passfactor),
      addressHash,
      ownerEntropy,
    );

    /// Decrypt 'factorb' and compute the private key.
    final factorb = _decryptAndGetFactorb(
      encryptedPart1Lower,
      encryptedPart2,
      derivedHalves.$1,
      derivedHalves.$2,
    );
    final privateKeyBytes = _computePrivateKey(passfactor, factorb);

    /// Create a public key from the private key and calculate address hash.
    final toPub = Secp256k1PrivateKey.fromBytes(privateKeyBytes);
    final addressHashGot = Bip38Addr.addressHash(
      toPub.publicKey.point.toBytes(),
      flagOptions.$1,
    );

    /// Verify the extracted address hash matches the expected value.
    if (!BytesUtils.bytesEqual(addressHash, addressHashGot)) {
      throw ArgumentException.invalidOperationArguments(
        "decrypt",
        name: "privKeyEnc",
        reason: "Invalid address hash.",
      );
    }

    return (privateKeyBytes, flagOptions.$1);
  }

  /// Decrypt and obtain the 'factorb' from encrypted parts.
  ///
  /// - [encryptedPart1Lower]: The lower part of the first encrypted segment.
  /// - [encryptedPart2]: The second encrypted segment.
  /// - [derivedHalf1]: The first derived key half.
  /// - [derivedHalf2]: The second derived key half.
  ///
  static List<int> _decryptAndGetFactorb(
    List<int> encryptedPart1Lower,
    List<int> encryptedPart2,
    List<int> derivedHalf1,
    List<int> derivedHalf2,
  ) {
    /// Decrypt the second part and extract encryptedPart1Higher and seedbPart2.
    final decryptedPart2 = BytesUtils.xor(
      QuickCrypto.aesCbcDecrypt(derivedHalf2, encryptedPart2),
      derivedHalf1.sublist(16),
    );
    final encryptedPart1Higher = decryptedPart2.sublist(0, 8);
    final seedbPart2 = decryptedPart2.sublist(8);

    /// Decrypt the first part and obtain seedbPart1.
    final seedbPart1 = BytesUtils.xor(
      QuickCrypto.aesCbcDecrypt(derivedHalf2, [
        ...encryptedPart1Lower,
        ...encryptedPart1Higher,
      ]),
      derivedHalf1.sublist(0, 16),
    );

    /// Combine seedbPart1 and seedbPart2 to obtain the full 'seedb'.
    final seedb = [...seedbPart1, ...seedbPart2];

    /// Compute the SHA-256 double hash of the 'seedb' to obtain 'factorb'.
    return QuickCrypto.sha256DoubleHash(seedb);
  }

  static List<int> _computePrivateKey(List<int> passfactor, List<int> factorb) {
    final gm = Curves.generatorSecp256k1;

    final passfactorInt = BigintUtils.fromBytes(passfactor);
    final factorbInt = BigintUtils.fromBytes(factorb);
    final privKeyInt = (passfactorInt * factorbInt) % gm.order!;
    return privKeyInt.toBeBytes(length: EcdsaKeysConst.privKeyByteLen);
  }

  /// Extract flag options from the 'flagbyte' value.
  ///
  /// - [flagbyte]: The 'flagbyte' value extracted from the BIP38-encrypted private key.
  ///
  static (PubKeyModes, bool) _getFlagbyteOptions(List<int> flagbyte) {
    int flagbyteInt = IntUtils.fromBytes(flagbyte, byteOrder: Endian.little);

    /// Check if the lot and sequence number bit is set.
    final hasLotSeq = BitUtils.intIsBitSet(
      flagbyteInt,
      Bip38EcConst.flagBitLotSeq,
    );

    /// Determine the public key mode (compressed or uncompressed).
    final pubKeyMode =
        BitUtils.intIsBitSet(flagbyteInt, Bip38EcConst.flagBitCompressed)
            ? PubKeyModes.compressed
            : PubKeyModes.uncompressed;

    /// Reset the flag bits and check if 'flagbyteInt' is now zero.
    flagbyteInt = BitUtils.resetBit(flagbyteInt, Bip38EcConst.flagBitLotSeq);
    flagbyteInt = BitUtils.resetBit(
      flagbyteInt,
      Bip38EcConst.flagBitCompressed,
    );

    /// Verify that 'flagbyteInt' is zero; otherwise, it's an invalid 'flagbyte'.
    if (flagbyteInt != 0) {
      throw ArgumentException.invalidOperationArguments(
        "decrypt",
        reason: "Invalid flagbyte.",
      );
    }

    return (pubKeyMode, hasLotSeq);
  }
}
