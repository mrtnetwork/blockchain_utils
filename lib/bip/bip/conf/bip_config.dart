/// The 'bip_config' library provides configuration files and information related to
/// various BIP (Bitcoin Improvement Proposal) standards, including BIP-44, BIP-49, BIP-84,
/// and BIP-86. It defines coin names, parameters, and coin configuration data for
/// hierarchical deterministic wallets in cryptocurrencies, facilitating wallet development
/// and key derivation for a variety of blockchain networks.
library;

export 'bip/bip_coins.dart';

/// bip44
export 'bip44/bip44_coins.dart';
export 'bip44/bip44_conf.dart';

/// bip49
export 'bip49/bip49_coins.dart';
export 'bip49/bip49_conf.dart';

/// bip84
export 'bip84/bip84_coins.dart';
export 'bip84/bip84_conf.dart';

/// bip86
export 'bip86/bip86_coins.dart';
export 'bip86/bip86_conf.dart';

/// coin configs
export 'config/bip_bitcoin_cash_conf.dart';
export 'config/bip_coin_conf.dart';
export 'config/bip_litecoin_conf.dart';

/// coin constants
export 'const/bip_conf_const.dart';

/// crypto coin base class
export 'core/coins.dart';
export 'core/coin_conf.dart';
