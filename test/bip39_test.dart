import 'package:blockchain_utils/bip39/bip39.dart';
import 'package:test/test.dart';

void main() {
  // Test case for generating and validating BIP-39 mnemonic phrases.
// It generates 24-word mnemonic phrases in Chinese Traditional language,
// converts them to entropy, and then back to mnemonic phrases.
// It ensures that the generated mnemonic phrases match the originals.
  test('test', () async {
    for (int i = 0; i < 1000; i++) {
      final bip = BIP39(language: Bip39Language.chineseTraditional);
      final gn = bip.generateMnemonic(strength: Bip39WordLength.words24);
      final entropy = bip.mnemonicToEntropy(gn);
      final back = bip.entropyToMnemonic(entropy);
      expect(back,
          gn); // Verify that the regenerated mnemonic matches the original.
    }
  });
}
