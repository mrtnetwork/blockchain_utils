/// The 'bip39' library provides a comprehensive set of tools for working with
/// BIP-39 mnemonics, a standard for creating human-readable mnemonic phrases
/// for cryptographic keys.
library;

/// Export statement for word list languages used in BIP-39 mnemonics.
export 'word_list/languages.dart';

/// Export statement for the functionality related to generating entropy for BIP-39 mnemonics.
export 'bip39_entropy_generator.dart';

/// Export statement for the BIP-39 mnemonic class, which provides methods for
/// working with BIP-39 mnemonics, including generating, decoding, and encoding them.
export 'bip39_mnemonic.dart';

/// Export statement for the BIP-39 mnemonic decoder, which allows you to decode
/// BIP-39 mnemonic phrases into their binary representations.
export 'bip39_mnemonic_decoder.dart';

/// Export statement for the BIP-39 mnemonic encoder, which enables the conversion
/// of binary data back into BIP-39 mnemonic phrases.
export 'bip39_mnemonic_encoder.dart';

/// Export statement for the BIP-39 mnemonic generator, responsible for generating
/// valid mnemonic phrases that can be used to derive cryptographic keys.
export 'bip39_mnemonic_generator.dart';

/// Export statement for utility functions related to BIP-39 mnemonics, which can
/// be helpful for various tasks involving mnemonic phrases.
export 'bip39_mnemonic_utils.dart';

/// Export statement for the BIP-39 seed generator, which is responsible for
/// generating cryptographic seeds from BIP-39 mnemonic phrases, a crucial step
/// in creating cryptographic keys.
export 'bip39_seed_generator.dart';

/// Export statement for the BIP-39 mnemonic validator, which helps you ensure the
/// validity of BIP-39 mnemonic phrases, important for the security and reliability
/// of cryptographic key management.
export 'bip39_mnemonic_validator.dart';
