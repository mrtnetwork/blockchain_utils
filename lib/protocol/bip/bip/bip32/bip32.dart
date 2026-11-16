/// The 'bip32' library provides a comprehensive set of tools for working with
/// BIP-32 Hierarchical Deterministic Wallets, which are commonly used in
/// cryptocurrencies to manage and derive keys.
library;

export 'package:blockchain_utils/protocol/bip/bip/bip32/base/bip32_base.dart';
export 'package:blockchain_utils/protocol/bip/bip/bip32/base/derivator.dart';

export 'package:blockchain_utils/protocol/bip/bip/bip32/khalow/bip32_kholaw_ed25519.dart';

/// Export the key derivator for Khalow-based Ed25519 BIP-32.
export 'package:blockchain_utils/protocol/bip/bip/bip32/khalow/bip32_kholaw_ed25519_key_derivator.dart';

/// Export the base key derivator for Khalow-based BIP-32.
export 'package:blockchain_utils/protocol/bip/bip/bip32/khalow/bip32_kholaw_key_derivator_base.dart';

/// Export the master key generator for Khalow-based BIP-32.
export 'package:blockchain_utils/protocol/bip/bip/bip32/khalow/bip32_kholaw_mst_key_generator.dart';

/// Export statements for Slip-10-based BIP-32 components:
/// Export the Slip-10 BIP-32 implementation for Ed25519.
export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_ed25519.dart';

/// Export the Slip-10 BIP-32 implementation for Ed25519 with Blake2b.
export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_ed25519_blake2b.dart';

/// Export the key derivator for Slip-10-based BIP-32.
export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_key_derivator.dart';

/// Export the master key generator for Slip-10-based BIP-32.
export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_mst_key_generator.dart';

/// Export the Slip-10 BIP-32 implementation for NIST P-256 .
export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_nist256p1.dart';

/// Export the Slip-10 BIP-32 implementation for SECG P-256k1.
export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_secp256k1.dart';

export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/bip32_slip10_nist256p1_hybrid.dart';

/// Export the Slip-10 implementation for ML-DSA-65 (NEP-649).
export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65.dart';

/// Export the key derivator for Slip-10 ML-DSA-65.
export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65_key_derivator.dart';

/// Export the master key generator for Slip-10 ML-DSA-65.
export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65_mst_key_generator.dart';

/// Export the key wrappers for Slip-10 ML-DSA-65.
export 'package:blockchain_utils/protocol/bip/bip/bip32/slip10/slip10_mldsa65_keys.dart';

/// Export errors for Slip-10 ML-DSA-65.

/// Export statements for general BIP-32 components:
/// Export BIP-32 path utilities for working with paths.
export 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_path.dart';

/// Export constants related to BIP-32.
export 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_const.dart';

/// Export utilities for working with BIP-32 key network versions.
export 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_net_ver.dart';

/// Export serialization utilities for BIP-32 keys.
export 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_ser.dart';

/// Export a collection of BIP-32 key-related functions and structures.
export 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_keys.dart';

export 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';

