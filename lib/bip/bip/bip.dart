/// The 'bip' library serves as a comprehensive collection of libraries for working
/// with various Bitcoin Improvement Proposals (BIPs) in the realm of cryptocurrency.
library;

/// Export statement for the 'bip32' library, providing tools for working with BIP-32,
/// which defines hierarchical deterministic wallets and key derivation.
export 'bip32/bip32.dart';

/// Export statement for the 'bip38' library, offering functionality related to BIP-38,
/// a standard for encrypting and decrypting private keys in a human-readable format.
export 'bip38/bip38.dart';

/// Export statement for the 'bip39' library, which includes tools for managing BIP-39
/// mnemonic phrases, a standard for creating human-readable cryptographic key phrases.
export 'bip39/bip39.dart';

/// Export statement for the 'bip44' library, which provides support for BIP-44,
/// a standard that defines hierarchical deterministic wallets and key derivation for
/// various cryptocurrencies.
export 'bip44/bip44.dart';

/// Export statement for the 'bip49' library, offering tools for working with BIP-49,
/// a standard for hierarchical deterministic wallets and key derivation in cryptocurrencies.
export 'bip49/bip49.dart';

/// Export statement for the 'bip84' library, providing support for BIP-84, which defines
/// hierarchical deterministic wallets and key derivation for a specific set of cryptocurrencies.
export 'bip84/bip84.dart';

/// Export statement for the 'bip86' library, which offers functionality for BIP-86,
/// a standard that defines the creation and management of Bitcoin addresses in a more secure
/// and efficient manner.
export 'bip86/bip86.dart';

/// Export statement for the 'conf/bip_config' library, which centralizes coin-related
/// definitions, coin names, parameters, and coin configuration information for different BIPs.
export 'conf/bip_config.dart';

export 'types/types.dart';
