import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_net_ver.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';

import 'bip32_slip10_ed25519.dart';

/// Represents a Bip32Slip10Ed25519Blake2b hierarchical deterministic key for Ed25519-Blake2b curve.
///
/// This class extends the [Bip32Slip10Ed25519] class and provides functionality for
/// working with Bip32Slip10Ed25519Blake2b keys. It is used for key derivation and
/// management within the Ed25519-Blake2b curve.
///
/// Constructors:
/// - [Bip32Slip10Ed25519Blake2b] constructor for creating an instance with provided key data.
/// - [Bip32Slip10Ed25519Blake2b.fromSeed] constructor for creating a key from a seed.
/// - [Bip32Slip10Ed25519Blake2b.fromPrivateKey] constructor for creating a key from a private key.
/// - [Bip32Slip10Ed25519Blake2b.fromPublicKey] constructor for creating a key from a public key.
/// - [Bip32Slip10Ed25519Blake2b.fromExtendedKey] constructor for creating a key from an extended key string.
///
/// This class is specific to the Ed25519-Blake2b curve and provides necessary methods for
/// working with this curve, such as key derivation and management.
class Bip32Slip10Ed25519Blake2b extends Bip32Slip10Ed25519 {
  /// constructor for creating an instance with provided key data.
  Bip32Slip10Ed25519Blake2b(
      {required Bip32KeyData keyData,
      required Bip32KeyNetVersions keyNetVer,
      required List<int>? privKey,
      required List<int>? pubKey})
      : super(
            keyData: keyData,
            keyNetVer: keyNetVer,
            pubKey: pubKey,
            privKey: privKey);

  /// constructor for creating a key from a seed.
  Bip32Slip10Ed25519Blake2b.fromSeed(List<int> seedBytes,
      [Bip32KeyNetVersions? keyNetVer])
      : super.fromSeed(seedBytes, keyNetVer);

  /// constructor for creating a key from a private key.
  Bip32Slip10Ed25519Blake2b.fromExtendedKey(String exKeyStr,
      [Bip32KeyNetVersions? keyNetVer])
      : super.fromExtendedKey(exKeyStr, keyNetVer);

  /// constructor for creating a key from a public key.
  Bip32Slip10Ed25519Blake2b.fromPrivateKey(List<int> privKey,
      {Bip32KeyData? keyData, Bip32KeyNetVersions? keyNetVer})
      : super.fromPrivateKey(privKey, keyData: keyData, keyNetVer: keyNetVer);

  /// constructor for creating a key from an extended key string.
  Bip32Slip10Ed25519Blake2b.fromPublicKey(List<int> pubkey,
      {Bip32KeyData? keyData, Bip32KeyNetVersions? keyNetVer})
      : super.fromPublicKey(pubkey, keyData: keyData, keyNetVer: keyNetVer);

  /// Returns the curve type Ed25519-blake2b.
  @override
  EllipticCurveTypes get curveType {
    return EllipticCurveTypes.ed25519Blake2b;
  }

  @override
  Bip32Slip10Ed25519Blake2b childKey(Bip32KeyIndex index) {
    return super.childKey(index) as Bip32Slip10Ed25519Blake2b;
  }
}
