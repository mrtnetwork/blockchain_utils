/// The 'monero' library provides tools for working with Monero cryptocurrency, including
/// configuration data, mnemonic phrases, keys, and address generation.
library;

/// Export statement for Monero coin definitions and configuration.
export 'package:blockchain_utils/protocol/bip/monero/conf/monero_coins.dart';
export 'package:blockchain_utils/protocol/bip/monero/conf/monero_conf.dart';

/// Export statements for Monero mnemonic-related components.
export 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_entropy_generator.dart';
export 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_mnemonic.dart';
export 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_mnemonic_decoder.dart';
export 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_mnemonic_encoder.dart';
export 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_mnemonic_generator.dart';
export 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_mnemonic_utils.dart';
export 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_mnemonic_validator.dart';
export 'package:blockchain_utils/protocol/bip/monero/mnemonic/monero_seed_generator.dart';
export 'package:blockchain_utils/protocol/bip/monero/mnemonic/words_list/languages.dart';

/// Export statement for Monero base components, including address generation.
export 'package:blockchain_utils/protocol/bip/monero/monero_base.dart';

/// Export statement for Monero subaddress components.
export 'package:blockchain_utils/protocol/bip/monero/monero_subaddr.dart';
