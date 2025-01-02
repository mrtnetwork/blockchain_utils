import 'package:blockchain_utils/bip/mnemonic/entropy_generator.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// The TonEntropyGeneratorUtils class provides utility methods for handling entropy
/// generation and validation related to the TON (The Open Network) blockchain. It
/// includes methods to determine if a given entropy corresponds to a basic seed,
/// a password-protected seed, and if a password is required based on a mnemonic phrase.
class TonEntropyGeneratorUtils {
  /// Constants defining the number of iterations for the PBKDF2 key derivation function.
  static const int basicSeedPbkdfIterations = 390;
  static const int passwordSeedPbkdfIterations = 1;
  static const String seedVersionSalt = "TON seed version";
  static const String seedFastVersionSalt = "TON fast seed version";

  /// Determines if the provided entropy is a basic seed by using PBKDF2 with a predefined
  /// salt and iteration count. Returns true if the derived key's first byte is 0.
  static bool isBasicSeed(List<int> entropy) {
    final scrypt = QuickCrypto.pbkdf2DeriveKey(
        password: entropy,
        salt: seedVersionSalt.codeUnits,
        iterations: basicSeedPbkdfIterations);
    return scrypt[0] == 0;
  }

  /// Determines if the provided entropy is a password-protected seed by using PBKDF2 with
  /// a predefined salt and a single iteration. Returns true if the derived key's first byte is 1.
  static bool isPasswordSeed(List<int> entropy) {
    final scrypt = QuickCrypto.pbkdf2DeriveKey(
        password: entropy,
        salt: seedFastVersionSalt.codeUnits,
        iterations: passwordSeedPbkdfIterations);
    return scrypt[0] == 1;
  }

  /// Checks if a password is needed for the given mnemonic by generating its entropy and
  /// evaluating it with isPasswordSeed and isBasicSeed methods.
  static bool isPasswordNeed(Mnemonic mnemonic) {
    final entropy = generateEnteropy(mnemonic);
    return isPasswordSeed(entropy) && !isBasicSeed(entropy);
  }

  /// Generates entropy from a given mnemonic and optional passphrase using HMAC-SHA512.
  static List<int> generateEnteropy(Mnemonic mnemonic, {String password = ""}) {
    return QuickCrypto.hmacSha512Hash(
        StringUtils.encode(mnemonic.toStr()), StringUtils.encode(password));
  }
}

/// The TonMnemonicEntropyGenerator class extends EntropyGenerator to provide specific
/// entropy generation functionalities tailored for TON mnemonic phrases.
class TonMnemonicEntropyGenerator extends EntropyGenerator {
  /// Constructor initializing the base EntropyGenerator with the given bit length.
  TonMnemonicEntropyGenerator(super.bitLen);

  /// Validates if the given bit length for entropy is within the acceptable range (88 to 528 bits).
  static bool isValidEntropyBitLen(int bitLen) {
    return bitLen >= 88 && bitLen <= 528;
  }

  /// Validates if the given byte length for entropy corresponds to a valid bit length.
  static bool isValidEntropyByteLen(int byteLen) {
    return isValidEntropyBitLen(byteLen * 8);
  }

  /// Generates random entropy based on the bit length provided at initialization.
  @override
  List<int> generate() {
    return QuickCrypto.generateRandom((bitlen / 8).ceil());
  }
}
