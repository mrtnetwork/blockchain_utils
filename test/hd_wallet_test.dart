import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/hd_wallet/cypto_currencies/cyrpto_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Bitcoin-related tests
  group("bitcoin", () {
    // Define constants for Bitcoin tests
    const String mnemonic =
        "arm siege skate hungry almost lens domain ordinary train horn dad feel";
    const String defaultBitcoinDriveXprv =
        "xprvA3uyqqRVVpqsMYsafaezca3nG1UsindYytdauXGJZFcHpWcWU3VESUW6KdwaUSPehdRFjYJkN5MPMct5LtqGuEwfAXYV338TqrgvjDBFKNk";
    const String defaultBitcoinDriveXpub =
        "xpub6GuLFLxPLCQAa2x3mcBzyhzWp3KN8FMQM7ZBhufv7b9GhJwf1aoUzGpaAuPjRLJ7bfk2Xk3sk35z9nhcxT8SbGR16JXW9Fu9ZmNxVgBXVpH";
    const String chidXpriveXPrive =
        "xprvAAFpxp4j6RCec9812NbWNGxiQTCbP2hYkt6C3ST9tqNMttBmu9evSgs2Afze5uN1ve5UyBy3Ft4sPTrg2KyWxzk8XCY1DChCP8u1vmkYZ9z";
    const String childXpubXpub =
        "xpub6PFBNKbcvnkwpdCU8Q8WjQuSxV35nVRQ871nqprmTAuLmgWvSgyAzVBW1xkgZa2kgjzdaBVuVdLtCgypw7UMSLjjzRuxqrCfP9PgJta2Trh";
    const String childXpubFromChildXpub =
        "xpub6WdLGoArPz3ZG7hSde2LH6b2hTVbvXXp96RMTmCpsRocv89Y8bdiR2628MzT16TTVyuxGqTGCXvhZ5qTEVoCqghaRua1JMWmQh8ssgWYUA4";

    test("test1", () {
      // Constants for Bitcoin test case 1
      const CurrencySymbol symbol = CurrencySymbol.btc;
      const ExtendedKeyType keyType = ExtendedKeyType.p2pkh;
      final Cryptocurrency cryptocurrency = Cryptocurrency.fromSymbol(symbol);
      final masterWallet = BIP32HWallet.fromMnemonic(mnemonic);

      // Create a drive wallet and derive xPrive and xPub
      final driveWallet =
          BIP32HWallet.drivePath(masterWallet, cryptocurrency.defaultPath);
      final xPrive =
          driveWallet.toXpriveKey(currencySymbol: symbol, semantic: keyType);
      final xPub =
          driveWallet.toXpublicKey(currencySymbol: symbol, semantic: keyType);

      // Verify that the derived xPrive and xPub match the expected values
      expect(xPrive, defaultBitcoinDriveXprv);
      expect(xPub, defaultBitcoinDriveXpub);
    });

    test("test2", () {
      // Constants for Bitcoin test case 2
      const CurrencySymbol symbol = CurrencySymbol.btc;
      const ExtendedKeyType keyType = ExtendedKeyType.p2pkh;

      // Create a master wallet from the defaultBitcoinDriveXprv
      final masterWallet = BIP32HWallet.fromXPrivateKey(defaultBitcoinDriveXprv,
          currencySymbol: symbol);

      // Create a drive wallet from the master wallet and derive xPrive and xPub
      final driveWallet = BIP32HWallet.drivePath(masterWallet, "m/1/6/8/0");
      final xPrive =
          driveWallet.toXpriveKey(currencySymbol: symbol, semantic: keyType);
      final xPub =
          driveWallet.toXpublicKey(currencySymbol: symbol, semantic: keyType);

      // Verify that the derived xPrive and xPub match the expected values
      expect(xPrive, chidXpriveXPrive);
      expect(xPub, childXpubXpub);
    });

    test("test3", () {
      // Constants for Bitcoin test case 3
      const CurrencySymbol symbol = CurrencySymbol.btc;
      const ExtendedKeyType keyType = ExtendedKeyType.p2pkh;

      // Create a master wallet from the childXpubXpub
      final masterWallet =
          BIP32HWallet.fromXpublicKey(childXpubXpub, currencySymbol: symbol);

      // Create a drive wallet from the master wallet and derive xPub
      final driveWallet = BIP32HWallet.drivePath(masterWallet, "m/1/0/12/0");
      final xPub =
          driveWallet.toXpublicKey(currencySymbol: symbol, semantic: keyType);

      // Verify that the derived xPub matches the expected value
      expect(xPub, childXpubFromChildXpub);
    });
  });

  // Dogecoin-related tests (similar structure as Bitcoin tests)
  group("dogecoin", () {
    // Define constants for Dogecoin tests
    const String mnemonic =
        "arm siege skate hungry almost lens domain ordinary train horn dad feel";
    const String defaultDogeDriveXprv =
        "dgpv5BSrwKoaUD7yVofKBTsPKT2a4PFsgEkDvb9ibsTMBp94SY9e1asxGyN7yzvrcPfGjZwFYKVGLUwNTGRMNKxNLTCutapyTUAmSYKyB51qGxJ";
    const String defaultDogeDriveXpub =
        "dgub8vKtH1jU2MnJnfKUDhVMSJaAWwdWWMmwDBvvkyrKywC4zbGLRMRivGmmZCXWGpzporNYFZ7SMzwYUh3YbUe524t5jqWFY1r9yE5Bgf9PEnX";
    const String chidXpriveXPrive =
        "dgpv5Kire3V5WrU31EMGeSx77pZ4QMyhnyfySb7fMNqZ3Gck6GgG3CR1rnfLtEDDDfUi3TjEEcVeUx8Yei6qLjgoxN7S9oDhR2ZWpDJtkGMb7pJ";
    const String childXpubXpub =
        "dgub94bsyjQy518NJ61Rgga5Eg6ervMLd6hgjBtsWVEXqPfkeKnxSxxnW64zTSzAknMEJDfWw6J4vKcJ367oY7rqgBxMNzrYs7XYXqgomGAEokL";
    const String childXpubFromChildXpub =
        "dgub9C59EWZV2Ro4Aen2B8PTJkTJDTBksDFrs4JLEBHLJjbPMM2L3of1YqoTPfH2CZKBJt8YWscQin62mSwGCC9iRATZ1ZVtGpgHfUt1SpGLrgm";

    test("test1", () {
      // Constants for Dogecoin test case 1
      const CurrencySymbol symbol = CurrencySymbol.doge;
      const ExtendedKeyType keyType = ExtendedKeyType.p2sh;
      final Cryptocurrency cryptocurrency = Cryptocurrency.fromSymbol(symbol);
      final masterWallet = BIP32HWallet.fromMnemonic(mnemonic);

      // Create a drive wallet and derive xPrive and xPub
      final driveWallet =
          BIP32HWallet.drivePath(masterWallet, cryptocurrency.defaultPath);
      final xPrive =
          driveWallet.toXpriveKey(currencySymbol: symbol, semantic: keyType);
      final xPub =
          driveWallet.toXpublicKey(currencySymbol: symbol, semantic: keyType);

      // Verify that the derived xPrive and xPub match the expected values
      expect(xPrive, defaultDogeDriveXprv);
      expect(xPub, defaultDogeDriveXpub);
    });

    test("test2", () {
      // Constants for Dogecoin test case 2
      const CurrencySymbol symbol = CurrencySymbol.doge;
      const ExtendedKeyType keyType = ExtendedKeyType.p2sh;

      // Create a master wallet from the defaultDogeDriveXprv
      final masterWallet = BIP32HWallet.fromXPrivateKey(defaultDogeDriveXprv,
          currencySymbol: symbol);

      // Create a drive wallet from the master wallet and derive xPrive and xPub
      final driveWallet = BIP32HWallet.drivePath(masterWallet, "m/1/6/8/0");
      final xPrive =
          driveWallet.toXpriveKey(currencySymbol: symbol, semantic: keyType);
      final xPub =
          driveWallet.toXpublicKey(currencySymbol: symbol, semantic: keyType);

      // Verify that the derived xPrive and xPub match the expected values
      expect(xPrive, chidXpriveXPrive);
      expect(xPub, childXpubXpub);
    });

    test("test3", () {
      // Constants for Dogecoin test case 3
      const CurrencySymbol symbol = CurrencySymbol.doge;
      const ExtendedKeyType keyType = ExtendedKeyType.p2sh;

      // Create a master wallet from the childXpubXpub
      final masterWallet =
          BIP32HWallet.fromXpublicKey(childXpubXpub, currencySymbol: symbol);

      // Create a drive wallet from the master wallet and derive xPub
      final driveWallet = BIP32HWallet.drivePath(masterWallet, "m/1/0/12/0");
      final xPub =
          driveWallet.toXpublicKey(currencySymbol: symbol, semantic: keyType);

      // Verify that the derived xPub matches the expected value
      expect(xPub, childXpubFromChildXpub);
    });
  });

  group("secretWallet", () {
    // Define a constant password for encryption/decryption
    const String password = "MYPASSWORD";

    test("test1", () {
      // Create a BIP39 instance with Japanese language
      final bip39 = BIP39(language: Bip39Language.japanese);

      // Generate a random 24-word mnemonic
      final mn = bip39.generateMnemonic(strength: Bip39WordLength.words24);

      // Create a BIP32 hierarchical wallet from the generated mnemonic
      final bip39Wallet = BIP32HWallet.fromMnemonic(mn);

      // Derive the xPrive and xPub keys from the wallet
      final xPriv = bip39Wallet.toXpriveKey();
      final xPub = bip39Wallet.toXpublicKey();

      // Encrypt the wallet using a password and base64 encoding
      final secureStorage = bip39Wallet.toSecretStorage(password,
          encoding: SecretWalletEncoding.base64);

      // Decrypt the wallet from the secure storage using the password
      final decodeWallet =
          BIP32HWallet.fromSecretStorage(secureStorage, password);

      // Derive the xPrive and xPub keys from the decrypted wallet
      final decodeXprive = decodeWallet.toXpriveKey();
      final decodeXpub = decodeWallet.toXpublicKey();

      // Verify that the derived xPrive and xPub keys match the original ones
      expect(xPriv, decodeXprive);
      expect(xPub, decodeXpub);
    });
  });
}
