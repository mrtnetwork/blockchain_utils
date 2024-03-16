# blockchain_utils

Discover a versatile and powerful cryptographic toolkit, carefully crafted in pure Dart to serve developers, businesses, and blockchain enthusiasts across multiple platforms. This package offers a wide array of essential features, including encoding/decoding for various data formats, support for numerous blockchain addresses, robust cryptographic algorithms, mnemonic management, and more – all without relying on external dependencies. Whether you're securing private keys, interacting with blockchain networks, or ensuring data integrity, this cross-platform solution simplifies your crypto journey. Experience a comprehensive set of tools designed to meet your diverse encoding, cryptography, and blockchain needs on iOS, Android, the web, Linux, and beyond.

This comprehensive package has been shaped by the influence of several key sources, culminating in its development for Dart.

- python [bip_utils](https://github.com/ebellocchia/bip_utils)
- python [ecdsa](https://github.com/tlsfuzzer/python-ecdsa)
- rust [schnorrkel](https://github.com/w3f/schnorrkel)
- js [stablelib](https://github.com/StableLib/stablelib)
- rust [strobe](https://github.com/rozbb/strobe-rs)


## Features

**Encoding and Decoding:**

1. **Base32 Encoding/Decoding:** Represent binary data with custom character sets for various encoding needs.

2. **SS58 Encoding/Decoding:** Encode Substrate-based blockchain addresses and public keys in a compact and human-readable format.

3. **Base58 and Base58 XMR Encoding/Decoding:** Efficiently encode binary data, with Base58 XMR tailored for Monero addresses.

4. **Base58Check Encoding/Decoding:** Supports checksum creation and verification in blockchain-related data.

5. **Bech32 Encoding/Decoding:** Including Bech32 for Bitcoin Cash (BCH) and Bech32 SegWit addresses, offering improved error detection and readability for blockchain addresses.

6. **Hex Encoding/Decoding:** Encode binary data as hexadecimal and decode it back.

7. **Web3 Secret Storage Definition:** Securely store and manage private keys using the Web3 Secret Storage format.

8. **UUIDv4 Generation:** Generate random UUIDs (Universally Unique Identifiers) following the UUIDv4 standard.

**Blockchain Address Encoding/Decoding:**
   - Zilliqa (ZIL)
   - Tezos (XTZ)
   - Ripple (XRP)
   - Monero (XMR)
   - Substrate address
   - Solana (SOL)
   - P2WPKH
   - P2TR
   - P2SH
   - Bitcoin Cash P2PKH
   - Harmony (ONE)
   - OKEx
   - Neo
   - NEAR
   - Nano
   - Injective
   - ICON
   - Filecoin
   - Ethereum
   - Ergo
   - EOS
   - Elrond
   - AVAX
   - Atom
   - Aptos
   - Algorand
   - Ada Shelley
   - Ada Byron

**Binary Data:**

9. **CBOR Encoding/Decoding:** Compact representation of structured data with cross-language compatibility.

**Cryptographic Algorithms:**

10. **Cryptographic Algorithms and Operations:**
    - AES (Advanced Encryption Standard)
    - ChaCha
    - ChaCha20Poly1305
    - CRC32 (Cyclic Redundancy Check)
    - CTR mode (Counter mode)
    - ECB mode (Electronic Codebook mode)
    - GCM (Galois/Counter Mode)
    - HMAC (Hash-based Message Authentication Code)
    - PBKDF2 (Password-Based Key Derivation Function 2)
    - Poly1305
    - scrypt (Password-based Key Derivation Function)
    - XModem CRC
    - Blake2b
    - Keccak
    - MD4 (Message Digest 4)
    - MD5 (Message Digest 5)
    - Rijndael (AES)
    - SHA (Secure Hash Algorithm)
    - SHA224
    - SHA256
    - SHA384
    - SHA512

   These algorithms provide a wide range of cryptographic functions, including encryption, decryption, message authentication, hashing, and more, to enhance security and data integrity in applications.

**Protocols:**

11. **Strobe Protocol:** A framework for cryptographic protocols, providing simplicity and compatibility for a variety of devices.

**Zero-Knowledge Proofs:**

12. **Merlin Transcript:** A STROBE-based transcript construction for zero-knowledge proofs.

**Schnorrkel-based Cryptography:**

13. **Schnorrkel-based Cryptographic Operations:** Includes Schnorrkel for signing, verification, key management, and more.

**Blockchain Support:**

14. **BIP39 Mnemonic Generation and Management:** Generate BIP39-compliant mnemonic phrases and manage cryptographic keys derived from them.

15. **Substrate Key, Address, and Coin Management:** Efficiently manage keys and addresses in Substrate-based blockchains.

16. **Monero Key, Address, and Coin Management:** Handle Monero cryptocurrency with support for key management, address derivation, and Monero mnemonics.

17. **BIP32 Multi-Curve Key Derivation and Address Management:** Derive keys across multiple cryptographic curves with BIP32 compliance.

18. **SLIP10 Key Derivation and Management:** Advanced key derivation capabilities.

19. **BIP38 Secure Paper Wallets:** Encrypt private keys to safeguard cryptocurrency assets.

20. **BIP44 Key, Address, and Coin Management:** Manage keys, derive addresses, and handle various coins in compliance with the BIP44 standard.

21. **BIP49 Key, Address, and Coin Management:** Similar to BIP44, with compliance to the BIP49 standard.

22. **BIP84 Key, Address, and Coin Management:** Manage keys, derive addresses, and handle various coins, complying with the BIP84 standard.

23. **BIP86 Key, Address, and Coin Management:** Manage keys, derive addresses, and handle various coins, complying with the BIP84 standard.

24. **Electrum Mnemonic V1 and V2 with Key and Address Management:** Support for both Electrum Mnemonic V1 and V2, including SegWit and Standard transactions.

These features make your package a comprehensive solution for encoding, cryptography, blockchain management, BIP39 mnemonic support, and diverse blockchain address encoding and decoding needs.

25. **Sign and Verification:** Implements classes for signing and verifying transaction digests.
   - Bitcoin (ECDSA, Schnorr)
   - BitcoinCash (EDDSA)
   - Dogecoin (EDDSA)
   - Litecoin (EDDSA)
   - Dash (EDDSA)
   - BSV (EDDSA)
   - Ethereum (EDDSA)
   - Tron (EDDSA)
   - Solana (EDDSA)
   - XRP (EDDSA, ECDSA)
   - Solana (EDDSA, EDDSA Khalow)

**Example: Explore Our Toolkit**

Discover the capabilities of our comprehensive crypto and blockchain toolkit through interactive tests. Visit our [test page](https://github.com/mrtnetwork/blockchain_utils/tree/main/test) to access thousands of examples, showcasing pure Dart's cross-platform functionality. Learn encoding, cryptography, address management, mnemonics, and more.


## Contributing

Contributions are welcome! Please follow these guidelines:
 - Fork the repository and create a new branch.
 - Make your changes and ensure tests pass.
 - Submit a pull request with a detailed description of your changes.

## Feature requests and bugs #

Please file feature requests and bugs in the issue tracker.


