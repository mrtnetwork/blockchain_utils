/// The 'cardano' library provides tools and components related to Cardano blockchain,
/// including key derivation, hierarchical deterministic wallets, mnemonic seed generation,
/// and more.
library;

/// Export statement for Cardano Byron Legacy BIP-32 related components.
export 'package:blockchain_utils/protocol/bip/cardano/bip32/cardano_byron_legacy_bip32.dart';
export 'package:blockchain_utils/protocol/bip/cardano/bip32/cardano_byron_legacy_key_derivator.dart';
export 'package:blockchain_utils/protocol/bip/cardano/bip32/cardano_byron_legacy_mst_key_generator.dart';

/// Export statement for Cardano Icarus BIP-32 related components.
export 'package:blockchain_utils/protocol/bip/cardano/bip32/cardano_icarus_bip32.dart';
export 'package:blockchain_utils/protocol/bip/cardano/bip32/cardano_icarus_mst_key_generator.dart';

/// Export statement for Cardano Byron Legacy components.
export 'package:blockchain_utils/protocol/bip/cardano/byron/cardano_byron_legacy.dart';

/// Export statement for CIP-1852 components, which relate to Cardano Improvement
/// Proposal 1852, introducing the concept of address discrimination for Cardano.
export 'package:blockchain_utils/protocol/bip/cardano/cip1852/cip1852.dart';

/// Export statement for CIP-1852 coin definitions and configuration.
export 'package:blockchain_utils/protocol/bip/cardano/cip1852/conf/cip1852_coins.dart';
export 'package:blockchain_utils/protocol/bip/cardano/cip1852/conf/cip1852_conf.dart';

/// Export statement for Cardano mnemonic seed generation for Byron Legacy and Icarus wallets.
export 'package:blockchain_utils/protocol/bip/cardano/mnemonic/cardano_byron_legacy_seed_generator.dart';
export 'package:blockchain_utils/protocol/bip/cardano/mnemonic/cardano_icarus_seed_generator.dart';

/// Export statement for Cardano Shelley components, which are relevant to the Shelley era
/// of the Cardano blockchain.
export 'package:blockchain_utils/protocol/bip/cardano/shelley/cardano_shelley.dart';
export 'package:blockchain_utils/protocol/bip/cardano/shelley/cardano_shelley_keys.dart';

export 'package:blockchain_utils/protocol/bip/cardano/cip0019/cip0019.dart';
