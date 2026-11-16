/// The 'bip' library serves as a comprehensive collection of libraries for working
/// with various Bitcoin Improvement Proposals (BIPs) in the realm of cryptocurrency.
library;

/// Export statement for the 'bip32' library, providing tools for working with BIP-32,
/// which defines hierarchical deterministic wallets and key derivation.
export 'package:blockchain_utils/protocol/bip/bip/bip32/bip32.dart';

/// Export statement for the 'bip38' library, offering functionality related to BIP-38,
/// a standard for encrypting and decrypting private keys in a human-readable format.
export 'package:blockchain_utils/protocol/bip/bip/bip38/bip38.dart';

/// Export statement for the 'bip39' library, which includes tools for managing BIP-39
/// mnemonic phrases, a standard for creating human-readable cryptographic key phrases.
export 'package:blockchain_utils/protocol/bip/bip/bip39/bip39.dart';

/// Export statement for the 'bip44' library, which provides support for BIP-44,
/// a standard that defines hierarchical deterministic wallets and key derivation for
/// various cryptocurrencies.
export 'package:blockchain_utils/protocol/bip/bip/bip44/bip44.dart';

/// Export statement for the 'bip49' library, offering tools for working with BIP-49,
/// a standard for hierarchical deterministic wallets and key derivation in cryptocurrencies.
export 'package:blockchain_utils/protocol/bip/bip/bip49/bip49.dart';

/// Export statement for the 'bip84' library, providing support for BIP-84, which defines
/// hierarchical deterministic wallets and key derivation for a specific set of cryptocurrencies.
export 'package:blockchain_utils/protocol/bip/bip/bip84/bip84.dart';

/// Export statement for the 'bip86' library, which offers functionality for BIP-86,
/// a standard that defines the creation and management of Bitcoin addresses in a more secure
/// and efficient manner.
export 'package:blockchain_utils/protocol/bip/bip/bip86/bip86.dart';

/// Export statement for the 'conf/bip_config' library, which centralizes coin-related
/// definitions, coin names, parameters, and coin configuration information for different BIPs.
export 'package:blockchain_utils/protocol/bip/bip/conf/bip_config.dart';

/// Export statement for the 'eip2333' library, providing EIP-2333
/// BLS12-381 hierarchical key generation (Lamport + HKDF-mod-r).
export 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333.dart';

/// Export statement for the 'eip2334' library, providing EIP-2334
/// BLS12-381 deterministic account hierarchy paths.
export 'package:blockchain_utils/protocol/bip/bip/eip2334/eip2334.dart';

/// Export statement for the 'nep649' library, providing NEP-649
/// deterministic ML-DSA-65 key derivation paths for NEAR.
export 'package:blockchain_utils/protocol/bip/bip/nep649/nep649.dart';
