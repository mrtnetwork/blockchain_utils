/// Blockchain Utilities Library
///
/// This library provides a collection of utility functions and classes for
/// working with blockchain-related operations and cryptographic tasks.
/// Developers can use these utilities to simplify tasks such as encoding and
/// decoding data, generating BIP39 mnemonics, working with HD wallets,
/// and more in the context of blockchain applications.
///
/// Modules and Exports:
///
/// - `base58`: Exported from 'package:blockchain_utils/base58/base58.dart'.
///   Provides functions for Base58 encoding and decoding.
///
/// - `bech32`: Exported from 'package:blockchain_utils/bech32/bech32.dart'.
///   Provides functions for encoding and decoding Bech32 data.
///
/// - `bip39`: Exported from 'package:blockchain_utils/bip39/bip39.dart'.
///   Includes classes and utilities for working with BIP39 mnemonics and
///   related functionality.
///
/// - `hd_wallet`: Exported from 'package:blockchain_utils/hd_wallet/hd_wallet.dart'.
///   Offers support for HD wallets using the BIP32 specification.
///
/// - `crypto_currencies`: Exported from 'package:blockchain_utils/hd_wallet/cypto_currencies/cyrpto_currency.dart'.
///   Provides information about cryptocurrency symbols and related data.
///
/// - `secret_wallet`: Exported from 'package:blockchain_utils/secret_wallet/secret_wallet.dart'.
///   Includes utilities for creating and encoding secret wallets.

library blockchain_utils;

export 'package:blockchain_utils/base58/base58.dart';

export 'package:blockchain_utils/bech32/bech32.dart'
    show encodeBech32, decodeBech32;

export 'package:blockchain_utils/bip39/bip39.dart'
    show BIP39, Bip39Language, Bip39WordLength;

export 'package:blockchain_utils/hd_wallet/hd_wallet.dart' show BIP32HWallet;
export 'package:blockchain_utils/hd_wallet/cypto_currencies/cyrpto_currency.dart'
    show CurrencySymbol, Cryptocurrency;

export 'package:blockchain_utils/secret_wallet/secret_wallet.dart'
    show SecretWallet, SecretWalletEncoding;
