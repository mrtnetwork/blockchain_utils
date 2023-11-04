/// The 'bip_config' library provides configuration files and information related to
/// various BIP (Bitcoin Improvement Proposal) standards, including BIP-44, BIP-49, BIP-84,
/// and BIP-86. It defines coin names, parameters, and coin configuration data for
/// hierarchical deterministic wallets in cryptocurrencies, facilitating wallet development
/// and key derivation for a variety of blockchain networks.
library bip_config;

/// Export statement for BIP-44 coin definitions and parameters, including
/// coin names and configuration information for hierarchical deterministic wallets.
export 'bip44/bip44_coins.dart';
export 'bip44/bip44_conf.dart';

/// Export statement for BIP-49 coin definitions and parameters, including
/// coin names and configuration information for hierarchical deterministic wallets.
export 'bip49/bip49_coins.dart';
export 'bip49/bip49_conf.dart';

/// Export statement for BIP-84 coin definitions and parameters, including
/// coin names and configuration information for hierarchical deterministic wallets.
export 'bip84/bip84_coins.dart';
export 'bip84/bip84_conf.dart';

/// Export statement for BIP-86 coin definitions and parameters, including
/// coin names and configuration information for hierarchical deterministic wallets.
export 'bip86/bip86_coins.dart';
export 'bip86/bip86_conf.dart';
