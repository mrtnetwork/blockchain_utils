/// The 'schnorrkel' library provides tools for working with the Schnorrkel
/// digital signature scheme, including key management and cryptographic functions.
library;

/// Export statement for Schnorrkel key management components.
export 'keys/keys.dart';

/// Export statement for the Schnorrkel Merlin transcript, which is used for
/// creating transcripts to be used in the signature process.
export 'merlin/transcript.dart';

/// Export statement for the Schnorrkel Strobe framework, which provides
/// cryptographic primitives for building the Schnorrkel digital signature scheme.
export 'strobe/strobe.dart';
