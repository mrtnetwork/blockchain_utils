/// The 'cdsa' library provides tools and components for working with various cryptographic
/// algorithms, including elliptic curve cryptography (ECDSA and EDDSA) and related functionality.
library cdsa;

/// Export statement for cryptographic curve definitions.
export 'curve/curves.dart';

/// Export statement for ECDSA (Elliptic Curve Digital Signature Algorithm) private and
/// public key components, as well as signature functionality.
export 'ecdsa/private_key.dart';
export 'ecdsa/public_key.dart';
export 'ecdsa/signature.dart';

/// Export statement for EDDSA (Edwards-curve Digital Signature Algorithm) private and
/// public key components.
export 'eddsa/privatekey.dart';
export 'eddsa/publickey.dart';

/// Export statements for elliptic curve point representations, including Edwards
/// and projective points.
export 'point/edwards.dart';
export 'point/point.dart';
export 'point/ec_projective_point.dart';

/// Export statement for RFC 6979, which provides deterministic ECDSA signatures,
/// allowing for secure signature generation.
export 'rfc6979/rfc6979.dart';
