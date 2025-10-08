import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'ton_entropy_generator.dart';
import 'ton_mnemonic_validator.dart';

/// The _TonSeedGeneratorConst class contains constants used for the TonSeedGenerator.
class _TonSeedGeneratorConst {
  static const int seedPbkdf2Rounds = 100000;
  static const String defaultTonSalt = "TON default seed";
}

/// The TonSeedGenerator class is responsible for generating a seed from a mnemonic phrase.
/// It can optionally validate the mnemonic according to TON specifications and use a passphrase.
class TonSeedGenerator {
  const TonSeedGenerator(this.mnemonic);
  final Mnemonic mnemonic;

  /// Generates a seed from the mnemonic, with optional passphrase and salt.
  /// If validateTonMnemonic is true, it validates the mnemonic before generating the seed.
  List<int> generate(
      {String password = "",
      String salt = _TonSeedGeneratorConst.defaultTonSalt,
      bool validateTonMnemonic = false}) {
    if (validateTonMnemonic) {
      TomMnemonicValidator().validate(mnemonic, password: password);
    }

    /// Generates entropy from the mnemonic and passphrase.
    final hash =
        TonEntropyGeneratorUtils.generateEnteropy(mnemonic, password: password);

    /// Derives a key using PBKDF2 with the generated hash, salt, and a specified number of iterations.
    return QuickCrypto.pbkdf2DeriveKey(
        password: hash,
        salt: StringUtils.encode(salt),
        iterations: _TonSeedGeneratorConst.seedPbkdf2Rounds);
  }
}
