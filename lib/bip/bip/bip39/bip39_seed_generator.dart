import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'bip39_mnemonic_decoder.dart';

/// Constants related to Bip39 seed generation.
class Bip39SeedGeneratorConst {
  /// The modification string used as part of the seed salt.
  static const String seedSaltMod = "mnemonic";

  /// The number of PBKDF2 rounds used in the seed derivation process.
  static const int seedPbkdf2Rounds = 2048;
}

/// Generates a seed from a Bip39 mnemonic.
///
/// This class allows you to generate a seed from a Bip39 mnemonic, taking an
/// optional passphrase into account. It validates the mnemonic before
/// generating the seed.
class Bip39SeedGenerator {
  final List<int> _entropy;
  final Mnemonic mnemonic;
  Bip39SeedGenerator._(this.mnemonic, List<int> entropy)
      : _entropy = entropy.asImmutableBytes;

  /// Initializes a new instance of the Bip39SeedGenerator.
  ///
  /// The [mnemonic] parameter represents the Bip39 mnemonic to be used for seed generation.
  factory Bip39SeedGenerator(Mnemonic mnemonic) {
    /// Validate the provided Bip39 mnemonic.
    final entropy = Bip39MnemonicDecoder().decode(mnemonic.toStr());
    return Bip39SeedGenerator._(mnemonic, entropy);
  }

  /// Generates a seed from the Bip39 mnemonic.
  ///
  /// Optionally, a [passphrase] can be provided to further secure the seed generation.
  ///
  /// Example usage:
  /// ```dart
  /// final seedGenerator = Bip39SeedGenerator(mnemonic);
  /// final seed = seedGenerator.generate("my_passphrase");
  /// ```
  List<int> generate([String passphrase = ""]) {
    final salt = Bip39SeedGeneratorConst.seedSaltMod + passphrase;
    return QuickCrypto.pbkdf2DeriveKey(
      password: StringUtils.encode(mnemonic.toStr()),
      salt: StringUtils.encode(salt),
      iterations: Bip39SeedGeneratorConst.seedPbkdf2Rounds,
    );
  }

  /// Generates a seed from the Bip39 mnemonic entropy.
  ///
  /// Optionally, a [passphrase] can be provided to further secure the seed generation.
  ///
  /// Example usage:
  /// ```dart
  /// final seedGenerator = Bip39SeedGenerator(mnemonic);
  /// final seed = seedGenerator.generateFromEntropy("my_passphrase");
  /// ```
  List<int> generateFromEntropy([String passphrase = ""]) {
    final salt = Bip39SeedGeneratorConst.seedSaltMod + passphrase;
    return QuickCrypto.pbkdf2DeriveKey(
      password: _entropy,
      salt: StringUtils.encode(salt),
      iterations: Bip39SeedGeneratorConst.seedPbkdf2Rounds,
    );
  }
}
