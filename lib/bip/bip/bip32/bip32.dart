/// The 'bip32' library provides a comprehensive set of tools for working with
/// BIP-32 Hierarchical Deterministic Wallets, which are commonly used in
/// cryptocurrencies to manage and derive keys.
library bip32;

export 'base/bip32_base.dart';
export 'base/ibip32_key_derivator.dart';
export 'base/ibip32_mst_key_generator.dart';

/// Export statements for Khalow-based BIP-32 components:
/// Export the Khalow BIP-32 implementation for Ed25519.
export 'khalow/bip32_kholaw_ed25519.dart';

/// Export the key derivator for Khalow-based Ed25519 BIP-32.
export 'khalow/bip32_kholaw_ed25519_key_derivator.dart';

/// Export the base key derivator for Khalow-based BIP-32.
export 'khalow/bip32_kholaw_key_derivator_base.dart';

/// Export the master key generator for Khalow-based BIP-32.
export 'khalow/bip32_kholaw_mst_key_generator.dart';

/// Export statements for Slip-10-based BIP-32 components:
/// Export the Slip-10 BIP-32 implementation for Ed25519.
export 'slip10/bip32_slip10_ed25519.dart';

/// Export the Slip-10 BIP-32 implementation for Ed25519 with Blake2b.
export 'slip10/bip32_slip10_ed25519_blake2b.dart';

/// Export the key derivator for Slip-10-based BIP-32.
export 'slip10/bip32_slip10_key_derivator.dart';

/// Export the master key generator for Slip-10-based BIP-32.
export 'slip10/bip32_slip10_mst_key_generator.dart';

/// Export the Slip-10 BIP-32 implementation for NIST P-256 .
export 'slip10/bip32_slip10_nist256p1.dart';

/// Export the Slip-10 BIP-32 implementation for SECG P-256k1.
export 'slip10/bip32_slip10_secp256k1.dart';

/// Export statements for general BIP-32 components:
/// Export BIP-32 path utilities for working with paths.
export 'bip32_path.dart';

/// Export constants related to BIP-32.
export 'bip32_const.dart';

/// Export utilities for working with BIP-32 key network versions.
export 'bip32_key_net_ver.dart';

/// Export serialization utilities for BIP-32 keys.
export 'bip32_key_ser.dart';

/// Export a collection of BIP-32 key-related functions and structures.
export 'bip32_keys.dart';

export 'bip32_key_data.dart';
