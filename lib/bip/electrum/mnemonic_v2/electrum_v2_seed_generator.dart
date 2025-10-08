import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic.dart';
import 'package:blockchain_utils/bip/electrum/mnemonic_v2/electrum_v2_mnemonic_validator.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Constants and configurations related to Electrum V2 seed generation.
class ElectrumV2SeedGeneratorConst {
  /// A salt modifier used in the PBKDF2 key derivation process.
  static const String seedSaltMod = 'electrum';

  /// Number of rounds for the PBKDF2 key derivation.
  static const int seedPbkdf2Rounds = 2048;
}

/// Class for generating an Electrum V2 seed from a mnemonic and an optional passphrase.
class ElectrumV2SeedGenerator {
  final Mnemonic mnemonic;

  /// Creates an ElectrumV2SeedGenerator instance with the given [mnemonic].
  /// Optionally, you can specify the [language] used in the mnemonic.
  /// The [mnemonic] is validated to ensure its correctness based on the specified language.
  ElectrumV2SeedGenerator(this.mnemonic, [ElectrumV2Languages? language]) {
    /// Validate the provided mnemonic to ensure its correctness.
    ElectrumV2MnemonicValidator(language: language).validate(mnemonic.toStr());
  }

  /// Generates an Electrum V2 seed from the mnemonic and an optional [passphrase].
  List<int> generate([String passphrase = '']) {
    /// Create a salt by combining the Electrum V2 salt modifier and the optional passphrase.
    final salt = ElectrumV2SeedGeneratorConst.seedSaltMod + passphrase;

    /// Derive the seed using PBKDF2 with the specified parameters.
    return QuickCrypto.pbkdf2DeriveKey(
      password: StringUtils.encode(mnemonic.toStr()),
      salt: StringUtils.encode(salt),
      iterations: ElectrumV2SeedGeneratorConst.seedPbkdf2Rounds,
    );
  }
}
