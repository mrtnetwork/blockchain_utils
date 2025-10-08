## 5.2.0

- Renamed constructors in CborListValue and CborMapValue:
  - fixedLength → definite
  - dynamicLength → indefinite
- `CborListValue`, `CborMapValue`, `CborSetValue`, and `CborTagValue` no longer accept dynamic values.
They now only accept `CborValue` instances.

## 5.1.0

- Added support for HKDF (HMAC-based Key Derivation Function)
- Added support for X25519 operations, including ScalarMultBase and ScalarMult

## 5.0.0

- Ported the Bitcoin secp256k1 cryptographic library to Dart.
- Enhanced security: all private key implementations (except secp256r1) now use constant-time techniques for public key generation.
- Improved signing safety: all signer classes (except secp256r1) now use constant-time signing methods.
Note: I'm not an expert in constant-time or side-channel attack mitigation. Feedback is welcome to help improve the safety of this package.


## 4.4.0
- Added support for BCH schnor signig and verifying
- Fix schnorr signature validation

## 4.3.0

- Added support for MuSig2
  - Signing and verification
  - Nonce generation
  - Aggregate public key computation
  - Aggregate nonce computation

## 4.2.0

- Added support for aptos addresses using Secp256k1, Secp256r1, Multikey and MultiEd25519.
- Fix sui multisig address validator  

## 4.1.0

- Added support for Sui addresses using Secp256k1, Secp256r1, Ed25519, and MultiSig.  
- Implemented support for Sui BIP44 coin derivation.


## 4.0.1
  
- Fix schnorr vrf verification.

## 4.0.0

- Minimum required Dart SDK version updated to 3.3.
- Implemented an abstract class for chain services.
- Unified service provider design to support a single provider architecture across all `MRTNETWORK` packages.

## 3.5.0

- Implemented Monero cryptographic operations.

## 3.4.0

- Stellar Address Support: Add support for stellar Contract address.
- Fix incorrect CBOR encoding of large negative integers.

## 3.3.0

  - Fix substrate key generation from seed (ECDSA, EDDSA).

## 3.2.0

  - Add Pepecoin configiration to Bip-44 and Bip-49 coins.

## 3.1.0

- Ton Address Support: Implemented functionality to support Ton addresses.
- Ton Mnemonic Support:
  - Added mnemonic and seed generation capabilities for Ton.
  - Introduced a mnemonic validator for Ton.
- BIP-44 Support for TonCoin: Added TonCoin to the list of supported coins under the BIP-44 standard.
- The SecretWallet class name has been updated to Web3SecretStorageDefinitionV3.

## 3.0.0

- Improved hex performance.
- Added support for Substrate ECDSA: address, sign, vrfsign, verify, derive.
- Added support for Substrate SR25519: address, sign, vrfsign, verify, derive.
- Added support for Substrate ED25519: address, sign, vrfsign, verify, derive.

## 2.1.2

- Implements classes for signing and verifying cosmos transaction digests

## 2.1.1

- Fix Cbor bigint encoding.

## 2.1.0

- Implements classes for signing and verifying transaction digests.
- Introduces classes for signing and verifying transaction digests, with support for Cardano.
- Adds a new class for encoding and decoding ADA addresses, covering enterprise, pointer, base, reward, shelly, and shelly legacy address formats.
- Fixes an issue with CBOR decoding of negative integers in web environments.

## 2.0.1

- dart format .

## 2.0.0

- Implements classes for signing and verifying transaction digests.
- Bitcoin (ECDSA, Schnorr)
- BitcoinCash (ECDSA)
- Dogecoin (ECDSA)
- Litecoin (ECDSA)
- Dash (ECDSA)
- BSV (ECDSA)
- Ethereum (ECDSA)
- Tron (ECDSA)
- Solana (EDDSA)
- XRP (EDDSA, ECDSA)

## 1.6.0

- Addressed an issue with Cbor decoding.
- Enhanced secret storage definition to encrypt and decrypt bytes instead of strings. This resolves a compatibility issue with Ethereum keystore.

## 1.5.0

- Added a new class for signing and verifying Ethereum and tron transactions.

## 1.4.1

- Corrected Ripple address encoding for ED25519
- Added support for Ripple ED25519 coin

## 1.4.0

- Downgrade DART SDK version from 2.17.1 to 2.15.0

## 1.3.0

- Downgrade DART SDK version from 3.1.1 to 2.17.1 to address compatibility issues and ensure smoother integration.
- Added a new class for signing and verifying Ripple transactions.

## 1.2.1

- Resolved an issue with byte order in the method IntUtils.toBytes for more consistent behavior.

## 1.2.0

- Fixed several bugs to enhance the stability and reliability of the code.
- Added utility functions to handle XRP X-address format for improved compatibility.
- Resolved an issue with byte order in the method IntUtils.toBytes for more consistent behavior.

## 1.1.0

- Implementing custom exception classes for more effective error handling.

## 1.0.6

- Resolved issue with CBOR decoding of lists
- Removed "tags" property from CBOR
- Introduced a new class for CBOR tags
- Added convenient utilities for signing and verifying Bitcoin transactions

## Changelog for Major Release 1.0.3

We're excited to present our biggest update yet, introducing a wide range of new features and enhancements to our toolkit. In this release, we've expanded our offering to include comprehensive support for various data encoding formats, blockchain addresses, advanced cryptographic algorithms, and cross-platform capabilities. Here's what you can expect:

**New Features and Enhancements:**

- Added support for encoding and decoding across numerous formats, including Base32, Hex, and more.
- Extensive support for a wide range of blockchain addresses, covering popular networks like Bitcoin, Ethereum, and beyond.
- A rich set of cryptographic algorithms, enhancing data security and integrity.
- Cross-platform compatibility, extending to iOS, Android, the web, and Linux.
- Mnemonic management, now complemented by BIP39 compliance.

This major release marks a significant step forward, making our toolkit an all-in-one solution for crypto enthusiasts, developers, and businesses. Embrace the future of encoding, cryptography, and blockchain interaction with confidence. Upgrade today and explore the endless possibilities our package offers.

[Full Release Notes](https://github.com/mrtnetwork/blockchain_utils) for more details on this groundbreaking release.
