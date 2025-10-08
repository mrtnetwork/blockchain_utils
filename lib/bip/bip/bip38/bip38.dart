/// The 'bip38' library provides tools for working with BIP-38, a standard for
/// encrypting and decrypting private keys in a human-readable format.
library;

/// Export statement for BIP-38 address-related functions and utilities.
export 'bip38_addr.dart';

/// Export statement for the BIP-38 base implementation.
export 'bip38_base.dart';

/// Export statement for BIP-38 functions related to elliptic curve cryptography.
export 'bip38_ec.dart';

/// Export statement for BIP-38 functions when no elliptic curve cryptography is used.
export 'bip38_no_ec.dart';
