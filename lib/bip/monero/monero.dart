/// The 'monero' library provides tools for working with Monero cryptocurrency, including
/// configuration data, mnemonic phrases, keys, and address generation.
library;

/// Export statement for Monero coin definitions and configuration.
export 'conf/monero_coins.dart';
export 'conf/monero_conf.dart';

/// Export statements for Monero mnemonic-related components.
export 'mnemonic/monero_entropy_generator.dart';
export 'mnemonic/monero_mnemonic.dart';
export 'mnemonic/monero_mnemonic_decoder.dart';
export 'mnemonic/monero_mnemonic_encoder.dart';
export 'mnemonic/monero_mnemonic_generator.dart';
export 'mnemonic/monero_mnemonic_utils.dart';
export 'mnemonic/monero_mnemonic_validator.dart';
export 'mnemonic/monero_seed_generator.dart';
export 'mnemonic/words_list/languages.dart';

/// Export statement for Monero base components, including address generation.
export 'monero_base.dart';

/// Export statement for Monero subaddress components.
export 'monero_subaddr.dart';
