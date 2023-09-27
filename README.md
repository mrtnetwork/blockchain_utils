# blockchain_utils

Blockchain Utils is a comprehensive Dart package that provides a wide range of utilities and functionalities for working with blockchain-related tasks. It offers support for various encoding and decoding formats, Web3 secret storage management, and BIP39 hierarchical wallets, including xPrive and xPub generation. Here's a description of its key features

## Features

### Base58 Encoding/Decoding
Blockchain Utils includes utilities for encoding and decoding data using the Base58 format. Base58 encoding is commonly used in blockchain networks for representing data like addresses and private keys.

### Base58Check Encoding/Decoding
In addition to basic Base58 encoding, the package also supports Base58Check encoding and decoding. Base58Check is used for creating and verifying checksums in blockchain-related data to prevent errors.

### Bech32 Encoding/Decoding
Bech32 encoding and decoding support is provided, simplifying the handling of data in Bech32 format. This feature is especially beneficial when working with native SegWit addresses in blockchain networks like Bitcoin.

### Multi-Language BIP39 Mnemonics
The package offers comprehensive support for BIP39 mnemonics, which enable the generation of deterministic wallets from mnemonic phrases (seed phrases). Developers can generate mnemonics in multiple languages, ensuring flexibility and accessibility.

### Web3 Secret Storage Definition
- JSON Format: Private keys are stored in a JSON (JavaScript Object Notation) format, making it easy to work with in various programming languages.
- Encryption: The private key is encrypted using the user's chosen password. This ensures that even if the JSON file is compromised, an attacker cannot access the private key without the password.
- Key Derivation: The user's password is typically used to derive an encryption key using a key derivation function (KDF). This derived key is then used to encrypt the private key.
- Scrypt Algorithm: The Scrypt algorithm is commonly used for key derivation, as it is computationally intensive and resistant to brute-force attacks.
- Checksum: A checksum is often included in the JSON file to help detect errors in the password.
- Initialization Vector (IV): An IV is typically used to add an extra layer of security to the encryption process.
- Versioning: The JSON file may include a version field to indicate which version of the encryption and storage format is being used.
- Metadata: Additional metadata, such as the address associated with the private key, may be included in the JSON file.

### BIP32 HD (Hierarchical Deterministic) wallet
It supports the generation of extended private (xPrv) and public (xPub) keys, enabling hierarchical deterministic wallet functionality for blockchain applications.

### Multi-Currency Support
With support for encoding and decoding xPrv and xPub keys across more than 160 different blockchain currencies, Blockchain Utils ensures compatibility with a wide variety of blockchain networks. This extensive support streamlines cross-network development efforts.

## EXAMPLES

### Base58 Encoding/Decoding
```
// Decode a Base58 encoded string using the Bitcoin alphabet.
final btcDecode = base58.decode("n4bkvTyU1dVdzsrhWBqBw8fEMbHjJvtmJR", alphabet: base58.bitcoin);

// Decode a Base58 encoded string using the Ripple alphabet.
final rplDecode = base58.decode("ragbHLSHyQzWraW46nBiyHuXgVNwCHHoBM", alphabet: base58.ripple);

// Encode the decoded Bitcoin data back to Base58 using the Bitcoin alphabet.
final btcEncode = base58.encode(btcDecode, alphabet: base58.bitcoin);

// Encode the decoded Ripple data back to Base58 using the Ripple alphabet.
final rplEncode = base58.encode(rplDecode, alphabet: base58.ripple);
```
### Base58Check Encoding/Decoding
```
// Decode a Base58Check encoded string using the Bitcoin alphabet.
final btcDecode = base58.decodeCheck("n4bkvTyU1dVdzsrhWBqBw8fEMbHjJvtmJR", alphabet: base58.bitcoin);

// Decode a Base58Check encoded string using the Ripple alphabet.
final rplDecode = base58.decodeCheck("ragbHLSHyQzWraW46nBiyHuXgVNwCHHoBM", alphabet: base58.ripple);

// Encode the decoded Bitcoin data back to Base58Check using the Bitcoin alphabet.
final btcEncode = base58.encodeCheck(btcDecode, alphabet: base58.bitcoin);

// Encode the decoded Ripple data back to Base58Check using the Ripple alphabet.
final rplEncode = base58.encodeCheck(rplDecode, alphabet: base58.ripple);
```

### Bech32 Encoding/Decoding
```
// Encode data as Bech32 with the human-readable part "tb" and a version of 1.
final encodedBitcoin = bech32.encodeBech32("tb", addressBytes, 1);

// Decode a Bech32 encoded Litecoin address.
final decodedLitecoin = bech32.decodeBech32("ltc1qyrrmwf3zl7e2h8u2pjkxc4pwym8r0vu26yczn9");

// Get the human-readable part (HRP) from the decoded Bech32 data.
decodedLitecoin.hrp;

// Get the version from the decoded Bech32 data.
decodedLitecoin.version;

// Get the data payload from the decoded Bech32 data.
decodedLitecoin.data;

```
### Multi-Language BIP39 Mnemonics
```
// Create a new BIP39 instance with the Japanese language setting.
final bip = BIP39(language: Bip39Language.japanese);

// Generate a BIP39 mnemonic phrase with a strength of 24 words.
final mnemonic = bip.generateMnemonic(strength: Bip39WordLength.words24);

// Validate the generated BIP39 mnemonic to ensure its correctness.
bip.validateMnemonic(mnemonic);

// Convert the BIP39 mnemonic to its corresponding entropy.
final toEntropy = bip.mnemonicToEntropy(mnemonic);

// Convert the entropy back to a BIP39 mnemonic phrase.
final toMnemonic = bip.entropyToMnemonic(toEntropy);

```
### Web3 Secret Storage Definition
```
// The data to be encrypted (replace "......." with your actual data).
final String data = ".......";

// The password used for encryption and decryption.
final String password = "password";

// Encode the data using SecretWallet with specified parameters (p: 1, scryptN: 8192).
final secureStorage = SecretWallet.encode(data, password, p: 1, scryptN: 8192);

// Encrypt the wallet data and obtain the result in JSON format.
final encryptWallet = secureStorage.encrypt(encoding: SecretWalletEncoding.json);

// The encrypted wallet data is represented in JSON format.
// {"crypto":{"cipher":"aes-128-ctr","cipherparams":{"iv":"ce5920c1e72d4f85e59a0ead72de35c0"},"ciphertext":"6cc6dcf3ed72c7","kdf":"scrypt","kdfparams": 
// {"dklen":32,"n":8192,"r":8,"p":1,"salt":"439eb03eb26157d105a4440365bb339dcd6a9802be64343ababc7fe3b6e146ca"},"mac":"8123f9b0404d5ab17b2c335119a2d8aef5454f41b85c9f41157f67bdf43bdc35"},"id":"dae7548d-3547-4c03-89b4- // // // // 
// 26ada925059f","version":3}

// Decode the encrypted wallet data using the provided password.
final decodeWallet = SecretWallet.decode(encryptWallet, password);
```

### BIP32 HD (Hierarchical Deterministic) wallet
```
// Define the cryptocurrency symbol as "doge" (referring to Dogecoin).
// Supports 160 currencies (e.g., BTC, LTC, DOGE, BTCTestnet, etc.)
const CurrencySymbol symbol = CurrencySymbol.doge;

// Define the extended key type as "p2sh" (Pay-to-Script-Hash).
const ExtendedKeyType keyType = ExtendedKeyType.p2sh;

// Create a Cryptocurrency instance by initializing it with the specified symbol.
final Cryptocurrency cryptocurrency = Cryptocurrency.fromSymbol(symbol);
// Explanation: This step defines the cryptocurrency you want to work with, in this case, Dogecoin.

// Create a master wallet by generating it from a BIP39 mnemonic.
final masterWallet = BIP32HWallet.fromMnemonic(mnemonic);
// Explanation: This step generates a hierarchical deterministic (HD) wallet from a BIP39 mnemonic phrase.

// Create a drive wallet by deriving it from the master wallet using the default path for the specified cryptocurrency.
final driveWallet = BIP32HWallet.drivePath(masterWallet, cryptocurrency.defaultPath);
// Explanation: This step derives a child wallet from the master wallet using a specific derivation path.

// Generate the extended private key (xPrive) for the chosen cryptocurrency and key type.
final xPrive = driveWallet.toXpriveKey(currencySymbol: symbol, semantic: keyType);
// Explanation: This step generates the extended private key for the specified cryptocurrency and key type.

// Generate the extended public key (xPub) for the chosen cryptocurrency and key type.
final xPub = driveWallet.toXpublicKey(currencySymbol: symbol, semantic: keyType);
// Explanation: This step generates the extended public key for the specified cryptocurrency and key type.

// Create a public wallet by generating it from the extended public key (xPub) and specifying the cryptocurrency symbol.
final publicWallet = BIP32HWallet.fromXpublicKey(xPub, currencySymbol: symbol);
// Explanation: This step generates a public wallet from the given extended public key and associates it with the specified cryptocurrency.

// Create a private wallet by generating it from the extended private key (Xprv) and specifying the cryptocurrency symbol.
final privateWallet = BIP32HWallet.fromXPrivateKey(xPrive, currencySymbol: symbol);
// Explanation: This step generates a private wallet from the given extended private key and associates it with the specified cryptocurrency.

// Convert the public wallet into a secure storage format using the specified password and encoding.
final toSecureStorage = publicWallet.toSecretStorage("password", encoding: SecretWalletEncoding.base64);
// Explanation: This step converts the public wallet into a secure storage format (encrypted) using a password for protection. The encoding is set to base64.

// Retrieve a wallet from secure storage by decoding it using the provided password.
final fromSecureStorage = BIP32HWallet.fromSecretStorage(toSecureStorage, "password");
// Explanation: This step decodes the wallet previously stored in secure storage using the provided password, resulting in a wallet instance.

```

## Contributing

Contributions are welcome! Please follow these guidelines:
 - Fork the repository and create a new branch.
 - Make your changes and ensure tests pass.
 - Submit a pull request with a detailed description of your changes.

## Feature requests and bugs #

Please file feature requests and bugs in the issue tracker.


