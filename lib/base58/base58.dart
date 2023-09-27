/// Base58 Encoding and Decoding Library
///
/// This library provides functions for encoding and decoding data using the
/// Base58 encoding scheme. Base58 is commonly used in blockchain applications,
/// such as Bitcoin and Ripple, for encoding binary data into a human-readable format.
///
/// Modules and Exports:
///
/// - `encodeCheck`, `decodeCheck`: Exported from 'package:blockchain_utils/base58/impl/bacse58_check.dart'.
///   These functions provide Base58 encoding and decoding with checksums, which
///   are often used in blockchain addresses and data encoding.
///
/// - `encode`, `decode`, `ripple`, `bitcoin`: Exported from 'package:blockchain_utils/base58/impl/base58.dart'.
///   These functions provide basic Base58 encoding and decoding, along with
///   implementations specific to Ripple and Bitcoin Base58 encoding schemes.
library base58;

export 'package:blockchain_utils/base58/impl/bacse58_check.dart'
    show encodeCheck, decodeCheck;

export 'package:blockchain_utils/base58/impl/base58.dart'
    show encode, decode, ripple, bitcoin;
