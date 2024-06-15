import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// An abstract class that defines methods for BIP-32 key derivation.
///
/// This class outlines key derivation methods for both public and private keys
/// in the context of BIP-32 hierarchical deterministic keys.
abstract class IBip32KeyDerivator {
  /// Checks if public key derivation is supported.
  bool isPublicDerivationSupported();

  /// Derives a child private key from the given private and public keys.
  ///
  /// The [privKey] parameter represents the parent private key, [pubKey] is the
  /// parent public key, [index] specifies the child key index, and [type] is the
  /// elliptic curve type.Tuple
  Tuple<List<int>, List<int>> ckdPriv(Bip32PrivateKey privKey,
      Bip32PublicKey pubKey, Bip32KeyIndex index, EllipticCurveTypes type);

  /// Derives a child public key from the given public key.
  ///
  /// The [pubKey] parameter represents the parent public key, [index] specifies
  /// the child key index, and [type] is the elliptic curve type.
  Tuple<List<int>, List<int>> ckdPub(
      Bip32PublicKey pubKey, Bip32KeyIndex index, EllipticCurveTypes type);
}
