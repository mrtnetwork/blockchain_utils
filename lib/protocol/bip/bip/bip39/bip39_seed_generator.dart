import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/protocol/bip/mnemonic/src/mnemonic.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'package:blockchain_utils/protocol/bip/bip/bip39/bip39_mnemonic_decoder.dart';

/// Constants related to Bip39 seed generation.
class Bip39SeedGeneratorConst {
  /// The modification string used as part of the seed salt.
  static const String seedSaltMod = "mnemonic";

  /// The number of PBKDF2 rounds used in the seed derivation process.
  static const int seedPbkdf2Rounds = 2048;
}

/// Generates a seed from a Bip39 mnemonic.
class Bip39SeedGenerator {
  // final SecretBytes entropy;
  final Mnemonic mnemonic;
  Bip39SeedGenerator._(this.mnemonic);

  /// Initializes a new instance of the Bip39SeedGenerator.
  ///
  /// The [mnemonic] parameter represents the Bip39 mnemonic to be used for seed generation.
  factory Bip39SeedGenerator(Mnemonic mnemonic) {
    /// Validate the provided Bip39 mnemonic.

    return Bip39SeedGenerator._(mnemonic);
  }

  /// Generates a seed from the Bip39 mnemonic.
  ///
  /// Optionally, a [passphrase] can be provided to further secure the seed generation.
  ///
  SecretBytes generate([String passphrase = ""]) {
    final salt = Bip39SeedGeneratorConst.seedSaltMod + passphrase;
    return SecretBytes.take(
      QuickCrypto.pbkdf2Sha512DeriveKey(
        password: StringUtils.encode(mnemonic.toStr()),
        salt: StringUtils.encode(salt),
        iterations: Bip39SeedGeneratorConst.seedPbkdf2Rounds,
      ),
    );
  }

  /// Generates a seed from the Bip39 mnemonic entropy.
  ///
  /// Optionally, a [passphrase] can be provided to further secure the seed generation.
  ///
  SecretBytes generateFromEntropy([String passphrase = ""]) {
    final salt = Bip39SeedGeneratorConst.seedSaltMod + passphrase;
    final entropy = Bip39MnemonicDecoder().decode(mnemonic);
    return entropy.useValue((entropy) {
      return SecretBytes.take(
        QuickCrypto.pbkdf2Sha512DeriveKey(
          password: entropy,
          salt: StringUtils.encode(salt),
          iterations: Bip39SeedGeneratorConst.seedPbkdf2Rounds,
        ),
      );
    }, zero: true);
  }
}
