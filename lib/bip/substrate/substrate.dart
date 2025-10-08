/// The 'substrate' library provides tools for working with the Substrate blockchain
/// ecosystem, including coin definitions, configuration data, and encoding utilities.
library;

/// Export statement for Substrate coin definitions and configuration.
export 'conf/substrate_coins.dart';
export 'conf/substrate_conf.dart';

/// Export statements for Substrate SCALE encoding utilities.
export 'scale/substrate_scale_enc_base.dart';
export 'scale/substrate_scale_enc_bytes.dart';
export 'scale/substrate_scale_enc_cuint.dart';
export 'scale/substrate_scale_enc_uint.dart';

/// Export statement for Substrate base components, including key, derivation, address.
export 'core/substrate_base.dart';

/// Export statement for Substrate key management components.
export 'keys/substrate_keys.dart';

/// Export statement for Substrate path components.
export 'path/substrate_path.dart';
